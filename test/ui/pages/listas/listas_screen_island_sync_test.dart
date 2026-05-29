import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/core/remote_config/dcc_remote_config.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/new_home/curated_lists_cubit.dart';
import 'package:guachinches/data/cubit/new_home/islands_cubit.dart';
import 'package:guachinches/data/cubit/new_home/new_home_filters_cubit.dart';
import 'package:guachinches/data/model/Island.dart';
import 'package:guachinches/data/model/curated_list.dart';
import 'package:guachinches/l10n/app_localizations.dart';
import 'package:guachinches/ui/pages/listas/listas_screen.dart';

// ── IDs de prueba ──────────────────────────────────────────────────────────────
const _kTfId = '76ac0bec-4bc1-41a5-bc60-e528e0c12f4d';
const _kGcId = 'gc-island-test-id-001';

// ── Fakes ──────────────────────────────────────────────────────────────────────

class _FakeRepo extends Fake implements RemoteRepository {}

class _FakeRcBridge implements RemoteConfigBridge {
  @override
  Future<void> configure(
          {required Duration fetchTimeout,
          required Duration minimumFetchInterval}) async {}
  @override
  Future<void> setDefaults(Map<String, dynamic> defaults) async {}
  @override
  Future<bool> fetchAndActivate() async => true;
  @override
  bool getBool(String key) => true;
  @override
  int getInt(String key) => 1;
}

class _StubCuratedListsCubit extends CuratedListsCubit {
  _StubCuratedListsCubit(List<CuratedList> lists) : super(_FakeRepo()) {
    emit(CuratedListsLoaded(lists));
  }

  @override
  Future<void> loadForIsland(String? islandId) async {}

  @override
  Future<void> refresh(String? islandId) async {}
}

class _StubIslandsCubit extends IslandsCubit {
  _StubIslandsCubit(List<Island> islands) : super(_FakeRepo()) {
    emit(IslandsLoaded(islands));
  }

  @override
  Future<void> load() async {}
}

// ── Helpers ───────────────────────────────────────────────────────────────────

CuratedList _list({
  required String id,
  required String title,
  String? islandId,
  int position = 1,
}) =>
    CuratedList(
      id: id,
      title: title,
      subtitle: '',
      eyebrow: 'Jonay',
      position: position,
      count: 5,
      enabled: true,
      islandId: islandId,
      location: 'Canarias',
      accent: const Color(0xFF1A6E4A),
    );

Island _island(String id, String name, String key) =>
    Island(id, '', name, key: key);

Widget _wrap({
  required _StubCuratedListsCubit curatedCubit,
  required NewHomeFiltersCubit filtersCubit,
  required _StubIslandsCubit islandsCubit,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<CuratedListsCubit>.value(value: curatedCubit),
      BlocProvider<NewHomeFiltersCubit>.value(value: filtersCubit),
      BlocProvider<IslandsCubit>.value(value: islandsCubit),
    ],
    child: MaterialApp(
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      theme: appDarkTheme,
      home: const ListasScreen(),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late NewHomeFiltersCubit filtersCubit;
  late _StubCuratedListsCubit curatedCubit;
  late _StubIslandsCubit islandsCubit;

  setUp(() {
    // Bypass Firebase for DccRemoteConfig
    DccRemoteConfig.testOverride = DccRemoteConfig.test(_FakeRcBridge());

    filtersCubit = NewHomeFiltersCubit();
    // Pre-select TF island
    filtersCubit.selectIsland(id: _kTfId, key: 'TF', label: 'Tenerife');

    // 3 lists: global, TF-specific, GC-specific
    curatedCubit = _StubCuratedListsCubit([
      _list(id: 'global', title: 'Lista Global', islandId: null, position: 1),
      _list(id: 'tf', title: 'Lista TF', islandId: _kTfId, position: 2),
      _list(id: 'gc', title: 'Lista GC', islandId: _kGcId, position: 3),
    ]);

    islandsCubit = _StubIslandsCubit([
      _island(_kTfId, 'Tenerife', 'TF'),
      _island(_kGcId, 'Gran Canaria', 'GC'),
    ]);
  });

  tearDown(() {
    DccRemoteConfig.testOverride = null;
    filtersCubit.close();
    curatedCubit.close();
    islandsCubit.close();
  });

  testWidgets(
    '(a) con isla TF activa se ven listas global y TF, no la de GC',
    (tester) async {
      await tester.pumpWidget(_wrap(
        curatedCubit: curatedCubit,
        filtersCubit: filtersCubit,
        islandsCubit: islandsCubit,
      ));
      await tester.pumpAndSettle();

      // Listas global y TF son visibles
      expect(find.textContaining('LISTA GLOBAL'), findsOneWidget);
      expect(find.textContaining('LISTA TF'), findsOneWidget);
      // Lista GC no debe aparecer
      expect(find.textContaining('LISTA GC'), findsNothing);
    },
  );

  testWidgets(
    '(b) al cambiar cubit a GC, TF desaparece y GC aparece sin reabrir pantalla',
    (tester) async {
      await tester.pumpWidget(_wrap(
        curatedCubit: curatedCubit,
        filtersCubit: filtersCubit,
        islandsCubit: islandsCubit,
      ));
      await tester.pumpAndSettle();

      // Estado inicial: TF activa
      expect(find.textContaining('LISTA TF'), findsOneWidget);
      expect(find.textContaining('LISTA GC'), findsNothing);

      // Cambiar isla a GC desde el cubit (simula cambio desde home)
      filtersCubit.selectIsland(id: _kGcId, key: 'GC', label: 'Gran Canaria');
      await tester.pumpAndSettle();

      // Ahora TF desaparece, GC aparece
      expect(find.textContaining('LISTA TF'), findsNothing);
      expect(find.textContaining('LISTA GC'), findsOneWidget);
      // Global sigue visible
      expect(find.textContaining('LISTA GLOBAL'), findsOneWidget);
    },
  );

  testWidgets(
    '(c) chip listas-island-chip-tf está en el árbol Semantics',
    (tester) async {
      await tester.pumpWidget(_wrap(
        curatedCubit: curatedCubit,
        filtersCubit: filtersCubit,
        islandsCubit: islandsCubit,
      ));
      await tester.pumpAndSettle();

      final tfChip = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.identifier == 'listas-island-chip-tf',
      );
      final gcChip = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.identifier == 'listas-island-chip-gc',
      );
      expect(tfChip, findsOneWidget);
      expect(gcChip, findsOneWidget);
    },
  );
}
