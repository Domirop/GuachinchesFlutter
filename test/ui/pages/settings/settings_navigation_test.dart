import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/cubit/user/user_state.dart';
import 'package:guachinches/data/model/user_info.dart';
import 'package:guachinches/ui/pages/favoritos/favoritos.dart';
import 'package:guachinches/ui/pages/settings/settings_screen.dart';
import 'package:guachinches/ui/pages/valoraciones/valoraciones.dart';
import 'package:guachinches/ui/theme/gm_favorites.dart';

import 'perfil_test_harness.dart';

Future<void> _pumpLoggedIn(WidgetTester tester) async {
  useTallSurface(tester);
  FlutterSecureStorage.setMockInitialValues({'userId': 'u1'});
  final repo = FakePerfilRepo(
    user: UserInfo(id: 'u1', nombre: 'María', valoraciones: []),
  );
  final favRepo = OrderedFavRepo(const []);
  await tester.pumpWidget(perfilApp(
    SettingsScreen(
      repository: repo,
      favorites: GmFavorites.withRepository(favRepo),
      favoritesStore: favRepo,
    ),
    userCubit: SeededUserCubit(repo, const UserInitial()),
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('Perfil · navegación', () {
    testWidgets('«Mis reseñas» abre ValoracionesPage', (tester) async {
      await _pumpLoggedIn(tester);
      await tester.tap(byIdentifier('settings-my-ratings-row'));
      await tester.pumpAndSettle();
      expect(find.byType(ValoracionesPage), findsOneWidget);
    });

    testWidgets('«Guardados» abre FavoritosPage', (tester) async {
      await _pumpLoggedIn(tester);
      await tester.tap(byIdentifier('settings-favorites-row'));
      await tester.pumpAndSettle();
      expect(find.byType(FavoritosPage), findsOneWidget);
      expect(find.text('Aún no has guardado nada'), findsOneWidget);
    });
  });
}
