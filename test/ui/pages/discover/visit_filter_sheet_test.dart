import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/advance_search/list_theme.dart';
import 'package:guachinches/ui/pages/discover/visit_sentiment.dart';
import 'package:guachinches/ui/pages/discover/widgets/sort_sheet.dart';
import 'package:guachinches/ui/pages/discover/widgets/visit_filter_sheet.dart';
import 'package:guachinches/utils/contextual_pool.dart';

Visit _v(String id, String sentiment, String type) {
  final r = Restaurant(id: 'r-$id', nombre: 'Sitio $id');
  r.type = type;
  r.municipio = 'La Orotava';
  return Visit(id: id, restaurantId: 'r-$id', overallSentiment: sentiment)
    ..restaurant = r;
}

Finder _id(String id) => find
    .byWidgetPredicate((w) => w is Semantics && w.properties.identifier == id);

void _bigSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  final visits = [
    _v('1', 'muy_positivo', RestaurantTypeIds.guachinchesTradicionales),
    _v('2', 'muy_positivo', RestaurantTypeIds.guachinchesTradicionales),
    _v('3', 'neutro', RestaurantTypeIds.guachinchesTradicionales),
    _v('4', 'positivo', RestaurantTypeIds.bodegones),
  ];

  Future<VisitFilterValues?> Function() open(WidgetTester tester,
      {VisitFilterValues initial = const VisitFilterValues(),
      ThemeData? theme}) {
    VisitFilterValues? result;
    var done = false;
    return () async {
      _bigSurface(tester);
      await tester.pumpWidget(MaterialApp(
        theme: theme ?? appLightTheme,
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () async {
                result = await VisitFilterSheet.show(
                    context: ctx, initial: initial, visits: visits);
                done = true;
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      return done ? result : null;
    };
  }

  testWidgets('recuentos en vivo y «Mostrar N visitas»', (tester) async {
    await open(tester)();
    expect(find.text('Filtrar visitas'), findsOneWidget);
    expect(find.text('Mostrar 4 visitas'), findsOneWidget);

    await tester.tap(_id('discover-filter-mood-loved'));
    await tester.pumpAndSettle();
    expect(find.text('Filtrar visitas · 1'), findsOneWidget);
    expect(find.text('Mostrar 2 visitas'), findsOneWidget);
    expect(find.text('Solo visitas con vídeo'), findsNothing);
  });

  testWidgets('sin resultados: dice qué filtro quitar', (tester) async {
    await open(tester,
        theme: appDarkTheme,
        initial: const VisitFilterValues(
            moods: {VisitMood.regular}, types: {ListThemeKind.bodegon}))();

    expect(find.text('Ninguna visita con estos filtros'), findsOneWidget);
    expect(_id('discover-filter-empty-hint'), findsOneWidget);

    await tester.tap(_id('discover-filter-empty-hint-remove'));
    await tester.pumpAndSettle();
    expect(_id('discover-filter-empty-hint'), findsNothing);
  });

  testWidgets('menú de orden sin ubicación no ofrece «Más cerca de ti»',
      (tester) async {
    VisitSort? picked;
    await tester.pumpWidget(MaterialApp(
      theme: appLightTheme,
      home: Scaffold(
        body: Center(
          child: Builder(
            builder: (ctx) => TextButton(
              onPressed: () async {
                picked = await showVisitSortMenu(ctx,
                    anchor: const Rect.fromLTWH(200, 100, 160, 44),
                    current: VisitSort.newest,
                    hasLocation: false);
              },
              child: const Text('ordenar'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('ordenar'));
    await tester.pumpAndSettle();

    expect(_id('discover-sort-menu'), findsOneWidget);
    expect(find.text('Más cerca de ti'), findsNothing);
    expect(find.text('Por autor'), findsNothing);
    await tester.tap(_id('discover-sort-name'));
    await tester.pumpAndSettle();
    expect(picked, VisitSort.alphaAsc);
  });
}
