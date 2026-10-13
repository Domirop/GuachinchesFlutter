import 'package:flutter/foundation.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/data/model/survey_in_app_choice.dart';
import 'package:guachinches/services/app_storage.dart';
import 'package:guachinches/ui/components/SurveyResults/SurveyResults.dart';
import 'package:guachinches/ui/pages/premios/premios_models.dart';
import 'package:guachinches/ui/pages/surveyRanking/surveyRankingPresenter.dart';
import 'package:guachinches/ui/pages/survey_in_app/survey_in_app_presenter.dart';
import 'package:http/http.dart';

// ── Interfaces de las vistas ───────────────────────────────────────────────
//
// Las pantallas de la encuesta solo conocen estas dos clases: un estado
// inmutable ([PremiosFlowState], [PremiosRankingState]) y unos pocos
// callbacks. El equipo de seguridad está rediseñando la identidad del
// dispositivo (DeviceCheck/App Attest, Play Integrity) y el contrato de la
// API: cuando llegue, basta con otra implementación de estas clases; las
// vistas no cambian.

/// Flujo de votación: candidatos, elección por categoría y envío.
abstract class PremiosFlowController extends ChangeNotifier {
  PremiosFlowState get state;

  /// (Re)carga los candidatos (orden aleatorio, sin los ya votados).
  Future<void> load();

  /// Elige [candidate] en su categoría; si ya estaba elegido, lo quita.
  void pick(PremiosCategory category, PremiosCandidate candidate);

  /// Envía todos los votos juntos.
  Future<void> submit();

  /// «Votar a otros sitios»: vacía la papeleta y vuelve a cargar.
  Future<void> voteAgain();
}

/// Ranking por categoría con puestos compartidos.
abstract class PremiosRankingController extends ChangeNotifier {
  PremiosRankingState get state;
  Future<void> refresh();
}

// ── Implementación sobre el presenter actual ───────────────────────────────

/// Mensajes literales del presenter actual → errores tipados. El contrato
/// nuevo mandará `code` (too_fast, no_selection, already_voted_this_business…)
/// y esto desaparece.
PremiosErrorKind premiosErrorFromLegacyMessage(String message) {
  switch (message) {
    case 'Por favor, tómate tu tiempo para votar.':
      return PremiosErrorKind.tooFast;
    case 'Debes seleccionar al menos una opción.':
      return PremiosErrorKind.noSelection;
    case 'Ya has votado a este negocio anteriormente.':
      return PremiosErrorKind.alreadyVoted;
  }
  // «Error al enviar: …» trae la excepción (nunca se enseña): si es de red,
  // «Se nos fue la cobertura»; si no, fallo del servidor.
  const net = [
    'SocketException',
    'ClientException',
    'TimeoutException',
    'Failed host lookup',
    'Connection',
    'Network is unreachable',
  ];
  if (net.any(message.contains)) return PremiosErrorKind.network;
  return PremiosErrorKind.server;
}

/// Adaptador: implementa la vista del [SurveyInAppPresenter] de siempre (que
/// sigue haciendo la identidad, la firma y el envío) y la traduce a
/// [PremiosFlowState].
class LegacyPremiosFlowController extends PremiosFlowController
    implements SurveyInAppView {
  final VoidCallback? onVoted;
  late final SurveyInAppPresenter _presenter;
  PremiosFlowState _state = const PremiosFlowState();
  bool _gotChoices = false;
  bool _disposed = false;

  LegacyPremiosFlowController({RemoteRepository? repository, this.onVoted}) {
    _presenter = SurveyInAppPresenter(
        repository ?? HttpRemoteRepository(Client()), this);
  }

  @override
  PremiosFlowState get state => _state;

  void _set(PremiosFlowState s) {
    if (_disposed) return;
    _state = s;
    notifyListeners();
  }

  @override
  Future<void> load() async {
    _gotChoices = false;
    _set(_state.copyWith(load: PremiosLoad.loading, error: () => null));
    await _presenter.initialize();
  }

  @override
  void pick(PremiosCategory category, PremiosCandidate candidate) {
    final picks = Map.of(_state.picks);
    if (picks[category] == candidate) {
      picks.remove(category);
    } else {
      picks[category] = candidate;
    }
    // Cambiar la papeleta deja atrás el aviso anterior.
    _set(_state.copyWith(picks: picks, error: () => null));
  }

  @override
  Future<void> submit() async {
    if (_state.submitting) return;
    if (_state.picks.isEmpty) {
      _set(_state.copyWith(
          error: () => const PremiosError(PremiosErrorKind.noSelection)));
      return;
    }
    _set(_state.copyWith(error: () => null));
    await _presenter.submitVotes(
      tradicionalValue: _state.picks[PremiosCategory.tradicional]?.value,
      modernoValue: _state.picks[PremiosCategory.moderno]?.value,
    );
  }

  @override
  Future<void> voteAgain() async {
    _set(_state.copyWith(
      picks: const {},
      flagged: const {},
      error: () => null,
      sent: () => null,
    ));
    await load();
  }

  // ── SurveyInAppView ──

  @override
  void setLoading(bool loading) {
    if (loading) {
      _set(_state.copyWith(load: PremiosLoad.loading));
    } else if (_state.load == PremiosLoad.loading) {
      _set(_state.copyWith(
          load: _gotChoices ? PremiosLoad.ready : PremiosLoad.error));
    }
  }

  @override
  void setSubmitting(bool submitting) =>
      _set(_state.copyWith(submitting: submitting));

  @override
  void setChoices({
    required List<SurveyInAppChoice> tradicionales,
    required List<SurveyInAppChoice> modernos,
  }) {
    _gotChoices = true;
    List<PremiosCandidate> map(List<SurveyInAppChoice> l) => [
          for (final c in l)
            if (c.value.isNotEmpty) PremiosCandidate.fromApi(c.value, c.text),
        ];
    _set(_state.copyWith(
      load: PremiosLoad.ready,
      candidates: {
        PremiosCategory.tradicional: map(tradicionales),
        PremiosCategory.moderno: map(modernos),
      },
    ));
  }

  @override
  void showError(String message) {
    if (_state.load == PremiosLoad.loading) {
      // Fallo al cargar los candidatos (nunca se enseña la excepción).
      AppLogger.warn('premios', 'carga de candidatos: $message');
      _set(_state.copyWith(load: PremiosLoad.error));
      return;
    }
    final kind = premiosErrorFromLegacyMessage(message);
    _set(_state.copyWith(error: () => PremiosError(kind)));
    if (kind == PremiosErrorKind.alreadyVoted) _flagAlreadyVoted();
  }

  /// Tras un 409 se repite `by-device` y se marca la fila ya votada.
  Future<void> _flagAlreadyVoted() async {
    final Map<String, List<String>> voted;
    try {
      voted = await _presenter.votedByDevice();
    } catch (e) {
      AppLogger.warn('premios', 'by-device tras 409: $e');
      return;
    }
    final flagged = <String>{};
    PremiosCategory? cat;
    String? value;
    for (final e in _state.picks.entries) {
      if ((voted[e.key.apiName] ?? const []).contains(e.value.value)) {
        flagged.add(e.value.value);
        cat ??= e.key;
        value ??= e.value.value;
      }
    }
    if (flagged.isEmpty) return;
    _set(_state.copyWith(
      flagged: flagged,
      error: () => PremiosError(PremiosErrorKind.alreadyVoted,
          category: cat, value: value),
    ));
  }

  @override
  void onSubmitSuccess() {
    _set(_state.copyWith(sent: () => Map.of(_state.picks), flagged: const {}));
    PremiosHomeStore.markVoted();
    onVoted?.call();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Ranking sobre el [SurveyRankingPresenter] de siempre.
class LegacyPremiosRankingController extends PremiosRankingController
    implements SurveyRankingView {
  final RemoteRepository _repository;
  late final SurveyRankingPresenter _presenter;
  List<Restaurant>? _restaurants;
  PremiosRankingState _state = const PremiosRankingState();
  bool _disposed = false;

  /// [restaurants] y los resultados iniciales son opcionales: el Inicio
  /// viejo ya los tenía cargados.
  LegacyPremiosRankingController({
    RemoteRepository? repository,
    List<Restaurant>? restaurants,
    List<SurveyResult>? tradicionales,
    List<SurveyResult>? modernos,
  }) : _repository = repository ?? HttpRemoteRepository(Client()) {
    _presenter = SurveyRankingPresenter(this, _repository);
    _restaurants = restaurants == null || restaurants.isEmpty
        ? null
        : restaurants;
    if (tradicionales != null && modernos != null &&
        (tradicionales.isNotEmpty || modernos.isNotEmpty)) {
      _state = PremiosRankingState(
        load: PremiosLoad.ready,
        tradicional: premiosRank(tradicionales),
        moderno: premiosRank(modernos),
      );
    }
  }

  @override
  PremiosRankingState get state => _state;

  void _set(PremiosRankingState s) {
    if (_disposed) return;
    _state = s;
    notifyListeners();
  }

  @override
  Future<void> refresh() async {
    if (_state.load == PremiosLoad.error) {
      _set(const PremiosRankingState());
    }
    try {
      _restaurants ??= [
        ...await _repository
            .getAllSurveyRestaurants(PremiosCategory.moderno.apiName),
        ...await _repository
            .getAllSurveyRestaurants(PremiosCategory.tradicional.apiName),
      ];
      await _presenter.getSurveyResults(_restaurants!);
    } catch (e) {
      AppLogger.warn('premios', 'ranking: $e');
      if (_state.load != PremiosLoad.ready) {
        _set(const PremiosRankingState(load: PremiosLoad.error));
      }
    }
  }

  @override
  void setSurveyResults(List<SurveyResult> guachinchesModernos,
      List<SurveyResult> guachinchesTradicionales) {
    _set(PremiosRankingState(
      load: PremiosLoad.ready,
      tradicional: premiosRank(guachinchesTradicionales),
      moderno: premiosRank(guachinchesModernos),
    ));
    if (_state.hasMine) PremiosHomeStore.markVoted();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

// ── Inicio: tarjeta y hoja ─────────────────────────────────────────────────

/// Lo que el Inicio recuerda de la encuesta en este móvil.
class PremiosHomeStore {
  PremiosHomeStore._();

  static const _kVoted = 'premios2026Voted';
  static const _kDismissed = 'premios2026SheetDismissedAt';

  /// La hoja no vuelve hasta pasados 7 días de «Ahora no».
  static const sheetCooldown = Duration(days: 7);

  /// Solo una hoja por arranque de la app.
  static bool sheetShownThisSession = false;

  static Future<bool> hasVoted() async {
    try {
      return await AppStorage.instance.read(key: _kVoted) == 'true';
    } catch (e) {
      AppLogger.warn('premios', 'leer voto local: $e');
      return false;
    }
  }

  static Future<void> markVoted() async {
    try {
      await AppStorage.instance.write(key: _kVoted, value: 'true');
    } catch (e) {
      AppLogger.warn('premios', 'guardar voto local: $e');
    }
  }

  static Future<DateTime?> dismissedAt() async {
    try {
      final raw = await AppStorage.instance.read(key: _kDismissed);
      return raw == null ? null : DateTime.tryParse(raw);
    } catch (e) {
      AppLogger.warn('premios', 'leer «Ahora no»: $e');
      return null;
    }
  }

  static Future<void> dismiss(DateTime now) async {
    try {
      await AppStorage.instance
          .write(key: _kDismissed, value: now.toIso8601String());
    } catch (e) {
      AppLogger.warn('premios', 'guardar «Ahora no»: $e');
    }
  }
}

/// La hoja al abrir: solo si la votación está abierta, este móvil no ha
/// votado y no se descartó en los últimos 7 días.
bool premiosShouldShowSheet({
  required PremiosPhase phase,
  required bool voted,
  required DateTime? dismissedAt,
  required DateTime now,
}) {
  if (phase == PremiosPhase.closed || voted) return false;
  if (dismissedAt == null) return true;
  return now.difference(dismissedAt) >= PremiosHomeStore.sheetCooldown;
}
