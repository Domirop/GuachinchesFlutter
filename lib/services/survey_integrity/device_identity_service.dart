import 'dart:io' show Platform;

import 'package:guachinches/data/model/survey_v3.dart';
import 'package:guachinches/services/survey_integrity/survey_integrity.dart';

export 'package:guachinches/services/survey_integrity/survey_integrity.dart';

/// Petición lista para la API v3: cuerpo + token de App Check de uso limitado
/// (cabecera [kAppCheckHeader]). `toString` redactado.
class SurveySignedRequest {
  final Map<String, Object?> body;
  final String appCheckToken;
  const SurveySignedRequest(this.body, this.appCheckToken);

  @override
  String toString() => 'SurveySignedRequest(<redactado>)';
}

/// Identidad del móvil para la encuesta (sustituye a `device_id_service.dart`).
///
/// - iOS: `localIdHash` de un secreto aleatorio del Keychain
///   ([KeychainLocalIdSource]); App Check con App Attest.
/// - Android: `localIdHash` del SSAID ([SsaidLocalIdSource]); App Check con
///   Play Integrity.
/// - Debug: proveedor Debug de App Check.
///
/// `votes` pide un token de App Check de uso limitado **nuevo** (el servidor lo
/// consume); `my-votes`, el token estándar. Sin token no hay petición.
class DeviceIdentityService {
  final LocalIdSource _localIds;
  final AppCheckTokenSource _appCheck;
  final String platform;

  /// Se guarda el Future, no el resultado: dos llamadas simultáneas en el
  /// primer arranque esperan la misma lectura (y en iOS la misma creación del
  /// secreto). Si falla, se olvida para poder reintentar.
  Future<SurveyLocalId>? _pending;

  DeviceIdentityService({
    required LocalIdSource localIds,
    required AppCheckTokenSource appCheck,
    required this.platform,
  })  : assert(platform == 'ios' || platform == 'android'),
        _localIds = localIds,
        _appCheck = appCheck;

  factory DeviceIdentityService.platform() {
    final ios = Platform.isIOS;
    return DeviceIdentityService(
      localIds: ios ? KeychainLocalIdSource.shared : SsaidLocalIdSource(),
      appCheck: FakeAppCheckTokenSource.enabled
          ? FakeAppCheckTokenSource()
          : FirebaseAppCheckTokenSource(),
      platform: ios ? 'ios' : 'android',
    );
  }

  /// Activa App Check y lee la identidad. Lanza [SurveyIntegrityException]
  /// (con `unsupported` si el móvil no puede votar).
  Future<void> ensureReady() async {
    await _appCheck.activate();
    await localId();
  }

  /// Una lectura por instancia; el secreto (iOS) o el SSAID (Android) se
  /// reutilizan siempre.
  Future<SurveyLocalId> localId() {
    final pending = _pending ??= _localIds.localId();
    pending.then((_) {}, onError: (Object _) {
      if (identical(_pending, pending)) _pending = null;
    });
    return pending;
  }

  /// `my-votes`: el servidor reconoce la identidad y devuelve lo que ya votó.
  /// Token **estándar** de App Check (el servidor no lo consume): no gasta la
  /// cuota de tokens de uso limitado de Play Integrity / App Attest.
  Future<SurveySignedRequest> identityRequest() =>
      _signed(const {}, limitedUse: false);

  Future<SurveySignedRequest> voteRequest(List<SurveyVoteSelection> votes) {
    final cats = votes.map((v) => v.category).toSet();
    if (votes.isEmpty || cats.length != votes.length) {
      throw ArgumentError('una sola opción por categoría');
    }
    return _signed({
      'votes': [for (final v in votes) v.toJson()],
    });
  }

  /// El token se pide lo último, justo antes del POST (el servidor rechaza
  /// los de más de 120 s).
  Future<SurveySignedRequest> _signed(Map<String, Object?> extra,
      {bool limitedUse = true}) async {
    final local = await localId();
    final token = limitedUse
        ? await _appCheck.limitedUseToken()
        : await _appCheck.standardToken();
    return SurveySignedRequest({
      'platform': platform,
      'localIdHash': local.hash,
      ...extra,
    }, token);
  }
}
