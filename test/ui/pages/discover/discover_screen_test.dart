import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/new_home/islands_cubit.dart';
import 'package:guachinches/data/cubit/new_home/new_home_filters_cubit.dart';
import 'package:guachinches/data/cubit/new_home/visits_cubit.dart';
import 'package:guachinches/data/model/Island.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/discover/discover_screen.dart';

// ── IDs de prueba ──────────────────────────────────────────────────────────
const _kTfId = '76ac0bec-4bc1-41a5-bc60-e528e0c12f4d';
const _kGcId = 'gc-island-test-id-001';
const _kGoId = 'go-island-test-id-001';

// ── Fakes ──────────────────────────────────────────────────────────────────

class _FakeRepo extends Fake implements RemoteRepository {}

class _StubVisitsCubit extends VisitsCubit {
  int loads = 0;
  _StubVisitsCubit(VisitsState initial) : super(_FakeRepo()) {
    emit(initial);
  }

  @override
  Future<void> loadVisits() async => loads++;
}

class _StubIslandsCubit extends IslandsCubit {
  _StubIslandsCubit() : super(_FakeRepo()) {
    emit(IslandsLoaded([
      Island(_kTfId, '', 'Tenerife', key: 'TF'),
      Island(_kGcId, '', 'Gran Canaria', key: 'GC'),
      Island(_kGoId, '', 'La Gomera', key: 'GO'),
    ]));
  }

  @override
  Future<void> load() async {}
}

// ── Helpers ────────────────────────────────────────────────────────────────

Visit _visit(
  String id, {
  required String name,
  required String islandId,
  String date = '2026-10-08T10:00:00Z',
  List<String> dishes = const [],
}) {
  final r = Restaurant(id: 'r-$id', nombre: name);
  r.municipioIslandId = islandId;
  r.municipio = 'La Victoria de Acentejo';
  return Visit(
    id: id,
    restaurantId: 'r-$id',
    videoPublishedAt: date,
    dishes: [for (final d in dishes) VisitDish(name: d)],
  )..restaurant = r;
}

final _visits = [
  _visit('tf1', name: 'Casa Tenerife', islandId: _kTfId, dishes: ['Cabra']),
  _visit('tf2',
      name: 'Bodegón Tinerfeño',
      islandId: _kTfId,
      date: '2026-09-20T10:00:00Z'),
  _visit('gc1', name: 'Casa Canaria', islandId: _kGcId, dishes: ['Pulpo']),
];

Finder _byId(String id) => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.identifier == id,
    );

Future<void> _pump(
  WidgetTester tester, {
  required NewHomeFiltersCubit filters,
  required _StubVisitsCubit visits,
  ThemeData? theme,
}) async {
  tester.view.physicalSize = const Size(402 * 3, 2400 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MultiBlocProvider(
    providers: [
      BlocProvider<NewHomeFiltersCubit>.value(value: filters),
      BlocProvider<VisitsCubit>.value(value: visits),
      BlocProvider<IslandsCubit>(create: (_) => _StubIslandsCubit()),
    ],
    child: MaterialApp(theme: theme ?? appDarkTheme, home: const DiscoverScreen()),
  ));
  await tester.pumpAndSettle();
}

void main() {
  late NewHomeFiltersCubit filters;

  setUp(() => filters = NewHomeFiltersCubit());
  tearDown(() => filters.close());

  testWidgets('muestra solo las visitas de la isla elegida y cambia con ella',
      (tester) async {
    final visits = _StubVisitsCubit(VisitsLoaded(_visits));
    await _pump(tester, filters: filters, visits: visits);

    expect(_byId('discover-visit-card-tf1'), findsOneWidget);
    expect(_byId('discover-visit-card-tf2'), findsOneWidget);
    expect(_byId('discover-visit-card-gc1'), findsNothing);
    expect(find.text('2 vídeos en 2 sitios de Tenerife'), findsOneWidget);
    expect(_byId('discover-active-island-label'), findsOneWidget);

    filters.selectIsland(id: _kGcId, key: 'GC', label: 'Gran Canaria');
    await tester.pumpAndSettle();

    expect(_byId('discover-visit-card-gc1'), findsOneWidget);
    expect(_byId('discover-visit-card-tf1'), findsNothing);
    expect(find.text('1 vídeo en 1 sitio de Gran Canaria'), findsOneWidget);
    await visits.close();
  });

  testWidgets('chips: una por isla con visitas; tocar cambia la isla global',
      (tester) async {
    final visits = _StubVisitsCubit(VisitsLoaded(_visits));
    await _pump(tester, filters: filters, visits: visits);

    expect(_byId('discover-island-chip-tf'), findsOneWidget);
    expect(_byId('discover-island-chip-gc'), findsOneWidget);
    // La Gomera no tiene visitas y no es la elegida.
    expect(_byId('discover-island-chip-go'), findsNothing);

    await tester.tap(_byId('discover-island-chip-gc'));
    await tester.pumpAndSettle();
    expect(filters.state.islandKey, 'GC');
    expect(filters.state.islandId, _kGcId);
    await visits.close();
  });

  testWidgets('secciones del tablero sin búsqueda', (tester) async {
    final visits = _StubVisitsCubit(VisitsLoaded(_visits));
    await _pump(tester, filters: filters, visits: visits, theme: appLightTheme);

    expect(find.text('Lo último'), findsOneWidget);
    expect(find.text('1 visita en octubre'), findsOneWidget);
    expect(_byId('discover-latest-cover-0'), findsOneWidget);
    expect(find.text('Lo que más piden'), findsOneWidget);
    expect(_byId('discover-dish-tile-cabra'), findsOneWidget);
    // Sin platos de cochino en la isla → la tarjeta no sale.
    expect(_byId('discover-dish-tile-cochino'), findsNothing);
    expect(find.text('Todas las visitas'), findsOneWidget);
    expect(find.text('Octubre de 2026 · 1 visita'), findsOneWidget);
    expect(find.text('Septiembre de 2026 · 1 visita'), findsOneWidget);
    expect(find.text('La Victoria'), findsWidgets);
    await visits.close();
  });

  testWidgets('tocar una tarjeta de plato busca ese plato', (tester) async {
    final visits = _StubVisitsCubit(VisitsLoaded(_visits));
    await _pump(tester, filters: filters, visits: visits);

    await tester.tap(_byId('discover-dish-tile-cabra'));
    await tester.pumpAndSettle();

    expect(find.text('1 resultado'), findsOneWidget);
    expect(find.text('Lo último'), findsNothing);
    expect(_byId('discover-visit-card-tf1'), findsOneWidget);
    expect(_byId('discover-visit-card-tf2'), findsNothing);
    await visits.close();
  });

  testWidgets('búsqueda sin resultados sugiere la isla que sí tiene',
      (tester) async {
    final visits = _StubVisitsCubit(VisitsLoaded(_visits));
    await _pump(tester, filters: filters, visits: visits);

    await tester.enterText(find.byType(TextField), 'pulpo');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(_byId('discover-empty'), findsOneWidget);
    expect(find.text('Ninguna visita con «pulpo» en Tenerife'), findsOneWidget);
    expect(find.text('En Gran Canaria hay 1 visita con «pulpo».'),
        findsOneWidget);

    await tester.tap(_byId('discover-empty-switch-island-button'));
    await tester.pumpAndSettle();
    expect(filters.state.islandKey, 'GC');
    expect(_byId('discover-visit-card-gc1'), findsOneWidget);
    await visits.close();
  });

  testWidgets('isla sin visitas: aviso y botón a la isla con más',
      (tester) async {
    filters.selectIsland(id: _kGoId, key: 'GO', label: 'La Gomera');
    final visits = _StubVisitsCubit(VisitsLoaded(_visits));
    await _pump(tester, filters: filters, visits: visits);

    expect(_byId('discover-island-empty'), findsOneWidget);
    expect(find.text('Todavía no hay visitas en La Gomera'), findsOneWidget);
    // La Gomera se ve como chip elegido aunque no tenga visitas.
    expect(_byId('discover-island-chip-go'), findsOneWidget);

    await tester.tap(_byId('discover-island-empty-switch-button'));
    await tester.pumpAndSettle();
    expect(filters.state.islandKey, 'TF');
    expect(_byId('discover-visit-card-tf1'), findsOneWidget);
    await visits.close();
  });

  testWidgets('error: volcán triste y Reintentar recarga', (tester) async {
    final visits = _StubVisitsCubit(VisitsFailure());
    await _pump(tester, filters: filters, visits: visits);
    final before = visits.loads;

    expect(_byId('discover-error'), findsOneWidget);
    expect(find.text('No pudimos cargar las visitas'), findsOneWidget);
    await tester.tap(_byId('discover-retry-button'));
    await tester.pump();
    expect(visits.loads, before + 1);
    await visits.close();
  });

  testWidgets('cargando: esqueleto con la forma real', (tester) async {
    final visits = _StubVisitsCubit(VisitsLoading());
    await _pump(tester, filters: filters, visits: visits);

    expect(_byId('discover-skeleton'), findsOneWidget);
    expect(_byId('discover-back-button'), findsNothing);
    await visits.close();
  });
}
