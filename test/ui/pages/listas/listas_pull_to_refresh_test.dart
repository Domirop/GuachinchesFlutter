import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/core/remote_config/dcc_remote_config.dart';
import 'package:guachinches/data/cubit/new_home/curated_lists_cubit.dart';
import 'package:guachinches/data/cubit/new_home/new_home_filters_cubit.dart';

import 'listas_test_harness.dart';

void main() {
  group('listas pull-to-refresh', () {
    late NewHomeFiltersCubit filters;
    late StubCuratedListsCubit cubit;

    setUp(() {
      DccRemoteConfig.testOverride = DccRemoteConfig.test(RemoteConfigAllOn());
      filters = NewHomeFiltersCubit();
      cubit = StubCuratedListsCubit(CuratedListsLoaded([
        guide(id: '1', title: 'Lista 1'),
        guide(id: '2', title: 'Lista 2'),
      ]));
      cubit.loadingWasEmitted = false;
    });

    tearDown(() {
      DccRemoteConfig.testOverride = null;
      filters.close();
      cubit.close();
    });

    testWidgets(
      '(a) listas-refresh-indicator Semantics anchor is present in the tree',
      (tester) async {
        await tester.pumpWidget(wrapListas(curated: cubit, filters: filters));
        await tester.pump();

        expect(byIdentifier('listas-refresh-indicator'), findsOneWidget);
      },
    );

    testWidgets(
      '(b) dragging down calls CuratedListsCubit.refresh() with the island',
      (tester) async {
        await tester.pumpWidget(wrapListas(curated: cubit, filters: filters));
        await tester.pump();

        await tester.drag(
          find.byType(CustomScrollView),
          const Offset(0, 400),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        expect(cubit.refreshCount, greaterThanOrEqualTo(1));
        expect(cubit.lastIsland, filters.state.islandId);
      },
    );

    testWidgets(
      '(c) CuratedListsLoading is NOT emitted while pull-to-refresh runs',
      (tester) async {
        await tester.pumpWidget(wrapListas(curated: cubit, filters: filters));
        await tester.pump();

        await tester.drag(
          find.byType(CustomScrollView),
          const Offset(0, 400),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        expect(cubit.loadingWasEmitted, isFalse);
      },
    );
  });
}
