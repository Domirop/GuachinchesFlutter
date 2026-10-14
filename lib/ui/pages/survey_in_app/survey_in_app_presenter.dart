import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/model/survey_in_app_choice.dart';
import 'package:guachinches/ui/pages/survey_in_app/survey_vote_presenter.dart';

/// Adaptador de compatibilidad para las vistas de siempre
/// (`survey_in_app_page.dart` y `LegacyPremiosFlowController`).
///
/// Ya no calcula identidad ni firmas: delega en [SurveyVotePresenter] (contrato
/// v3, identidad atestada del dispositivo) y traduce su estado a la interfaz
/// MVP antigua. Las vistas nuevas deben usar [SurveyVotePresenter] directamente.
class SurveyInAppPresenter {
  static const tradicional = 'Mejor-Guachinche-Tradicional';
  static const moderno = 'Mejor-Guachinche-Moderno';

  final SurveyInAppView _view;
  final SurveyVotePresenter core;

  SurveyInAppPresenter(RemoteRepository repository, this._view,
      {SurveyVotePresenter? core})
      : core = core ?? SurveyVotePresenter.platform(repository);

  Future<void> initialize() async {
    _view.setLoading(true);
    await core.load();
    final s = core.state;
    if (s.stage == SurveyVoteStage.ready) {
      _view.setChoices(
        tradicionales: s.candidates[tradicional] ?? const [],
        modernos: s.candidates[moderno] ?? const [],
      );
    } else {
      _view.showError(legacyMessage(s));
    }
    _view.setLoading(false);
  }

  Future<void> submitVotes({
    required String? tradicionalValue,
    required String? modernoValue,
  }) async {
    if (core.state.stage == SurveyVoteStage.sent) core.voteAgain();
    core.select(tradicional, tradicionalValue);
    core.select(moderno, modernoValue);
    _view.setSubmitting(true);
    await core.submit();
    _view.setSubmitting(false);
    final s = core.state;
    if (s.stage == SurveyVoteStage.sent) {
      _view.onSubmitSuccess();
    } else if (s.failure != null) {
      _view.showError(legacyMessage(s));
    }
  }

  /// Lo que este móvil ya votó, por categoría (tras un 409 ya incluye los
  /// conflictos que devolvió el servidor).
  Future<Map<String, List<String>>> votedByDevice() async => {
        for (final e in core.state.voted.entries) e.key: e.value.toList()
      };

  /// Textos literales que entienden las vistas antiguas
  /// (`premiosErrorFromLegacyMessage`).
  static String legacyMessage(SurveyVoteState s) {
    switch (s.failure) {
      case SurveyNoSelection():
        return 'Debes seleccionar al menos una opción.';
      case SurveyTooFast():
        return 'Por favor, tómate tu tiempo para votar.';
      case SurveyAlreadyVoted():
        return 'Ya has votado a este negocio anteriormente.';
      case SurveyNetworkFailure():
        return 'Error al enviar: SocketException';
      case SurveyRateLimited():
        return 'Demasiados intentos, prueba en un minuto.';
      case SurveyIntegrityFailed():
        return 'No hemos podido verificar este móvil. Actualiza la app.';
      case SurveyUpgradeRequired():
        return 'Actualiza la app para votar.';
      case SurveyDeviceBlocked():
        return 'Este móvil no puede votar.';
      case SurveyEditionClosed():
        return 'La votación está cerrada.';
      case SurveyDeviceUnsupported():
        return 'Este dispositivo no puede votar.';
      case SurveyVerificationUnavailable():
        return 'No podemos verificar ahora mismo, inténtalo en unos minutos.';
      default:
        return 'No se pudo enviar tu voto. Inténtalo de nuevo.';
    }
  }
}

abstract class SurveyInAppView {
  void setLoading(bool loading);
  void setSubmitting(bool submitting);
  void setChoices({
    required List<SurveyInAppChoice> tradicionales,
    required List<SurveyInAppChoice> modernos,
  });
  void showError(String message);
  void onSubmitSuccess();
}
