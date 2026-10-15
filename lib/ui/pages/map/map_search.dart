import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/menu/menu_cubit.dart';
import 'package:guachinches/data/cubit/new_home/islands_cubit.dart';
import 'package:guachinches/data/cubit/new_home/new_home_filters_cubit.dart';
import 'package:guachinches/data/cubit/new_home/new_home_filters_state.dart';
import 'package:guachinches/data/cubit/restaurants/map/restaurant_map_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/map/restaurant_map_state.dart';
import 'package:guachinches/data/http_client.dart';
import 'package:guachinches/data/model/Island.dart';
import 'package:guachinches/data/model/Types.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/advance_search/list_theme.dart';
import 'package:guachinches/ui/pages/advance_search/map_clusters.dart';
import 'package:guachinches/ui/pages/map/driving_detector.dart';
import 'package:guachinches/ui/pages/map/map_logic.dart';
import 'package:guachinches/ui/pages/map/map_pins.dart';
import 'package:guachinches/ui/pages/map/map_search_presenter.dart';
import 'package:guachinches/ui/pages/map/map_style.dart';
import 'package:guachinches/ui/pages/map/widgets/map_chrome.dart';
import 'package:guachinches/ui/pages/map/widgets/map_drive.dart';
import 'package:guachinches/ui/pages/map/widgets/map_nearby.dart';
import 'package:guachinches/ui/pages/map/widgets/map_peek_sheet.dart';
import 'package:guachinches/ui/pages/new_home/sheets/island_picker_sheet.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show gmDisplayName, gmPlaceName;
import 'package:guachinches/ui/pages/restaurant_detail/restaurant_detail_screen.dart';
import 'package:guachinches/ui/theme/gm_favorites.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:guachinches/utils/island_bounds.dart';
import 'package:guachinches/utils/island_key_utils.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:url_launcher/url_launcher.dart';

/// Pestaña Mapa (tablero TabMapa) y su variante empujada «Cerca de ti»
/// (tablero MapaEmpujado). Ambas abren el modo coche (tablero MapaCoche)
/// cuando el usuario confirma que va conduciendo.
///
/// - `MapSearch()` es la pestaña 2 de `NewHomeTabScaffold`: el GoogleMap se
///   monta la primera vez que el usuario entra en la pestaña.
/// - `MapSearch(nearby: true)` se empuja desde «Cerca de ti» del Inicio y de
///   Listas: se monta al instante (antes esperaba a que la pestaña 2 fuera
///   la elegida y nunca aparecía).
class MapSearch extends StatefulWidget {
  final bool nearby;
  const MapSearch({super.key, this.nearby = false});

  @override
  State<MapSearch> createState() => MapSearchState();
}

enum _Phase { loading, ready, error }

enum _Loc { unknown, granted, denied }

class MapSearchState extends State<MapSearch>
    with WidgetsBindingObserver
    implements MapSearchView {
  static const int _kMapTabIndex = 2;
  static const LatLng _kDefaultTarget = LatLng(28.4528, -16.4478);

  late final RemoteRepository _repo;
  late final RestaurantMapCubit _restaurantsCubit;
  late final MapSearchPresenter _presenter;
  late final MapPinFactory _pins = MapPinFactory(onReady: _onPinReady);

  final Completer<GoogleMapController> _controller = Completer();
  final MapDrivingDetector _driving = MapDrivingDetector();
  final TextEditingController _search = TextEditingController();
  final ScrollController _carousel = ScrollController();
  Timer? _searchDebounce;

  String _islandId = '';
  List<Types> _types = const [];
  _Phase _phase = _Phase.loading;
  List<Restaurant> _restaurants = const [];
  List<MapSite> _sites = const [];
  MapFilters _filters = const MapFilters();

  // Ubicación.
  StreamSubscription<Position>? _posSub;
  bool _startingLocation = false;
  _Loc _loc = _Loc.unknown;
  LocationPermission? _lastPermission;
  bool _serviceOff = false;
  double? _userLat;
  double? _userLon;
  double _heading = 0;
  bool _firstFix = true;
  DateTime _sitesAt = DateTime.fromMillisecondsSinceEpoch(0);
  double? _sitesLat;
  double? _sitesLon;

  // Mapa.
  bool _mapMounted = false;
  bool _onMapTab = false;
  double _zoom = 14.5;
  double? _pendingZoom;
  MapBox? _bounds;
  int _pinVersion = 0;
  String? _markersKey;
  Set<Marker> _markersMemo = const {};

  // Selección (pestaña) y zona congelada para anterior/siguiente.
  String? _selectedId;
  List<MapSite> _zone = const [];

  // «Cerca de ti».
  bool _listMode = false;
  bool _showIsland = false;
  String? _nearbyHighlight;

  // Modo coche.
  MapDriveController? _drive;
  bool _suggestOpen = false;

  // Cambio de isla al arrastrar el mapa (solo pestaña).
  String? _autoIslandKeyInFlight;
  bool _movingCameraToIsland = false;
  String? _pendingFlyIslandId;

  bool get _islandMode => !widget.nearby || _showIsland;

  // ── Ciclo de vida ──────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _repo = HttpRemoteRepository(sharedHttpClient);
    _restaurantsCubit = context.read<RestaurantMapCubit>();
    _presenter = MapSearchPresenter(this, _repo, _restaurantsCubit);
    _islandId = context.read<NewHomeFiltersCubit>().state.islandId;

    _driving.isDriving.addListener(_onDrivingChanged);
    _driving.shouldSuggest.addListener(_onDriveSuggested);
    GmFavorites.instance.ensureLoaded();

    _presenter.getAllTypes();
    // «Cerca de ti» reutiliza los sitios que ya cargó la pestaña.
    final s = _restaurantsCubit.state;
    if (s is AllRestaurantMapLoaded &&
        s.restaurantResponse.restaurants.isNotEmpty) {
      _setRestaurants(s.restaurantResponse.restaurants, notify: false);
    }
    _load(silent: true);

    final onTab =
        context.read<MenuCubit>().state.selectedIndex == _kMapTabIndex;
    if (widget.nearby || onTab) {
      _mapMounted = true;
      _onMapTab = true;
      _startLocation();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _driving.isDriving.removeListener(_onDrivingChanged);
    _driving.shouldSuggest.removeListener(_onDriveSuggested);
    _driving.dispose();
    _drive?.dispose();
    _posSub?.cancel();
    _pins.dispose();
    _search.dispose();
    _carousel.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Volver de Ajustes con el permiso concedido: arrancar la ubicación.
    if (state == AppLifecycleState.resumed &&
        _loc != _Loc.granted &&
        _onMapTab) {
      _startLocation(prompt: false);
    }
  }

  @override
  void setTypes(List<Types> types) {
    if (mounted) setState(() => _types = types);
  }

  void _onPinReady() {
    if (mounted) setState(() => _pinVersion++);
  }

  // ── Datos ──────────────────────────────────────────────────────────────

  Future<void> _load({bool silent = false, bool force = false}) async {
    if (!silent && mounted) setState(() => _phase = _Phase.loading);
    try {
      if (force) {
        await _presenter.reloadRestaurants(_islandId);
      } else {
        await _presenter.getAllRestaurants(_islandId);
      }
    } catch (e) {
      AppLogger.warn('mapa', 'no se pudieron cargar los sitios: $e');
      if (!mounted) return;
      if (_phase != _Phase.ready || _restaurants.isEmpty) {
        setState(() => _phase = _Phase.error);
      }
    }
  }

  void _setRestaurants(List<Restaurant> list, {bool notify = true}) {
    _restaurants = list;
    _sites = buildMapSites(list, DateTime.now(),
        userLat: _userLat, userLon: _userLon);
    _sitesAt = DateTime.now();
    _sitesLat = _userLat;
    _sitesLon = _userLon;
    _phase = _Phase.ready;
    if (_selectedId != null && !_sites.any((s) => s.id == _selectedId)) {
      _selectedId = null;
    }
    _drive?.update(sites: _sites);
    if (notify && mounted) setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshBounds());
  }

  /// Distancias y estados de apertura al día (como mucho cada 30 m o 60 s).
  void _refreshSitesForLocation({bool force = false}) {
    if (_restaurants.isEmpty) return;
    final moved = (_sitesLat == null || _userLat == null)
        ? double.infinity
        : Geolocator.distanceBetween(
            _sitesLat!, _sitesLon!, _userLat!, _userLon!);
    final stale = DateTime.now().difference(_sitesAt).inSeconds >= 60;
    if (!force && moved < 30 && !stale) return;
    _sites = buildMapSites(_restaurants, DateTime.now(),
        userLat: _userLat, userLon: _userLon);
    _sitesAt = DateTime.now();
    _sitesLat = _userLat;
    _sitesLon = _userLon;
  }

  List<MapSite> get _filtered => applyMapFilters(_sites, _filters);

  MapSite? _siteById(String? id) {
    if (id == null) return null;
    for (final s in _sites) {
      if (s.id == id) return s;
    }
    return null;
  }

  // ── Ubicación ──────────────────────────────────────────────────────────

  Future<void> _startLocation({bool prompt = true}) async {
    if (_posSub != null || _startingLocation) return;
    _startingLocation = true;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _serviceOff = true;
        _setDenied();
        return;
      }
      _serviceOff = false;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && prompt) {
        permission = await Geolocator.requestPermission();
      }
      _lastPermission = permission;
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        _setDenied();
        return;
      }
      if (!mounted) return;
      setState(() => _loc = _Loc.granted);
      _posSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen(_onPosition, onError: (Object e) {
        AppLogger.warn('mapa', 'flujo de ubicación: $e');
      });
      _centerOnUserNow();
    } catch (e) {
      AppLogger.warn('mapa', 'no se pudo arrancar la ubicación: $e');
      _setDenied();
    } finally {
      _startingLocation = false;
    }
  }

  void _setDenied() {
    if (!mounted) return;
    final first = _loc != _Loc.denied;
    setState(() => _loc = _Loc.denied);
    // Sin ubicación: la isla entera (también en «Cerca de ti»).
    if (first) _flyToIsland(_islandId);
  }

  void _stopLocation() {
    _posSub?.cancel();
    _posSub = null;
    _driving.onPaused();
  }

  /// Centra ya con la última posición conocida (el primer fix del flujo
  /// puede tardar varios segundos en iOS).
  Future<void> _centerOnUserNow() async {
    try {
      Position? pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 8));
      if (!mounted) return;
      _applyPosition(pos.latitude, pos.longitude);
    } catch (_) {
      // El flujo centrará cuando llegue el primer fix.
    }
  }

  void _onPosition(Position p) {
    if (!mounted) return;
    if (p.heading >= 0 && p.speed > 3.0) _heading = p.heading;
    _driving.onPosition(p);
    _applyPosition(p.latitude, p.longitude);
  }

  void _applyPosition(double lat, double lon) {
    _userLat = lat;
    _userLon = lon;
    final first = _firstFix;
    _refreshSitesForLocation(force: first);
    setState(() {
      if (_showIsland && widget.nearby && first) _showIsland = false;
    });
    _drive?.update(lat: lat, lon: lon, heading: _heading, sites: _sites);
    if (first) {
      _firstFix = false;
      if (widget.nearby && !_showIsland) {
        _fitNearby();
      } else {
        _animateTo(LatLng(lat, lon), zoom: 14.5);
      }
    }
  }

  Future<void> _activateLocation() async {
    HapticFeedback.selectionClick();
    if (_serviceOff) {
      await Geolocator.openLocationSettings();
      return;
    }
    if (_lastPermission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return;
    }
    await _startLocation();
  }

  // ── Cámara ─────────────────────────────────────────────────────────────

  Future<void> _animateTo(LatLng target, {double? zoom}) async {
    if (!_controller.isCompleted) return;
    final c = await _controller.future;
    await c.animateCamera(zoom == null
        ? CameraUpdate.newLatLng(target)
        : CameraUpdate.newLatLngZoom(target, zoom));
  }

  Future<void> _fitBounds(List<(double, double)> pts, {double pad = 64}) async {
    if (pts.isEmpty || !_controller.isCompleted) return;
    final c = await _controller.future;
    if (pts.length == 1) {
      await c.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(pts.first.$1, pts.first.$2), 15));
      return;
    }
    var minLat = 90.0, maxLat = -90.0, minLon = 180.0, maxLon = -180.0;
    for (final p in pts) {
      minLat = math.min(minLat, p.$1);
      maxLat = math.max(maxLat, p.$1);
      minLon = math.min(minLon, p.$2);
      maxLon = math.max(maxLon, p.$2);
    }
    if ((maxLat - minLat).abs() < 1e-5 && (maxLon - minLon).abs() < 1e-5) {
      await c.animateCamera(CameraUpdate.newLatLngZoom(
          LatLng(minLat, minLon), math.min(_zoom + 3, 19)));
      return;
    }
    await c.animateCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(
            southwest: LatLng(minLat, minLon),
            northeast: LatLng(maxLat, maxLon)),
        pad));
  }

  /// Encuadra el círculo de 3 km alrededor del usuario.
  void _fitNearby() {
    final lat = _userLat, lon = _userLon;
    if (lat == null || lon == null) return;
    const r = kNearbyRadiusKm * 1000;
    final dLat = r / 111200;
    final dLon = r / (111320 * math.cos(lat * math.pi / 180));
    _fitBounds([(lat - dLat, lon - dLon), (lat + dLat, lon + dLon)], pad: 12);
  }

  Future<void> _refreshBounds() async {
    if (!_controller.isCompleted || !mounted) return;
    final c = await _controller.future;
    LatLngBounds b;
    try {
      b = await c.getVisibleRegion();
    } catch (_) {
      return;
    }
    if (!mounted) return;
    final box = MapBox(b.southwest.latitude, b.southwest.longitude,
        b.northeast.latitude, b.northeast.longitude);
    setState(() {
      _bounds = box;
      final z = _pendingZoom;
      if (z != null) _zoom = z;
    });
    if (!widget.nearby) _maybeSwitchIslandFor(box);
  }

  // ── Selección ──────────────────────────────────────────────────────────

  (double, double) get _refPoint {
    if (_userLat != null && _userLon != null) return (_userLat!, _userLon!);
    final b = _bounds;
    if (b != null) return (b.centerLat, b.centerLon);
    return (_kDefaultTarget.latitude, _kDefaultTarget.longitude);
  }

  void _select(MapSite site) {
    HapticFeedback.selectionClick();
    final box = _bounds;
    final pool = box == null ? _filtered : sitesIn(_filtered, box);
    final zone = [
      ...pool,
      if (!pool.any((s) => s.id == site.id)) site,
    ];
    final (lat, lon) = _refPoint;
    setState(() {
      _selectedId = site.id;
      _zone = sortByProximity(zone, lat, lon);
    });
    _animateTo(LatLng(site.lat, site.lon));
  }

  void _step(int delta) {
    final i = _zone.indexWhere((s) => s.id == _selectedId);
    final next = zoneStep(i, delta, _zone.length);
    if (next < 0) return;
    final s = _zone[next];
    HapticFeedback.selectionClick();
    setState(() => _selectedId = s.id);
    _animateTo(LatLng(s.lat, s.lon));
  }

  void _deselect() {
    if (_selectedId == null) return;
    setState(() {
      _selectedId = null;
      _zone = const [];
    });
  }

  void _highlightNearby(MapSite site, List<MapSite> near) {
    HapticFeedback.selectionClick();
    setState(() => _nearbyHighlight = site.id);
    final i = near.indexWhere((s) => s.id == site.id);
    if (i >= 0 && _carousel.hasClients) {
      final w = MapNearbySheet.cardWidth(context) + 10;
      _carousel.animateTo(
        math.min(i * w, _carousel.position.maxScrollExtent),
        duration: const Duration(milliseconds: 320),
        curve: GmMotion.settle,
      );
    }
  }

  // ── Acciones de sitio ──────────────────────────────────────────────────

  void _openDetail(MapSite s) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => RestaurantDetailScreen(id: s.id),
    ));
  }

  void _directions(MapSite s) {
    MapsLauncher.launchCoordinates(
        s.lat, s.lon, gmDisplayName(s.restaurant.nombre));
  }

  VoidCallback? _callFor(MapSite s) {
    final phone = s.restaurant.telefono.replaceAll(RegExp(r'[^\d+]'), '');
    if (phone.length < 6) return null;
    return () async {
      try {
        // Sin canLaunchUrl: en iOS devuelve false para tel: si el esquema no
        // está en LSApplicationQueriesSchemes.
        await launchUrl(Uri(scheme: 'tel', path: phone));
      } catch (e) {
        AppLogger.warn('mapa', 'no se pudo llamar: $e');
      }
    };
  }

  // ── Filtros ────────────────────────────────────────────────────────────

  void _toggleOpen() {
    setState(() {
      _filters = _filters.copyWith(openNow: !_filters.openNow);
      _selectedId = null;
    });
  }

  void _toggleType(String id) {
    setState(() {
      _filters = _filters.toggleType(id);
      _selectedId = null;
    });
  }

  void _onSearchChanged(String v) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _filters = _filters.copyWith(query: v);
        _selectedId = null;
      });
      // Si lo buscado no está en pantalla, se encuadra.
      final matches = _filtered;
      final box = _bounds;
      if (v.trim().isNotEmpty &&
          matches.isNotEmpty &&
          matches.length <= 40 &&
          (box == null || sitesIn(matches, box).isEmpty)) {
        _fitBounds([for (final s in matches) (s.lat, s.lon)]);
      }
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _search.clear();
    setState(() => _filters = _filters.copyWith(query: ''));
  }

  void _clearFilters() {
    _searchDebounce?.cancel();
    _search.clear();
    setState(() {
      _filters = const MapFilters();
      _selectedId = null;
    });
  }

  ListThemeKind? _singleTypeKind() {
    if (_filters.typeIds.length != 1) return null;
    final id = _filters.typeIds.first;
    for (final t in _types) {
      if (t.id == id) return listThemeForType(t.id, t.nombre);
    }
    return listThemeForType(id, '');
  }

  // ── Isla ───────────────────────────────────────────────────────────────

  void _onIslandChanged(String id) {
    if (!mounted || id == _islandId) return;
    setState(() {
      _islandId = id;
      _restaurants = const [];
      _sites = const [];
      _selectedId = null;
      _phase = _Phase.loading;
    });
    _load();
    if (_onMapTab) {
      _flyToIsland(id);
    } else {
      _pendingFlyIslandId = id;
    }
  }

  void _showIslandSheet() {
    IslandPickerSheet.show(
      context: context,
      selectedIslandId: context.read<NewHomeFiltersCubit>().state.islandId,
      onSelect: (island) {
        final key = (island.key != null && island.key!.isNotEmpty)
            ? island.key!
            : islandKeyFromName(island.name);
        context
            .read<NewHomeFiltersCubit>()
            .selectIsland(id: island.id, key: key, label: island.name);
      },
    );
  }

  Island? _islandById(String id) {
    final st = context.read<IslandsCubit>().state;
    if (st is! IslandsLoaded) return null;
    for (final i in st.islands) {
      if (i.id == id) return i;
    }
    return null;
  }

  Future<void> _flyToIsland(String islandId) async {
    if (!_controller.isCompleted) return;
    final island = _islandById(islandId);
    final key = island == null
        ? context.read<NewHomeFiltersCubit>().state.islandKey
        : ((island.key != null && island.key!.isNotEmpty)
            ? island.key!
            : islandKeyFromName(island.name));
    final b = islandBoundsForKey(key);
    if (b == null) return;
    _autoIslandKeyInFlight = key.toUpperCase();
    _movingCameraToIsland = true;
    try {
      final c = await _controller.future;
      await c.animateCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(b.minLat, b.minLon),
          northeast: LatLng(b.maxLat, b.maxLon),
        ),
        40,
      ));
      // La animación no avisa al terminar: se espera antes de reactivar el
      // cambio automático de isla.
      await Future<void>.delayed(const Duration(milliseconds: 900));
    } catch (_) {
      // El mapa aún no está listo.
    } finally {
      _movingCameraToIsland = false;
    }
  }

  /// Si el centro del mapa cae sobre OTRA isla (y el usuario está mirando
  /// el mapa), se cambia a esa isla. Sobre el mar no se toca nada.
  void _maybeSwitchIslandFor(MapBox box) {
    if (!mounted || _drive != null || !_onMapTab || _movingCameraToIsland) {
      return;
    }
    final key = islandKeyAt(box.centerLat, box.centerLon);
    if (key == null) return;
    final st = context.read<IslandsCubit>().state;
    if (st is! IslandsLoaded) return;
    Island? target;
    for (final i in st.islands) {
      final k = (i.key != null && i.key!.isNotEmpty)
          ? i.key!
          : islandKeyFromName(i.name);
      if (k.toUpperCase() == key) {
        target = i;
        break;
      }
    }
    if (target == null) return;
    final filters = context.read<NewHomeFiltersCubit>();
    if (filters.state.islandId == target.id) {
      _autoIslandKeyInFlight = null;
      return;
    }
    if (_autoIslandKeyInFlight == key) return;
    _autoIslandKeyInFlight = key;
    AppLogger.info('mapa', 'auto-isla → ${target.name} (centro sobre $key)');
    filters.selectIsland(id: target.id, key: key, label: target.name);
  }

  // ── Pestaña visible ────────────────────────────────────────────────────

  void _onMenuChanged(MenuState state) {
    if (widget.nearby) return;
    final onMap = state.selectedIndex == _kMapTabIndex;
    _onMapTab = onMap;
    if (onMap && !_mapMounted) {
      // Un fotograma de margen para que el platform view pinte las teselas.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_mapMounted) setState(() => _mapMounted = true);
      });
    }
    if (onMap && _pendingFlyIslandId != null) {
      final id = _pendingFlyIslandId!;
      _pendingFlyIslandId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _flyToIsland(id);
      });
    }
    if (onMap) {
      // Al volver a la pestaña, horarios y distancias al día.
      _refreshSitesForLocation();
      setState(() {});
      _startLocation();
    } else {
      _stopLocation();
    }
  }

  // ── Modo coche ─────────────────────────────────────────────────────────

  void _onDriveSuggested() {
    if (!mounted || !_driving.shouldSuggest.value || _suggestOpen) return;
    if (!(ModalRoute.of(context)?.isCurrent ?? true) || !_onMapTab) {
      _driving.dismissSuggestion(cooldown: const Duration(minutes: 1));
      return;
    }
    _suggestOpen = true;
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MapDriveSuggestionSheet(
        onConfirm: () {
          Navigator.of(ctx).pop();
          _driving.confirmDrive();
        },
        onDismiss: () {
          Navigator.of(ctx).pop();
          _driving.dismissSuggestion();
        },
      ),
    ).whenComplete(() {
      _suggestOpen = false;
      // Cerrada sin elegir: cuenta como «Ahora no».
      if (_driving.shouldSuggest.value) _driving.dismissSuggestion();
    });
  }

  void _onDrivingChanged() {
    if (!mounted) return;
    HapticFeedback.lightImpact();
    if (_driving.isDriving.value) {
      _enterDrive();
    } else {
      _drive?.active.value = false;
    }
  }

  /// El modo coche se empuja a pantalla completa en el navegador raíz: así
  /// tapa la barra de pestañas sin tocar el andamio de las pestañas.
  void _enterDrive() {
    if (_drive != null) return;
    _refreshSitesForLocation(force: true);
    final drive = MapDriveController()
      ..update(lat: _userLat, lon: _userLon, heading: _heading, sites: _sites);
    _drive = drive;
    setState(() => _selectedId = null);
    Navigator.of(context, rootNavigator: true)
        .push(PageRouteBuilder<void>(
      transitionDuration:
          Duration(milliseconds: GmMotion.reduced(context) ? 0 : 320),
      reverseTransitionDuration:
          Duration(milliseconds: GmMotion.reduced(context) ? 0 : 240),
      pageBuilder: (_, __, ___) => MapDriveScreen(
        controller: drive,
        onExit: _driving.forceExit,
        onGo: _directions,
      ),
      transitionsBuilder: (_, a, __, child) =>
          FadeTransition(opacity: a, child: child),
    ))
        .whenComplete(() {
      // Cerrada a mano (gesto atrás): también sale del modo coche.
      if (_driving.isDriving.value) _driving.forceExit();
      _drive = null;
      // El controlador se libera tras la animación de salida.
      Future<void>.delayed(const Duration(milliseconds: 400), drive.dispose);
      if (mounted) setState(() {});
    });
  }

  // ── Marcadores ─────────────────────────────────────────────────────────

  Set<Marker> _markers(bool dark, List<MapSite> nearList) {
    final List<MapSite> shown;
    final String? selected;
    if (!_islandMode) {
      shown = _loc == _Loc.granted ? nearList : const [];
      selected = _nearbyHighlight;
    } else {
      shown = _filtered;
      selected = _selectedId;
    }
    final f = _filters;
    final key = '${identityHashCode(_sites)}|${shown.length}|$selected|'
        '${f.openNow}|${f.typeIds.join(',')}|${f.query}|$_loc|'
        '${_zoom.toStringAsFixed(2)}|$dark|$_pinVersion|$_islandMode';
    if (key == _markersKey) return _markersMemo;

    final out = <Marker>{};
    final selIndex = shown.indexWhere((s) => s.id == selected);
    final clusters =
        mapClusters([for (final s in shown) (s.lat, s.lon)], _zoom, radius: 40);
    for (final cl in clusters) {
      final members = [
        for (final m in cl.members)
          if (m != selIndex) m
      ];
      if (members.isEmpty) continue;
      if (members.length == 1) {
        final s = shown[members.first];
        final b = _pins.pin(
            s.kind, s.closed ? MapPinVariant.dimmed : MapPinVariant.normal,
            dark: dark);
        if (b == null) continue;
        out.add(Marker(
          markerId: MarkerId(s.id),
          position: LatLng(s.lat, s.lon),
          icon: b.icon,
          anchor: b.anchor,
          zIndexInt: s.closed ? 1 : 2,
          consumeTapEvents: true,
          onTap: () => _islandMode ? _select(s) : _highlightNearby(s, shown),
        ));
        continue;
      }
      final b = _pins.cluster(members.length, dark: dark);
      if (b == null) continue;
      final pts = [for (final m in members) (shown[m].lat, shown[m].lon)];
      final lat = pts.map((p) => p.$1).reduce((a, b) => a + b) / pts.length;
      final lon = pts.map((p) => p.$2).reduce((a, b) => a + b) / pts.length;
      out.add(Marker(
        markerId: MarkerId('cluster-${shown[members.first].id}-${pts.length}'),
        position: LatLng(lat, lon),
        icon: b.icon,
        anchor: b.anchor,
        zIndexInt: 3,
        consumeTapEvents: true,
        onTap: () => _fitBounds(pts, pad: 72),
      ));
    }
    if (selIndex >= 0) {
      final s = shown[selIndex];
      final b = _pins.pin(s.kind, MapPinVariant.selected, dark: dark);
      if (b != null) {
        out.add(Marker(
          markerId: MarkerId(s.id),
          position: LatLng(s.lat, s.lon),
          icon: b.icon,
          anchor: b.anchor,
          zIndexInt: 10,
          consumeTapEvents: true,
          onTap: () {},
        ));
      }
    }
    // Las chinchetas aún sin pintar se añaden al llegar (`_pinVersion`).
    _markersKey = key;
    _markersMemo = out;
    return out;
  }

  Set<Circle> _nearbyCircles() {
    if (_islandMode || _userLat == null || _listMode) return const {};
    return {
      Circle(
        circleId: const CircleId('nearby-fill'),
        center: LatLng(_userLat!, _userLon!),
        radius: kNearbyRadiusKm * 1000,
        fillColor: const Color(0x0D0085C4),
        strokeWidth: 0,
        strokeColor: Colors.transparent,
      ),
    };
  }

  /// Aro discontinuo de 3 km (los círculos de Google no admiten trazo
  /// discontinuo: es una polilínea cerrada).
  Set<Polyline> _nearbyRing(GmColors gm) {
    if (_islandMode || _userLat == null || _listMode) return const {};
    const r = kNearbyRadiusKm * 1000;
    final lat = _userLat!, lon = _userLon!;
    final pts = <LatLng>[];
    for (var i = 0; i <= 72; i++) {
      final (pLat, pLon) = projectAhead(lat, lon, i * 5.0, r);
      pts.add(LatLng(pLat, pLon));
    }
    return {
      Polyline(
        polylineId: const PolylineId('nearby-ring'),
        points: pts,
        width: 2,
        color: gm.label2.withValues(alpha: 0.45 * gm.label2.a),
        patterns: [PatternItem.dash(10), PatternItem.gap(12)],
        consumeTapEvents: false,
      ),
    };
  }

  // ── Construcción ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    Widget body = _mapMounted
        ? _buildMapScreen(context, gm)
        : ColoredBox(color: gm.mapLand, child: const SizedBox.expand());

    body = BlocListener<RestaurantMapCubit, RestaurantMapState>(
      listener: (_, s) {
        if (s is AllRestaurantMapLoaded) {
          _setRestaurants(s.restaurantResponse.restaurants);
        }
      },
      child: BlocListener<NewHomeFiltersCubit, NewHomeFiltersState>(
        listenWhen: (a, b) => a.islandId != b.islandId,
        listener: (_, s) => _onIslandChanged(s.islandId),
        child: body,
      ),
    );
    if (!widget.nearby) {
      body = BlocListener<MenuCubit, MenuState>(
        listenWhen: (a, b) => a.selectedIndex != b.selectedIndex,
        listener: (_, s) => _onMenuChanged(s),
        child: body,
      );
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: gm.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: gm.mapLand,
        resizeToAvoidBottomInset: false,
        body: Semantics(
          identifier: widget.nearby ? 'mapa-nearby-screen' : 'mapa-screen',
          container: true,
          child: body,
        ),
      ),
    );
  }

  Widget _buildMapScreen(BuildContext context, GmColors gm) {
    final media = MediaQuery.of(context);
    final top = media.padding.top;
    // En la pestaña, el padding inferior ya incluye la barra flotante.
    final bottom = media.padding.bottom;
    final near = widget.nearby ? nearbySites(_sites) : const <MapSite>[];
    final selected = _islandMode ? _siteById(_selectedId) : null;
    final showSheet = selected != null && _phase == _Phase.ready;
    final nearbyPhase = _nearbyPhase();

    final double mapTop = top + (widget.nearby ? 64 : 160);
    final double mapBottom =
        !_islandMode ? (_listMode ? 0 : 300) : bottom + (showSheet ? 270 : 0);

    final stack = <Widget>[
      Positioned.fill(
        child: GoogleMap(
          initialCameraPosition:
              const CameraPosition(target: _kDefaultTarget, zoom: 14.5),
          style: mapStyleFor(gm),
          markers:
              _phase == _Phase.ready ? _markers(gm.isDark, near) : const {},
          circles: _nearbyCircles(),
          polylines: _nearbyRing(gm),
          myLocationEnabled: _loc == _Loc.granted,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          buildingsEnabled: false,
          indoorViewEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          padding: EdgeInsets.only(top: mapTop, bottom: mapBottom),
          onMapCreated: (c) {
            if (!_controller.isCompleted) _controller.complete(c);
            if (_userLat != null) {
              widget.nearby && !_showIsland
                  ? _fitNearby()
                  : _animateTo(LatLng(_userLat!, _userLon!), zoom: 14.5);
            } else if (_loc == _Loc.denied && _islandMode) {
              _flyToIsland(_islandId);
            }
            Future<void>.delayed(
                const Duration(milliseconds: 300), _refreshBounds);
          },
          onTap: (_) => _islandMode ? _deselect() : null,
          onCameraMove: (p) => _pendingZoom = p.zoom,
          onCameraIdle: _refreshBounds,
        ),
      ),
      // Velo superior (efecto de borde de scroll del tablero).
      Positioned(
        left: 0,
        right: 0,
        top: 0,
        height: top + (widget.nearby ? 110 : 150),
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [gm.edgeTop0, gm.edgeTop1, gm.edgeFade0],
                stops: const [0, 0.48, 1],
              ),
            ),
          ),
        ),
      ),
    ];

    if (widget.nearby) {
      stack.addAll(_nearbyOverlay(context, gm, near, nearbyPhase, top, bottom));
    } else {
      stack.addAll(_tabOverlay(context, gm, top));
    }

    if (_islandMode && showSheet) {
      final i = _zone.indexWhere((s) => s.id == selected.id);
      stack.add(Positioned(
        left: 8,
        right: 8,
        bottom: (widget.nearby ? math.max(bottom, 16) : bottom) + 4,
        child: _SheetEntrance(
          child: MapPeekSheet(
            site: selected,
            positionLabel: zonePosition(
                math.max(i, 0), math.max(_zone.length, 1),
                byDistance: _userLat != null),
            onPrev: () => _step(-1),
            onNext: () => _step(1),
            onClose: _deselect,
            onOpenDetail: () => _openDetail(selected),
            onDirections: () => _directions(selected),
            onCall: _callFor(selected),
          ),
        ),
      ));
    }
    return Stack(children: stack);
  }

  NearbyPhase _nearbyPhase() {
    if (_phase == _Phase.error) return NearbyPhase.error;
    if (_loc == _Loc.denied) return NearbyPhase.noLocation;
    if (_phase == _Phase.loading || _loc == _Loc.unknown || _userLat == null) {
      return NearbyPhase.loading;
    }
    return NearbyPhase.ready;
  }

  /// Cabecera, chips, accesorio y estados de la pestaña (tablero TabMapa).
  List<Widget> _tabOverlay(BuildContext context, GmColors gm, double top) {
    final islandLabel = context.watch<NewHomeFiltersCubit>().state.islandLabel;
    final filtered = _filtered;
    final box = _bounds;
    final zone = box == null ? filtered : sitesIn(filtered, box);
    final ready = _phase == _Phase.ready;
    final noLoc = _loc == _Loc.denied;
    final emptyFilters = ready && _filters.any && box != null && zone.isEmpty;
    final present = {for (final s in _sites) s.restaurant.type};
    final chips = mapTypeChips(
      _types,
      active: _filters.typeIds,
      presentTypeIds: _sites.isEmpty ? null : present,
    );

    final out = <Widget>[
      Positioned(
        left: GmSpace.gutter,
        right: GmSpace.gutter,
        top: top + 4,
        child: Row(
          children: [
            Expanded(
              child: MapSearchCapsule(
                controller: _search,
                onChanged: _onSearchChanged,
                onClear: _clearSearch,
              ),
            ),
            const SizedBox(width: 8),
            MapIslandChip(label: islandLabel, onTap: _showIslandSheet),
          ],
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        top: top + 57,
        child: MapChipRow(
          skeleton: _phase == _Phase.loading,
          openNow: _filters.openNow,
          types: chips,
          activeTypes: _filters.typeIds,
          onToggleOpen: _toggleOpen,
          onToggleType: _toggleType,
        ),
      ),
    ];

    // Fila del accesorio: aviso sin ubicación, cargando o «N abiertos de M».
    Widget? accessory;
    if (_phase == _Phase.loading) {
      accessory = MapLoadingCapsule(text: loadingCopy(islandLabel));
    } else if (noLoc) {
      accessory = MapNoLocationBanner(onActivate: _activateLocation);
    } else if (ready &&
        _selectedId == null &&
        !emptyFilters &&
        zone.isNotEmpty) {
      accessory = MapInfoPill(
        identifier: 'mapa-zone-pill',
        text: zoneSummary(zone),
        dot: true,
      );
    }
    if (accessory != null) {
      out.add(Positioned(
        left: GmSpace.gutter,
        right: noLoc && _phase != _Phase.loading ? GmSpace.gutter : 72,
        top: top + 114 + (accessory is MapInfoPill ? 6 : 0),
        child: Align(alignment: Alignment.centerLeft, child: accessory),
      ));
    }
    if (!noLoc) {
      out.add(Positioned(
        right: GmSpace.gutter,
        top: top + 114,
        child: MapRoundButton(
          identifier: 'mapa-center-fab',
          icon: kMapLocateIcon,
          label: 'Centrar en mi ubicación',
          onTap: () {
            if (_userLat != null) {
              _animateTo(LatLng(_userLat!, _userLon!), zoom: 15);
            } else {
              _startLocation();
            }
          },
        ),
      ));
    }

    if (_phase == _Phase.error) {
      out.add(_stateCard(top, _errorCard()));
    } else if (emptyFilters) {
      final copy = emptyWithFiltersCopy(
        filters: _filters,
        singleKind: _singleTypeKind(),
        islandMatches: filtered,
        islandLabel: islandLabel,
        placeName: gmPlaceName,
      );
      out.add(_stateCard(
        top,
        MapStateCard(
          identifier: 'mapa-empty-state',
          art: copy.kind != null
              ? MapTypeTile(copy.kind)
              : const GmSadVolcano(width: 84),
          title: copy.title,
          text: copy.text,
          actions: [
            if (copy.showAllLabel != null)
              GmCapsuleButton(
                identifier: 'mapa-empty-show-all',
                label: copy.showAllLabel!,
                onTap: () =>
                    _fitBounds([for (final s in filtered) (s.lat, s.lon)]),
              ),
            copy.showAllLabel != null
                ? GmSoftCapsuleButton(
                    identifier: 'mapa-clear-filters',
                    label: 'Quitar filtros',
                    onTap: _clearFilters,
                  )
                : GmCapsuleButton(
                    identifier: 'mapa-clear-filters',
                    label: 'Quitar filtros',
                    onTap: _clearFilters,
                  ),
          ],
        ),
      ));
    }
    return out;
  }

  Widget _errorCard() => MapStateCard(
        identifier: 'mapa-error-state',
        alert: true,
        art: const GmSadVolcano(width: 100),
        title: 'No pudimos cargar los sitios',
        text: 'Revisa tu conexión e inténtalo de nuevo. El mapa sigue aquí.',
        actions: [
          GmCapsuleButton(
            identifier: 'mapa-error-retry',
            label: 'Reintentar',
            onTap: () => _load(force: true),
          ),
        ],
      );

  Widget _stateCard(double top, Widget card) => Positioned(
        left: GmSpace.gutter,
        right: GmSpace.gutter,
        top: top + 204,
        child: GmRise(child: card),
      );

  /// Barra, lista, hoja y estados de «Cerca de ti» (tablero MapaEmpujado).
  List<Widget> _nearbyOverlay(BuildContext context, GmColors gm,
      List<MapSite> near, NearbyPhase phase, double top, double bottom) {
    final out = <Widget>[];
    if (_listMode) {
      out.add(Positioned.fill(
        child: ColoredBox(
          color: gm.canvas,
          child: MapNearbyList(
            phase: phase,
            near: near,
            topInset: top + 64,
            onOpen: _openDetail,
            onActivateLocation: _activateLocation,
            onShowIsland: _showWholeIsland,
            onRetry: () => _load(force: true),
          ),
        ),
      ));
      out.add(Positioned(
        left: 0,
        right: 0,
        top: 0,
        height: top + 60,
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [gm.edgeTop0, gm.edgeTop1, gm.edgeFade0],
                stops: const [0, 0.7, 1],
              ),
            ),
          ),
        ),
      ));
    }
    out.add(Positioned(
      left: GmSpace.gutter,
      right: GmSpace.gutter,
      top: top + 2,
      child: MapNearbyToolbar(
        listSelected: _listMode,
        onBack: () => Navigator.of(context).maybePop(),
        onMode: (list) => setState(() {
          _listMode = list;
          if (list) _selectedId = null;
        }),
      ),
    ));
    if (_listMode) return out;

    if (_islandMode) {
      // «Ver toda la isla»: el mapa entero con su hoja de sitio elegido.
      if (_loc == _Loc.denied) {
        out.add(Positioned(
          left: GmSpace.gutter,
          right: GmSpace.gutter,
          top: top + 56,
          child: MapNoLocationBanner(onActivate: _activateLocation),
        ));
      }
      if (_phase == _Phase.loading) {
        out.add(Positioned(
          left: GmSpace.gutter,
          top: top + 56,
          child: MapLoadingCapsule(
              text: loadingCopy(
                  context.watch<NewHomeFiltersCubit>().state.islandLabel)),
        ));
      } else if (_phase == _Phase.error) {
        out.add(_stateCard(top - 60, _errorCard()));
      }
      return out;
    }

    if (phase == NearbyPhase.ready && near.isNotEmpty) {
      out.add(Positioned(
        left: GmSpace.gutter,
        top: top + 56,
        child: MapInfoPill(
          identifier: 'mapa-nearby-range',
          text: nearbyRangeLabel(near.length),
        ),
      ));
    }
    out.add(Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: MapNearbySheet(
        phase: phase,
        near: near,
        carousel: _carousel,
        highlightedId: _nearbyHighlight,
        onOpen: _openDetail,
        onActivateLocation: _activateLocation,
        onShowIsland: _showWholeIsland,
        onRetry: () => _load(force: true),
      ),
    ));
    return out;
  }

  void _showWholeIsland() {
    setState(() {
      _showIsland = true;
      _listMode = false;
      _nearbyHighlight = null;
    });
    _flyToIsland(_islandId);
  }
}

/// La hoja del sitio entra subiendo una vez (asentar, 320 ms); con
/// «reducir movimiento», quieta.
class _SheetEntrance extends StatelessWidget {
  final Widget child;
  const _SheetEntrance({required this.child});

  @override
  Widget build(BuildContext context) {
    if (GmMotion.reduced(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: const Duration(milliseconds: 320),
      curve: GmMotion.settle,
      builder: (_, t, c) =>
          Transform.translate(offset: Offset(0, 40 * t), child: c),
      child: child,
    );
  }
}
