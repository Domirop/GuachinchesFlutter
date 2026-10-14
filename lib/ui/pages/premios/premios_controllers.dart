import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/model/survey_v3.dart';
import 'package:guachinches/services/app_storage.dart';
import 'package:guachinches/ui/pages/premios/premios_models.dart';
import 'package:guachinches/ui/pages/survey_in_app/survey_vote_presenter.dart';
import 'package:http/http.dart';

// ── Interfaces de las vistas ───────────────────────────────────────────────
//
// Las pantallas de la encuesta solo conocen estas clases: un estado
// inmutable ([PremiosFlowState], [PremiosRankingState]) y unos pocos
// callbacks. La votación va sobre el presenter del contrato v3
// (`SurveyVotePresenter`: App Check, identidad del móvil y errores tipados;
// ver `docs/encuesta-antivoto.md`).

/// Flujo de votación: candidatos, elección por categoría y envío.
abstract class PremiosFlowController extends ChangeNotifier {
  PremiosFlowState get state;

  /// (Re)carga todo: edición, identidad, lo ya votado y candidatos.
  Future<void> load();

  /// Elige [candidate] en su categoría; si ya estaba elegido, lo quita.
  void pick(PremiosCategory category, PremiosCandidate candidate);

  /// Envía todos los votos juntos.
  Future<void> submit();

  /// «Reintentar»: recarga si no llegó a cargar o reenvía (token nuevo).
  Future<void> retry();

  /// «Votar a otros sitios»: vacía la papeleta (sin los ya votados).
  Future<void> voteAgain();
}

/// Ranking por categoría con puestos compartidos.
abstract class PremiosRankingController extends ChangeNotifier {
  PremiosRankingState get state;
  Future<void> refresh();
}

// ── Votación sobre el presenter v3 ─────────────────────────────────────────

/// `SurveyFailure` del presenter → aviso de la vista.
PremiosErrorKind? premiosErrorKindOf(SurveyFailure? f) => switch (f) {
      null => null,
      SurveyNoSelection() => PremiosErrorKind.noSelection,
      SurveyTooFast() => PremiosErrorKind.tooFast,
      SurveyAlreadyVoted() => PremiosErrorKind.alreadyVoted,
      SurveyIntegrityFailed() => PremiosErrorKind.deviceUnverified,
      SurveyRateLimited() => PremiosErrorKind.rateLimited,
      SurveyVerificationUnavailable() =>
        PremiosErrorKind.verificationUnavailable,
      SurveyNetworkFailure() => PremiosErrorKind.network,
      SurveyInvalidOption() => PremiosErrorKind.invalidOption,
      SurveyInsecureConnection() => PremiosErrorKind.insecureConnection,
      SurveyVotingUnavailable() => PremiosErrorKind.votingUnavailable,
      SurveyServerFailure() => PremiosErrorKind.server,
      // Estos acompañan a una etapa de bloqueo ([premiosGateOf]).
      SurveyUpgradeRequired() ||
      SurveyDeviceUnsupported() ||
      SurveyDeviceBlocked() ||
      SurveyEditionClosed() =>
        null,
    };

/// Etapa del presenter → pantalla de bloqueo.
PremiosGate? premiosGateOf(SurveyVoteStage stage) => switch (stage) {
      SurveyVoteStage.upcoming => PremiosGate.upcoming,
      SurveyVoteStage.closed => PremiosGate.closed,
      SurveyVoteStage.blocked => PremiosGate.blocked,
      SurveyVoteStage.upgradeRequired => PremiosGate.upgradeRequired,
      SurveyVoteStage.unsupported => PremiosGate.unsupported,
      _ => null,
    };

PremiosCategory? premiosCategoryOf(String apiName) {
  for (final c in PremiosCategory.values) {
    if (c.apiName == apiName) return c;
  }
  return null;
}

/// La votación de las vistas sobre `SurveyVotePresenter` (contrato v3).
class V3PremiosFlowController extends PremiosFlowController {
  final SurveyVotePresenter _p;
  final bool _ownsPresenter;
  final VoidCallback? onVoted;

  /// Nombres de todo candidato visto (`value` → candidato): el presenter
  /// quita de `candidates` lo ya votado y Gracias lo sigue necesitando.
  final Map<String, PremiosCandidate> _names = {};
  PremiosFlowState _state = const PremiosFlowState();
  SurveyVoteStage? _lastStage;
  SurveyEdition? _lastEdition;
  bool _disposed = false;

  V3PremiosFlowController({
    SurveyVotePresenter? presenter,
    RemoteRepository? repository,
    this.onVoted,
  })  : _p = presenter ??
            SurveyVotePresenter.platform(
                repository ?? HttpRemoteRepository(Client())),
        _ownsPresenter = presenter == null {
    _p.addListener(_sync);
    _sync();
  }

  @override
  PremiosFlowState get state => _state;

  PremiosCandidate _candidate(String value) =>
      _names[value] ?? PremiosCandidate(value: value, name: value);

  void _sync() {
    if (_disposed) return;
    final s = _p.state;
    for (final list in s.candidates.values) {
      for (final c in list) {
        _names.putIfAbsent(
            c.value, () => PremiosCandidate.fromApi(c.value, c.text));
      }
    }
    final edition = s.edition;
    if (edition != null && !identical(edition, _lastEdition)) {
      _lastEdition = edition;
      PremiosEditionStore.instance.publish(edition);
    }

    final gate = premiosGateOf(s.stage);
    final failed = s.stage == SurveyVoteStage.failed;
    final kind = premiosErrorKindOf(s.failure);
    final conflicts = <PremiosCategory, PremiosCandidate>{
      for (final c in s.conflicts)
        if (premiosCategoryOf(c.category) case final cat?)
          cat: _candidate(c.value),
    };
    PremiosError? error;
    if (!failed && gate == null && kind != null) {
      final first = switch (s.failure) {
        SurveyAlreadyVoted(:final conflicts) when conflicts.isNotEmpty =>
          conflicts.first,
        SurveyInvalidOption(:final option) => option,
        _ => null,
      };
      error = PremiosError(kind,
          category: first == null ? null : premiosCategoryOf(first.category),
          value: first?.value);
    }

    _state = PremiosFlowState(
      load: switch (s.stage) {
        SurveyVoteStage.loading => PremiosLoad.loading,
        SurveyVoteStage.failed => PremiosLoad.error,
        _ => PremiosLoad.ready,
      },
      candidates: {
        for (final e in s.candidates.entries)
          if (premiosCategoryOf(e.key) case final cat?)
            cat: [for (final c in e.value) _candidate(c.value)],
      },
      picks: {
        for (final e in s.selection.entries)
          if (premiosCategoryOf(e.key) case final cat?)
            cat: _candidate(e.value),
      },
      submitting: s.stage == SurveyVoteStage.submitting,
      error: error,
      flagged: {for (final c in conflicts.values) c.value},
      conflicts: conflicts,
      sent: s.stage == SurveyVoteStage.sent
          ? {
              for (final a in s.accepted)
                if (premiosCategoryOf(a.category) case final cat?)
                  cat: _candidate(a.value),
            }
          : null,
      gate: gate,
      loadError: failed ? (kind ?? PremiosErrorKind.server) : null,
      minAppVersion: switch (s.failure) {
        SurveyUpgradeRequired(:final minAppVersion) => minAppVersion,
        _ => null,
      },
    );

    // Lo ya votado viene del servidor (`my-votes` y el recibo del voto):
    // queda en caché para el Inicio y el Ranking.
    if (s.stage == SurveyVoteStage.ready || s.stage == SurveyVoteStage.sent) {
      PremiosVotedStore.instance.update(s.voted);
    }
    final justSent =
        s.stage == SurveyVoteStage.sent && _lastStage != SurveyVoteStage.sent;
    _lastStage = s.stage;
    notifyListeners();
    if (justSent) onVoted?.call();
  }

  @override
  Future<void> load() => _p.load();

  @override
  void pick(PremiosCategory category, PremiosCandidate candidate) =>
      _p.select(category.apiName, candidate.value);

  @override
  Future<void> submit() => _p.submit();

  @override
  Future<void> retry() => _p.retry();

  @override
  Future<void> voteAgain() async => _p.voteAgain();

  @override
  void dispose() {
    _disposed = true;
    _p.removeListener(_sync);
    if (_ownsPresenter) _p.dispose();
    super.dispose();
  }
}

// ── Lo votado desde este móvil ─────────────────────────────────────────────

/// Lo que este móvil ya votó en la edición, por categoría (`value`s). La
/// fuente es el servidor (`POST …/my-votes` y el recibo de `…/votes`, a
/// través del presenter v3); aquí queda en caché para que el Inicio no
/// tenga que activar App Check al arrancar.
class PremiosVotedStore
    extends ValueNotifier<Map<PremiosCategory, Set<String>>> {
  PremiosVotedStore._() : super(const {});

  static final PremiosVotedStore instance = PremiosVotedStore._();

  static const _kCache = 'premiosVotedCache';
  bool _loaded = false;
  bool _fromServer = false;

  bool get hasVoted => value.values.any((s) => s.isNotEmpty);

  bool isMine(String id) => value.values.any((s) => s.contains(id));

  /// Lee la caché una vez.
  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final raw = await AppStorage.instance.read(key: _kCache);
      // Lo que haya llegado del servidor mientras tanto manda.
      if (raw == null || raw.isEmpty || _fromServer) return;
      final m = json.decode(raw);
      if (m is! Map) return;
      value = {
        for (final e in m.entries)
          if (premiosCategoryOf(e.key.toString()) case final cat?)
            cat: {
              for (final v in (e.value is List ? e.value as List : const []))
                v.toString()
            },
      };
    } catch (e) {
      AppLogger.warn('premios', 'leer votos en caché: ${e.runtimeType}');
    }
  }

  /// Datos del servidor (`state.voted` del presenter).
  void update(Map<String, Set<String>> voted) {
    _loaded = true;
    _fromServer = true;
    final next = {
      for (final e in voted.entries)
        if (premiosCategoryOf(e.key) case final cat?) cat: {...e.value},
    };
    if (mapEquals(_flat(next), _flat(value))) return;
    value = next;
    _persist();
  }

  /// Pide `my-votes` al servidor a través del presenter (activa App Check:
  /// solo desde pantallas de la encuesta, nunca al arrancar). Si falla, se
  /// queda la caché.
  Future<void> refreshFromServer({SurveyVotePresenter? presenter}) async {
    final p = presenter ??
        SurveyVotePresenter.platform(HttpRemoteRepository(Client()));
    try {
      await p.load();
      final s = p.state;
      if (s.stage == SurveyVoteStage.ready || s.stage == SurveyVoteStage.sent) {
        update(s.voted);
      }
      if (s.edition != null) PremiosEditionStore.instance.publish(s.edition!);
    } finally {
      if (presenter == null) p.dispose();
    }
  }

  static Map<String, String> _flat(Map<PremiosCategory, Set<String>> m) => {
        for (final e in m.entries)
          e.key.apiName: (e.value.toList()..sort()).join(','),
      };

  Future<void> _persist() async {
    try {
      await AppStorage.instance.write(
        key: _kCache,
        value: json.encode({
          for (final e in value.entries) e.key.apiName: e.value.toList(),
        }),
      );
    } catch (e) {
      AppLogger.warn('premios', 'guardar votos en caché: ${e.runtimeType}');
    }
  }

  @visibleForTesting
  void reset() {
    _loaded = false;
    _fromServer = false;
    value = const {};
  }
}

// ── Ranking ────────────────────────────────────────────────────────────────

/// Ranking público de la edición en curso (`GET /surveys/v3/editions/:id/
/// results`, sin App Check, cliente con pinning) con «Tu voto» desde
/// [PremiosVotedStore]. El `editionId` sale de `editions/current`.
class PremiosResultsController extends PremiosRankingController {
  final RemoteRepository _repository;
  SurveyEditionResults? _results;
  PremiosRankingState _state = const PremiosRankingState();
  bool _disposed = false;

  PremiosResultsController({RemoteRepository? repository})
      : _repository = repository ?? HttpRemoteRepository(Client()) {
    PremiosVotedStore.instance.addListener(_remark);
    PremiosVotedStore.instance.ensureLoaded();
  }

  @override
  PremiosRankingState get state => _state;

  /// Total de votos de las dos categorías (antetítulo del Inicio).
  int get totalVotes => _state.totalVotes;

  PremiosRankingState _build(SurveyEditionResults r) {
    final voted = PremiosVotedStore.instance;
    List<PremiosRankEntry> rows(PremiosCategory c) => r.hidden
        ? const []
        : premiosRankFromRows(r.category(c.apiName)?.results ?? const [],
            isMine: voted.isMine);
    return PremiosRankingState(
      load: PremiosLoad.ready,
      hidden: r.hidden,
      tradicional: rows(PremiosCategory.tradicional),
      moderno: rows(PremiosCategory.moderno),
      totals: {
        for (final c in PremiosCategory.values)
          c: r.category(c.apiName)?.totalVotes ?? 0,
      },
    );
  }

  void _remark() {
    final r = _results;
    if (_disposed || r == null) return;
    _state = _build(r);
    notifyListeners();
  }

  void _set(PremiosRankingState s) {
    if (_disposed) return;
    _state = s;
    notifyListeners();
  }

  @override
  Future<void> refresh() async {
    if (_state.load == PremiosLoad.error) _set(const PremiosRankingState());
    try {
      final store = PremiosEditionStore.instance;
      store.ensureLoaded(_repository);
      await store.loading;
      var id = store.current.id;
      if (id == null) {
        // Respaldo sin API: se intenta una vez más la edición en curso.
        final e = await _repository.getCurrentSurveyEdition();
        store.publish(e);
        id = e.editionId;
      }
      final r = _results = await _repository.getSurveyEditionResults(id);
      _set(_build(r));
    } catch (e) {
      // 404 edition_not_found, 429, red… El Inicio no enseña un fallo.
      AppLogger.warn('premios',
          'ranking: ${e is SurveyApiException ? e.code : e.runtimeType}');
      if (_state.load != PremiosLoad.ready) {
        _set(const PremiosRankingState(load: PremiosLoad.error));
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    PremiosVotedStore.instance.removeListener(_remark);
    super.dispose();
  }
}

// ── Inicio: hoja ───────────────────────────────────────────────────────────

/// Lo que el Inicio recuerda de la hoja en este móvil.
class PremiosHomeStore {
  PremiosHomeStore._();

  static const _kDismissed = 'premios2026SheetDismissedAt';

  /// La hoja no vuelve hasta pasados 7 días de «Ahora no».
  static const sheetCooldown = Duration(days: 7);

  /// Solo una hoja por arranque de la app.
  static bool sheetShownThisSession = false;

  static Future<DateTime?> dismissedAt() async {
    try {
      final raw = await AppStorage.instance.read(key: _kDismissed);
      return raw == null ? null : DateTime.tryParse(raw);
    } catch (e) {
      AppLogger.warn('premios', 'leer «Ahora no»: ${e.runtimeType}');
      return null;
    }
  }

  static Future<void> dismiss(DateTime now) async {
    try {
      await AppStorage.instance
          .write(key: _kDismissed, value: now.toUtc().toIso8601String());
    } catch (e) {
      AppLogger.warn('premios', 'guardar «Ahora no»: ${e.runtimeType}');
    }
  }
}

/// ¿Se descartó hace menos de 7 días?
bool premiosRecentlyDismissed(DateTime? at, DateTime now) =>
    at != null &&
    now.toUtc().difference(at.toUtc()) < PremiosHomeStore.sheetCooldown;

/// La hoja al abrir: solo si la votación está abierta, este móvil no ha
/// votado y no se descartó en los últimos 7 días.
bool premiosShouldShowSheet({
  required PremiosPhase phase,
  required bool voted,
  required DateTime? dismissedAt,
  required DateTime now,
}) {
  if (!phase.counting || voted) return false;
  return !premiosRecentlyDismissed(dismissedAt, now);
}
