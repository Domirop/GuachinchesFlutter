import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/model/survey_in_app_choice.dart';
import 'package:guachinches/data/model/survey_v3.dart';
import 'package:guachinches/services/survey_integrity/device_identity_service.dart';
import 'package:guachinches/ui/pages/survey_in_app/survey_vote_state.dart';
import 'package:guachinches/utils/app_version.dart';

export 'package:guachinches/ui/pages/survey_in_app/survey_vote_state.dart';

const _tag = 'survey-v3';

/// Presenter de la encuesta v3 (ENCUESTA-SEGURIDAD.md, «Plan elegido: App
/// Check»).
///
/// Flujo: edición → ¿versión mínima? → App Check activo e identidad del móvil →
/// `my-votes` (token de App Check nuevo; lo ya votado) → candidatos sin los ya
/// votados → elegir → `votes` (otro token nuevo, que el servidor consume).
///
/// Reintentos:
/// - Con espera (backoff) solo en lecturas sin token (edición y candidatos).
/// - Un voto **nunca** se reenvía con el mismo token de App Check: es de uso
///   limitado y el servidor lo consume. Solo hay un reintento automático, con
///   token nuevo, si el servidor responde `403 integrity_failed` por token ya
///   usado (`app_check_replayed`) o caducado (`stale`): no se contó nada.
/// - `my-votes` usa el token estándar de App Check (no gasta cuota de uso
///   limitado); `votes`, uno de uso limitado nuevo en cada petición.
/// - `429`, `503` y red: se informa y el usuario pulsa «Reintentar» (token
///   nuevo).
///
/// Lo que se registra son etapas y códigos: nunca tokens ni `localIdHash`.
class SurveyVotePresenter extends ChangeNotifier {
  final RemoteRepository _repo;
  final DeviceIdentityService _identity;
  final String? _appVersion;
  final DateTime Function() _now;
  final Future<void> Function(Duration) _sleep;
  final Random _random;
  final Duration minDuration;

  SurveyVoteState _state = const SurveyVoteState();
  DateTime? _startedAt;

  /// Candidatos tal cual llegan (para volver a filtrar tras votar).
  Map<String, List<SurveyInAppChoice>> _allCandidates = const {};

  /// Votos de un envío que se cortó después de salir (modo avión a mitad): si
  /// el reintento responde 409 con todos ellos, es que el primero sí entró.
  List<SurveyVoteSelection>? _maybeDelivered;
  bool _disposed = false;

  SurveyVotePresenter({
    required RemoteRepository repository,
    required DeviceIdentityService identity,
    String? appVersion,
    DateTime Function()? clock,
    Future<void> Function(Duration)? sleep,
    Random? random,
    this.minDuration = const Duration(seconds: 3),
  })  : _repo = repository,
        _identity = identity,
        _appVersion = appVersion,
        _now = clock ?? DateTime.now,
        _sleep = sleep ?? Future<void>.delayed,
        _random = random ?? Random();

  factory SurveyVotePresenter.platform(RemoteRepository repository) =>
      SurveyVotePresenter(
        repository: repository,
        identity: DeviceIdentityService.platform(),
        appVersion: currentAppVersion(),
      );

  SurveyVoteState get state => _state;

  void _set(SurveyVoteState s) {
    if (_disposed) return;
    _state = s;
    notifyListeners();
  }

  // ── API para la vista ──────────────────────────────────────────────────

  /// Carga (o recarga) todo. Siempre deja un `stage` distinto de `loading`.
  Future<void> load() async {
    _set(_state.copyWith(
        stage: SurveyVoteStage.loading,
        failure: () => null,
        conflicts: const [],
        accepted: const []));
    try {
      final edition = await _retrying(_repo.getCurrentSurveyEdition);
      _set(_state.copyWith(edition: edition));
      if (edition.status == SurveyEditionStatus.upcoming) {
        return _set(_state.copyWith(stage: SurveyVoteStage.upcoming));
      }
      if (edition.status == SurveyEditionStatus.closed) {
        return _set(_state.copyWith(
            stage: SurveyVoteStage.closed,
            failure: () => const SurveyEditionClosed()));
      }
      final min = edition.minAppVersion[_identity.platform];
      if (min != null &&
          _appVersion != null &&
          compareAppVersions(_appVersion!, min) < 0) {
        return _set(_state.copyWith(
            stage: SurveyVoteStage.upgradeRequired,
            failure: () => SurveyUpgradeRequired(min)));
      }
      await _identity.ensureReady();
      final mine = await _withFreshToken(
          'my-votes',
          _identity.identityRequest,
          (r) => _repo.getMySurveyVotes(edition.editionId, r.body,
              appCheckToken: r.appCheckToken));
      if (mine.status == SurveyDeviceStatus.blocked) {
        return _set(_state.copyWith(
            stage: SurveyVoteStage.blocked,
            failure: () => const SurveyDeviceBlocked()));
      }
      final voted = _toSets(mine.voted);
      final all = _allCandidates = await _loadCandidates(edition);
      _startedAt = _now();
      _set(_state.copyWith(
        stage: SurveyVoteStage.ready,
        voted: voted,
        candidates: _filter(all, voted, edition),
        selection: {
          for (final e in _state.selection.entries)
            if (!_isVoted(voted, e.key, e.value, edition)) e.key: e.value
        },
      ));
      AppLogger.info(_tag, 'load → ready');
    } catch (e) {
      final (stage, failure) = _map(e);
      AppLogger.warn(_tag, 'load → ${(stage ?? SurveyVoteStage.failed).name} '
          '${_describe(e)}');
      _set(_state.copyWith(
          stage: stage ?? SurveyVoteStage.failed, failure: () => failure));
    }
  }

  /// Elige [value] en [category]; con `null` (o el mismo valor) la quita.
  void select(String category, String? value) {
    if (_state.stage != SurveyVoteStage.ready) return;
    final selection = Map.of(_state.selection);
    if (value == null || selection[category] == value) {
      selection.remove(category);
    } else {
      selection[category] = value;
    }
    _set(_state.copyWith(
      selection: selection,
      failure: () => null,
      conflicts: [
        for (final c in _state.conflicts)
          if (c.category != category) c
      ],
    ));
  }

  /// Envía todos los votos de la papeleta juntos (atómico en el servidor).
  Future<void> submit() async {
    if (_state.stage != SurveyVoteStage.ready) return;
    if (_state.selection.isEmpty) {
      return _set(_state.copyWith(failure: () => const SurveyNoSelection()));
    }
    final started = _startedAt;
    if (started != null && _now().difference(started) < minDuration) {
      return _set(_state.copyWith(failure: () => const SurveyTooFast()));
    }
    final edition = _state.edition!;
    final votes = [
      for (final c in (_state.selection.keys.toList()..sort()))
        SurveyVoteSelection(c, _state.selection[c]!)
    ];
    _set(_state.copyWith(
        stage: SurveyVoteStage.submitting,
        failure: () => null,
        conflicts: const []));
    try {
      final receipt = await _withFreshToken(
          'vote',
          () => _identity.voteRequest(votes),
          (r) => _repo.submitSurveyVotesV3(edition.editionId, r.body,
              appCheckToken: r.appCheckToken));
      _maybeDelivered = null;
      AppLogger.info(_tag, 'submit → 201 (${votes.length})');
      _onSent(edition, receipt.accepted.isEmpty ? votes : receipt.accepted,
          receipt.voted);
    } catch (e) {
      if (e is SurveyApiException && e.code == 'already_voted_this_business') {
        return _onConflict(edition, votes, e.conflicts);
      }
      if (e is SurveyNetworkException && e.maybeDelivered) {
        _maybeDelivered = votes;
      }
      final (stage, failure) = _map(e);
      AppLogger.warn(_tag, 'submit → ${(stage ?? SurveyVoteStage.ready).name} '
          '${_describe(e)}');
      _set(_state.copyWith(
          stage: stage ?? SurveyVoteStage.ready, failure: () => failure));
    }
  }

  /// Botón «Reintentar»: recarga si no llegó a cargar; si no, reenvía (con un
  /// token nuevo).
  Future<void> retry() async {
    switch (_state.stage) {
      case SurveyVoteStage.ready:
        if (_state.failure?.retryable ?? false) return submit();
        return;
      case SurveyVoteStage.loading:
      case SurveyVoteStage.submitting:
        return;
      default:
        return load();
    }
  }

  /// «Votar a otros sitios»: vacía la papeleta y vuelve a la elección (sin los
  /// negocios ya votados).
  void voteAgain() {
    if (_state.stage != SurveyVoteStage.sent) return;
    _startedAt = _now();
    _set(_state.copyWith(
      stage: SurveyVoteStage.ready,
      selection: const {},
      accepted: const [],
      conflicts: const [],
      failure: () => null,
    ));
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // ── Envío ──────────────────────────────────────────────────────────────

  /// Pide el token justo antes de enviar ([sign] va pegado a [send]). Si el
  /// servidor dice que ese token ya se usó (`app_check_replayed`) o que está
  /// caducado (`app_check_invalid` / `stale`, > 120 s), pide **otro** y repite
  /// una sola vez: la petición se rechazó antes de contar nada.
  Future<T> _withFreshToken<T>(
    String what,
    Future<SurveySignedRequest> Function() sign,
    Future<T> Function(SurveySignedRequest) send,
  ) async {
    for (var attempt = 0;; attempt++) {
      final request = await sign();
      try {
        return await send(request);
      } on SurveyApiException catch (e) {
        final retry = e.isReplayedAppCheck || e.isStaleAppCheck;
        if (!retry || attempt > 0) rethrow;
        AppLogger.info(_tag, '$what: token ${e.isStaleAppCheck ? 'caducado' : 'ya usado'} → token nuevo');
      }
    }
  }

  void _onSent(SurveyEdition edition, List<SurveyVoteSelection> accepted,
      SurveyVoted serverVoted) {
    final voted = serverVoted.isEmpty
        ? _merge(_state.voted, accepted)
        : _toSets(serverVoted);
    _set(_state.copyWith(
      stage: SurveyVoteStage.sent,
      accepted: accepted,
      voted: voted,
      selection: const {},
      conflicts: const [],
      candidates: _filter(_allCandidates, voted, edition),
      failure: () => null,
    ));
  }

  void _onConflict(SurveyEdition edition, List<SurveyVoteSelection> votes,
      List<SurveyVoteSelection> conflicts) {
    final pending = _maybeDelivered;
    _maybeDelivered = null;
    if (pending != null &&
        setEquals(pending.toSet(), votes.toSet()) &&
        conflicts.toSet().containsAll(votes)) {
      // El envío cortado sí había entrado: es un éxito, no un 409.
      AppLogger.info(_tag, 'submit → 409 de un envío ya contado: sent');
      return _onSent(edition, votes, const {});
    }
    AppLogger.info(_tag, 'submit → 409 (${conflicts.length} conflictos)');
    _set(_state.copyWith(
      stage: SurveyVoteStage.ready,
      voted: _merge(_state.voted, conflicts),
      selection: {
        for (final s in _state.selection.entries)
          if (!conflicts.any((c) => c.value == s.value)) s.key: s.value
      },
      conflicts: conflicts,
      failure: () => SurveyAlreadyVoted(conflicts),
    ));
  }

  // ── Candidatos ─────────────────────────────────────────────────────────

  Future<Map<String, List<SurveyInAppChoice>>> _loadCandidates(
      SurveyEdition edition) async {
    final lists = await Future.wait([
      for (final cat in edition.categories)
        _retrying(() => _repo.getSurveyEditionChoices(edition.editionId, cat))
    ]);
    return {
      for (var i = 0; i < edition.categories.length; i++)
        edition.categories[i]: [
          for (final c in lists[i])
            if (c.value.isNotEmpty) c
        ]..shuffle(_random),
    };
  }

  bool _isVoted(Map<String, Set<String>> voted, String category, String value,
          SurveyEdition edition) =>
      edition.businessScope
          ? voted.values.any((s) => s.contains(value))
          : (voted[category]?.contains(value) ?? false);

  Map<String, List<SurveyInAppChoice>> _filter(
          Map<String, List<SurveyInAppChoice>> all,
          Map<String, Set<String>> voted,
          SurveyEdition edition) =>
      {
        for (final e in all.entries)
          e.key: [
            for (final c in e.value)
              if (!_isVoted(voted, e.key, c.value, edition)) c
          ]
      };

  static Map<String, Set<String>> _toSets(SurveyVoted v) =>
      {for (final e in v.entries) e.key: e.value.toSet()};

  static Map<String, Set<String>> _merge(
      Map<String, Set<String>> base, List<SurveyVoteSelection> add) {
    final out = {for (final e in base.entries) e.key: {...e.value}};
    for (final s in add) {
      (out[s.category] ??= <String>{}).add(s.value);
    }
    return out;
  }

  // ── Reintentos y errores ───────────────────────────────────────────────

  static const _backoff = [Duration(milliseconds: 600), Duration(seconds: 2)];

  /// Solo para lecturas sin token: red o 5xx (salvo 503 con espera larga) →
  /// espera y repite.
  Future<T> _retrying<T>(Future<T> Function() op) async {
    for (var attempt = 0;; attempt++) {
      try {
        return await op();
      } catch (e) {
        // Un fallo de pinning no se arregla esperando: no se reintenta.
        final transient = (e is SurveyNetworkException && !e.untrusted) ||
            (e is SurveyApiException &&
                e.status >= 500 &&
                e.code != 'integrity_unavailable' &&
                (e.retryAfter == null || e.retryAfter! <= _backoff.last));
        if (!transient || attempt >= _backoff.length) rethrow;
        await _sleep(e is SurveyApiException && e.retryAfter != null
            ? e.retryAfter!
            : _backoff[attempt]);
      }
    }
  }

  /// Error → (etapa que bloquea la pantalla o `null` si es un aviso, fallo).
  (SurveyVoteStage?, SurveyFailure) _map(Object e) {
    if (e is SurveyNetworkException) {
      return (
        null,
        e.untrusted ? const SurveyInsecureConnection() : const SurveyNetworkFailure()
      );
    }
    if (e is SurveyIntegrityException) {
      switch (e.error) {
        case SurveyIntegrityError.unsupported:
          return (SurveyVoteStage.unsupported, const SurveyDeviceUnsupported());
        case SurveyIntegrityError.network:
          return (null, const SurveyNetworkFailure());
        case SurveyIntegrityError.rateLimited:
          return (null, const SurveyRateLimited());
        case SurveyIntegrityError.serverUnavailable:
        case SurveyIntegrityError.keychainLocked:
          return (null, const SurveyVerificationUnavailable());
        case SurveyIntegrityError.keychain:
        case SurveyIntegrityError.failed:
          return (null, SurveyIntegrityFailed('client', e.error.name));
      }
    }
    if (e is SurveyApiException) {
      switch (e.code) {
        case 'upgrade_required':
          final min = e.minAppVersion;
          return (
            SurveyVoteStage.upgradeRequired,
            SurveyUpgradeRequired(min is Map
                ? min[_identity.platform]?.toString()
                : min?.toString())
          );
        case 'device_blocked':
          return (SurveyVoteStage.blocked, const SurveyDeviceBlocked());
        case 'edition_closed':
          return e.details['status'] == 'upcoming'
              ? (SurveyVoteStage.upcoming, const SurveyEditionClosed())
              : (SurveyVoteStage.closed, const SurveyEditionClosed());
        case 'edition_not_found':
          // Ninguna edición protegida: no hay votación ahora mismo.
          return (SurveyVoteStage.closed, const SurveyEditionClosed());
        case 'already_voted_this_business':
          return (null, SurveyAlreadyVoted(e.conflicts));
        case 'integrity_failed':
          return (null, SurveyIntegrityFailed(e.code, e.reason));
        case 'rate_limited':
          return (null, SurveyRateLimited(e.retryAfter));
        case 'verification_unavailable':
          return (null, SurveyVerificationUnavailable(e.retryAfter));
        case 'integrity_unavailable':
          return (null, const SurveyVotingUnavailable());
        case 'invalid_option':
          final c = e.details['category'], v = e.details['value'];
          return (
            null,
            SurveyInvalidOption(c == null || v == null
                ? null
                : SurveyVoteSelection(c.toString(), v.toString()))
          );
      }
      if (e.status == 426) {
        return (SurveyVoteStage.upgradeRequired, const SurveyUpgradeRequired());
      }
      if (e.status == 429) return (null, SurveyRateLimited(e.retryAfter));
      if (e.status == 503) {
        return (null, SurveyVerificationUnavailable(e.retryAfter));
      }
      return (null, SurveyServerFailure(e.status, e.code));
    }
    return (null, const SurveyServerFailure());
  }

  /// Para el log: tipo y código, nunca el contenido.
  static String _describe(Object e) =>
      e is SurveyApiException ||
              e is SurveyIntegrityException ||
              e is SurveyNetworkException
          ? e.toString()
          : e.runtimeType.toString();
}
