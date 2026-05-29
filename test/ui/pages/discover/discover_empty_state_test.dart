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
  final r = Restaurant(id: 'r-tf', nombre: 'Rest TF');
  r.island = islandName;
  return r;
}

Visit _visitTf(String id) {
  final v = Visit(id: id, restaurantId: 'r-tf', name: 'Visita $id');
  v.restaurant = _restaurant('Tenerife');
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

  // 3 visitas, todas en Tenerife
  final tenerifVisits = [
    _visitTf('v1'),
    _visitTf('v2'),
    _visitTf('v3'),
  ];

  setUp(() {
    filtersCubit = NewHomeFiltersCubit();
    visitsCubit = _StubVisitsCubit(tenerifVisits);
  });

  tearDown(() {
    filtersCubit.close();
    visitsCubit.close();
  });

  testWidgets(
    '(a) con 3 visitas en Tenerife y cubit en La Gomera → empty state con CTA',
    (tester) async {
      filtersCubit.selectIsland(id: _kGoId, key: 'GO', label: 'La Gomera');
      await tester.pumpWidget(_wrap(
        filtersCubit: filtersCubit,
        visitsCubit: visitsCubit,
      ));
      await tester.pumpAndSettle();

      // El empty state de isla debe aparecer
      expect(
        _byIdentifier('discover-show-all-islands-button'),
        findsOneWidget,
      );
      // Las visitas NO deben aparecer
      expect(find.textContaining('VISITA V'), findsNothing);
    },
  );

  testWidgets(
    '(b) tap en discover-show-all-islands-button muestra todas las visitas',
    (tester) async {
      filtersCubit.selectIsland(id: _kGoId, key: 'GO', label: 'La Gomera');
      await tester.pumpWidget(_wrap(
        filtersCubit: filtersCubit,
        visitsCubit: visitsCubit,
      ));
      await tester.pumpAndSettle();

      // Confirmar que CTA está presente
      final cta = _byIdentifier('discover-show-all-islands-button');
      expect(cta, findsOneWidget);

      // Tap en el CTA
      await tester.tap(cta);
      await tester.pumpAndSettle();

      // Ahora el CTA desaparece y las visitas aparecen
      expect(_byIdentifier('discover-show-all-islands-button'), findsNothing);
      // Las 3 visitas deben estar en el árbol
      expect(find.textContaining('VISITA V'), findsWidgets);
    },
  );

  testWidgets(
    '(c) con cubit en TF (isla con visitas) no aparece el empty state de isla',
    (tester) async {
      filtersCubit.selectIsland(id: _kTfId, key: 'TF', label: 'Tenerife');
      await tester.pumpWidget(_wrap(
        filtersCubit: filtersCubit,
        visitsCubit: visitsCubit,
      ));
      await tester.pumpAndSettle();

      expect(_byIdentifier('discover-show-all-islands-button'), findsNothing);
      // Las 3 visitas de Tenerife son visibles
      expect(find.textContaining('VISITA V'), findsWidgets);
    },
  );
}
