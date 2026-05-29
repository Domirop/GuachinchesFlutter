import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/new_home/new_home_filters_cubit.dart';
import 'package:guachinches/data/cubit/new_home/visits_cubit.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/discover/discover_screen.dart';

// ── IDs de prueba ──────────────────────────────────────────────────────────────
const _kTfId = '76ac0bec-4bc1-41a5-bc60-e528e0c12f4d';
const _kGcId = 'gc-island-test-id-001';
const _kGoId = 'go-island-test-id-001';

// ── Fakes ──────────────────────────────────────────────────────────────────────

class _FakeRepo extends Fake implements RemoteRepository {}

class _StubVisitsCubit extends VisitsCubit {
  _StubVisitsCubit(List<Visit> visits) : super(_FakeRepo()) {
    emit(VisitsLoaded(visits));
  }

  @override
  Future<void> loadVisits() async {}
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Restaurant _restaurant(String islandName) {
  final r = Restaurant(id: 'r-$islandName', nombre: 'Restaurante $islandName');
  r.island = islandName;
  return r;
}

Visit _visit({required String id, required String name, required String island}) {
  final v = Visit(id: id, restaurantId: 'r-$island', name: name);
  v.restaurant = _restaurant(island);
  return v;
}

Widget _wrap({
  required NewHomeFiltersCubit filtersCubit,
  required _StubVisitsCubit visitsCubit,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<NewHomeFiltersCubit>.value(value: filtersCubit),
      BlocProvider<VisitsCubit>.value(value: visitsCubit),
    ],
    child: MaterialApp(
      theme: appDarkTheme,
      home: const DiscoverScreen(),
    ),
  );
}

Finder _byIdentifier(String id) => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.identifier == id,
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late NewHomeFiltersCubit filtersCubit;
  late _StubVisitsCubit visitsCubit;

  final threeVisits = [
    _visit(id: 'v-tf', name: 'Visita Tenerife', island: 'Tenerife'),
    _visit(id: 'v-gc', name: 'Visita GranCanaria', island: 'Gran Canaria'),
    _visit(id: 'v-go', name: 'Visita Gomera', island: 'La Gomera'),
  ];

  setUp(() {
    filtersCubit = NewHomeFiltersCubit();
    visitsCubit = _StubVisitsCubit(threeVisits);
  });

  tearDown(() {
    filtersCubit.close();
    visitsCubit.close();
  });

  testWidgets(
    '(a) con TF activo se muestra solo la visita de Tenerife',
    (tester) async {
      filtersCubit.selectIsland(id: _kTfId, key: 'TF', label: 'Tenerife');
      await tester.pumpWidget(_wrap(
        filtersCubit: filtersCubit,
        visitsCubit: visitsCubit,
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('VISITA TENERIFE'), findsOneWidget);
      expect(find.textContaining('VISITA GRANCANARIA'), findsNothing);
      expect(find.textContaining('VISITA GOMERA'), findsNothing);
    },
  );

  testWidgets(
    '(b) al cambiar a GC se muestra solo la visita de Gran Canaria',
    (tester) async {
      filtersCubit.selectIsland(id: _kTfId, key: 'TF', label: 'Tenerife');
      await tester.pumpWidget(_wrap(
        filtersCubit: filtersCubit,
        visitsCubit: visitsCubit,
      ));
      await tester.pumpAndSettle();

      filtersCubit.selectIsland(
          id: _kGcId, key: 'GC', label: 'Gran Canaria');
      await tester.pumpAndSettle();

      expect(find.textContaining('VISITA GRANCANARIA'), findsOneWidget);
      expect(find.textContaining('VISITA TENERIFE'), findsNothing);
      expect(find.textContaining('VISITA GOMERA'), findsNothing);
    },
  );

  testWidgets(
    '(c) al cambiar a GO se muestra solo la visita de La Gomera',
    (tester) async {
      filtersCubit.selectIsland(id: _kGoId, key: 'GO', label: 'La Gomera');
      await tester.pumpWidget(_wrap(
        filtersCubit: filtersCubit,
        visitsCubit: visitsCubit,
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('VISITA GOMERA'), findsOneWidget);
      expect(find.textContaining('VISITA TENERIFE'), findsNothing);
      expect(find.textContaining('VISITA GRANCANARIA'), findsNothing);
    },
  );

  testWidgets(
    '(d) discover-active-island-label muestra el label de la isla activa',
    (tester) async {
      filtersCubit.selectIsland(id: _kTfId, key: 'TF', label: 'Tenerife');
      await tester.pumpWidget(_wrap(
        filtersCubit: filtersCubit,
        visitsCubit: visitsCubit,
      ));
      await tester.pumpAndSettle();

      expect(_byIdentifier('discover-active-island-label'), findsOneWidget);
      expect(find.text('TENERIFE'), findsWidgets);

      filtersCubit.selectIsland(
          id: _kGcId, key: 'GC', label: 'Gran Canaria');
      await tester.pumpAndSettle();

      expect(find.text('GRAN CANARIA'), findsWidgets);
    },
  );
}
