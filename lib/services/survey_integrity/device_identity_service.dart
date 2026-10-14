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
/// Cada petición pide un token de App Check **nuevo** (de uso limitado: el
/// servidor lo consume al votar). Sin token no hay petición.
class DeviceIdentityService {
  final LocalIdSource _localIds;
  final AppCheckTokenSource _appCheck;
  final String platform;
  SurveyLocalId? _localId;

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
      localIds: ios ? KeychainLocalIdSource() : SsaidLocalIdSource(),
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
  Future<SurveyLocalId> localId() async => _localId ??= await _localIds.localId();

  /// `my-votes`: el servidor reconoce la identidad y devuelve lo que ya votó.
  Future<SurveySignedRequest> identityRequest() => _signed(const {});

  Future<SurveySignedRequest> voteRequest(List<SurveyVoteSelection> votes) {
    final cats = votes.map((v) => v.category).toSet();
    if (votes.isEmpty || cats.length != votes.length) {
      throw ArgumentError('una sola opción por categoría');
    }
    return _signed({
      'votes': [for (final v in votes) v.toJson()],
    });
  }

  Future<SurveySignedRequest> _signed(Map<String, Object?> extra) async {
    final local = await localId();
    final token = await _appCheck.limitedUseToken();
    return SurveySignedRequest({
      'platform': platform,
      'localIdHash': local.hash,
      ...extra,
    }, token);
  }
}
