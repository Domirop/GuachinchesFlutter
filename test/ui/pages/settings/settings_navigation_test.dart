import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/cubit/theme/theme_cubit.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/data/cubit/user/user_state.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/model/user_info.dart';
import 'package:guachinches/l10n/app_localizations.dart';
import 'package:guachinches/ui/pages/favoritos/favoritos.dart';
import 'package:guachinches/ui/pages/settings/settings_screen.dart';
import 'package:guachinches/ui/pages/valoraciones/valoraciones.dart';

// ── Fake helpers ──────────────────────────────────────────────────────────────

class _FakeRepo extends Fake implements RemoteRepository {
  @override
  Future<UserInfo> getUserInfo(String userId) async => UserInfo(
        id: userId,
        nombre: 'María',
        apellidos: 'López',
        email: 'maria@gmail.com',
        valoraciones: [],
      );

  @override
  Future<void> deleteUser(String id) async {}

  @override
  Future<dynamic> loginUser(String email, String password) async {
    throw Exception('stub');
  }
}

class _PreSeededUserCubit extends UserCubit {
  final UserState seedState;
  _PreSeededUserCubit(RemoteRepository repo, this.seedState) : super(repo) {
    emit(seedState);
  }
}

Widget _wrapWithState(UserState userState) {
  final repo = _FakeRepo();
  final userCubit = _PreSeededUserCubit(repo, userState);

  return MultiBlocProvider(
    providers: [
      BlocProvider<UserCubit>.value(value: userCubit),
      BlocProvider<ThemeCubit>(
        create: (_) => ThemeCubit(ThemeMode.dark),
      ),
    ],
    child: MaterialApp(
      theme: appLightTheme,
      darkTheme: appDarkTheme,
      themeMode: ThemeMode.dark,
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: const SettingsScreen(),
    ),
  );
}

void _setLargeSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  final testUser = UserInfo(
    id: '1',
    nombre: 'María',
    apellidos: 'López',
    email: 'maria@gmail.com',
    valoraciones: [],
  );

  setUp(() {
    // Provide a non-null userId so ValoracionesPage.isUserLogged() takes the
    // getUserInfo branch instead of goToLogin(), keeping ValoracionesPage on top.
    FlutterSecureStorage.setMockInitialValues({'userId': 'test-123'});
  });

  group('SettingsScreen navigation', () {
    testWidgets('tapping Mis valoraciones row navigates to ValoracionesPage',
        (tester) async {
      _setLargeSurface(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrapWithState(UserLoaded(testUser)));
      await tester.pumpAndSettle();

      final rowFinder = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.identifier == 'settings-my-ratings-row',
      );
      expect(rowFinder, findsOneWidget);

      await tester.tap(rowFinder);
      await tester.pumpAndSettle();

      expect(find.byType(ValoracionesPage), findsOneWidget);
    });

    testWidgets('tapping Favoritos guardados row navigates to FavoritosPage',
        (tester) async {
      _setLargeSurface(tester);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrapWithState(UserLoaded(testUser)));
      await tester.pumpAndSettle();

      final rowFinder = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.identifier == 'settings-favorites-row',
      );
      expect(rowFinder, findsOneWidget);

      await tester.tap(rowFinder);
      await tester.pump(); // start route push
      await tester.pump(const Duration(milliseconds: 400)); // finish transition
      // pumpAndSettle would timeout: FavoritosPage shows CircularProgressIndicator
      // while SQLite plugin is unavailable in flutter_test. Finite pumps are
      // sufficient to assert the route was pushed.
      expect(find.byType(FavoritosPage), findsOneWidget);
    });
  });
}
