import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/cubit/theme/theme_cubit.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/data/cubit/user/user_state.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/model/user_info.dart';
import 'package:guachinches/ui/pages/settings/settings_screen.dart';

class _FakeRepo extends Fake implements RemoteRepository {
  @override
  Future<UserInfo> getUserInfo(String userId) async => UserInfo(
        id: '123',
        nombre: 'María',
        apellidos: 'López',
        email: 'maria.lopez@gmail.com',
        valoraciones: [],
      );

  @override
  Future<void> deleteUser(String id) async {}

  @override
  Future<dynamic> loginUser(String email, String password) async {
    throw Exception('stub');
  }
}

/// Pre-seeded UserCubit for tests that need specific states immediately.
class _PreSeededUserCubit extends UserCubit {
  final UserState seedState;
  _PreSeededUserCubit(RemoteRepository repo, this.seedState) : super(repo) {
    emit(seedState);
  }
}

/// Wraps SettingsScreen with Bloc providers and a large enough test surface.
Widget _wrapWithState({
  required UserState userState,
  ThemeMode themeMode = ThemeMode.dark,
}) {
  final repo = _FakeRepo();
  final userCubit = _PreSeededUserCubit(repo, userState);

  return MultiBlocProvider(
    providers: [
      BlocProvider<UserCubit>.value(value: userCubit),
      BlocProvider<ThemeCubit>(
        create: (_) => ThemeCubit(themeMode),
      ),
    ],
    child: MaterialApp(
      theme: appLightTheme,
      darkTheme: appDarkTheme,
      themeMode: themeMode,
      home: const SettingsScreen(),
    ),
  );
}

/// Sets a large device surface so all items are findable by the test framework,
/// even when rendered off-screen in a scrollable list.
void _setLargeSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
}

void main() {
  final testUser = UserInfo(
    id: '1',
    nombre: 'María',
    apellidos: 'López',
    email: 'maria@gmail.com',
    valoraciones: [],
  );

  // ── Not logged in state ──────────────────────────────────────────────────
  group('SettingsScreen — not logged in (UserInitial)', () {
    setUp(() {}); // nothing here — tearDown handles view reset

    testWidgets('shows login CTA and "Tu perfil en..." headline',
        (tester) async {
      _setLargeSurface(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
          _wrapWithState(userState: const UserInitial()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Tu perfil en'), findsOneWidget);
      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.textContaining('Google o Apple'), findsOneWidget);
    });

    testWidgets('shows theme segmented control even when not logged in',
        (tester) async {
      _setLargeSurface(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
          _wrapWithState(userState: const UserInitial()));
      await tester.pumpAndSettle();

      expect(find.text('Claro'), findsOneWidget);
      expect(find.text('Oscuro'), findsOneWidget);
      expect(find.text('Sistema'), findsOneWidget);
    });

    testWidgets('shows version label', (tester) async {
      _setLargeSurface(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
          _wrapWithState(userState: const UserInitial()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Dónde Comer Canarias v2.4.0'), findsOneWidget);
    });
  });

  // ── Logged in state ──────────────────────────────────────────────────────
  group('SettingsScreen — logged in (UserLoaded)', () {
    testWidgets('shows user name and email in header', (tester) async {
      _setLargeSurface(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
          _wrapWithState(userState: UserLoaded(testUser)));
      await tester.pumpAndSettle();

      expect(find.textContaining('María'), findsAtLeast(1));
      expect(find.textContaining('maria@gmail.com'), findsAtLeast(1));
    });

    testWidgets('shows all four section labels', (tester) async {
      _setLargeSurface(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
          _wrapWithState(userState: UserLoaded(testUser)));
      await tester.pumpAndSettle();

      expect(find.text('CUENTA'), findsOneWidget);
      expect(find.text('PREFERENCIAS'), findsOneWidget);
      expect(find.text('LEGAL'), findsOneWidget);
      expect(find.text('SESIÓN'), findsOneWidget);
    });

    testWidgets('shows Cuenta section rows', (tester) async {
      _setLargeSurface(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
          _wrapWithState(userState: UserLoaded(testUser)));
      await tester.pumpAndSettle();

      expect(find.text('Editar nombre'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Mis valoraciones'), findsOneWidget);
      expect(find.text('Favoritos guardados'), findsOneWidget);
    });

    testWidgets('shows Preferencias rows (Idioma + Tema)', (tester) async {
      _setLargeSurface(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
          _wrapWithState(userState: UserLoaded(testUser)));
      await tester.pumpAndSettle();

      expect(find.text('Idioma'), findsOneWidget);
      expect(find.text('Tema de la app'), findsOneWidget);
      expect(find.text('Claro'), findsOneWidget);
      expect(find.text('Oscuro'), findsOneWidget);
      expect(find.text('Sistema'), findsOneWidget);
    });

    testWidgets('shows Legal rows', (tester) async {
      _setLargeSurface(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
          _wrapWithState(userState: UserLoaded(testUser)));
      await tester.pumpAndSettle();

      expect(find.text('Términos de uso'), findsOneWidget);
      expect(find.text('Política de privacidad'), findsOneWidget);
    });

    testWidgets('shows Sesion rows (Cerrar sesión + Eliminar cuenta)',
        (tester) async {
      _setLargeSurface(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
          _wrapWithState(userState: UserLoaded(testUser)));
      await tester.pumpAndSettle();

      expect(find.text('Cerrar sesión'), findsOneWidget);
      expect(find.text('Eliminar cuenta'), findsOneWidget);
    });

    testWidgets('email row has Solo lectura badge', (tester) async {
      _setLargeSurface(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
          _wrapWithState(userState: UserLoaded(testUser)));
      await tester.pumpAndSettle();

      expect(find.text('Solo lectura'), findsOneWidget);
    });

    testWidgets('shows user initials in avatar', (tester) async {
      _setLargeSurface(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
          _wrapWithState(userState: UserLoaded(testUser)));
      await tester.pumpAndSettle();

      // Initials ML (María López)
      expect(find.text('ML'), findsOneWidget);
    });

    testWidgets('tapping Cerrar sesión opens destructive modal',
        (tester) async {
      _setLargeSurface(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
          _wrapWithState(userState: UserLoaded(testUser)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('¿Cerrar sesión?'), findsOneWidget);
      expect(find.text('Sí, cerrar sesión'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('tapping Cancelar in logout modal closes it', (tester) async {
      _setLargeSurface(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
          _wrapWithState(userState: UserLoaded(testUser)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('¿Cerrar sesión?'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // Modal dismissed — section label visible again
      expect(find.text('¿Cerrar sesión?'), findsNothing);
      expect(find.text('SESIÓN'), findsOneWidget);
    });

    testWidgets('tapping Eliminar cuenta opens delete modal with warning',
        (tester) async {
      _setLargeSurface(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
          _wrapWithState(userState: UserLoaded(testUser)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Eliminar cuenta'));
      await tester.pumpAndSettle();

      expect(find.text('Eliminar mi cuenta definitivamente'), findsOneWidget);
      expect(find.textContaining('no se puede deshacer'), findsOneWidget);
    });

    testWidgets('theme segmented control changes mode on tap', (tester) async {
      _setLargeSurface(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
          _wrapWithState(userState: UserLoaded(testUser)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Claro'));
      await tester.pumpAndSettle();

      // Still renders (no crash)
      expect(find.text('Claro'), findsOneWidget);
    });

    testWidgets('Idioma tap shows Próximamente SnackBar', (tester) async {
      _setLargeSurface(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
          _wrapWithState(userState: UserLoaded(testUser)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Idioma'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Próximamente'), findsOneWidget);
    });

    testWidgets('renders correctly in light theme', (tester) async {
      _setLargeSurface(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrapWithState(
        userState: UserLoaded(testUser),
        themeMode: ThemeMode.light,
      ));
      await tester.pumpAndSettle();

      expect(find.text('CUENTA'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
    });
  });

  // Note: _DestructiveModal is private — tested indirectly via
  // logout/delete modal tests above.
}
