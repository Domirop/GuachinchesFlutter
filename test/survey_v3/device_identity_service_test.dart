import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/model/survey_v3.dart';
import 'package:guachinches/services/survey_integrity/device_identity_service.dart';
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
