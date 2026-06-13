import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/model/user_info.dart';
import 'package:guachinches/data/newsletter/newsletter_consent_service.dart';

/// Repo falso que captura la última llamada a setNewsletterConsent.
class _CapturingRepo extends Fake implements RemoteRepository {
  bool? granted;
  String? version;
  String? source;
  String? userId;
  bool shouldThrow = false;
  int calls = 0;

  @override
  Future<void> setNewsletterConsent(
    String userId, {
    required bool granted,
    required String consentTextVersion,
    required String source,
  }) async {
    calls++;
    this.userId = userId;
    this.granted = granted;
    version = consentTextVersion;
    this.source = source;
    if (shouldThrow) throw Exception('backend caído');
  }

  @override
  Future<UserInfo> getUserInfo(String userId) async => UserInfo();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Storage en memoria simulando flutter_secure_storage vía su MethodChannel.
  final store = <String, String?>{};

  setUp(() {
    store.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async {
        final args = (call.arguments as Map?) ?? {};
        final key = args['key'] as String?;
        switch (call.method) {
          case 'write':
            store[key!] = args['value'] as String?;
            return null;
          case 'read':
            return store[key];
          default:
            return null;
        }
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      null,
    );
  });

  group('NewsletterConsentService', () {
    test('(a) submit(granted) manda versión + origen correctos al backend',
        () async {
      final repo = _CapturingRepo();
      final service = NewsletterConsentService(repo);

      await service.submit(userId: 'u1', granted: true, source: 'onboarding');

      expect(repo.calls, 1);
      expect(repo.userId, 'u1');
      expect(repo.granted, true);
      expect(repo.source, 'onboarding');
      // El contrato RGPD: la versión enviada == la mostrada.
      expect(repo.version, kNewsletterConsentTextVersion);
    });

    test('(b) submit persiste estado local (asked + granted)', () async {
      final repo = _CapturingRepo();
      final service = NewsletterConsentService(repo);

      expect(await service.hasBeenAsked(), false);

      await service.submit(userId: 'u1', granted: true, source: 'onboarding');
      expect(await service.hasBeenAsked(), true);
      expect(await service.isGranted(), true);

      await service.submit(userId: 'u1', granted: false, source: 'settings');
      expect(await service.isGranted(), false);
    });

    test('(c) un fallo del backend NO propaga (estado local queda guardado)',
        () async {
      final repo = _CapturingRepo()..shouldThrow = true;
      final service = NewsletterConsentService(repo);

      // No debe lanzar.
      await service.submit(userId: 'u1', granted: true, source: 'onboarding');

      expect(await service.isGranted(), true);
      expect(await service.hasBeenAsked(), true);
    });

    test('(d) sin userId no llama al backend pero marca asked', () async {
      final repo = _CapturingRepo();
      final service = NewsletterConsentService(repo);

      await service.submit(userId: '', granted: true, source: 'onboarding');

      expect(repo.calls, 0);
      expect(await service.hasBeenAsked(), true);
    });
  });
}
