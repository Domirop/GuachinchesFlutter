import 'package:flutter/foundation.dart';
import 'package:guachinches/data/model/survey_in_app_choice.dart';
import 'package:guachinches/data/model/survey_v3.dart';

/// Estado de la encuesta v3 que pinta la vista (ENCUESTA-SEGURIDAD.md, plan
/// App Check).
///
/// La vista decide la pantalla por [SurveyVoteState.stage] y el aviso por
/// [SurveyVoteState.failure]. Nada aquí lleva tokens ni identificadores del
/// dispositivo.
enum SurveyVoteStage {
  /// Cargando edición, verificando el móvil y trayendo candidatos.
  loading,

  /// Puede elegir y enviar.
  ready,

  /// Enviando (bloquear el botón).
  submitting,

  /// Votos aceptados: [SurveyVoteState.accepted]. «Votar a otros sitios» →
  /// `voteAgain()`.
  sent,

  /// La edición aún no ha abierto ([SurveyVoteState.edition] trae fechas).
  upcoming,

  /// Votación cerrada (hora del servidor).
  closed,

  /// `403 device_blocked`: «Este móvil no puede votar.»
  blocked,

  /// `426` o versión por debajo de `minAppVersion`: pantalla de actualizar.
  upgradeRequired,

  /// App Check no puede dar token: sin App Attest (simulador en release, iPad
  /// antiguo) o sin Google Play / Play Integrity (Huawei…). Sin token no se
  /// vota. [SurveyVoteState.failure] es [SurveyDeviceUnsupported].
  unsupported,

  /// No se pudo cargar (red, servidor, verificación). [SurveyVoteState.failure]
  /// dice por qué; `retry()` vuelve a empezar.
  failed,
}

/// Errores tipados. Los de [SurveyVoteStage.ready] son avisos sobre la papeleta
/// (los votos elegidos se conservan); los demás acompañan a su `stage`.
@immutable
sealed class SurveyFailure {
  const SurveyFailure();

  /// El botón principal pasa a «Reintentar».
  bool get retryable => false;
}

/// Envío sin elegir nada.
final class SurveyNoSelection extends SurveyFailure {
  const SurveyNoSelection();
}

/// Envío antes del mínimo de 3 s (solo UX; el servidor no se fía del cliente).
final class SurveyTooFast extends SurveyFailure {
  const SurveyTooFast();
}

/// `409 already_voted_this_business`: estos negocios ya tenían voto de este
/// móvil. Ya se han quitado de la selección; marcar sus filas.
final class SurveyAlreadyVoted extends SurveyFailure {
  final List<SurveyVoteSelection> conflicts;
  const SurveyAlreadyVoted(this.conflicts);
}

/// `403 integrity_failed` (App Check ausente, no válido, reutilizado o de otra
/// app) o App Check rechazado en el propio móvil (`code == 'client'`):
/// «No hemos podido verificar este móvil. Actualiza la app desde la App Store /
/// Google Play.» [reason] solo para métricas, nunca en pantalla.
final class SurveyIntegrityFailed extends SurveyFailure {
  final String code;
  final String? reason;
  const SurveyIntegrityFailed(this.code, [this.reason]);

  @override
  bool get retryable => true;
}

/// `426 upgrade_required` / versión mínima.
final class SurveyUpgradeRequired extends SurveyFailure {
  final String? minAppVersion;
  const SurveyUpgradeRequired([this.minAppVersion]);
}

/// `429 rate_limited`: «Demasiados intentos, prueba en un minuto.»
final class SurveyRateLimited extends SurveyFailure {
  final Duration? retryAfter;
  const SurveyRateLimited([this.retryAfter]);

  @override
  bool get retryable => true;
}

/// `503 integrity_unavailable`, o Firebase / Apple / Google sin servicio al
/// pedir el token en el móvil: «No podemos verificar ahora mismo, inténtalo en
/// unos minutos.»
final class SurveyVerificationUnavailable extends SurveyFailure {
  final Duration? retryAfter;
  const SurveyVerificationUnavailable([this.retryAfter]);

  @override
  bool get retryable => true;
}

/// Sin conexión / tiempo agotado. Los votos siguen en la papeleta.
final class SurveyNetworkFailure extends SurveyFailure {
  const SurveyNetworkFailure();

  @override
  bool get retryable => true;
}

/// La conexión con el servidor no es la nuestra: la cadena TLS no acaba en las
/// raíces fijadas (proxy, CA instalada en el móvil, wifi con portal cautivo).
/// No se ha enviado nada. Texto propuesto: «No podemos conectar de forma segura.
/// Prueba con otra red (datos móviles).»
final class SurveyInsecureConnection extends SurveyFailure {
  const SurveyInsecureConnection();

  @override
  bool get retryable => true;
}

/// 400, 5xx o respuesta inesperada.
final class SurveyServerFailure extends SurveyFailure {
  final int? status;
  final String? code;
  const SurveyServerFailure([this.status, this.code]);

  @override
  bool get retryable => true;
}

/// `422 invalid_option`: la opción ya no es candidata en esa categoría.
final class SurveyInvalidOption extends SurveyFailure {
  final SurveyVoteSelection? option;
  const SurveyInvalidOption([this.option]);
}

/// Acompaña a [SurveyVoteStage.unsupported]: este móvil no puede obtener un
/// token de App Check.
final class SurveyDeviceUnsupported extends SurveyFailure {
  const SurveyDeviceUnsupported();
}

/// Acompañan a sus `stage` ([SurveyVoteStage.blocked], [SurveyVoteStage.closed]).
final class SurveyDeviceBlocked extends SurveyFailure {
  const SurveyDeviceBlocked();
}

final class SurveyEditionClosed extends SurveyFailure {
  const SurveyEditionClosed();
}

@immutable
class SurveyVoteState {
  final SurveyVoteStage stage;
  final SurveyEdition? edition;

  /// Candidatos por categoría (`apiName`), ya sin los negocios que este móvil
  /// votó (con `voteScope=business`, en cualquier categoría).
  final Map<String, List<SurveyInAppChoice>> candidates;

  /// Elección actual: categoría → `value`.
  final Map<String, String> selection;

  /// Lo que este móvil ya votó en la edición (del servidor).
  final Map<String, Set<String>> voted;

  /// Último 409: filas a marcar («Ya has votado a este negocio anteriormente.»).
  final List<SurveyVoteSelection> conflicts;

  /// Votos aceptados en el último envío ([SurveyVoteStage.sent]).
  final List<SurveyVoteSelection> accepted;
  final SurveyFailure? failure;

  const SurveyVoteState({
    this.stage = SurveyVoteStage.loading,
    this.edition,
    this.candidates = const {},
    this.selection = const {},
    this.voted = const {},
    this.conflicts = const [],
    this.accepted = const [],
    this.failure,
  });

  List<String> get categories => edition?.categories ?? const [];

  bool get canSubmit =>
      stage == SurveyVoteStage.ready && selection.isNotEmpty;

  bool get hasVoted => voted.values.any((s) => s.isNotEmpty);

  bool isVoted(String value) => voted.values.any((s) => s.contains(value));

  bool isConflict(String category, String value) =>
      conflicts.contains(SurveyVoteSelection(category, value));

  SurveyVoteState copyWith({
    SurveyVoteStage? stage,
    SurveyEdition? edition,
    Map<String, List<SurveyInAppChoice>>? candidates,
    Map<String, String>? selection,
    Map<String, Set<String>>? voted,
    List<SurveyVoteSelection>? conflicts,
    List<SurveyVoteSelection>? accepted,
    SurveyFailure? Function()? failure,
  }) =>
      SurveyVoteState(
        stage: stage ?? this.stage,
        edition: edition ?? this.edition,
        candidates: candidates ?? this.candidates,
        selection: selection ?? this.selection,
        voted: voted ?? this.voted,
        conflicts: conflicts ?? this.conflicts,
        accepted: accepted ?? this.accepted,
        failure: failure != null ? failure() : this.failure,
      );

  @override
  String toString() => 'SurveyVoteState(${stage.name}, '
      'failure: ${failure.runtimeType}, picks: ${selection.length})';
}
