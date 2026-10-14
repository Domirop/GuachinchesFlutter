import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Piezas de la identidad del móvil y de App Check para la encuesta
/// (ENCUESTA-SEGURIDAD.md, «Plan elegido: App Check»).
///
/// Nada de lo que sale de aquí (hash, tokens) se registra: los modelos ocultan
/// su contenido en `toString()` y los errores solo llevan un código.

enum SurveyIntegrityError {
  /// App Check no puede dar token en este dispositivo: sin App Attest
  /// (simulador en release, Mac, iPad antiguo) o sin Google Play / Play
  /// Integrity (Huawei, Android no certificado). Sin token no se vota.
  unsupported,

  /// Sin conexión al pedir el token.
  network,

  /// Firebase limita las peticiones de token (demasiados intentos).
  rateLimited,

  /// Firebase / Apple / Google no responden. Se puede reintentar más tarde.
  serverUnavailable,

  /// iOS: Keychain bloqueado (antes del primer desbloqueo tras reiniciar).
  keychainLocked,

  /// iOS: no se pudo leer o guardar el secreto (nunca se crea otro encima).
  keychain,

  /// App Check rechazó el atestado (app modificada, dispositivo no íntegro,
  /// token de depuración sin registrar…) u otro fallo.
  failed;

  bool get isPermanent => this == unsupported;
}

class SurveyIntegrityException implements Exception {
  final SurveyIntegrityError error;
  const SurveyIntegrityException(this.error);

  @override
  String toString() => 'SurveyIntegrityException(${error.name})';
}

/// `localIdHash = hex(SHA256("gm-survey-id:" ‖ L))`. Opaco: no se imprime.
@immutable
class SurveyLocalId {
  final String hash;

  /// iOS: el secreto se acaba de crear (primera vez en este iPhone, o tras
  /// borrarlo). Android: siempre `false` (el SSAID no se crea).
  final bool created;
  const SurveyLocalId(this.hash, {this.created = false});

  static final _hex64 = RegExp(r'^[0-9a-f]{64}$');
  static bool isValid(String h) => _hex64.hasMatch(h);

  /// El cálculo del cliente (fixture compartida con `identity.ts` del backend).
  static String hashOf(List<int> secret) => sha256
      .convert([...utf8.encode('gm-survey-id:'), ...secret]).toString();

  @override
  String toString() => 'SurveyLocalId(<redactado>, created: $created)';
}

/// De dónde sale `localIdHash` en cada plataforma.
abstract class LocalIdSource {
  Future<SurveyLocalId> localId();
}

/// iOS: secreto `L` de 32 bytes en el Keychain con
/// `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` y sin sincronizar: no
/// migra a otro iPhone ni a sus copias, y en la práctica sobrevive a
/// desinstalar (Apple no lo garantiza).
///
/// Va en su propio servicio del Keychain ([service]) para que
/// `FreshInstallGuard` (que borra el almacén por defecto al reinstalar) no lo
/// toque: si lo borrara, cada reinstalación sería un móvil nuevo.
class KeychainLocalIdSource implements LocalIdSource {
  static const service = 'com.jonay.guachinches.survey';
  static const key = 'survey_device_secret_v1';
  static const iosOptions = IOSOptions(
    accountName: service,
    accessibility: KeychainAccessibility.first_unlock_this_device,
    synchronizable: false,
  );

  /// Una sola instancia por proceso: todas las lecturas y la creación del
  /// secreto pasan por el mismo [_pending].
  static final shared = KeychainLocalIdSource();

  final FlutterSecureStorage _storage;
  final Random _random;
  Future<SurveyLocalId>? _pending;

  KeychainLocalIdSource({FlutterSecureStorage? storage, Random? random})
      : _storage = storage ?? const FlutterSecureStorage(iOptions: iosOptions),
        _random = random ?? Random.secure();

  /// Dos llamadas a la vez (primer arranque) comparten la misma lectura y la
  /// misma creación: nunca se escriben dos secretos distintos.
  @override
  Future<SurveyLocalId> localId() {
    final pending = _pending ??= _readOrCreate();
    pending.then((_) {}, onError: (Object _) {
      if (identical(_pending, pending)) _pending = null;
    });
    return pending;
  }

  Future<SurveyLocalId> _readOrCreate() async {
    final stored = await _read();
    if (stored != null) {
      final bytes = _decode(stored);
      // Un valor corrupto no se sobrescribe: otro L sería otra identidad.
      if (bytes == null) {
        throw const SurveyIntegrityException(SurveyIntegrityError.keychain);
      }
      return SurveyLocalId(SurveyLocalId.hashOf(bytes));
    }
    final secret =
        Uint8List.fromList(List.generate(32, (_) => _random.nextInt(256)));
    final encoded = base64Encode(secret);
    try {
      await _storage.write(key: key, value: encoded, iOptions: iosOptions);
    } on PlatformException {
      throw const SurveyIntegrityException(SurveyIntegrityError.keychain);
    }
    // Si otra llamada se adelantó, manda lo que quedó guardado.
    final saved = await _read();
    final bytes = saved == null ? null : _decode(saved);
    if (bytes == null) {
      throw const SurveyIntegrityException(SurveyIntegrityError.keychain);
    }
    return SurveyLocalId(SurveyLocalId.hashOf(bytes),
        created: saved == encoded);
  }

  Future<String?> _read() async {
    try {
      return await _storage.read(key: key, iOptions: iosOptions);
    } on PlatformException catch (e) {
      // errSecInteractionNotAllowed (-25308): antes del primer desbloqueo.
      final locked = '${e.code} ${e.message}'.contains('-25308');
      throw SurveyIntegrityException(locked
          ? SurveyIntegrityError.keychainLocked
          : SurveyIntegrityError.keychain);
    }
  }

  static Uint8List? _decode(String v) {
    try {
      final b = base64Decode(v);
      return b.length == 32 ? b : null;
    } on FormatException {
      return null;
    }
  }
}

/// Android: SSAID (`Settings.Secure.ANDROID_ID`) por un canal Kotlin mínimo
/// (`SurveyDevicePlugin.kt`). El SSAID no sale del código nativo: llega el hash.
class SsaidLocalIdSource implements LocalIdSource {
  static const channelName = 'com.jonay.guachinches/survey_device';
  final MethodChannel _channel;
  SsaidLocalIdSource([MethodChannel? channel])
      : _channel = channel ?? const MethodChannel(channelName);

  @override
  Future<SurveyLocalId> localId() async {
    final Object? r;
    try {
      r = await _channel.invokeMethod<Object?>('localIdHash');
    } on PlatformException catch (e) {
      throw SurveyIntegrityException(e.code == 'unsupported'
          ? SurveyIntegrityError.unsupported
          : SurveyIntegrityError.failed);
    } on MissingPluginException {
      throw const SurveyIntegrityException(SurveyIntegrityError.unsupported);
    }
    final hash = r is Map ? r['localIdHash'] : null;
    if (hash is! String || !SurveyLocalId.isValid(hash)) {
      throw const SurveyIntegrityException(SurveyIntegrityError.failed);
    }
    return SurveyLocalId(hash);
  }
}

/// Tokens de App Check **de uso limitado**: el servidor los consume, así que
/// cada alta o voto pide uno nuevo (nunca se reutiliza).
abstract class AppCheckTokenSource {
  /// Activa App Check (idempotente). Lanza [SurveyIntegrityException].
  Future<void> activate();

  /// Token de uso limitado nuevo para la cabecera `X-Firebase-AppCheck` de
  /// `votes`. Opaco: no se imprime.
  Future<String> limitedUseToken();

  /// Token estándar (el SDK lo reutiliza mientras no caduque) para `my-votes`,
  /// que el servidor verifica sin consumir.
  Future<String> standardToken();
}

/// Proveedores: App Attest en iOS, Play Integrity en Android y Debug en las
/// compilaciones de depuración (el token de depuración se registra en la
/// consola de Firebase).
class FirebaseAppCheckTokenSource implements AppCheckTokenSource {
  static Future<void>? _activation;
  final bool debugProvider;

  FirebaseAppCheckTokenSource({this.debugProvider = kDebugMode});

  @override
  Future<void> activate() => _activation ??= _activate().catchError((Object e) {
        _activation = null;
        throw classify(e);
      });

  Future<void> _activate() async {
    final appCheck = FirebaseAppCheck.instance;
    await appCheck.activate(
      androidProvider:
          debugProvider ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider: debugProvider ? AppleProvider.debug : AppleProvider.appAttest,
    );
    // Solo se usan tokens de uso limitado: sin refresco en segundo plano.
    await appCheck.setTokenAutoRefreshEnabled(false);
  }

  @override
  Future<String> limitedUseToken() async {
    await activate();
    final String token;
    try {
      token = await FirebaseAppCheck.instance.getLimitedUseToken();
    } catch (e) {
      throw classify(e);
    }
    if (token.isEmpty) {
      throw const SurveyIntegrityException(SurveyIntegrityError.failed);
    }
    return token;
  }

  @override
  Future<String> standardToken() async {
    await activate();
    final String? token;
    try {
      token = await FirebaseAppCheck.instance.getToken();
    } catch (e) {
      throw classify(e);
    }
    if (token == null || token.isEmpty) {
      throw const SurveyIntegrityException(SurveyIntegrityError.failed);
    }
    return token;
  }

  /// Los errores nativos de App Check llegan como [FirebaseException] con
  /// códigos que cambian entre plataformas: se clasifican por palabras clave.
  /// Nunca se conserva el mensaje (podría llevar datos del token).
  @visibleForTesting
  static SurveyIntegrityException classify(Object e) {
    if (e is SurveyIntegrityException) return e;
    final text = e is FirebaseException
        ? '${e.code} ${e.message}'.toLowerCase()
        : e is PlatformException
            ? '${e.code} ${e.message}'.toLowerCase()
            : '';
    SurveyIntegrityError kind;
    if (e is MissingPluginException ||
        text.contains('unsupported') ||
        text.contains('not supported') ||
        text.contains('play store') ||
        text.contains('play services') ||
        text.contains('api_not_available') ||
        text.contains('api not available')) {
      kind = SurveyIntegrityError.unsupported;
    } else if (text.contains('too many') ||
        text.contains('too_many') ||
        text.contains('throttl') ||
        text.contains('429')) {
      kind = SurveyIntegrityError.rateLimited;
    } else if (text.contains('network') || text.contains('offline')) {
      kind = SurveyIntegrityError.network;
    } else if (text.contains('unavailable') ||
        text.contains('unreachable') ||
        text.contains('timeout') ||
        text.contains('timed out') ||
        text.contains('503')) {
      kind = SurveyIntegrityError.serverUnavailable;
    } else {
      kind = SurveyIntegrityError.failed;
    }
    return SurveyIntegrityException(kind);
  }
}

/// Solo para desarrollo contra el backend en modo `fake`
/// (`--dart-define=SURVEY_INTEGRITY=fake`, y únicamente en debug; el backend
/// local necesita `NODE_ENV=development`): token con el formato de
/// `fakeAppCheck.verifier.ts`, `fake-appcheck.<appId>.<único>~<iat>`, con `iat`
/// en segundos para que también se pruebe la frescura (> 120 s → `stale`). En
/// release la constante es `false` y este código se elimina al compilar.
class FakeAppCheckTokenSource implements AppCheckTokenSource {
  static const enabled = kDebugMode &&
      String.fromEnvironment('SURVEY_INTEGRITY') == 'fake';

  final String appId;
  final DateTime Function() _now;
  FakeAppCheckTokenSource({String? appId, DateTime Function()? clock})
      : appId = appId ?? _firebaseAppId(),
        _now = clock ?? DateTime.now;

  static String _firebaseAppId() {
    try {
      return Firebase.app().options.appId;
    } catch (_) {
      return 'fake-app';
    }
  }

  @override
  Future<void> activate() async {}

  @override
  Future<String> limitedUseToken() async =>
      'fake-appcheck.$appId.${const Uuid().v4()}'
      '~${_now().millisecondsSinceEpoch ~/ 1000}';

  @override
  Future<String> standardToken() => limitedUseToken();
}
