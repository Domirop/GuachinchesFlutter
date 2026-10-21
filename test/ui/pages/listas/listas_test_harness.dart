import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/core/remote_config/dcc_remote_config.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/new_home/curated_lists_cubit.dart';
import 'package:guachinches/data/cubit/new_home/new_home_filters_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_state.dart';
import 'package:guachinches/data/local/local_repository.dart';
import 'package:guachinches/data/local/restaurant_sql_lite.dart';
import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/data/model/Municipality.dart';
import 'package:guachinches/data/model/TopRestaurants.dart';
import 'package:guachinches/data/model/Types.dart';
import 'package:guachinches/data/model/curated_list.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/data/model/restaurant_response.dart';
import 'package:guachinches/ui/pages/listas/listas_screen.dart';
import 'package:guachinches/ui/theme/gm_favorites.dart';
import 'package:guachinches/utils/contextual_pool.dart';

/// Arnés compartido de los tests de la pestaña Listas (no es un test).

const kTfId = '76ac0bec-4bc1-41a5-bc60-e528e0c12f4d';
const kGcId = 'gc-island-test-id-001';

/// Repositorio falso: tipos, categorías, municipios y ranking en memoria.
class FakeListasRepo extends Fake implements RemoteRepository {
  List<Types> types;
  List<TopRestaurants> top;
  FakeListasRepo({List<Types>? types, this.top = const []})
      : types = types ??
            [
              Types(id: RestaurantTypeIds.tascas, nombre: 'Tascas'),
              Types(id: RestaurantTypeIds.bodegones, nombre: 'Bodegones'),
            ];

  @override
  Future<List<Types>> getAllTypes() async => types;

  @override
  Future<List<ModelCategory>> getAllCategories() async => const [];

  @override
  Future<List<Municipality>> getAllMunicipalitiesFiltered(
          String islandId) async =>
      const [];

  @override
  Future<List<TopRestaurants>> getTopRestaurants() async => top;
}

class FakeCubitRepo extends Fake implements RemoteRepository {}

/// Cubit de guías con estado fijo; cuenta llamadas.
class StubCuratedListsCubit extends CuratedListsCubit {
  int loadCount = 0;
  int refreshCount = 0;
  String? lastIsland;
  bool loadingWasEmitted = false;

  StubCuratedListsCubit(CuratedListsState initial) : super(FakeCubitRepo()) {
    emit(initial);
  }

  @override
  Future<void> loadForIsland(String? islandId) async {
    loadCount++;
    lastIsland = islandId;
  }

  @override
  Future<void> refresh(String? islandId) async {
    refreshCount++;
    lastIsland = islandId;
  }

  void set(CuratedListsState s) => emit(s);

  @override
  void emit(CuratedListsState state) {
    if (state is CuratedListsLoading) loadingWasEmitted = true;
    super.emit(state);
  }
}

class StubRestaurantCubit extends RestaurantCubit {
  StubRestaurantCubit(List<Restaurant> pool) : super(FakeCubitRepo()) {
    emit(AllRestaurantLoaded(RestaurantResponse(restaurants: pool)));
  }
}

class RemoteConfigAllOn implements RemoteConfigBridge {
  final bool curated;
  RemoteConfigAllOn({this.curated = true});
  @override
  Future<void> configure(
          {required Duration fetchTimeout,
          required Duration minimumFetchInterval}) async {}
  @override
  Future<void> setDefaults(Map<String, dynamic> defaults) async {}
  @override
  Future<bool> fetchAndActivate() async => true;
  @override
  bool getBool(String key) => key == 'show_curated_lists' ? curated : true;
  @override
  int getInt(String key) => 1;
  @override
  String getString(String key) => '';
}

class MemFavRepo implements LocalRepository {
  final Set<String> ids;
  MemFavRepo(this.ids);

  @override
  Future<List<RestaurantSQLLite>> getRestaurants() async => [
        for (final id in ids)
          RestaurantSQLLite.fromMap({'id': 1, 'restaurantId': id}),
      ];
  @override
  Future<bool> insertRestaurant(String id) async => ids.add(id);
  @override
  Future<bool> removeRestaurant(String id) async => ids.remove(id);
  @override
  Future<bool> isFavorite(String id) async => ids.contains(id);
  @override
  Future<RestaurantSQLLite?> getRestaurant(String id) async => null;
}

CuratedList guide({
  required String id,
  required String title,
  String? islandId,
  int position = 1,
  String eyebrow = 'Guía',
  String subtitle = '',
  String location = 'Canarias',
  int count = 5,
  String? heroEmoji,
}) =>
    CuratedList(
      id: id,
      title: title,
      subtitle: subtitle,
      eyebrow: eyebrow,
      position: position,
      count: count,
      enabled: true,
      islandId: islandId,
      location: location,
      heroEmoji: heroEmoji,
      accent: const Color(0xFF1A6E4A),
    );

/// Monta [ListasScreen] con todo lo que necesita.
Widget wrapListas({
  required CuratedListsCubit curated,
  required NewHomeFiltersCubit filters,
  RestaurantCubit? restaurants,
  List<Restaurant> pool = const [],
  FakeListasRepo? repo,
  GmFavorites? favorites,
  ThemeData? theme,
}) {
  // El estado del cubit da el «pool» (lo que cargó el Inicio).
  final rc = restaurants ?? StubRestaurantCubit(pool);
  return MultiBlocProvider(
    providers: [
      BlocProvider<CuratedListsCubit>.value(value: curated),
      BlocProvider<NewHomeFiltersCubit>.value(value: filters),
      BlocProvider<RestaurantCubit>.value(value: rc),
    ],
    child: MaterialApp(
      theme: theme ?? appDarkTheme,
      home: ListasScreen(
        repository: repo ?? FakeListasRepo(),
        favorites: favorites ?? GmFavorites.withRepository(MemFavRepo({})),
      ),
    ),
  );
}

Finder byIdentifier(String id) => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.identifier == id,
    );
