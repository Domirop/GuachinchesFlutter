import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/new_home/new_home_filters_cubit.dart';
import 'package:guachinches/data/model/Municipality.dart';
import 'package:guachinches/data/model/SimpleMunicipality.dart';
import 'package:guachinches/data/model/TopRestaurants.dart';
import 'package:guachinches/ui/pages/new_home/top_rated_logic.dart';
import 'package:guachinches/ui/pages/new_home/top_rated_ranking_screen.dart';

TopRestaurants top(String id, double avg, int n,
        {String muni = 'La Orotava'}) =>
    TopRestaurants(
      id: id,
      nombre: 'Sitio $id',
      avg: avg,
      counter: (avg * n).toString(),
      municipio: muni,
    );

class _Repo extends Fake implements RemoteRepository {
  List<TopRestaurants> top;
  Object? error;
  int topCalls = 0;
  final List<String> areaCalls = [];
  List<Municipality> areas;

  _Repo({this.top = const [], this.error, this.areas = const []});

  @override
  Future<List<TopRestaurants>> getTopRestaurants() async {
    topCalls++;
    final e = error;
    if (e != null) throw e;
    return top;
  }

  @override
  Future<List<Municipality>> getAllMunicipalitiesFiltered(
      String islandId) async {
    areaCalls.add(islandId);
    return areas;
  }
}

Finder _byId(String id) => find
    .byWidgetPredicate((w) => w is Semantics && w.properties.identifier == id);

final _island = [
  top('E', 3.455, 11),
  top('A', 5.0, 18, muni: 'Arico'),
  top('h', 4.0, 9),
  top('C', 4.815, 46, muni: 'LA MATANZA'),
  top('g', 5.0, 3),
  top('B', 4.847, 36, muni: 'San Cristóbal de La Laguna'),
  top('i', 5.0, 1),
  top('D', 5.0, 14),
  top('f', 5.0, 7),
  top('j', 4.6, 5),
];

void main() {
  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize =
        const Size(402 * 3, 2600 * 3);
    binding.platformDispatcher.views.first.devicePixelRatio = 3;
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  Widget app(Widget child,
      {NewHomeFiltersCubit? filters, ThemeMode mode = ThemeMode.light}) {
    final m = MaterialApp(
      theme: appLightTheme,
      darkTheme: appDarkTheme,
      themeMode: mode,
      home: child,
    );
    return filters == null ? m : BlocProvider.value(value: filters, child: m);
  }

  List<String> rowIdsIn(WidgetTester tester, String listId) => tester
      .widgetList<Semantics>(find.descendant(
          of: _byId(listId),
          matching: find.byWidgetPredicate((w) =>
              w is Semantics &&
              (w.properties.identifier ?? '').startsWith('top-rated-row-'))))
      .map((s) => s.properties.identifier!.substring('top-rated-row-'.length))
      .toList();

  testWidgets('list: medals for 1–3, «Nº» after, few places apart',
      (tester) async {
    final repo = _Repo();
    await tester.pumpWidget(app(TopRatedRankingScreen(
      restaurants: _island,
      islandLabel: 'Tenerife',
      repository: repo,
    )));
    await tester.pumpAndSettle();

    expect(repo.topCalls, 0);
    expect(find.text(kTopRatedTitle), findsOneWidget);
    expect(find.text(kTopRatedSubtitle), findsOneWidget);
    expect(find.text(kTopRatedCaption), findsOneWidget);
    expect(_byId('top-rated-back-button'), findsOneWidget);
    expect(
        find.descendant(
            of: _byId('top-rated-island-pill'),
            matching: find.text('Tenerife')),
        findsOneWidget);

    expect(rowIdsIn(tester, 'top-rated-list'), ['A', 'B', 'C', 'D', 'E']);
    expect(find.text('Nº'), findsNWidgets(2));
    expect(find.text('18 reseñas'), findsOneWidget);
    expect(find.text('Arico'), findsOneWidget);
    expect(find.text('La Matanza'), findsOneWidget);

    // Pocas reseñas: 3 y el botón para ver los 5.
    expect(find.text(kTopRatedFewTitle), findsOneWidget);
    expect(rowIdsIn(tester, 'top-rated-few-list'), ['f', 'g', 'j']);
    expect(find.text('Ver los 5 con pocas reseñas'), findsOneWidget);
    await tester.tap(_byId('top-rated-few-more'));
    await tester.pumpAndSettle();
    expect(rowIdsIn(tester, 'top-rated-few-list'), ['f', 'g', 'j', 'i', 'h']);
    expect(_byId('top-rated-few-more'), findsNothing);
    expect(find.text(kTopRatedFooter), findsOneWidget);

    final sem = tester.widget<Semantics>(_byId('top-rated-row-A'));
    expect(sem.properties.label, startsWith('Número 1, '));
    expect(
        sem.properties.label, endsWith(', Arico, 5,0 estrellas, 18 reseñas'));
  });

  testWidgets('already filtered list (≥ 10): no few section', (tester) async {
    await tester.pumpWidget(app(TopRatedRankingScreen(
      restaurants: _island.where((t) => t.id.toUpperCase() == t.id).toList(),
      islandLabel: 'Tenerife',
      repository: _Repo(),
    )));
    await tester.pumpAndSettle();
    expect(rowIdsIn(tester, 'top-rated-list'), hasLength(5));
    expect(find.text(kTopRatedFewTitle), findsNothing);
  });

  testWidgets('empty list passed: loads the island from the global ranking',
      (tester) async {
    final repo = _Repo(top: [
      ..._island,
      top('GC1', 5, 30, muni: 'Telde'),
      top('X', 5, 12, muni: 'LOS CRISTIANOS'),
    ], areas: [
      Municipality(id: 'a', nombre: 'Sur', municipalities: [
        SimpleMunicipality(id: 'm', nombre: 'LOS CRISTIANOS'),
      ]),
    ]);
    final filters = NewHomeFiltersCubit();
    addTearDown(filters.close);
    await tester.pumpWidget(app(
      TopRatedRankingScreen(
        restaurants: const [],
        islandLabel: 'Tenerife',
        repository: repo,
      ),
      filters: filters,
      mode: ThemeMode.dark,
    ));
    expect(_byId('top-rated-loading'), findsOneWidget);
    await tester.pumpAndSettle();

    expect(repo.topCalls, 1);
    expect(repo.areaCalls, [filters.state.islandId]);
    final ids = rowIdsIn(tester, 'top-rated-list');
    expect(ids, contains('X'));
    expect(ids, isNot(contains('GC1')));
  });

  testWidgets('empty: nobody reaches 10 reviews on the island', (tester) async {
    final filters = NewHomeFiltersCubit();
    addTearDown(filters.close);
    final repo = _Repo(top: [
      ..._island,
      top('GC1', 5, 4, muni: 'Telde'),
    ]);
    await tester.pumpWidget(app(
      TopRatedRankingScreen(
        restaurants: const [],
        islandLabel: 'Gran Canaria',
        islandId: 'gc-id',
        islandKey: 'GC',
        repository: repo,
      ),
      filters: filters,
    ));
    await tester.pumpAndSettle();

    expect(_byId('top-rated-empty'), findsOneWidget);
    expect(find.text(topRatedEmptyTitle('Gran Canaria')), findsOneWidget);
    expect(find.text(topRatedEmptyText('Gran Canaria')), findsOneWidget);
    // Sin cambio de isla en la píldora no hay «Ver el ranking de…».
    expect(_byId('top-rated-empty-back'), findsNothing);

    await tester.tap(_byId('top-rated-empty-see-island'));
    await tester.pumpAndSettle();
    expect(filters.state.islandId, 'gc-id');
    expect(filters.state.islandKey, 'GC');
    expect(filters.state.islandLabel, 'Gran Canaria');
  });

  testWidgets('error: retry loads again', (tester) async {
    final repo = _Repo(top: _island, error: Exception('offline'));
    await tester.pumpWidget(app(TopRatedRankingScreen(
      restaurants: const [],
      islandLabel: 'Tenerife',
      repository: repo,
    )));
    await tester.pumpAndSettle();

    expect(_byId('top-rated-error'), findsOneWidget);
    expect(find.text(kTopRatedErrorTitle), findsOneWidget);
    expect(find.text(kTopRatedErrorText), findsOneWidget);

    repo.error = null;
    await tester.tap(_byId('top-rated-retry'));
    await tester.pumpAndSettle();
    expect(repo.topCalls, 2);
    expect(_byId('top-rated-error'), findsNothing);
    expect(rowIdsIn(tester, 'top-rated-list'), ['A', 'B', 'C', 'D', 'E']);
  });

  testWidgets('an empty global ranking is an error, not «nobody»',
      (tester) async {
    await tester.pumpWidget(app(TopRatedRankingScreen(
      restaurants: const [],
      islandLabel: 'Tenerife',
      repository: _Repo(),
    )));
    await tester.pumpAndSettle();
    expect(_byId('top-rated-error'), findsOneWidget);
    expect(_byId('top-rated-empty'), findsNothing);
  });
}
