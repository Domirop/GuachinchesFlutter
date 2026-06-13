import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel, PlatformException;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/cubit/theme/theme_cubit.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/model/user_info.dart';
import 'package:guachinches/l10n/app_localizations.dart';
import 'package:guachinches/ui/pages/login/login_screen.dart';

/// Minimal fake RemoteRepository — all methods that tests exercise return
/// sane defaults; everything else throws via noSuchMethod (which is fine
/// because these tests don't reach those code paths).
class _FakeRepo extends Fake implements RemoteRepository {
  @override
  Future<dynamic> loginUser(String email, String password) async {
    throw Exception('stub: login always fails in tests');
  }

  @override
  Future<UserInfo> getUserInfo(String userId) async => UserInfo();

  @override
  Future<void> deleteUser(String id) async {}
}

/// Wraps the widget under test with required Bloc providers.
Widget _wrap(Widget child, {ThemeMode themeMode = ThemeMode.dark}) {
  final repo = _FakeRepo();
  return MultiBlocProvider(
    providers: [
      BlocProvider<UserCubit>(
        create: (_) => UserCubit(repo),
      ),
      BlocProvider<ThemeCubit>(
        create: (_) => ThemeCubit(themeMode),
      ),
    ],
    child: MaterialApp(
      theme: appLightTheme,
      darkTheme: appDarkTheme,
      themeMode: themeMode,
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      // Los asserts comprueban copy en español; sin esto el host usa 'en'.
      locale: const Locale('es'),
      home: child,
    ),
  );
}

void main() {
  group('LoginScreen', () {
    testWidgets('renders hero section and OAuth buttons in default state',
        (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen()));
      await tester.pump();

      // Hero headline text
      expect(find.textContaining('Dónde comer'), findsOneWidget);

      // OAuth buttons
      expect(find.text('Continuar con Google'), findsOneWidget);
      expect(find.text('Continuar con Apple'), findsOneWidget);

      // Email legacy link
      expect(find.text('Entrar con email y contraseña'), findsOneWidget);

      // Legal footer
      expect(find.textContaining('Al continuar'), findsOneWidget);
    });

    testWidgets('tapping email link transitions to email form',
        (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen()));
      await tester.pump();

      await tester.tap(find.text('Entrar con email y contraseña'));
      await tester.pumpAndSettle();

      // Email form title
      expect(find.text('Entrar con email'), findsOneWidget);
      // Back link
      expect(find.text('Otras formas de entrar'), findsOneWidget);
      // Submit button
      expect(find.text('Iniciar sesión'), findsOneWidget);
    });

    testWidgets('email form: tapping back returns to default state',
        (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen()));
      await tester.pump();

      // Go to email form
      await tester.tap(find.text('Entrar con email y contraseña'));
      await tester.pumpAndSettle();

      // Tap back
      await tester.tap(find.text('Otras formas de entrar'));
      await tester.pumpAndSettle();

      // Back to default — OAuth buttons visible again
      expect(find.text('Continuar con Google'), findsOneWidget);
    });

    testWidgets('renders correctly in light theme', (tester) async {
      await tester.pumpWidget(
          _wrap(const LoginScreen(), themeMode: ThemeMode.light));
      await tester.pump();

      expect(find.text('Continuar con Google'), findsOneWidget);
      expect(find.text('Continuar con Apple'), findsOneWidget);
    });

    testWidgets('loading state: Apple button still visible when Google loading',
        (tester) async {
      // Mock del canal google_sign_in: sin él, signIn() nunca completa en el
      // host de tests y la pantalla queda cargando para siempre.
      // init OK, signIn → null (usuario cancela) → vuelve a defaultView.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/google_sign_in'),
        (call) async => null,
      );
      addTearDown(() => TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('plugins.flutter.io/google_sign_in'), null));

      await tester.pumpWidget(_wrap(const LoginScreen()));
      await tester.pump();

      // Tap Google (triggers loading state transition)
      await tester.tap(find.text('Continuar con Google'));
      await tester.pump(); // one frame — state changes to loading

      // Both buttons still in widget tree (opacity changes, not removal).
      expect(find.text('Continuar con Apple'), findsAtLeast(1));

      await tester.pumpAndSettle();
    });

    testWidgets('error state: error banner is shown after auth failure',
        (tester) async {
      // Mock del canal google_sign_in que FALLA: fuerza la ruta loginError →
      // banner de error con el copy actual.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/google_sign_in'),
        (call) async => throw PlatformException(code: 'sign_in_failed'),
      );
      addTearDown(() => TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('plugins.flutter.io/google_sign_in'), null));

      await tester.pumpWidget(_wrap(const LoginScreen()));
      await tester.pump();

      // Tap Google to enter loading state
      await tester.tap(find.text('Continuar con Google'));
      await tester.pumpAndSettle();

      // Error banner visible (copy actual de loginError)
      expect(
        find.textContaining('Inténtalo de nuevo'),
        findsAtLeast(1),
      );
    });

    testWidgets('forgot password SnackBar shows in email form', (tester) async {
      // Use a larger test surface so the form content is fully on screen
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(const LoginScreen()));
      await tester.pump();

      // Navigate to email form
      await tester.tap(find.text('Entrar con email y contraseña'));
      await tester.pumpAndSettle();

      // Ensure forgot password button is visible
      await tester.ensureVisible(find.text('¿Olvidaste tu contraseña?'));
      await tester.pumpAndSettle();

      // Tap forgot password
      await tester.tap(find.text('¿Olvidaste tu contraseña?'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Contacta con soporte'), findsOneWidget);
    });
  });
}
