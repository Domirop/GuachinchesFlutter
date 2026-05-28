import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/new_home/curated_lists_cubit.dart';
import 'package:guachinches/data/cubit/new_home/visits_cubit.dart';
import 'package:guachinches/data/cubit/new_home/weather_cubit.dart';
import 'package:guachinches/data/cubit/new_home/zone_weather_cubit.dart';
import 'package:guachinches/data/cubit/new_home/zones_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_cubit.dart';
import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/data/model/SimpleMunicipality.dart';
import 'package:guachinches/data/model/TopRestaurants.dart';
import 'package:guachinches/data/model/Types.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/utils/contextual_pool.dart';
import 'package:guachinches/utils/distance_utils.dart';
import 'package:guachinches/utils/open_now_utils.dart';
import 'package:guachinches/utils/opening_later_utils.dart';
import 'package:guachinches/utils/time_of_day_engine.dart';

class NewHomePresenter {
  final NewHomeView _view;
  final RemoteRepository repository;
  final RestaurantCubit _restaurantCubit;
  final WeatherCubit _weatherCubit;
  final CuratedListsCubit _curatedListsCubit;
  final ZonesCubit _zonesCubit;
  final VisitsCubit _visitsCubit;
  final ZoneWeatherCubit _zoneWeatherCubit;

  NewHomePresenter(
    this._view,
    this.repository,
    this._restaurantCubit,
    this._weatherCubit,
    this._curatedListsCubit,
    this._zonesCubit,
    this._visitsCubit,
    this._zoneWeatherCubit,
  );

  // ──────────────────────────────────────────────
  // Bootstrap — carga inicial de todos los datos
  // ──────────────────────────────────────────────

  Future<void> bootstrap(String islandId) async {
    _view.setBootstrapLoading(true);
    try {
      await Future.wait([
        _loadPool(islandId),
        _loadTop(),
        _loadCategories(),
        _loadMunicipalities(islandId),
        _loadTypes(),
        _loadWeather(islandId),
        _curatedListsCubit.loadForIsland(islandId),
        _zonesCubit.loadForIsland(islandId),
        _visitsCubit.loadVisits(),
      ]);
      _zoneWeatherCubit.loadForIsland(islandId);
    } catch (e) {
      _view.setError('bootstrap', e);
    } finally {
      _view.setBootstrapLoading(false);
    }
    _refreshTimeWindow();
  }

  // ──────────────────────────────────────────────
  // Cambio de isla — recarga todo excepto visitas
  // ──────────────────────────────────────────────

  Future<void> onIslandChanged(String islandId) async {
    _view.setBootstrapLoading(true);
    try {
      await Future.wait([
        _loadPool(islandId),
        _loadTop(),
        _loadMunicipalities(islandId),
        _loadWeather(islandId),
        _curatedListsCubit.loadForIsland(islandId),
        _zonesCubit.loadForIsland(islandId),
      ]);
      _zoneWeatherCubit.loadForIsland(islandId);
    } catch (e) {
      _view.setError('island', e);
    } finally {
      _view.setBootstrapLoading(false);
    }
    _refreshTimeWindow();
  }

  // ──────────────────────────────────────────────
  // Filtros secundarios (solo cliente o re-fetch)
  // ──────────────────────────────────────────────

  /// Aplica el filtro de zona y recarga el clima al nivel correspondiente:
  /// si hay zona seleccionada (zoneId != null) → clima de la zona;
  /// si la zona se limpia → vuelve al clima de la isla.
  void onZoneChanged(
    String? zoneKey, {
    String? zoneId,
    required String islandId,
  }) {
    _view.applyClientFilters(zoneKey: zoneKey);
    if (zoneId != null) {
      _weatherCubit.loadForZone(zoneId);
    } else {
      _weatherCubit.loadForIsland(islandId);
    }
  }

  /// Refresco horario del clima. Llamado por el timer del screen cada hora.
  /// Mantiene el nivel actual (zona si hay zona seleccionada, isla si no).
  Future<void> refreshWeather({
    required String islandId,
    String? zoneId,
  }) async {
    if (zoneId != null) {
      await _weatherCubit.loadForZone(zoneId);
    } else {
      await _weatherCubit.loadForIsland(islandId);
    }
  }

  Future<void> onMunicipalityChanged(
    String? municipalityId,
    String islandId,
  ) async {
    if (municipalityId == null) return;
    try {
      final restaurants = await repository.getFilterRestaurants(
        '', municipalityId, '', '', islandId,
      );
      _view.setRestaurants(restaurants);
    } catch (e) {
      _view.setError('municipality', e);
    }
    _refreshTimeWindow();
  }

  Future<void> onCategoryChanged(
    String? categoryId,
    String islandId,
  ) async {
    if (categoryId == null) {
      await _loadPool(islandId);
      _refreshTimeWindow();
      return;
    }
    try {
      final restaurants = await repository.getFilterRestaurants(
        categoryId, '', '', '', islandId,
      );
      _view.setRestaurants(restaurants);
    } catch (e) {
      _view.setError('category', e);
    }
    _refreshTimeWindow();
  }

  // ──────────────────────────────────────────────
  // Timer 1-min: recomputa ventana sin red
  // ──────────────────────────────────────────────

  void refreshTimeWindow() => _refreshTimeWindow();

  void _refreshTimeWindow() {
    final window = TimeOfDayEngine.computeWindow(DateTime.now());
    _view.setTimeWindow(window);
  }

  // ──────────────────────────────────────────────
  // Helpers privados
  // ──────────────────────────────────────────────

  Future<void> _loadPool(String islandId) async {
    await _restaurantCubit.getAllRestaurants(0, islandId);
  }

  Future<void> _loadTop() async {
    try {
      final top = await repository.getTopRestaurants();
      _view.setTopRestaurants(top);
    } catch (e) {
      _view.setError('top', e);
    }
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await repository.getAllCategories();
      _view.setCategories(cats);
    } catch (e) {
      _view.setError('categories', e);
    }
  }

  Future<void> _loadMunicipalities(String islandId) async {
    try {
      final munis =
          await repository.getOfficialMunicipalitiesByIsland(islandId);
      _view.setMunicipalities(munis);
    } catch (e) {
      _view.setError('municipalities', e);
    }
  }

  Future<void> _loadTypes() async {
    try {
      final types = await repository.getAllTypes();
      _view.setTypes(types);
    } catch (e) {
      _view.setError('types', e);
    }
  }

  Future<void> _loadWeather(String islandId) async {
    await _weatherCubit.loadForIsland(islandId);
  }

  // ──────────────────────────────────────────────
  // Utilidades para las secciones (llamadas desde la vista)
  // ──────────────────────────────────────────────

  List<Restaurant> filterOpenNow(List<Restaurant> pool) {
    final now = DateTime.now();
    return pool.where((r) {
      if (r.horariosJson == null) return false;
      return isOpenNow(r.horariosJson, now);
    }).toList();
  }

  /// Pool para la sección "HOY EN..." alineada con el copy contextual
  /// del banner. Filtra primero por abierto ahora y luego por type/categoría
  /// según la hora. Si la intersección queda escasa (< 2) cae al pool
  /// abierto sin filtrar para no enseñar una sección casi vacía.
  List<Restaurant> filterContextual(List<Restaurant> pool, int hour) {
    final openNow = filterOpenNow(pool);
    final cfg = contextualFilterFor(hour);
    if (cfg.isEmpty) return openNow;
    final filtered = openNow.where((r) {
      final typeOk = cfg.typeIds.isEmpty || cfg.typeIds.contains(r.type);
      final catOk = cfg.categoryIds.isEmpty ||
          r.categoriaRestaurantes
              .any((c) => cfg.categoryIds.contains(c.categoriaId));
      return typeOk && catOk;
    }).toList();
    return filtered.length >= 2 ? filtered : openNow;
  }

  /// Pool de fallback para "HOY EN …" cuando no hay nada abierto AHORA.
  /// Devuelve restaurantes que abrirán más tarde durante el mismo día
  /// natural, ordenados por *quién abre antes*. Usado en islas donde la
  /// cocina arranca a las 13:00-13:30 (El Hierro, La Gomera, La Palma)
  /// para evitar que la home aparezca vacía a las 12:00.
  ///
  /// Excluye restaurantes sin `horariosJson` (no podemos prometer
  /// apertura sin datos estructurados) y los que no abren hoy.
  List<Restaurant> filterOpeningLaterToday(List<Restaurant> pool, DateTime now) {
    final result = <MapEntry<Restaurant, int>>[];
    for (final r in pool) {
      final mins = minutesUntilOpenToday(r.horariosJson, now);
      if (mins == null) continue;
      result.add(MapEntry(r, mins));
    }
    result.sort((a, b) => a.value.compareTo(b.value));
    return result.map((e) => e.key).toList();
  }

  List<Restaurant> filterClosingSoon(List<Restaurant> pool) {
    final now = DateTime.now();
    return pool.where((r) {
      if (r.horariosJson != null) return closingSoon(r.horariosJson, now);
      return false;
    }).toList();
  }

  List<NearbyRestaurant> filterNearby(
    List<Restaurant> pool,
    double userLat,
    double userLon, {
    List<Types> types = const [],
  }) {
    final nearby = <NearbyRestaurant>[];
    for (final r in pool) {
      if (r.lat == 0.0 && r.lon == 0.0) continue;
      final meters = haversineDistanceMeters(userLat, userLon, r.lat, r.lon);
      String typeName = '';
      try {
        typeName = types.firstWhere((t) => t.id == r.type).nombre;
      } catch (_) {}
      if (typeName.isEmpty && r.categoriaRestaurantes.isNotEmpty) {
        typeName = r.categoriaRestaurantes.first.categorias.nombre;
      }
      nearby.add(NearbyRestaurant(
        restaurant: r,
        distanceLabel: formatDistance(meters),
        typeName: typeName,
      ));
    }
    nearby.sort((a, b) {
      final dA = haversineDistanceMeters(userLat, userLon, a.restaurant.lat, a.restaurant.lon);
      final dB = haversineDistanceMeters(userLat, userLon, b.restaurant.lat, b.restaurant.lon);
      return dA.compareTo(dB);
    });
    return nearby.take(15).toList();
  }

  List<Restaurant> filterTerraza(List<Restaurant> pool) {
    return pool.where((r) {
      if (r.nombre.toLowerCase().contains('terraza')) return true;
      return r.categoriaRestaurantes.any(
        (c) => c.categorias.nombre.toLowerCase().contains('terraza'),
      );
    }).toList();
  }

  List<Restaurant> filterMercados(List<Restaurant> pool) {
    return pool.where((r) {
      final n = r.nombre.toLowerCase();
      return n.contains('mercado') || n.contains('tasca') ||
          r.categoriaRestaurantes.any(
            (c) {
              final cn = c.categorias.nombre.toLowerCase();
              return cn.contains('mercado') || cn.contains('tasca');
            },
          );
    }).toList();
  }
}

// ──────────────────────────────────────────────
// View interface (implementado por NewHomeScreen)
// ──────────────────────────────────────────────

abstract class NewHomeView {
  void setBootstrapLoading(bool v);
  void setRestaurants(List<Restaurant> restaurants);
  void setTopRestaurants(List<TopRestaurants> top);
  void setCategories(List<ModelCategory> categories);
  void setMunicipalities(List<SimpleMunicipality> municipalities);
  void setTypes(List<Types> types);
  void setTimeWindow(TimeOfDayWindow window);
  void applyClientFilters({String? zoneKey});
  void setError(String section, Object error);
}
