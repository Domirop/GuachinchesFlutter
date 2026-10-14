import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/model/survey_v3.dart';
import 'package:guachinches/services/survey_integrity/device_identity_service.dart';
import 'package:guachinches/services/survey_integrity/survey_pinning.dart';
import 'package:guachinches/utils/app_version.dart';

import 'survey_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KeychainLocalIdSource (iOS)', () {
    test('el secreto del Keychain se reutiliza: misma identidad tras reiniciar o reinstalar', () async {
      final keychain = MemorySecureStorage();

      final first = await KeychainLocalIdSource(storage: keychain, random: Random(1)).localId();
      expect(first.created, isTrue);
      expect(SurveyLocalId.isValid(first.hash), isTrue);
      expect(keychain.writes, 1);

      // Otro arranque (o reinstalación con el Keychain intacto) y otra semilla:
      // si se creara un secreto nuevo, el hash cambiaría.
      final second = await KeychainLocalIdSource(storage: keychain, random: Random(2)).localId();
      expect(second.created, isFalse, reason: 'no se crea un secreto nuevo');
      expect(second.hash, first.hash);
      expect(keychain.writes, 1, reason: 'no se reescribe');
    });

    test('se guarda con AfterFirstUnlockThisDeviceOnly, sin sincronizar y en su propio servicio', () async {
      final keychain = MemorySecureStorage();
      await KeychainLocalIdSource(storage: keychain).localId();
      final opts = keychain.writeOptions[KeychainLocalIdSource.key]!.toMap();
      expect(opts['accessibility'], 'first_unlock_this_device');
      expect(opts['synchronizable'], 'false');
      // FreshInstallGuard borra el servicio por defecto al reinstalar: el
      // secreto de la encuesta no puede estar ahí.
      expect(opts['accountName'], KeychainLocalIdSource.service);
      expect(opts['accountName'], isNot(const IOSOptions().toMap()['accountName']));
    });

    test('hash = SHA256("gm-survey-id:" ‖ L) (fixture de identity.ts del backend)', () async {
      final keychain = MemorySecureStorage();
      final l = List<int>.generate(32, (i) => i);
      keychain.items['${KeychainLocalIdSource.service}/${KeychainLocalIdSource.key}'] = base64Encode(l);
      final id = await KeychainLocalIdSource(storage: keychain).localId();
      expect(id.hash, sha256.convert([...utf8.encode('gm-survey-id:'), ...l]).toString());
      expect(SurveyLocalId.hashOf(utf8.encode('abc')),
          sha256.convert(utf8.encode('gm-survey-id:abc')).toString());
    });

    test('Keychain bloqueado o ilegible → error tipado y NUNCA otro secreto encima', () async {
      final keychain = MemorySecureStorage()
        ..readError = PlatformException(code: 'Unexpected security result code', message: 'Code: -25308');
      await expectLater(
          KeychainLocalIdSource(storage: keychain).localId(),
          throwsA(isA<SurveyIntegrityException>()
              .having((e) => e.error, 'error', SurveyIntegrityError.keychainLocked)));
      expect(keychain.writes, 0);

      final corrupt = MemorySecureStorage();
      corrupt.items['${KeychainLocalIdSource.service}/${KeychainLocalIdSource.key}'] = 'no-base64!';
      await expectLater(KeychainLocalIdSource(storage: corrupt).localId(),
          throwsA(isA<SurveyIntegrityException>()));
      expect(corrupt.writes, 0);
    });
  });

  group('carrera en el primer arranque', () {
    test('dos llamadas simultáneas al servicio → mismo id y una sola lectura', () async {
      final src = _SlowRandomSource();
      final s = identity(localIds: src);
      final results = await Future.wait([s.localId(), s.localId(), s.enrollLike()]);
      expect(results.map((r) => r.hash).toSet(), hasLength(1));
      expect(src.calls, 1);
    });

    test('dos llamadas simultáneas al Keychain vacío → un solo secreto escrito', () async {
      final keychain = MemorySecureStorage();
      final src = KeychainLocalIdSource(storage: keychain, random: Random.secure());
      final results = await Future.wait([src.localId(), src.localId()]);
      expect(results[0].hash, results[1].hash);
      expect(keychain.writes, 1);
    });

    test('si la lectura falla, se olvida y el siguiente intento vuelve a leer', () async {
      final src = _SlowRandomSource()..failNext = true;
      final s = identity(localIds: src);
      await expectLater(s.localId(), throwsA(isA<SurveyIntegrityException>()));
      expect((await s.localId()).hash, isNotEmpty);
      expect(src.calls, 2);
    });
  });

  group('SsaidLocalIdSource (Android)', () {
    const channel = MethodChannel('test/survey_device');
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test('lee el hash del canal y valida el formato', () async {
      messenger.setMockMethodCallHandler(channel, (call) async => {'localIdHash': 'b' * 64, 'created': false});
      expect((await SsaidLocalIdSource(channel).localId()).hash, 'b' * 64);
      messenger.setMockMethodCallHandler(channel, (call) async => {'localIdHash': 'nope'});
      await expectLater(SsaidLocalIdSource(channel).localId(), throwsA(isA<SurveyIntegrityException>()));
    });

    test('sin SSAID o sin canal → unsupported (error tipado, no un fallo)', () async {
      messenger.setMockMethodCallHandler(channel, (call) async => throw PlatformException(code: 'unsupported'));
      await expectLater(
          SsaidLocalIdSource(channel).localId(),
          throwsA(isA<SurveyIntegrityException>()
              .having((e) => e.error, 'error', SurveyIntegrityError.unsupported)));
      await expectLater(
          SsaidLocalIdSource(const MethodChannel('test/no_handler')).localId(),
          throwsA(isA<SurveyIntegrityException>()
              .having((e) => e.error, 'error', SurveyIntegrityError.unsupported)));
    });
  });

  group('DeviceIdentityService', () {
    test('cada petición lleva un token de App Check nuevo; la identidad se lee una vez', () async {
      final ids = FakeLocalIdSource();
      final appCheck = FakeAppCheck();
      final s = identity(localIds: ids, appCheck: appCheck);
      final a = await s.identityRequest();
      final b = await s.voteRequest(const [SurveyVoteSelection(kTrad, 'r-1')]);
      expect(a.appCheckToken, isNot(b.appCheckToken));
      expect(ids.calls, 1);
      expect(b.body['votes'], [
        {'category': kTrad, 'value': 'r-1'}
      ]);
      expect(a.toString(), isNot(contains(kTokenPrefix)));
    });

    test('dos votos en la misma categoría → ArgumentError (no se pide token)', () {
      final appCheck = FakeAppCheck();
      final s = identity(appCheck: appCheck);
      expect(
          () => s.voteRequest(const [SurveyVoteSelection(kTrad, 'a'), SurveyVoteSelection(kTrad, 'b')]),
          throwsArgumentError);
      expect(appCheck.tokens, isEmpty);
    });

    test('token falso para el backend en modo fake: formato de fakeAppCheck.verifier.ts', () async {
      final t1 = await FakeAppCheckTokenSource(appId: '1:123:ios:abc').limitedUseToken();
      final t2 = await FakeAppCheckTokenSource(appId: '1:123:ios:abc').limitedUseToken();
      expect(t1, startsWith('fake-appcheck.1:123:ios:abc.'));
      expect(t1, isNot(t2), reason: 'de un solo uso');
      expect(FakeAppCheckTokenSource.enabled, isFalse, reason: 'solo con --dart-define');
    });
  });

  group('SurveyPinning', () {
    test('raíces fijadas: ISRG Root X1 y X2 (huellas SHA-256 del DER)', () async {
      const expected = {
        'assets/certs/isrg_root_x1.pem':
            '96bcec06264976f37460779acf28c5a7cfe8a3c0aae11a8ffcee05c0bddf08c6',
        'assets/certs/isrg_root_x2.pem':
            '69729b8e15a86efc177a57afb7171dfc64add28c2fca8cf1507e34453ccb1470',
      };
      expect(SurveyPinning.roots, expected.keys.toList());
      for (final e in expected.entries) {
        final pem = await rootBundle.loadString(e.key);
        final b64 = pem
            .split('\n')
            .where((l) => l.isNotEmpty && !l.startsWith('-----'))
            .join();
        expect(sha256.convert(base64Decode(b64)).toString(), e.value, reason: e.key);
      }
      // Y el contexto TLS las acepta.
      expect(await SurveyPinning.context(), isNotNull);
    });

    test('solo se desactiva en debug contra un backend local (o fake)', () {
      for (final h in ['localhost', '127.0.0.1', '10.0.2.2', '192.168.1.20', 'mac.local']) {
        expect(SurveyPinning.isLocalHost(h), isTrue, reason: h);
      }
      for (final h in ['api.guachinchesmodernos.com', '51.159.11.23', 'evil.localhost.com']) {
        expect(SurveyPinning.isLocalHost(h), isFalse, reason: h);
      }
      expect(SurveyPinning.disabledFor(Uri.parse('https://api.guachinchesmodernos.com:459/')), isFalse,
          reason: 'producción siempre con pinning, también en debug');
    });
  });

  group('FirebaseAppCheckTokenSource.classify', () {
    SurveyIntegrityError kind(String code, [String? message]) => FirebaseAppCheckTokenSource.classify(
            FirebaseException(plugin: 'firebase_app_check', code: code, message: message))
        .error;

    test('errores nativos de App Check → error tipado', () {
      expect(kind('unknown', 'App attestation is not supported on this device'), SurveyIntegrityError.unsupported);
      expect(kind('unknown', 'Play Store app is not installed'), SurveyIntegrityError.unsupported);
      expect(kind('unknown', 'Too many attempts'), SurveyIntegrityError.rateLimited);
      expect(kind('unknown', 'A network error occurred'), SurveyIntegrityError.network);
      expect(kind('unknown', 'Server unreachable'), SurveyIntegrityError.serverUnavailable);
      expect(kind('unknown', 'App attestation failed'), SurveyIntegrityError.failed);
      expect(FirebaseAppCheckTokenSource.classify(MissingPluginException()).error, SurveyIntegrityError.unsupported);
      expect(FirebaseAppCheckTokenSource.classify(StateError('x')).error, SurveyIntegrityError.failed);
    });
  });

  group('compareAppVersions (splash y minAppVersion)', () {
    test('compara numéricamente y por componentes', () {
      expect(compareAppVersions('5.0.0', '4.7.0'), greaterThan(0),
          reason: 'antes 5.0 < 4.7 por comparar el menor');
      expect(compareAppVersions('4.10.0', '4.9.9'), greaterThan(0));
      expect(compareAppVersions('4.6.0+94', '4.7.0'), lessThan(0));
      expect(compareAppVersions('4.7', '4.7.0'), 0);
    });
  });
}

/// Fuente lenta que daría un id distinto en cada lectura: si el servicio la
/// llamara dos veces a la vez, saldrían dos identidades.
class _SlowRandomSource implements LocalIdSource {
  int calls = 0;
  bool failNext = false;
  final _random = Random();

  @override
  Future<SurveyLocalId> localId() async {
    calls++;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    if (failNext) {
      failNext = false;
      throw const SurveyIntegrityException(SurveyIntegrityError.keychain);
    }
    return SurveyLocalId(SurveyLocalId.hashOf([_random.nextInt(1 << 32)]));
  }
}

extension on DeviceIdentityService {
  /// Una petición real también lee la identidad.
  Future<SurveyLocalId> enrollLike() async {
    final r = await identityRequest();
    return SurveyLocalId(r.body['localIdHash'] as String);
  }
}
