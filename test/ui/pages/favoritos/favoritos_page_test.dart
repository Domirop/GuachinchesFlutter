import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/cubit/user/user_state.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/favoritos/favoritos.dart';
import 'package:guachinches/ui/theme/gm_favorites.dart';

import '../settings/perfil_test_harness.dart';

Map<String, Restaurant> _places() => {
      for (final (id, name) in [
        ('a', 'Guachinche Casa Aguere'),
        ('b', 'Dragón Kitchen'),
        ('c', 'La Mentirosilla'),
      ])
        id: Restaurant(id: id, nombre: name, municipio: 'Santa Cruz'),
    };

Future<OrderedFavRepo> _pump(
  WidgetTester tester, {
  List<String> saved = const ['a', 'b', 'c'],
  bool failRestaurants = false,
}) async {
  useTallSurface(tester);
  final fav = OrderedFavRepo(saved);
  final repo =
      FakePerfilRepo(restaurants: _places(), failRestaurants: failRestaurants);
  await tester.pumpWidget(perfilApp(
    FavoritosPage(
      localRepository: fav,
      favorites: GmFavorites.withRepository(fav),
      repository: repo,
    ),
    userCubit: SeededUserCubit(repo, const UserInitial()),
  ));
  await tester.pumpAndSettle();
  return fav;
}

double _y(String text) => find.text(text).evaluate().isEmpty
    ? -1
    : (find.text(text).evaluate().first.renderObject! as RenderBox)
        .localToGlobal(Offset.zero)
        .dy;

void main() {
  testWidgets('el último guardado primero', (tester) async {
    await _pump(tester);
    expect(find.text('Guardados'), findsOneWidget);
    expect(find.text('3 sitios. Se guardan en este móvil, sin cuenta.'),
        findsOneWidget);
    expect(_y('La Mentirosilla'), lessThan(_y('Dragón Kitchen')));
    expect(_y('Dragón Kitchen'), lessThan(_y('Guachinche Casa Aguere')));
    expect(byIdentifier('favoritos-view-list'), findsOneWidget);
    expect(byIdentifier('favoritos-view-map'), findsOneWidget);
  });

  testWidgets('quitar con el corazón y deshacer lo devuelve a su sitio',
      (tester) async {
    final fav = await _pump(tester);
    final before = _y('Dragón Kitchen');

    await tester.tap(byIdentifier('favoritos-remove-b'));
    await tester.pumpAndSettle();
    expect(find.text('Dragón Kitchen'), findsNothing);
    expect(find.text('Quitaste Dragón Kitchen'), findsOneWidget);
    expect(find.text('2 sitios. Se guardan en este móvil, sin cuenta.'),
        findsOneWidget);
    // Aún no se ha borrado de la BD: «Deshacer» lo deja como estaba.
    expect(fav.ids, contains('b'));

    await tester.tap(byIdentifier('favoritos-undo-toast-action'));
    await tester.pumpAndSettle();
    expect(find.text('Quitaste Dragón Kitchen'), findsNothing);
    expect(_y('Dragón Kitchen'), before);
    expect(fav.ids, contains('b'));
  });

  testWidgets('deslizar quita y, sin deshacer, se borra al caducar el aviso',
      (tester) async {
    final fav = await _pump(tester);
    await tester.drag(
        find.byKey(const ValueKey('dismiss-a')), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Quitaste Guachinche Casa Aguere'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Quitaste Guachinche Casa Aguere'), findsNothing);
    expect(fav.ids, isNot(contains('a')));
    expect(find.text('Guachinche Casa Aguere'), findsNothing);
  });

  testWidgets('vacío: el corazón y «Explorar sitios»', (tester) async {
    await _pump(tester, saved: const []);
    expect(byIdentifier('favoritos-empty'), findsOneWidget);
    expect(find.text('Aún no has guardado nada'), findsOneWidget);
    expect(byIdentifier('favoritos-view-map'), findsNothing);
  });

  testWidgets('error si no se puede cargar ningún sitio', (tester) async {
    await _pump(tester, failRestaurants: true);
    expect(byIdentifier('favoritos-error'), findsOneWidget);
    expect(find.text('No pudimos cargar tus guardados'), findsOneWidget);
  });
}
