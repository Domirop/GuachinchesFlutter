import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/core/remote_config/dcc_remote_config.dart';
import 'package:guachinches/data/cubit/new_home/curated_lists_cubit.dart';
import 'package:guachinches/data/cubit/new_home/new_home_filters_cubit.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/theme/gm_favorites.dart';
import 'package:guachinches/utils/contextual_pool.dart';

import 'listas_test_harness.dart';

void main() {
  late NewHomeFiltersCubit filters;
  late StubCuratedListsCubit curated;

  setUp(() {
    DccRemoteConfig.testOverride = DccRemoteConfig.test(RemoteConfigAllOn());
    filters = NewHomeFiltersCubit();
    curated = StubCuratedListsCubit(CuratedListsLoaded([
      guide(
        id: 'bocadillos',
        title: 'MEJORES BOCADILLOS COCHINO',
        eyebrow: 'TOP',
        location: 'Toda la isla',
        count: 7,
        heroEmoji: '🥪',
      ),
      guide(
          id: 'japoneses',
          title: 'Japoneses en Tenerife',
          subtitle: 'Un recorrido por los mejores japoneses de la isla.',
          position: 2,
          count: 6),
      guide(
          id: 'cenas',
          title: 'Sitios para ocasiones especiales',
          eyebrow: 'Cenas especiales',
          position: 3,
          count: 3),
    ]));
  });

  tearDown(() {
    DccRemoteConfig.testOverride = null;
    filters.close();
    curated.close();
  });

  Future<void> scrollTo(WidgetTester tester, Finder f) =>
      tester.scrollUntilVisible(f, 300,
          scrollable: find
              .descendant(
                  of: find.byType(CustomScrollView),
                  matching: find.byType(Scrollable))
              .first);

  testWidgets('pinta cabecera, «Para ahora», guías y las demás secciones',
      (tester) async {
    await tester.pumpWidget(wrapListas(curated: curated, filters: filters));
    await tester.pumpAndSettle();

    expect(find.text('Listas'), findsOneWidget);
    expect(find.text('Guías de Jonay y Joana, rankings y lo que guardas.'),
        findsOneWidget);
    expect(byIdentifier('listas-search-field'), findsOneWidget);
    expect(byIdentifier('listas-para-ahora'), findsOneWidget);
    expect(find.textContaining('Para ahora · '), findsOneWidget);
    // Guía destacada: título en tipo título, chips de cristal y antetítulo.
    expect(find.text('Mejores Bocadillos Cochino'), findsOneWidget);
    expect(find.text('Top'), findsOneWidget);
    expect(find.text('7 sitios'), findsOneWidget);
    expect(find.text('Top · Toda la isla'), findsOneWidget);
    // Filas: «<Antetítulo> · N sitios».
    expect(find.text('Guía · 6 sitios'), findsOneWidget);
    expect(find.text('Cenas especiales · 3 sitios'), findsOneWidget);
    // El emoji de la guía no se pinta nunca.
    expect(find.text('🥪'), findsNothing);

    await scrollTo(tester, byIdentifier('listas-more-nearby'));
    expect(find.text('Guardados'), findsOneWidget);
    expect(find.text('Más listas'), findsOneWidget);
    expect(find.text('Abiertos ahora'), findsOneWidget);
    expect(find.text('Cerca de ti'), findsOneWidget);

    await scrollTo(tester, find.text('Por tipo'));
    expect(find.text('2 tipos de sitio'), findsOneWidget);
    expect(byIdentifier('listas-type-tasca'), findsOneWidget);
    expect(byIdentifier('listas-type-bodegon'), findsOneWidget);
  });

  testWidgets('sin botón de volver en la pestaña', (tester) async {
    await tester.pumpWidget(wrapListas(curated: curated, filters: filters));
    await tester.pumpAndSettle();
    expect(byIdentifier('listas-back-button'), findsNothing);
  });

  testWidgets('«Por tipo» cuenta los sitios reales y quita tipos vacíos',
      (tester) async {
    final pool = [
      for (var i = 0; i < 3; i++)
        Restaurant(id: 't$i')..type = RestaurantTypeIds.tascas,
    ];
    await tester.pumpWidget(
        wrapListas(curated: curated, filters: filters, pool: pool));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Por tipo'));
    expect(find.text('1 tipo de sitio'), findsOneWidget);
    expect(find.text('3 sitios'), findsOneWidget);
    expect(byIdentifier('listas-type-bodegon'), findsNothing);
  });

  testWidgets('buscar filtra las guías y oculta el resto', (tester) async {
    await tester.pumpWidget(wrapListas(curated: curated, filters: filters));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'japon');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Japoneses en Tenerife'), findsOneWidget);
    expect(find.text('Mejores Bocadillos Cochino'), findsNothing);
    expect(byIdentifier('listas-para-ahora'), findsNothing);
    expect(find.text('Más listas'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(byIdentifier('listas-search-empty'), findsOneWidget);
    expect(find.text('Sin resultados'), findsOneWidget);

    await tester.tap(byIdentifier('listas-search-clear'));
    await tester.pumpAndSettle();
    expect(byIdentifier('listas-para-ahora'), findsOneWidget);
  });

  testWidgets('cargando: esqueleto de las guías', (tester) async {
    curated.set(CuratedListsLoading());
    await tester.pumpWidget(wrapListas(curated: curated, filters: filters));
    await tester.pump(const Duration(seconds: 1));
    expect(byIdentifier('listas-guides-loading'), findsOneWidget);
  });

  testWidgets('error: tarjeta de sección y «Reintentar» con la isla',
      (tester) async {
    curated.set(CuratedListsFailure('boom'));
    await tester.pumpWidget(wrapListas(
        curated: curated, filters: filters, theme: appLightTheme));
    await tester.pumpAndSettle();

    expect(find.text('No pudimos cargar las guías'), findsOneWidget);
    await tester.tap(byIdentifier('listas-guides-retry'));
    await tester.pump();
    expect(curated.loadCount, 1);
    expect(curated.lastIsland, filters.state.islandId);
  });

  testWidgets('sin la bandera de guías, la sección no sale', (tester) async {
    DccRemoteConfig.testOverride =
        DccRemoteConfig.test(RemoteConfigAllOn(curated: false));
    await tester.pumpWidget(wrapListas(curated: curated, filters: filters));
    await tester.pumpAndSettle();
    expect(find.text('Guías de Jonay y Joana'), findsNothing);
    expect(byIdentifier('listas-para-ahora'), findsOneWidget);
  });

  testWidgets('guardados: vacío', (tester) async {
    await tester.pumpWidget(wrapListas(curated: curated, filters: filters));
    await tester.pumpAndSettle();
    await scrollTo(tester, byIdentifier('listas-saved-empty'));
    expect(find.text('Aún no has guardado nada'), findsOneWidget);
  });

  testWidgets('guardados: con sitios', (tester) async {
    final favs = GmFavorites.withRepository(MemFavRepo({'a', 'b'}));
    await favs.ensureLoaded();
    await tester.pumpWidget(
        wrapListas(curated: curated, filters: filters, favorites: favs));
    await tester.pumpAndSettle();
    await scrollTo(tester, byIdentifier('listas-saved-card'));
    expect(find.text('2 sitios guardados'), findsOneWidget);
    expect(find.text('En lista o en el mapa'), findsOneWidget);
  });
}
