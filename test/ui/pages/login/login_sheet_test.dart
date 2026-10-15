import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/newsletter/newsletter_consent_service.dart';
import 'package:guachinches/ui/pages/login/login_logic.dart';
import 'package:guachinches/ui/pages/login/login_presenter.dart';
import 'package:guachinches/ui/pages/login/login_sheet.dart';
import 'package:guachinches/ui/pages/login/widgets/login_widgets.dart';

const _secureStorage =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

/// Acceso falso: cada intento espera a que la prueba lo resuelva.
class _FakeAuth implements LoginAuth {
  @override
  final bool appleAvailable;
  _FakeAuth({this.appleAvailable = true});

  final calls = <(LoginMethod, String, String)>[];
  Completer<LoginOutcome>? pending;
  int kept = 0;
  int signedOut = 0;

  @override
  Future<LoginOutcome> signIn(LoginMethod method,
      {String email = '', String password = ''}) {
    calls.add((method, email, password));
    pending = Completer<LoginOutcome>();
    return pending!.future;
  }

  @override
  Future<bool> keepAccount(String userId) async {
    kept++;
    return true;
  }

  @override
  Future<void> signOut() async => signedOut++;
}

class _Repo extends Fake implements RemoteRepository {}

Finder _id(String id) => find.byWidgetPredicate(
    (w) => w is Semantics && w.properties.identifier == id);

Finder _field(String id) =>
    find.descendant(of: _id(id), matching: find.byType(TextField));

Future<void> _pumpSheet(
  WidgetTester tester,
  _FakeAuth auth, {
  LoginReason? reason,
  bool startOnEmail = false,
  ThemeMode mode = ThemeMode.light,
}) async {
  await tester.pumpWidget(MaterialApp(
    theme: appLightTheme,
    darkTheme: appDarkTheme,
    themeMode: mode,
    home: LoginSheet(auth: auth, reason: reason, startOnEmail: startOnEmail),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorage, (call) async {
      // La newsletter ya se preguntó: no se abre su hoja.
      if (call.method == 'read') return 'true';
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorage, null);
  });

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1206, 2622);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('inicio', () {
    testWidgets('logo, chip de contexto, Apple, Google, email y legal',
        (tester) async {
      phone(tester);
      await _pumpSheet(tester, _FakeAuth(),
          reason: LoginReason.save('Casa Ángela'));

      expect(_id('login-main-step'), findsOneWidget);
      expect(find.byType(LoginLogo), findsOneWidget);
      expect(_id('login-reason-chip'), findsOneWidget);
      expect(find.text('Para guardar Casa Ángela'), findsOneWidget);
      expect(find.text('Entra o crea tu cuenta'), findsOneWidget);
      expect(find.text(kLoginSubtitle), findsOneWidget);
      expect(_id('login-apple-button'), findsOneWidget);
      expect(_id('login-google-button'), findsOneWidget);
      expect(_id('login-email-entry'), findsOneWidget);
      expect(find.text(kLoginEmailNote), findsOneWidget);
      expect(_id('login-terms-link'), findsOneWidget);
      expect(_id('login-privacy-link'), findsOneWidget);
      expect(_id('login-close-button'), findsOneWidget);
      // Apple encima de Google.
      expect(tester.getTopLeft(_id('login-apple-button')).dy,
          lessThan(tester.getTopLeft(_id('login-google-button')).dy));
      // Sin «Crear cuenta» ni registro con email.
      expect(find.textContaining('Crear cuenta'), findsNothing);
    });

    testWidgets('desde el Perfil no hay chip; sin Apple fuera de iOS',
        (tester) async {
      phone(tester);
      await _pumpSheet(tester, _FakeAuth(appleAvailable: false),
          reason: LoginReason.profile, mode: ThemeMode.dark);

      expect(_id('login-reason-chip'), findsNothing);
      expect(_id('login-apple-button'), findsNothing);
      expect(_id('login-google-button'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('conectando y error de proveedor', () {
    testWidgets('Google: «Conectando con Google…» y el resto deshabilitado',
        (tester) async {
      phone(tester);
      final auth = _FakeAuth();
      await _pumpSheet(tester, auth);

      await tester.tap(_id('login-google-button'));
      await tester.pump();
      expect(auth.calls.single.$1, LoginMethod.google);
      expect(find.text('Conectando con Google…'), findsOneWidget);
      final apple = tester.widget<LoginProviderButton>(find.byWidgetPredicate(
          (w) => w is LoginProviderButton && w.method == LoginMethod.apple));
      expect(apple.onTap, isNull);

      auth.pending!
          .complete(const LoginOutcome.failed(LoginFailure.unknown));
      await tester.pumpAndSettle();
      expect(_id('login-error-banner'), findsOneWidget);
      expect(find.text('No hemos podido conectar con Google'), findsOneWidget);
      expect(find.textContaining('contraseña'), findsOneWidget); // solo «email y contraseña» del enlace
      expect(find.textContaining('Email o contraseña'), findsNothing);
      expect(find.text('Continuar con Google'), findsOneWidget);
    });

    testWidgets('cancelar vuelve al inicio sin aviso', (tester) async {
      phone(tester);
      final auth = _FakeAuth();
      await _pumpSheet(tester, auth);
      await tester.tap(_id('login-apple-button'));
      await tester.pump();
      expect(find.text('Conectando con Apple…'), findsOneWidget);
      auth.pending!.complete(LoginOutcome.cancelled);
      await tester.pumpAndSettle();
      expect(_id('login-error-banner'), findsNothing);
      expect(find.text('Continuar con Apple'), findsOneWidget);
    });
  });

  group('email', () {
    testWidgets('«Iniciar sesión» deshabilitado hasta que es válido',
        (tester) async {
      phone(tester);
      final auth = _FakeAuth();
      await _pumpSheet(tester, auth);

      await tester.tap(_id('login-email-entry'));
      await tester.pumpAndSettle();
      expect(_id('login-email-step'), findsOneWidget);
      expect(find.text('Entrar con email'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
      expect(find.text('EMAIL'), findsNothing);

      LoginSubmitButton submit() =>
          tester.widget<LoginSubmitButton>(find.byType(LoginSubmitButton));
      expect(submit().enabled, isFalse);

      await tester.enterText(_field('login-email-field'), 'ana@ejemplo');
      await tester.enterText(_field('login-password-field'), 'secreta');
      await tester.pump();
      expect(submit().enabled, isFalse);

      await tester.enterText(_field('login-email-field'), 'ana@ejemplo.com');
      await tester.pump();
      expect(submit().enabled, isTrue);

      // Mostrar / ocultar contraseña.
      TextField pwd() => tester.widget<TextField>(_field('login-password-field'));
      expect(pwd().obscureText, isTrue);
      await tester.tap(_id('login-password-toggle'));
      await tester.pump();
      expect(pwd().obscureText, isFalse);
      final email = tester.widget<TextField>(_field('login-email-field'));
      expect(email.keyboardType, TextInputType.emailAddress);
      expect(email.autofillHints, contains(AutofillHints.email));

      await tester.tap(_id('login-submit-button'));
      await tester.pump();
      expect(auth.calls.single, (LoginMethod.email, 'ana@ejemplo.com', 'secreta'));
      expect(find.text('Entrando…'), findsOneWidget);
      auth.pending!
          .complete(const LoginOutcome.failed(LoginFailure.credentials));
      await tester.pumpAndSettle();
    });

    testWidgets('error en línea con credenciales que no coinciden',
        (tester) async {
      phone(tester);
      final auth = _FakeAuth();
      await _pumpSheet(tester, auth, startOnEmail: true);
      await tester.enterText(_field('login-email-field'), 'ana@ejemplo.com');
      await tester.enterText(_field('login-password-field'), 'mala');
      await tester.pump();
      await tester.tap(_id('login-submit-button'));
      await tester.pump();
      auth.pending!
          .complete(const LoginOutcome.failed(LoginFailure.credentials));
      await tester.pumpAndSettle();

      expect(_id('login-error-banner'), findsOneWidget);
      expect(find.text('No hemos podido entrar'), findsOneWidget);
      expect(find.textContaining('no coinciden'), findsOneWidget);
      expect(_id('login-email-step'), findsOneWidget);

      // Al editar, el aviso se va.
      await tester.enterText(_field('login-password-field'), 'otra');
      await tester.pump();
      expect(_id('login-error-banner'), findsNothing);
    });

    testWidgets('volver al inicio con el botón de cristal', (tester) async {
      phone(tester);
      await _pumpSheet(tester, _FakeAuth(), startOnEmail: true);
      expect(_id('login-back-button'), findsOneWidget);
      await tester.tap(_id('login-back-button'));
      await tester.pumpAndSettle();
      expect(_id('login-main-step'), findsOneWidget);
      expect(_id('login-close-button'), findsOneWidget);
    });
  });

  group('olvido', () {
    testWidgets('recuperar con Google/Apple del mismo email o soporte',
        (tester) async {
      phone(tester);
      await _pumpSheet(tester, _FakeAuth(), startOnEmail: true);
      await tester.tap(_id('login-forgot-button'));
      await tester.pumpAndSettle();

      expect(_id('login-recover-step'), findsOneWidget);
      expect(find.text('Recuperar la cuenta'), findsOneWidget);
      expect(find.textContaining('Google o Apple usando el mismo email',
          findRichText: true), findsOneWidget);
      expect(_id('login-apple-button'), findsOneWidget);
      expect(_id('login-google-button'), findsOneWidget);
      expect(_id('login-support-button'), findsOneWidget);
      expect(find.text('Escribir a soporte'), findsOneWidget);

      await tester.tap(_id('login-back-button'));
      await tester.pumpAndSettle();
      expect(_id('login-email-step'), findsOneWidget);
    });
  });

  group('showLoginSheet', () {
    Future<Future<bool>> open(WidgetTester tester, _FakeAuth auth) async {
      late Future<bool> result;
      await tester.pumpWidget(MaterialApp(
        theme: appLightTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => result = showLoginSheet(
                  context,
                  reason: LoginReason.quiz,
                  auth: auth,
                  newsletter: NewsletterConsentService(_Repo()),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('cerrar con la X devuelve false', (tester) async {
      phone(tester);
      final result = await open(tester, _FakeAuth());
      expect(find.text('Para jugar al quiz'), findsOneWidget);
      await tester.tap(_id('login-close-button'));
      await tester.pumpAndSettle();
      expect(_id('login-sheet'), findsNothing);
      expect(await result, isFalse);
    });

    testWidgets('entrar con eliminación pendiente: conservar y cerrar',
        (tester) async {
      phone(tester);
      final auth = _FakeAuth();
      final result = await open(tester, auth);
      await tester.tap(_id('login-google-button'));
      await tester.pump();
      auth.pending!.complete(LoginOutcome.success(LoginSession(
        userId: 'u1',
        method: LoginMethod.google,
        deletionPending: true,
        deletionAt: DateTime.now().add(const Duration(days: 20)),
      )));
      // El botón de Google sigue cargando bajo el aviso: sin pumpAndSettle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(_id('login-deletion-dialog'), findsOneWidget);
      expect(find.textContaining('Tu cuenta se eliminará el'), findsOneWidget);
      expect(find.text('Conservar mi cuenta'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);

      await tester.tap(_id('login-deletion-keep'));
      await tester.pumpAndSettle();
      expect(auth.kept, 1);
      expect(_id('login-sheet'), findsNothing);
      expect(await result, isTrue);
    });

    testWidgets('eliminación pendiente → «Cerrar sesión» sigue en el acceso',
        (tester) async {
      phone(tester);
      final auth = _FakeAuth();
      await open(tester, auth);
      await tester.tap(_id('login-google-button'));
      await tester.pump();
      auth.pending!.complete(const LoginOutcome.success(LoginSession(
          userId: 'u1', method: LoginMethod.google, deletionPending: true)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Tu cuenta está pendiente de eliminación'),
          findsOneWidget);
      await tester.tap(_id('login-deletion-logout'));
      await tester.pumpAndSettle();
      expect(auth.signedOut, 1);
      expect(_id('login-sheet'), findsOneWidget);
      expect(find.text('Continuar con Google'), findsOneWidget);
    });
  });
}
