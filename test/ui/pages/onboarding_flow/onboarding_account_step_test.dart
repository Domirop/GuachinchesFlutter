import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/onboarding_flow/onboarding_logic.dart';
import 'package:guachinches/ui/pages/onboarding_flow/widgets/onboarding_account_step.dart';

Finder _byId(String id) => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.identifier == id,
    );

Future<void> _pump(WidgetTester tester, Widget child,
    {ThemeData? theme}) async {
  tester.view.physicalSize = const Size(402 * 3, 874 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: theme ?? appLightTheme,
    builder: (ctx, c) => MediaQuery(
      data: MediaQuery.of(ctx).copyWith(disableAnimations: true),
      child: c!,
    ),
    home: child,
  ));
  await tester.pump();
}

void main() {
  group('paso 4 · cuenta', () {
    Widget step({
      Future<List<Restaurant>> Function(String?)? loader,
      VoidCallback? onSkip,
      VoidCallback? onEmail,
      GlobalKey<OnboardingAccountStepState>? key,
      Future<OnbSignInOutcome> Function(OnbAuthProvider)? signIn,
    }) =>
        OnboardingAccountStep(
          key: key,
          islandId: 'tf',
          loadPlaces: loader ?? (_) async => const <Restaurant>[],
          onBack: () {},
          signIn: signIn ?? (_) async => OnbSignInOutcome.cancelled,
          onSkip: onSkip ?? () {},
          onLoginEmail: onEmail ?? () {},
          showAppleOverride: true,
        );

    testWidgets('Apple primero, luego Google; textos y legal', (tester) async {
      var skipped = 0;
      var email = 0;
      await _pump(
          tester, step(onSkip: () => skipped++, onEmail: () => email++));
      await tester.pump();
      expect(find.text('Guarda tus sitios favoritos'), findsOneWidget);
      final apple = tester.getTopLeft(_byId('onboarding-account-apple'));
      final google = tester.getTopLeft(_byId('onboarding-account-google'));
      expect(apple.dy, lessThan(google.dy));
      expect(find.textContaining('Política de privacidad', findRichText: true),
          findsOneWidget);

      await tester.tap(_byId('onboarding-account-skip'));
      await tester.tap(_byId('onboarding-account-email'));
      expect(skipped, 1);
      expect(email, 1);
    });

    testWidgets('error en un aviso dentro de la pantalla (sin snackbar)',
        (tester) async {
      final key = GlobalKey<OnboardingAccountStepState>();
      await _pump(tester, step(key: key), theme: appDarkTheme);
      key.currentState!.showErrorForTesting(OnbAuthProvider.google);
      await tester.pump();
      expect(_byId('onboarding-account-error'), findsOneWidget);
      expect(find.text('No hemos podido conectar con Google'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('conectando: «Conectando con Google…» y el resto bloqueado',
        (tester) async {
      final key = GlobalKey<OnboardingAccountStepState>();
      var skipped = 0;
      await _pump(tester, step(key: key, onSkip: () => skipped++));
      key.currentState!.showLoadingForTesting(OnbAuthProvider.google);
      await tester.pump();
      expect(find.text('Conectando con Google…'), findsOneWidget);
      await tester.tap(_byId('onboarding-account-skip'));
      expect(skipped, 0);
    });

    testWidgets('Google falla → aviso «No hemos podido conectar con Google»',
        (tester) async {
      final calls = <OnbAuthProvider>[];
      await _pump(tester, step(signIn: (p) async {
        calls.add(p);
        return OnbSignInOutcome.error;
      }));
      // Google está bajo el pliegue en pantallas bajas.
      await tester.ensureVisible(_byId('onboarding-account-google'));
      await tester.tap(_byId('onboarding-account-google'));
      await tester.pump();
      expect(calls, [OnbAuthProvider.google]);
      expect(_byId('onboarding-account-error'), findsOneWidget);
      expect(find.text('No hemos podido conectar con Google'), findsOneWidget);
    });

    testWidgets('cancelar no muestra error y deja volver a intentarlo',
        (tester) async {
      var calls = 0;
      await _pump(tester, step(signIn: (p) async {
        calls++;
        return OnbSignInOutcome.cancelled;
      }));
      await tester.ensureVisible(_byId('onboarding-account-google'));
      await tester.tap(_byId('onboarding-account-google'));
      await tester.pump();
      expect(_byId('onboarding-account-error'), findsNothing);
      expect(find.text('Continuar con Google'), findsOneWidget);
      await tester.tap(_byId('onboarding-account-google'));
      await tester.pump();
      expect(calls, 2);
    });

    testWidgets('sin sitios: tarjetas con glifo y sin nombre inventado',
        (tester) async {
      await _pump(tester, step(loader: (_) async => throw Exception('x')));
      await tester.pump();
      expect(find.textContaining('Casa'), findsNothing);
    });
  });
}
