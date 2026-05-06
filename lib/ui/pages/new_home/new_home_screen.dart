import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/cubit/new_home/curated_lists_cubit.dart';
import 'package:guachinches/data/cubit/new_home/new_home_filters_cubit.dart';
import 'package:guachinches/data/cubit/new_home/new_home_filters_state.dart';
import 'package:guachinches/data/cubit/new_home/visits_cubit.dart';
import 'package:guachinches/data/cubit/new_home/weather_cubit.dart';
import 'package:guachinches/data/cubit/new_home/zones_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_state.dart';
import 'package:guachinches/data/cubit/restaurants/top/top_restaurants_cubit.dart';
import 'package:guachinches/data/model/TopRestaurants.dart';
import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/data/model/Municipality.dart';
import 'package:guachinches/data/model/SimpleMunicipality.dart';
import 'package:guachinches/data/model/Types.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/data/model/weather_data.dart';
import 'package:guachinches/data/model/zone.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/advance_search/advanced_search.dart';
import 'package:guachinches/ui/pages/restaurant_detail/restaurant_detail_screen.dart';
import 'package:guachinches/utils/distance_utils.dart';
import 'package:guachinches/utils/time_of_day_engine.dart';
import 'package:http/http.dart' as http;
import 'new_home_presenter.dart';
import 'new_home_body.dart';

/// Pantalla principal nueva. Implementa [NewHomeView].
class NewHomeScreen extends StatefulWidget {
  const NewHomeScreen({super.key});

  @override
  State<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen>
    implements NewHomeView {
  late final NewHomePresenter _presenter;
  Timer? _minuteTimer;

  // Estado local
  bool _bootstrapLoading = true;
  List<Restaurant> _pool = [];
  List<ModelCategory> _categories = [];
  List<SimpleMunicipality> _municipalities = [];
  List<Municipality> _municipalitiesOld = [];
  List<Types> _types = [];
  TimeOfDayWindow _window = TimeOfDayEngine.computeWindow(DateTime.now());
  String? _filterZoneKey;
  Set<String> _filterZoneMuniIds = const {};
  String? _filterMunicipalityId;
  Position? _userPosition;

  // Scroll para parallax
  final ScrollController _scrollCtrl = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    final repository = HttpRemoteRepository(http.Client());
    _presenter = NewHomePresenter(
      this,
      repository,
      context.read<RestaurantCubit>(),
      context.read<WeatherCubit>(),
      context.read<CuratedListsCubit>(),
      context.read<ZonesCubit>(),
      context.read<VisitsCubit>(),
    );
    final filters = context.read<NewHomeFiltersCubit>().state;
    _presenter.bootstrap(filters.islandId);
    _loadOldMunicipalities(filters.islandId);
    _startMinuteTimer();
    _scrollCtrl.addListener(_onScroll);
    _requestLocation();
  }

  void _startMinuteTimer() {
    _minuteTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) _presenter.refreshTimeWindow();
    });
  }

  Future<void> _requestLocation() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.reduced,
      );
      if (mounted) setState(() => _userPosition = pos);
    } catch (_) {}
  }

  Future<void> _loadOldMunicipalities(String islandId) async {
    try {
      final repo = HttpRemoteRepository(http.Client());
      final munis = await repo.getAllMunicipalitiesFiltered(islandId);
      if (mounted) setState(() => _municipalitiesOld = munis);
    } catch (_) {}
  }

  void _onScroll() {
    if (mounted) setState(() => _scrollOffset = _scrollCtrl.offset);
  }

  @override
  void dispose() {
    _minuteTimer?.cancel();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── NewHomeView ──────────────────────────────────

  @override
  void setBootstrapLoading(bool v) {
    if (mounted) setState(() => _bootstrapLoading = v);
  }

  @override
  void setRestaurants(List<Restaurant> restaurants) {
    if (mounted) setState(() => _pool = restaurants);
  }

  @override
  void setTopRestaurants(List<TopRestaurants> top) {}

  @override
  void setCategories(List<ModelCategory> categories) {
    if (mounted) setState(() => _categories = categories);
  }

  @override
  void setMunicipalities(List<SimpleMunicipality> municipalities) {
    if (mounted) setState(() => _municipalities = municipalities);
  }

  @override
  void setTypes(List<Types> types) {
    if (mounted) setState(() => _types = types);
  }

  @override
  void setTimeWindow(TimeOfDayWindow window) {
    if (mounted) setState(() => _window = window);
  }

  @override
  void applyClientFilters({String? zoneKey}) {
    if (mounted) setState(() => _filterZoneKey = zoneKey);
  }

  @override
  void setError(String section, Object error) {
    debugPrint('NewHome error [$section]: $error');
  }

  Future<void> _loadZoneMuniIds(Zone? zone) async {
    if (zone == null || zone.key == 'all' || zone.id == null) {
      if (mounted) setState(() => _filterZoneMuniIds = const {});
      return;
    }
    try {
      final repo = HttpRemoteRepository(http.Client());
      final munis = await repo.getMunicipalitiesByZone(zone.id!);
      if (!mounted) return;
      setState(() => _filterZoneMuniIds = munis.map((m) => m.id).toSet());
    } catch (e) {
      debugPrint('Error loadZoneMuniIds: $e');
      if (mounted) setState(() => _filterZoneMuniIds = const {});
    }
  }

  // ── Derivaciones de pool ─────────────────────────

  List<SimpleMunicipality> get _municipalitiesForPicker {
    if (_filterZoneMuniIds.isEmpty) return _municipalities;
    return _municipalities
        .where((m) => _filterZoneMuniIds.contains(m.id))
        .toList();
  }

  List<Restaurant> get _filteredPool {
    if (_filterMunicipalityId != null) return _pool;
    if (_filterZoneKey == null ||
        _filterZoneKey == 'all' ||
        _filterZoneMuniIds.isEmpty) {
      return _pool;
    }
    return _pool.where((r) {
      return _filterZoneMuniIds.contains(r.negocioMunicipioId);
    }).toList();
  }

  List<NearbyRestaurant> get _nearbyList {
    final pos = _userPosition;
    if (pos == null) return [];
    return _presenter.filterNearby(
      _filteredPool, pos.latitude, pos.longitude,
      types: _types,
    );
  }

  // ── Build ────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<RestaurantCubit, RestaurantState>(
      listener: (_, state) {
        if (state is AllRestaurantLoaded) {
          setRestaurants(state.restaurantResponse.restaurants);
        }
      },
      child: BlocBuilder<NewHomeFiltersCubit, NewHomeFiltersState>(
        builder: (_, filters) {
          return BlocBuilder<WeatherCubit, WeatherState>(
            builder: (_, weatherState) {
              final weather = weatherState is WeatherLoaded
                  ? weatherState.data
                  : const WeatherData.unknown();

              return BlocBuilder<ZonesCubit, ZonesState>(
                builder: (_, zonesState) {
                  final zones = zonesState is ZonesLoaded
                      ? zonesState.zones
                      : const <Zone>[];
                  return Scaffold(
                    backgroundColor: context.brand.base,
                    extendBody: true,
                    body: NewHomeBody(
                      scrollCtrl: _scrollCtrl,
                      scrollOffset: _scrollOffset,
                      bootstrapLoading: _bootstrapLoading,
                      hour: DateTime.now().hour,
                      window: _window,
                      filters: filters,
                      weather: weather,
                      pool: _filteredPool,
                      categories: _categories,
                      types: _types,
                      municipalities: _municipalitiesForPicker,
                      nearbyList: _nearbyList,
                      presenter: _presenter,
                      zones: zones,
                      onZoneSelected: (zone) {
                        final key = zone?.key;
                        final label = zone?.label;
                        if (zone == null) {
                          context.read<NewHomeFiltersCubit>().clearZone();
                        } else {
                          context.read<NewHomeFiltersCubit>().selectZone(
                                key: key!, label: label!);
                        }
                        _presenter.onZoneChanged(key);
                        _loadZoneMuniIds(zone);
                      },
                      onIslandSelected: (island) {
                        final key = island.id ==
                                '6f91d60f-0996-4dde-9088-167aab83a21a'
                            ? 'GC'
                            : 'TF';
                        context.read<NewHomeFiltersCubit>().selectIsland(
                              id: island.id,
                              key: key,
                              label: island.name,
                            );
                        setState(() {
                          _filterMunicipalityId = null;
                          _filterZoneMuniIds = const {};
                          _filterZoneKey = null;
                        });
                        _presenter.onIslandChanged(island.id);
                        _loadOldMunicipalities(island.id);
                      },
                      onMunicipalitySelected: (muni) {
                        if (muni == null) {
                          context.read<NewHomeFiltersCubit>().clearMunicipality();
                          setState(() => _filterMunicipalityId = null);
                          _presenter.onMunicipalityChanged(null, filters.islandId);
                        } else {
                          context.read<NewHomeFiltersCubit>().selectMunicipality(
                                id: muni.id, label: muni.nombre);
                          setState(() => _filterMunicipalityId = muni.id);
                          _presenter.onMunicipalityChanged(
                              muni.id, filters.islandId);
                        }
                      },
                      onRestaurantTap: _onRestaurantTap,
                      onSearchTap: () {
                        GlobalMethods().pushPage(
                          context,
                          AdvancedSearch(
                            categories: _categories,
                            municipalities: _municipalitiesOld,
                            types: _types,
                            islandId: filters.islandId,
                          ),
                        );
                      },
                      onSearchPreSelected: ({categories, types}) {
                        GlobalMethods().pushPage(
                          context,
                          AdvancedSearch(
                            categories: _categories,
                            municipalities: _municipalitiesOld,
                            types: _types,
                            islandId: filters.islandId,
                            preSelectedCategories: categories ?? const [],
                            preSelectedTypes: types ?? const [],
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _onRestaurantTap(String restaurantId) {
    GlobalMethods().pushPage(
      context,
      RestaurantDetailScreen(id: restaurantId),
    );
  }
}
