import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/cubit/theme/theme_cubit.dart';
import 'package:guachinches/data/cubit/user/user_state.dart';
import 'package:guachinches/data/model/user_info.dart';
import 'package:guachinches/ui/pages/settings/settings_screen.dart';
import 'package:guachinches/ui/theme/gm_favorites.dart';

import 'perfil_test_harness.dart';

UserInfo _carmen() => UserInfo(
      id: 'u1',
      nombre: 'Carmen',
      valoraciones: [
        Valoraciones(id: 'v1', rating: '4', valoracionesNegocioId: 'r1'),
        Valoraciones(id: 'v2', rating: '5', valoracionesNegocioId: 'r2'),
      ],
    );

Future<FakePerfilRepo> _pump(
  WidgetTester tester, {
  Map<String, String> storage = const {},
  UserInfo? user,
  bool failUser = false,
  List<String> favs = const ['a', 'b'],
  ThemeCubit? themeCubit,
}) async {
  useTallSurface(tester);
  FlutterSecureStorage.setMockInitialValues({...storage});
  final repo = FakePerfilRepo(user: user, failUser: failUser);
  await tester.pumpWidget(perfilApp(
    SettingsScreen(
      repository: repo,
      favorites: GmFavorites.withRepository(OrderedFavRepo(favs)),
    ),
    userCubit: SeededUserCubit(repo, const UserInitial()),
    themeCubit: themeCubit,
  ));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  group('Perfil sin sesión', () {
    testWidgets('entrar con Google o email, guardados, tema y legal',
        (tester) async {
      await _pump(tester);

      expect(byIdentifier('perfil-guest-card'), findsOneWidget);
      expect(find.text('Tu perfil en Dónde Comer Canarias'), findsOneWidget);
      expect(byIdentifier('perfil-login-google'), findsOneWidget);
      expect(byIdentifier('perfil-login-email'), findsOneWidget);
      // Apple solo en iOS.
      expect(byIdentifier('perfil-login-apple'), findsNothing);
      expect(find.text('Sin cuenta también puedes'), findsOneWidget);
      expect(find.text('2 sitios en este móvil'), findsOneWidget);
      expect(find.text('Tema'), findsOneWidget);
      expect(find.text('Términos de uso'), findsOneWidget);
      expect(find.text('Política de privacidad'), findsOneWidget);
      expect(find.text('Dónde Comer Canarias 4.6.0'), findsOneWidget);
      expect(find.text('Hecho en Canarias'), findsOneWidget);
      // Fuera del rediseño: idioma y la píldora «Muchacho/a».
      expect(find.text('Idioma'), findsNothing);
      expect(find.textContaining('Muchacho'), findsNothing);
    });

    testWidgets('«Entrar con email» abre el acceso único en su paso de email',
        (tester) async {
      await _pump(tester);
      await tester.tap(byIdentifier('perfil-login-email'));
      await tester.pumpAndSettle();
      expect(byIdentifier('login-sheet'), findsOneWidget);
      expect(byIdentifier('login-email-step'), findsOneWidget);
      // Desde el Perfil no hay chip de contexto.
      expect(byIdentifier('login-reason-chip'), findsNothing);

      // Volver al inicio del acceso y cerrar: sigue el Perfil sin sesión.
      await tester.tap(byIdentifier('login-back-button'));
      await tester.pumpAndSettle();
      await tester.tap(byIdentifier('login-close-button'));
      await tester.pumpAndSettle();
      expect(byIdentifier('login-sheet'), findsNothing);
      expect(byIdentifier('perfil-guest-card'), findsOneWidget);
    });

    testWidgets('en iOS, Apple va primero', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await _pump(tester);
      final apple = tester.getTopLeft(byIdentifier('perfil-login-apple'));
      final google = tester.getTopLeft(byIdentifier('perfil-login-google'));
      expect(apple.dy, lessThan(google.dy));
      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('Perfil con sesión', () {
    const session = {
      'userId': 'u1',
      'session_email': 'carmen@ejemplo.com',
      'session_provider': 'google',
    };

    testWidgets('identidad desde la sesión y actividad real', (tester) async {
      await _pump(tester, storage: session, user: _carmen());

      expect(byIdentifier('perfil-identity-card'), findsOneWidget);
      expect(find.text('Carmen'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('carmen@ejemplo.com'), findsOneWidget);
      expect(find.text('Has entrado con Google'), findsOneWidget);
      expect(find.text('2 reseñas · media 4,5'), findsOneWidget);
      expect(find.text('2 sitios en este móvil'), findsOneWidget);
      for (final caption in [
        'Tu actividad',
        'Preferencias',
        'Legal',
        'Cuenta'
      ]) {
        expect(find.text(caption), findsOneWidget);
      }
      expect(byIdentifier('settings-newsletter-row'), findsOneWidget);
      expect(byIdentifier('settings-account-management-row'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
      // Sin endpoint para cambiar el nombre: no se ofrece «Editar».
      expect(find.text('Editar'), findsNothing);
    });

    testWidgets('error parcial: solo falla la fila del perfil y se reintenta',
        (tester) async {
      final repo = await _pump(tester,
          storage: {...session, 'session_name': 'Carmen'},
          user: _carmen(),
          failUser: true);

      expect(byIdentifier('perfil-profile-error'), findsOneWidget);
      expect(find.text('No pudimos cargar tu perfil'), findsOneWidget);
      // La identidad sigue (nombre guardado en el móvil) y Guardados también.
      expect(find.text('Carmen'), findsOneWidget);
      expect(byIdentifier('settings-favorites-row'), findsOneWidget);
      expect(byIdentifier('settings-my-ratings-row'), findsNothing);

      repo.failUser = false;
      await tester.tap(byIdentifier('perfil-retry-button'));
      await tester.pumpAndSettle();
      expect(byIdentifier('perfil-profile-error'), findsNothing);
      expect(find.text('2 reseñas · media 4,5'), findsOneWidget);
    });

    testWidgets('cerrar sesión pide confirmación en una hoja', (tester) async {
      await _pump(tester, storage: session, user: _carmen());

      await tester.tap(byIdentifier('settings-logout-row'));
      await tester.pumpAndSettle();
      expect(find.text('¿Cerrar sesión?'), findsOneWidget);
      expect(byIdentifier('perfil-logout-confirm-button'), findsOneWidget);

      await tester.tap(byIdentifier('perfil-logout-cancel-button'));
      await tester.pumpAndSettle();
      expect(find.text('¿Cerrar sesión?'), findsNothing);
    });

    testWidgets('Mis datos avisa de la eliminación programada', (tester) async {
      final at = DateTime.now().add(const Duration(days: 20));
      await _pump(tester,
          storage: {
            ...session,
            'account_deletion_at_u1': at.toUtc().toIso8601String(),
          },
          user: _carmen());
      expect(find.textContaining('Tu cuenta se eliminará el'), findsOneWidget);
    });
  });

  testWidgets('el control de tema cambia el ThemeCubit', (tester) async {
    final theme = ThemeCubit(ThemeMode.light);
    await _pump(tester, themeCubit: theme);
    await tester.tap(byIdentifier('settings-theme-oscuro'));
    await tester.pumpAndSettle();
    expect(theme.state, ThemeMode.dark);
    await tester.tap(byIdentifier('settings-theme-sistema'));
    await tester.pumpAndSettle();
    expect(theme.state, ThemeMode.system);
  });
}
