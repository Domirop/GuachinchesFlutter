import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/core/remote_config/dcc_remote_config.dart';
import 'package:guachinches/data/cubit/new_home/curated_lists_cubit.dart';
import 'package:guachinches/data/cubit/new_home/new_home_filters_cubit.dart';

import 'listas_test_harness.dart';

// La pestaña Listas sigue a la isla global (`NewHomeFiltersCubit`): filtra
// en el cliente las guías del cubit compartido con el Inicio y pinta la isla
// en el antetítulo. Ya no tiene chips de isla propios (tablero TabListas).

void main() {
  late NewHomeFiltersCubit filtersCubit;
  late StubCuratedListsCubit curatedCubit;

  setUp(() {
    DccRemoteConfig.testOverride = DccRemoteConfig.test(RemoteConfigAllOn());
    filtersCubit = NewHomeFiltersCubit();
    filtersCubit.selectIsland(id: kTfId, key: 'TF', label: 'Tenerife');
    curatedCubit = StubCuratedListsCubit(CuratedListsLoaded([
      guide(id: 'global', title: 'Lista Global', position: 1),
      guide(id: 'tf', title: 'Lista TF', islandId: kTfId, position: 2),
      guide(id: 'gc', title: 'Lista GC', islandId: kGcId, position: 3),
    ]));
  });

  tearDown(() {
    DccRemoteConfig.testOverride = null;
    filtersCubit.close();
    curatedCubit.close();
  });

  testWidgets('(a) con isla TF activa se ven listas global y TF, no la de GC',
      (tester) async {
    await tester.pumpWidget(
        wrapListas(curated: curatedCubit, filters: filtersCubit));
    await tester.pumpAndSettle();

    expect(find.text('Lista Global'), findsOneWidget);
    expect(find.text('Lista TF'), findsOneWidget);
    expect(find.text('Lista GC'), findsNothing);
  });

  testWidgets(
      '(b) al cambiar la isla a GC, TF desaparece y GC aparece sin reabrir',
      (tester) async {
    await tester.pumpWidget(
        wrapListas(curated: curatedCubit, filters: filtersCubit));
    await tester.pumpAndSettle();
    expect(find.text('Lista TF'), findsOneWidget);
    expect(find.text('Lista GC'), findsNothing);

    filtersCubit.selectIsland(id: kGcId, key: 'GC', label: 'Gran Canaria');
    await tester.pumpAndSettle();

    expect(find.text('Lista TF'), findsNothing);
    expect(find.text('Lista GC'), findsOneWidget);
    expect(find.text('Lista Global'), findsOneWidget);
  });

  testWidgets('(c) la isla global sale en el antetítulo y en «Mejor valorados»',
      (tester) async {
    await tester.pumpWidget(
        wrapListas(curated: curatedCubit, filters: filtersCubit));
    await tester.pumpAndSettle();
    expect(find.text('Tenerife'), findsOneWidget);

    filtersCubit.selectIsland(id: kGcId, key: 'GC', label: 'Gran Canaria');
    await tester.pumpAndSettle();
    expect(find.text('Gran Canaria'), findsOneWidget);
    await tester.scrollUntilVisible(
        find.text('Mejor valorados de Gran Canaria'), 300,
        scrollable: find
            .descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(Scrollable))
            .first);
    expect(find.text('Mejor valorados de Gran Canaria'), findsOneWidget);
  });

  testWidgets('(d) no vuelve a pedir las guías si el Inicio ya las cargó',
      (tester) async {
    await tester.pumpWidget(
        wrapListas(curated: curatedCubit, filters: filtersCubit));
    await tester.pumpAndSettle();
    expect(curatedCubit.loadCount, 0);
  });

  testWidgets('(e) si nadie las ha pedido, las pide con la isla global',
      (tester) async {
    final fresh = StubCuratedListsCubit(CuratedListsInitial());
    await tester.pumpWidget(wrapListas(curated: fresh, filters: filtersCubit));
    await tester.pump();
    expect(fresh.loadCount, 1);
    expect(fresh.lastIsland, kTfId);
    await fresh.close();
  });
}
