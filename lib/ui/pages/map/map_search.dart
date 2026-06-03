import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:guachinches/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/cubit/menu/menu_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/map/restaurant_map_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/map/restaurant_map_state.dart';
import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/data/model/Municipality.dart';
import 'package:guachinches/data/model/Types.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/data/cubit/new_home/new_home_filters_cubit.dart';
import 'package:guachinches/data/cubit/new_home/new_home_filters_state.dart';
import 'package:guachinches/ui/pages/map/map_search_presenter.dart';
import 'package:guachinches/ui/pages/map/map_style.dart';
import 'package:guachinches/ui/pages/restaurant_detail/restaurant_detail_screen.dart';
import 'package:guachinches/data/http_client.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:guachinches/ui/pages/new_home/sheets/island_picker_sheet.dart';
import 'package:guachinches/utils/island_key_utils.dart';

const double _markerHueOpen = BitmapDescriptor.hueGreen;
const double _markerHueClosed = BitmapDescriptor.hueRed;

// Driving detection thresholds (m/s)
const double _kEnterDriveSpeed = 5.0; // ~18 km/h
const double _kExitDriveSpeed = 1.5; // ~5.4 km/h
const int _kDriveSampleWindow = 8;
const int _kDriveMinSamplesToEnter = 5;

class MapSearch extends StatefulWidget {
  const MapSearch({Key? key}) : super(key: key);

  @override
  State<MapSearch> createState() => MapSearchState();
}

class MapSearchState extends State<MapSearch> implements MapSearchView {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  LatLng currentLocation = const LatLng(28.4495292, -16.4206765);
  double _lastHeading = 0;
  bool _hasUserLocation = false;

  static const CameraPosition _initialCamera = CameraPosition(
    target: LatLng(28.4495292, -16.4206765),
    zoom: 14.4746,
  );

  Set<Marker> _markers = {};
  bool _firstCameraMove = true;

  late RemoteRepository remoteRepository;
  late RestaurantMapCubit restaurantsCubit;
  late MapSearchPresenter presenter;

  List<ModelCategory> categories = [];
  List<Municipality> municipalities = [];
  List<Types> types = [];
  String islandId = '';

  // Quick filter state (header chips)
  bool _quickOpen = false;
  String? _quickCategoryId;
  String _searchText = '';

  StreamSubscription<Position>? _locationSubscription;
  final _DrivingDetector _driving = _DrivingDetector();

  // Cached list of currently rendered restaurants (whatever the cubit emitted)
  List<Restaurant> _allRestaurants = [];

  // Custom marker bitmap cache, keyed by "${id}_${open}".
  final Map<String, BitmapDescriptor> _markerCache = {};
  final Set<String> _pendingMarkerKeys = {};

  // Compact dot icons (zoom-out fallback)
  BitmapDescriptor? _dotIconOpen;
  BitmapDescriptor? _dotIconClosed;
  double _currentZoom = 14.4746;
  static const double _kBubbleZoomThreshold = 13.0;

  // Visible-restaurants carousel
  List<Restaurant> _visibleRestaurants = [];
  String? _selectedRestaurantId;
  final PageController _cardsPageController =
      PageController(viewportFraction: 0.88);
  bool _suppressNextPageEvent = false;

  // Live search
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  // Index del tab Mapa en NewHomeTabScaffold.
  static const int _kMapTabIndex = 2;
  // Defer-mount: el GoogleMap solo se monta cuando el usuario entra al tab,
  // si no las platform views fallan al renderizar tiles.
  bool _mapMounted = false;

  @override
  void initState() {
    super.initState();
    remoteRepository = HttpRemoteRepository(sharedHttpClient);
    restaurantsCubit = context.read<RestaurantMapCubit>();
    presenter = MapSearchPresenter(this, remoteRepository, restaurantsCubit);

    final filtersState = context.read<NewHomeFiltersCubit>().state;
    islandId = filtersState.islandId;

    presenter.getAllTypes();
    presenter.getAllMunicipalities(islandId);
    presenter.getAllCategories();
    presenter.getAllRestaurants(islandId);

    _driving.isDriving.addListener(_onDrivingChanged);
    _driving.shouldSuggest.addListener(_onDriveSuggested);
    _buildDotIcons();

    // Si abrimos directamente esta pestaña (deep-link / initialIndex), ya
    // estamos visibles → marcamos como montado y arrancamos sensores.
    final menu = context.read<MenuCubit>();
    if (menu.state.selectedIndex == _kMapTabIndex) {
      _mapMounted = true;
      _startLiveLocation();
    }
  }

  bool _suggestSheetOpen = false;

  void _onDriveSuggested() {
    if (!mounted) return;
    if (!_driving.shouldSuggest.value) return;
    if (_suggestSheetOpen) return;
    _suggestSheetOpen = true;
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DriveModeSuggestionSheet(
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
      _suggestSheetOpen = false;
      // If sheet closed via swipe/back without an explicit choice, treat
      // it as a dismissal so we don't re-prompt immediately.
      if (_driving.shouldSuggest.value) {
        _driving.dismissSuggestion();
      }
    });
  }

  Future<void> _buildDotIcons() async {
    final open = await _buildDotBitmap(const Color.fromRGBO(149, 220, 0, 1));
    final closed =
        await _buildDotBitmap(const Color.fromRGBO(226, 120, 120, 1));
    if (!mounted) return;
    setState(() {
      _dotIconOpen = open;
      _dotIconClosed = closed;
    });
  }

  Future<BitmapDescriptor> _buildDotBitmap(Color color) async {
    const double scale = 3.0;
    const double size = 22;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(scale, scale);
    final center = const Offset(size / 2, size / 2);
    // Outer white ring
    canvas.drawCircle(center, size / 2, Paint()..color = Colors.white);
    // Colored fill
    canvas.drawCircle(center, size / 2 - 3, Paint()..color = color);
    // Inner highlight
    canvas.drawCircle(
      center,
      size / 2 - 7,
      Paint()..color = Colors.white.withOpacity(0.25),
    );
    final pic = recorder.endRecording();
    final img = await pic.toImage(
      (size * scale).round(),
      (size * scale).round(),
    );
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      bd!.buffer.asUint8List(),
      imagePixelRatio: scale,
    );
  }

  @override
  void dispose() {
    _driving.isDriving.removeListener(_onDrivingChanged);
    _driving.shouldSuggest.removeListener(_onDriveSuggested);
    _driving.dispose();
    _locationSubscription?.cancel();
    _cardsPageController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  // ── Visible restaurants ────────────────────────────────────────────────
  Future<void> _refreshVisible() async {
    if (!_controller.isCompleted) return;
    final controller = await _controller.future;
    final LatLngBounds bounds;
    try {
      bounds = await controller.getVisibleRegion();
    } catch (_) {
      return;
    }
    final inBounds = _allRestaurants.where((r) {
      if (r.lat == 0.0 && r.lon == 0.0) return false;
      return bounds.contains(LatLng(r.lat, r.lon));
    }).toList();
    final inBoundsIds = inBounds.map((r) => r.id).toSet();

    // Stable order: keep already-shown restaurants in their existing slots
    // (so swiping cards never reshuffles the carousel under the user's
    // finger). Newly-visible restaurants are appended sorted by distance.
    final preserved = _visibleRestaurants
        .where((r) => inBoundsIds.contains(r.id))
        .toList(growable: false);
    final preservedIds = preserved.map((r) => r.id).toSet();
    final newlyVisible = inBounds
        .where((r) => !preservedIds.contains(r.id))
        .toList()
      ..sort((a, b) => _distanceTo(a).compareTo(_distanceTo(b)));

    // First load (or after a hard reset): no stable order to preserve, so
    // sort everything by distance from the user.
    final List<Restaurant> visible;
    if (preserved.isEmpty) {
      visible = newlyVisible;
    } else {
      visible = [...preserved, ...newlyVisible];
    }

    if (!mounted) return;
    setState(() {
      _visibleRestaurants = visible;
      // Keep selection if still visible, otherwise pick the closest visible.
      if (_selectedRestaurantId == null ||
          !inBoundsIds.contains(_selectedRestaurantId)) {
        _selectedRestaurantId = visible.isNotEmpty ? visible.first.id : null;
      }
    });

    // Sync the PageView only if the selected card actually moved to a
    // different index in the new list (rare with stable ordering).
    final idx = _selectedIndex();
    if (idx >= 0 &&
        _cardsPageController.hasClients &&
        (_cardsPageController.page ?? 0).round() != idx) {
      _suppressNextPageEvent = true;
      _cardsPageController.animateToPage(
        idx,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  int _selectedIndex() {
    if (_selectedRestaurantId == null) return -1;
    return _visibleRestaurants
        .indexWhere((r) => r.id == _selectedRestaurantId);
  }

  void _onCardPageChanged(int index) {
    if (_suppressNextPageEvent) {
      _suppressNextPageEvent = false;
      return;
    }
    if (index < 0 || index >= _visibleRestaurants.length) return;
    final r = _visibleRestaurants[index];
    setState(() => _selectedRestaurantId = r.id);
    _animateToRestaurant(r);
  }

  // ── Location ───────────────────────────────────────────────────────────
  Future<void> _startLiveLocation() async {
    if (_locationSubscription != null) return;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen(_onPositionUpdate);
    } catch (e) {
      debugPrint('Error tracking location: $e');
    }
  }

  void _setSensorsActive(bool active) {
    if (active) {
      _startLiveLocation();
    } else {
      _locationSubscription?.cancel();
      _locationSubscription = null;
      _driving.onPaused();
    }
  }

  void _onPositionUpdate(Position position) {
    if (!mounted) return;
    if (position.heading >= 0 && position.speed > 3.0) {
      _lastHeading = position.heading;
    }
    setState(() {
      currentLocation = LatLng(position.latitude, position.longitude);
      _hasUserLocation = true;
    });
    _driving.onPosition(position);

    if (_firstCameraMove) {
      _firstCameraMove = false;
      _animateToUser(zoom: 14.4746, tilt: 0, bearing: 0);
    } else if (_driving.isDriving.value) {
      _animateToUser(
        zoom: 16,
        tilt: 55,
        bearing: _lastHeading,
        chase: true,
      );
    }
  }

  /// Returns a point `meters` ahead of `origin` along `bearingDeg` (great-
  /// circle). Used by the chase camera so the user marker sits near the
  /// bottom of the viewport while the road ahead stays visible.
  static LatLng _projectAhead(
      LatLng origin, double bearingDeg, double meters) {
    const earthR = 6371000.0;
    final br = bearingDeg * math.pi / 180.0;
    final dr = meters / earthR;
    final lat1 = origin.latitude * math.pi / 180.0;
    final lon1 = origin.longitude * math.pi / 180.0;
    final lat2 = math.asin(
      math.sin(lat1) * math.cos(dr) +
          math.cos(lat1) * math.sin(dr) * math.cos(br),
    );
    final lon2 = lon1 +
        math.atan2(
          math.sin(br) * math.sin(dr) * math.cos(lat1),
          math.cos(dr) - math.sin(lat1) * math.sin(lat2),
        );
    return LatLng(lat2 * 180.0 / math.pi, lon2 * 180.0 / math.pi);
  }

  Future<void> _animateToUser({
    double zoom = 15,
    double tilt = 0,
    double bearing = 0,
    bool chase = false,
  }) async {
    final controller = await _controller.future;
    final target = chase
        ? _projectAhead(currentLocation, bearing, 240)
        : currentLocation;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: target,
        zoom: zoom,
        tilt: tilt,
        bearing: bearing,
      ),
    ));
  }

  void _onDrivingChanged() {
    if (!mounted) return;
    HapticFeedback.lightImpact();
    setState(() {});
    if (_driving.isDriving.value) {
      _animateToUser(
        zoom: 16,
        tilt: 55,
        bearing: _lastHeading,
        chase: true,
      );
    } else {
      _animateToUser(zoom: 15, tilt: 0, bearing: 0);
    }
  }

  void _exitDriveMode() {
    _driving.forceExit();
  }

  // ── Markers ────────────────────────────────────────────────────────────
  void _rebuildMarkers(List<Restaurant> restaurants) {
    final useDot = _currentZoom < _kBubbleZoomThreshold;
    final Set<Marker> aux = {};
    for (final r in restaurants) {
      if (r.lat == 0.0 && r.lon == 0.0) continue;
      final isSelected = _selectedRestaurantId == r.id;

      BitmapDescriptor icon;
      Offset anchor;
      if (useDot && !isSelected) {
        icon = (r.open ? _dotIconOpen : _dotIconClosed) ??
            BitmapDescriptor.defaultMarkerWithHue(
              r.open ? _markerHueOpen : _markerHueClosed,
            );
        anchor = const Offset(0.5, 0.5);
      } else {
        final key = _markerKey(r, isSelected);
        final cached = _markerCache[key];
        if (cached == null) {
          _scheduleMarkerBuild(r, isSelected);
        }
        icon = cached ??
            (r.open ? _dotIconOpen : _dotIconClosed) ??
            BitmapDescriptor.defaultMarkerWithHue(
              r.open ? _markerHueOpen : _markerHueClosed,
            );
        anchor = cached != null
            ? const Offset(0.5, 1.0)
            : const Offset(0.5, 0.5);
      }

      aux.add(Marker(
        markerId: MarkerId(r.id),
        position: LatLng(r.lat, r.lon),
        anchor: anchor,
        icon: icon,
        zIndexInt: isSelected ? 10 : 0,
        onTap: () => _onMarkerTapped(r.id),
      ));
    }
    _markers = aux;
  }

  void _onCameraMove(CameraPosition position) {
    final wasDot = _currentZoom < _kBubbleZoomThreshold;
    final isDot = position.zoom < _kBubbleZoomThreshold;
    _currentZoom = position.zoom;
    if (wasDot != isDot && mounted) {
      // Trigger a rebuild so markers swap between dot and bubble.
      setState(() {});
    }
  }

  String _markerKey(Restaurant r, bool selected) =>
      '${r.id}_${r.open ? 1 : 0}_${selected ? 1 : 0}';

  void _scheduleMarkerBuild(Restaurant r, bool selected) {
    final key = _markerKey(r, selected);
    if (_pendingMarkerKeys.contains(key)) return;
    _pendingMarkerKeys.add(key);
    _buildBubbleMarker(r, selected: selected).then((bitmap) {
      _pendingMarkerKeys.remove(key);
      if (!mounted) return;
      _markerCache[key] = bitmap;
      setState(() {});
    }).catchError((e) {
      _pendingMarkerKeys.remove(key);
      debugPrint('marker build failed: $e');
    });
  }

  Future<BitmapDescriptor> _buildBubbleMarker(Restaurant r,
      {bool selected = false}) async {
    // Compact "rating pill" marker (TheFork-style).
    // Selected markers are noticeably larger and use the atlántico/blue
    // brand color so they pop against the cream-toned map.
    final double scale = selected ? 4.2 : 3.0;
    final double pad = selected ? 14 : 10;
    final double h = selected ? 40 : 30;
    final double tailW = selected ? 12 : 8;
    final double tailH = selected ? 9 : 6;
    final double radius = selected ? 14 : 10;
    final double fontSize = selected ? 16 : 13;
    final double dotSize = selected ? 9 : 7;
    final double dotGap = selected ? 7 : 5;

    final bool hasRating = r.avgRating > 0;
    final ratingText =
        hasRating ? r.avgRating.toStringAsFixed(1) : '';

    final ratingPainter = TextPainter(
      text: TextSpan(
        text: ratingText,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontFamily: 'SF Pro Display',
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    ratingPainter.layout();

    final double w = hasRating
        ? pad + dotSize + dotGap + ratingPainter.width + pad
        : pad + dotSize + pad;
    // Halo around selected marker so it stands out on the map. Padding only
    // on top + sides (not below) so the tail tip stays at the bitmap bottom
    // and the marker anchor (0.5, 1.0) lands on the restaurant coords.
    final double haloPad = selected ? 6 : 0;
    final double totalW = w + haloPad * 2;
    final double totalH = h + tailH + haloPad;
    final double originX = haloPad;
    final double originY = haloPad;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(scale, scale);

    final bgPaint = Paint()
      ..color = selected
          ? AppColors.atlantico
          : const Color(0xFF1B1D22);
    final pillRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(originX, originY, w, h),
      Radius.circular(radius),
    );

    // Halo (outer soft ring, selected only).
    if (selected) {
      final haloRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          originX - haloPad,
          originY - haloPad,
          w + haloPad * 2,
          h + haloPad * 2,
        ),
        Radius.circular(radius + haloPad),
      );
      canvas.drawRRect(
        haloRRect,
        Paint()
          ..color = AppColors.atlantico.withOpacity(0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    // Drop shadow.
    canvas.drawRRect(
      pillRRect.shift(Offset(0, selected ? 3 : 2)),
      Paint()
        ..color = Color.fromRGBO(0, 0, 0, selected ? 0.45 : 0.33)
        ..maskFilter = MaskFilter.blur(
            BlurStyle.normal, selected ? 6 : 4),
    );
    canvas.drawRRect(pillRRect, bgPaint);

    // White outline for selected (lifts pill from blurred shadow); subtle
    // dark border for unselected.
    final borderPaint = Paint()
      ..color = selected
          ? Colors.white
          : Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 2.5 : 1;
    canvas.drawRRect(pillRRect, borderPaint);

    // Status dot (open/closed).
    final dotColor = r.open
        ? const Color.fromRGBO(149, 220, 0, 1)
        : const Color.fromRGBO(226, 120, 120, 1);
    canvas.drawCircle(
      Offset(originX + pad + dotSize / 2, originY + h / 2),
      dotSize / 2,
      Paint()..color = dotColor,
    );

    // Rating text.
    if (hasRating) {
      ratingPainter.paint(
        canvas,
        Offset(
          originX + pad + dotSize + dotGap,
          originY + (h - ratingPainter.height) / 2,
        ),
      );
    }

    // Tail (downward triangle).
    final tailCenterX = originX + w / 2;
    final tailTopY = originY + h - 0.5;
    final tailPath = Path()
      ..moveTo(tailCenterX - tailW / 2, tailTopY)
      ..lineTo(tailCenterX + tailW / 2, tailTopY)
      ..lineTo(tailCenterX, originY + h + tailH)
      ..close();
    canvas.drawPath(tailPath, bgPaint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      (totalW * scale).round(),
      (totalH * scale).round(),
    );
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      byteData!.buffer.asUint8List(),
      imagePixelRatio: scale,
    );
  }

  void _onMarkerTapped(String markerId) {
    final r = _allRestaurants.firstWhere(
      (e) => e.id == markerId,
      orElse: () => Restaurant(),
    );
    if (r.id.isEmpty) return;
    setState(() => _selectedRestaurantId = r.id);
    final idx = _visibleRestaurants.indexWhere((e) => e.id == r.id);
    if (idx >= 0 && _cardsPageController.hasClients) {
      _suppressNextPageEvent = true;
      _cardsPageController.jumpToPage(idx);
    }
  }

  Future<void> _animateToRestaurant(Restaurant r) async {
    final controller = await _controller.future;
    // Pan only — keep current zoom so marker tap / card swipe doesn't
    // jump the user closer to the marker.
    controller.animateCamera(
      CameraUpdate.newLatLng(LatLng(r.lat, r.lon)),
    );
  }

  // ── Distance / sort ────────────────────────────────────────────────────
  double _distanceTo(Restaurant r) {
    if (!_hasUserLocation) return double.infinity;
    return Geolocator.distanceBetween(
      currentLocation.latitude,
      currentLocation.longitude,
      r.lat,
      r.lon,
    );
  }

  List<Restaurant> _sortedByDistance(List<Restaurant> source) {
    final list = source
        .where((r) => r.lat != 0.0 || r.lon != 0.0)
        .toList(growable: false);
    if (!_hasUserLocation) return list;
    final sorted = [...list];
    sorted.sort((a, b) => _distanceTo(a).compareTo(_distanceTo(b)));
    return sorted;
  }

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return BlocListener<MenuCubit, MenuState>(
      listenWhen: (prev, curr) => prev.selectedIndex != curr.selectedIndex,
      listener: (_, state) {
        final onMap = state.selectedIndex == _kMapTabIndex;
        // Primera vez que el usuario entra al tab Mapa: montamos la
        // platform view con un frame de delay para evitar tiles en blanco.
        if (onMap && !_mapMounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _mapMounted) return;
            setState(() => _mapMounted = true);
          });
        }
        _setSensorsActive(onMap);
      },
      child: BlocListener<NewHomeFiltersCubit, NewHomeFiltersState>(
        listenWhen: (prev, curr) => prev.islandId != curr.islandId,
        listener: (_, state) => _onIslandChanged(state.islandId),
        child: _buildScaffold(context),
      ),
    );
  }

  void _onIslandChanged(String newIslandId) {
    if (!mounted) return;
    setState(() => islandId = newIslandId);
    presenter.getAllMunicipalities(newIslandId);
    presenter.getAllRestaurants(newIslandId);
  }

  void _showIslandSheet(BuildContext context) {
    IslandPickerSheet.show(
      context: context,
      selectedIslandId: context.read<NewHomeFiltersCubit>().state.islandId,
      onSelect: (island) {
        final key = (island.key != null && island.key!.isNotEmpty)
            ? island.key!
            : islandKeyFromName(island.name);
        context.read<NewHomeFiltersCubit>().selectIsland(
              id: island.id,
              key: key,
              label: island.name,
            );
      },
    );
  }

  Widget _buildScaffold(BuildContext context) {
    if (!_mapMounted) {
      return Scaffold(
        backgroundColor: context.brand.base,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.atlanticoClaro,
              ),
              const SizedBox(height: 14),
              Text(
                'Preparando el mapa…',
                style: AppTextStyles.muted(size: 12),
              ),
            ],
          ),
        ),
      );
    }
    final isDriving = _driving.isDriving.value;

    return Scaffold(
      backgroundColor: context.brand.base,
      body: BlocBuilder<RestaurantMapCubit, RestaurantMapState>(
        builder: (context, state) {
          List<Restaurant> restaurants = _allRestaurants;
          if (state is AllRestaurantMapLoaded) {
            restaurants = state.restaurantResponse.restaurants;
          } else if (state is RestaurantFilterMap) {
            restaurants = state.filtersRestaurants;
          }
          restaurants = _applyClientFilters(restaurants);
          final dataChanged =
              !identical(_allRestaurants, restaurants) &&
                  _allRestaurants.length != restaurants.length;
          _allRestaurants = restaurants;
          _rebuildMarkers(restaurants);

          if (dataChanged) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _refreshVisible());
          }

          final sorted = _sortedByDistance(restaurants);
          final double mapBottomInset =
              isDriving ? 210 : (_visibleRestaurants.isNotEmpty ? 165 : 0);

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: GoogleMap(
                  mapType: MapType.normal,
                  style: kMapStyleLight,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  compassEnabled: false,
                  zoomControlsEnabled: false,
                  padding: EdgeInsets.only(bottom: mapBottomInset),
                  initialCameraPosition: _initialCamera,
                  onMapCreated: (controller) {
                    if (!_controller.isCompleted) {
                      _controller.complete(controller);
                    }
                    // Kick the platform view so tiles render even if the
                    // map mounted while in a non-visible IndexedStack tab.
                    Future.delayed(const Duration(milliseconds: 250), () {
                      if (!mounted) return;
                      controller.animateCamera(
                        CameraUpdate.newCameraPosition(_initialCamera),
                      );
                    });
                  },
                  onCameraMove: _onCameraMove,
                  onCameraIdle: _refreshVisible,
                  markers: _markers,
                ),
              ),

              // ── Empty state (loaded, no results, not in drive mode) ────
              if ((state is AllRestaurantMapLoaded ||
                      state is RestaurantFilterMap) &&
                  restaurants.isEmpty &&
                  !isDriving)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: _buildEmptyState(context),
                  ),
                ),

              // ── Header (search + filter chips) ─────────────────────────
              // In drive mode the search bar is hidden (distraction) and
              // we show a compact chip row at the top with a "Salir" pill.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _MapHeader(
                  categories: categories,
                  selectedCategoryId: _quickCategoryId,
                  openActive: _quickOpen,
                  municipalityLabel: context.read<NewHomeFiltersCubit>().state.islandLabel.toUpperCase(),
                  searchController: _searchController,
                  onSearchChanged: _onSearchChanged,
                  onClearSearch: _clearSearch,
                  onToggleOpen: _toggleOpenFilter,
                  onToggleCategory: _toggleCategory,
                  driveMode: isDriving,
                  onExitDrive: _exitDriveMode,
                  onIslandTap: () => _showIslandSheet(context),
                ),
              ),

              // ── Center-on-user FAB ─────────────────────────────────────
              Positioned(
                bottom: isDriving ? 140 : 142,
                right: 16,
                child: Semantics(
                  identifier: 'mapa-center-fab',
                  button: true,
                  label: 'Centrar en mi ubicación',
                  child: FloatingActionButton.small(
                    heroTag: 'centerOnUser',
                    backgroundColor: context.brand.surface,
                    onPressed: () => _animateToUser(
                      zoom: isDriving ? 16 : 15,
                      tilt: isDriving ? 55 : 0,
                      bearing: isDriving ? _lastHeading : 0,
                      chase: isDriving,
                    ),
                    child: Icon(Icons.my_location,
                        color: context.brand.textPrimary, size: 20),
                  ),
                ),
              ),

              // ── "Activar modo coche" shortcut ──────────────────────────
              // Shown when we detect movement at drive speed but the user is
              // not in drive mode (dismissed the suggestion or exited by
              // accident). Tap to enter drive mode immediately.
              if (!isDriving)
                Positioned(
                  bottom: 142,
                  left: 16,
                  child: ValueListenableBuilder<double>(
                    valueListenable: _driving.currentSpeed,
                    builder: (context, speed, _) {
                      final visible = speed > _kEnterDriveSpeed;
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: visible
                            ? _EnterDrivePill(
                                key: const ValueKey('enter-drive'),
                                onTap: () => _driving.confirmDrive(),
                              )
                            : const SizedBox.shrink(
                                key: ValueKey('enter-drive-empty')),
                      );
                    },
                  ),
                ),

              // ── Refresh FAB (hidden in drive mode) ────────────────────
              if (!isDriving)
                Positioned(
                  bottom: 140,
                  right: 16,
                  child: Semantics(
                    identifier: 'mapa-refresh-fab',
                    button: true,
                    label: 'Refrescar restaurantes',
                    child: FloatingActionButton.small(
                      heroTag: 'refreshMap',
                      backgroundColor: context.brand.surface,
                      onPressed: () async {
                        await remoteRepository.invalidateCache('restaurants:');
                        restaurantsCubit.refresh();
                      },
                      child: Icon(
                        Icons.refresh_rounded,
                        color: context.brand.textPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ),

              // ── Bottom: drive-mode pill list OR nearby carousel ────────
              if (isDriving)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _DriveNearbyStrip(
                    nearby: sorted.take(10).toList(),
                    distanceTo: _distanceTo,
                  ),
                )
              else if (_visibleRestaurants.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 8,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: context.brand.surface,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: context.brand.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            AppL10n.of(context).mapRestaurantsNearby(
                                _visibleRestaurants.length),
                            style: AppTextStyles.ui(
                              size: 12,
                              weight: FontWeight.w700,
                              color: context.brand.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 116,
                        child: _FloatingCardCarousel(
                          restaurants: _visibleRestaurants,
                          pageController: _cardsPageController,
                          onPageChanged: _onCardPageChanged,
                          distanceTo: _distanceTo,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  List<Restaurant> _applyClientFilters(List<Restaurant> source) {
    if (!_quickOpen && _quickCategoryId == null && _searchText.trim().isEmpty) {
      return source;
    }
    final q = _searchText.trim().toLowerCase();
    return source.where((r) {
      if (_quickOpen && !r.open) return false;
      if (_quickCategoryId != null &&
          !r.categoriaRestaurantes.any((c) => c.categoriaId == _quickCategoryId)) {
        return false;
      }
      if (q.isNotEmpty && !r.nombre.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
  }

  void _toggleOpenFilter() {
    setState(() => _quickOpen = !_quickOpen);
  }

  void _toggleCategory(String id) {
    setState(() => _quickCategoryId = _quickCategoryId == id ? null : id);
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      setState(() => _searchText = value);
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() => _searchText = '');
  }

  void _clearAllQuickFilters() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {
      _quickOpen = false;
      _quickCategoryId = null;
      _searchText = '';
    });
  }

  Widget _buildEmptyState(BuildContext context) {
    final brand = context.brand;
    final l10n = AppL10n.of(context);
    final hasFilters =
        _quickOpen || _quickCategoryId != null || _searchText.isNotEmpty;
    return Semantics(
      identifier: 'mapa-empty-state',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: brand.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: brand.border),
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(0, 0, 0, 0.15),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off_outlined,
                  color: brand.textMuted, size: 48),
              const SizedBox(height: 16),
              Text(
                l10n.mapEmptyTitle,
                style: TextStyle(
                  color: brand.textPrimary,
                  fontFamily: 'SF Pro Display',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                hasFilters
                    ? l10n.mapEmptyWithFilters
                    : l10n.mapEmptyNoFilters,
                style: TextStyle(
                  color: brand.textSecondary,
                  fontFamily: 'SF Pro Display',
                  fontSize: 13,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              if (hasFilters) ...[
                const SizedBox(height: 20),
                Semantics(
                  identifier: 'mapa-clear-filters',
                  button: true,
                  child: GestureDetector(
                    onTap: _clearAllQuickFilters,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 13),
                      decoration: BoxDecoration(
                        color: AppColors.atlantico,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        l10n.mapClearFilters,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'SF Pro Display',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── MapSearchView ──────────────────────────────────────────────────────
  @override
  setCategories(List<ModelCategory> categories) {
    setState(() => this.categories = categories);
  }

  @override
  setMunicipalities(List<Municipality> municipalities) {
    setState(() => this.municipalities = municipalities);
  }

  @override
  setTypes(List<Types> types) {
    setState(() => this.types = types);
  }

  @override
  setIsland(String islandId) {
    setState(() => this.islandId = islandId);
    presenter.getAllRestaurants(islandId);
  }
}

// ── Driving detector ────────────────────────────────────────────────────
class _DrivingDetector {
  final List<double> _samples = [];
  final ValueNotifier<bool> isDriving = ValueNotifier<bool>(false);
  // Fires when we detect driving but haven't asked the user yet. The UI
  // listens and shows a confirmation sheet.
  final ValueNotifier<bool> shouldSuggest = ValueNotifier<bool>(false);
  // Live median speed (m/s). Used by the UI to show a "Activar modo coche"
  // shortcut while moving but outside drive mode (e.g. after the user
  // dismissed the suggestion or exited drive mode by mistake).
  final ValueNotifier<double> currentSpeed = ValueNotifier<double>(0);
  Position? _lastPos;
  DateTime? _suppressUntil;

  void onPosition(Position p) {
    // iOS Simulator's `simctl location start` reports CLLocation.speed=0 (or -1)
    // even while the position is moving, so we compute speed from the
    // distance/time delta between successive points and keep whichever value
    // is higher. Real devices keep using the OS-provided speed.
    double computed = 0;
    if (_lastPos != null) {
      final dtMs = p.timestamp
          .difference(_lastPos!.timestamp)
          .inMilliseconds;
      if (dtMs > 0) {
        final meters = Geolocator.distanceBetween(
          _lastPos!.latitude,
          _lastPos!.longitude,
          p.latitude,
          p.longitude,
        );
        computed = meters / (dtMs / 1000.0);
      }
    }
    final raw = p.speed.isFinite && p.speed > 0 ? p.speed : 0.0;
    final speed = raw > computed ? raw : computed;
    _lastPos = p;

    _samples.add(speed);
    if (_samples.length > _kDriveSampleWindow) {
      _samples.removeAt(0);
    }
    final med = _median(_samples);
    currentSpeed.value = med;

    if (isDriving.value) {
      if (med < _kExitDriveSpeed) isDriving.value = false;
      return;
    }
    if (shouldSuggest.value) return; // already asking
    final cooldownActive = _suppressUntil != null &&
        DateTime.now().isBefore(_suppressUntil!);
    if (cooldownActive) return;
    if (_samples.length >= _kDriveMinSamplesToEnter &&
        med > _kEnterDriveSpeed) {
      shouldSuggest.value = true;
    }
  }

  void confirmDrive() {
    shouldSuggest.value = false;
    isDriving.value = true;
  }

  void dismissSuggestion(
      {Duration cooldown = const Duration(minutes: 5)}) {
    shouldSuggest.value = false;
    _suppressUntil = DateTime.now().add(cooldown);
  }

  void forceExit() {
    _samples.clear();
    _lastPos = null;
    _suppressUntil = DateTime.now().add(const Duration(minutes: 5));
    isDriving.value = false;
    shouldSuggest.value = false;
  }

  void onPaused() {
    _samples.clear();
    _lastPos = null;
    currentSpeed.value = 0;
  }

  void dispose() {
    isDriving.dispose();
    shouldSuggest.dispose();
    currentSpeed.dispose();
  }

  static double _median(List<double> values) {
    if (values.isEmpty) return 0;
    final sorted = [...values]..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[mid];
    return (sorted[mid - 1] + sorted[mid]) / 2.0;
  }
}

// ── Drive-mode suggestion sheet ─────────────────────────────────────────
class _DriveModeSuggestionSheet extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onDismiss;
  const _DriveModeSuggestionSheet({
    Key? key,
    required this.onConfirm,
    required this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          decoration: BoxDecoration(
            color: brand.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: brand.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.atlantico.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.directions_car_filled,
                  color: AppColors.atlantico,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '¿Vas en el coche?',
                style: TextStyle(
                  color: brand.textPrimary,
                  fontFamily: 'SF Pro Display',
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Hemos notado que te mueves a buena velocidad. ¿Activamos el modo coche para mostrarte los restaurantes mientras conduces?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: brand.textSecondary,
                  fontFamily: 'SF Pro Display',
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onDismiss,
                      child: Container(
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: brand.borderStrong, width: 1.2),
                        ),
                        child: Text(
                          'Ahora no',
                          style: TextStyle(
                            color: brand.textPrimary,
                            fontFamily: 'SF Pro Display',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onConfirm,
                      child: Container(
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.atlantico,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.atlantico.withOpacity(0.38),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Sí, activar',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'SF Pro Display',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Drive-mode bottom strip (compact, large-touch) ──────────────────────
class _DriveNearbyStrip extends StatefulWidget {
  final List<Restaurant> nearby; // sorted by distance, nearest first
  final double Function(Restaurant) distanceTo;

  const _DriveNearbyStrip({
    Key? key,
    required this.nearby,
    required this.distanceTo,
  }) : super(key: key);

  @override
  State<_DriveNearbyStrip> createState() => _DriveNearbyStripState();
}

class _DriveNearbyStripState extends State<_DriveNearbyStrip> {
  final PageController _pc = PageController();
  final ScrollController _pillsScroll = ScrollController();
  int _index = 0;

  @override
  void didUpdateWidget(covariant _DriveNearbyStrip old) {
    super.didUpdateWidget(old);
    if (_index >= widget.nearby.length) {
      _index = widget.nearby.isEmpty ? 0 : widget.nearby.length - 1;
      if (_pc.hasClients) {
        _pc.jumpToPage(_index);
      }
    }
  }

  @override
  void dispose() {
    _pc.dispose();
    _pillsScroll.dispose();
    super.dispose();
  }

  void _go(int i) {
    if (i < 0 || i >= widget.nearby.length) return;
    _pc.animateToPage(
      i,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.nearby;
    if (list.isEmpty) return const SizedBox.shrink();
    final clamped = _index.clamp(0, list.length - 1);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            context.brand.base,
            context.brand.base.withOpacity(0.0),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Full-width swipeable main card. Paging: swipe horizontally OR
          // tap a pill below.
          SizedBox(
            height: 116,
            child: PageView.builder(
              controller: _pc,
              onPageChanged: (i) => setState(() => _index = i),
              itemCount: list.length,
              itemBuilder: (_, i) => _DriveNearestCard(
                restaurant: list[i],
                distanceMeters: widget.distanceTo(list[i]),
                index: i,
                total: list.length,
              ),
            ),
          ),
          if (list.length > 1) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              child: ListView.separated(
                controller: _pillsScroll,
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, i) => _DrivePill(
                  restaurant: list[i],
                  distanceMeters: widget.distanceTo(list[i]),
                  active: i == clamped,
                  onTap: () => _go(i),
                ),
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: list.length,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DriveNearestCard extends StatelessWidget {
  final Restaurant restaurant;
  final double distanceMeters;
  final int index;
  final int total;
  const _DriveNearestCard({
    Key? key,
    required this.restaurant,
    required this.distanceMeters,
    required this.index,
    required this.total,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final label = index == 0 ? 'MÁS CERCANO' : '${index + 1} DE $total';
    final status = _statusFor(restaurant, distanceMeters);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.brand.elevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.brand.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.atlantico,
                    fontFamily: 'SF Pro Display',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  restaurant.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.brand.textPrimary,
                    fontFamily: 'SF Pro Display',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${status.label} · ${_fmtDistance(distanceMeters)} · ${_fmtDriveMinutes(distanceMeters)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: status.color,
                    fontFamily: 'SF Pro Display',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _IrButton(restaurant: restaurant, big: true),
        ],
      ),
    );
  }
}

class _DrivePill extends StatelessWidget {
  final Restaurant restaurant;
  final double distanceMeters;
  final bool active;
  final VoidCallback onTap;
  const _DrivePill({
    Key? key,
    required this.restaurant,
    required this.distanceMeters,
    required this.active,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final status = _statusFor(restaurant, distanceMeters);
    final unreachable = status.color == _kStatusUrgent;
    final closingSoon = status.color == _kStatusWarning;
    // Trailing label: distance, but swap to time-to-close when urgent or
    // soon so the user gets the most useful info at a glance.
    final close = _closingTimeNow(restaurant);
    String trailing;
    if ((unreachable || closingSoon) && close != null) {
      trailing = 'cierra ${_fmtClock(close)}';
    } else {
      trailing = _fmtDistance(distanceMeters);
    }
    return Opacity(
      opacity: unreachable ? 0.55 : 1.0,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? AppColors.atlantico
                : context.brand.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: active
                  ? AppColors.atlantico
                  : (closingSoon || unreachable)
                      ? status.color.withOpacity(0.6)
                      : context.brand.border,
              width: (closingSoon || unreachable) && !active ? 1.4 : 1,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.atlantico.withOpacity(0.32),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: status.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(
                  restaurant.nombre.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active ? Colors.white : context.brand.textPrimary,
                    fontFamily: 'SF Pro Display',
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w700,
                    letterSpacing: 0.4,
                    decoration: unreachable
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                trailing,
                style: TextStyle(
                  color: active
                      ? Colors.white
                      : (closingSoon || unreachable)
                          ? status.color
                          : context.brand.textMuted,
                  fontFamily: 'SF Pro Display',
                  fontSize: 12,
                  fontWeight: (closingSoon || unreachable)
                      ? FontWeight.w700
                      : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Nearby carousel (non-drive) ─────────────────────────────────────────
/// Floating, full-width landscape card carousel that hovers over the map.
/// One card visible at a time, swipeable to neighbours.
class _FloatingCardCarousel extends StatelessWidget {
  final List<Restaurant> restaurants;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final double Function(Restaurant) distanceTo;

  const _FloatingCardCarousel({
    Key? key,
    required this.restaurants,
    required this.pageController,
    required this.onPageChanged,
    required this.distanceTo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: pageController,
      onPageChanged: onPageChanged,
      itemCount: restaurants.length,
      itemBuilder: (_, i) {
        final r = restaurants[i];
        return Semantics(
          identifier: 'mapa-sheet-card',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _FloatingMapCard(
              restaurant: r,
              distanceMeters: distanceTo(r),
            ),
          ),
        );
      },
    );
  }
}

class _FloatingMapCard extends StatelessWidget {
  final Restaurant restaurant;
  final double distanceMeters;

  const _FloatingMapCard({
    Key? key,
    required this.restaurant,
    required this.distanceMeters,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final r = restaurant;
    return Semantics(
      identifier: 'mapa-card-${r.id}',
      button: true,
      label: r.nombre,
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RestaurantDetailScreen(id: r.id),
          ),
        ),
        child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            // Blur fuerte para que el mapa de fondo se vea suavizado.
            filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              decoration: BoxDecoration(
                // Doble capa: gradiente translúcido cream → cream-soft con highlight
                // arriba simulando luz reflejada (efecto frosted real).
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: brand.textPrimary == AppColors.ink
                      // Light mode (crema)
                      ? const [
                          Color(0xCCFFF8E8),
                          Color(0xB3F2E8D5),
                        ]
                      // Dark mode
                      : const [
                          Color(0xCC1A2535),
                          Color(0x99111820),
                        ],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: brand.textPrimary == AppColors.ink
                      ? Colors.white.withOpacity(0.55)
                      : Colors.white.withOpacity(0.10),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Thumbnail con rating badge superpuesto
            SizedBox(
              width: 92,
              height: 92,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      color: brand.elevated,
                      child: r.mainFoto.isNotEmpty
                          ? Image.network(
                              r.mainFoto,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.image_not_supported,
                                color: brand.textMuted,
                              ),
                            )
                          : Icon(Icons.restaurant, color: brand.textMuted),
                    ),
                  ),
                  if (r.avgRating > 0)
                    Positioned(
                      left: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.72),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: AppColors.sol, size: 12),
                            const SizedBox(width: 3),
                            Text(
                              r.avgRating.toStringAsFixed(1),
                              style: AppTextStyles.ui(
                                size: 11,
                                weight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Distance pill
                  if (distanceMeters.isFinite) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.atlantico.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.place_rounded,
                              color: AppColors.atlantico, size: 12),
                          const SizedBox(width: 3),
                          Text(
                            _fmtDistance(distanceMeters),
                            style: AppTextStyles.ui(
                              size: 11,
                              weight: FontWeight.w700,
                              color: AppColors.atlantico,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          r.nombre.toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.displayHero(
                            size: 16,
                            color: brand.textPrimary,
                          ),
                        ),
                      ),
                      if (r.avgRating > 0)
                        Semantics(
                          identifier: 'mapa-sheet-rating',
                          child: Padding(
                            padding: const EdgeInsets.only(left: 6, top: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: AppColors.sol, size: 13),
                                const SizedBox(width: 2),
                                Text(
                                  r.avgRating.toStringAsFixed(1),
                                  style: AppTextStyles.ui(
                                    size: 13,
                                    weight: FontWeight.w700,
                                    color: brand.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _StatusLine(
                    restaurant: r,
                    brand: brand,
                    distanceMeters: distanceMeters,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Botón IR (abre Google Maps con direcciones)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => MapsLauncher.launchCoordinates(
                  r.lat, r.lon, r.nombre),
              child: Container(
                width: 64,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.atlantico,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.atlantico.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.near_me_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'IR',
                      style: AppTextStyles.chipLabel(
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Línea de estado: "● Abierto hasta 22:30 · Candelaria · 12-22€"
class _StatusLine extends StatelessWidget {
  final Restaurant restaurant;
  final BrandColors brand;
  final double distanceMeters;
  const _StatusLine({
    required this.restaurant,
    required this.brand,
    required this.distanceMeters,
  });

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    final status = _statusFor(r, distanceMeters);
    final priceLabel = (r.minPrice != null && r.maxPrice != null)
        ? '${r.minPrice}–${r.maxPrice}€'
        : null;

    final separator = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Text(
        '·',
        style: AppTextStyles.ui(
          size: 11,
          weight: FontWeight.w700,
          color: brand.textMuted,
        ),
      ),
    );

    return DefaultTextStyle.merge(
      style: AppTextStyles.ui(
        size: 11,
        weight: FontWeight.w500,
        color: brand.textSecondary,
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              status.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.ui(
                size: 11,
                weight: FontWeight.w700,
                color: status.color,
              ),
            ),
          ),
          if (r.municipio.isNotEmpty) ...[
            separator,
            Flexible(
              child: Text(
                r.municipio,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (priceLabel != null) ...[
            separator,
            Text(
              priceLabel,
              style: AppTextStyles.ui(
                size: 11,
                weight: FontWeight.w700,
                color: brand.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _IrButton extends StatelessWidget {
  final Restaurant restaurant;
  final bool big;
  const _IrButton({Key? key, required this.restaurant, this.big = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = big ? 76.0 : 40.0;
    final iconSize = big ? 30.0 : 18.0;
    return GestureDetector(
      onTap: () => MapsLauncher.launchCoordinates(
          restaurant.lat, restaurant.lon, restaurant.nombre),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.atlantico,
          borderRadius: BorderRadius.circular(big ? 20 : 12),
          boxShadow: [
            BoxShadow(
              color: AppColors.atlantico.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.arrow_outward_rounded,
          color: Colors.white,
          size: iconSize,
        ),
      ),
    );
  }
}

// ── Format helpers ──────────────────────────────────────────────────────
String _fmtDistance(double meters) {
  if (!meters.isFinite) return '--';
  if (meters < 950) return '${meters.round()} m';
  return '${(meters / 1000).toStringAsFixed(1)} km';
}

String _fmtDriveMinutes(double meters) {
  if (!meters.isFinite) return '--';
  // 60 km/h ≈ 1000 m/min
  final mins = (meters / 1000).round();
  if (mins < 1) return '<1 min';
  return '$mins min';
}

int _etaMinutes(double meters) {
  if (!meters.isFinite) return 0;
  return (meters / 1000).ceil();
}

/// Parses `Restaurant.googleHorarios` (multi-line "Lunes: 09:00–22:30"
/// strings) and returns the closing time of the slot the restaurant is in
/// right now. Null if the place is closed, has no schedule, or is 24h.
DateTime? _closingTimeNow(Restaurant r) {
  final raw = r.googleHorarios;
  if (raw.isEmpty) return null;
  final lower = raw.toLowerCase();
  if (lower == 'cerrado' || lower == 'sin horario') return null;
  final lines = raw.split('\n');
  final weekday = DateTime.now().toUtc().weekday - 1;
  if (weekday < 0 || weekday >= lines.length) return null;
  final colonIdx = lines[weekday].indexOf(': ');
  if (colonIdx < 0) return null;
  final hours = lines[weekday].substring(colonIdx + 2).trim();
  final hoursLower = hours.toLowerCase();
  if (hoursLower == 'cerrado') return null;
  if (hoursLower.contains('24 horas')) return null;
  final now = DateTime.now();
  for (final range in hours.split(', ')) {
    final hh = range.split('–');
    if (hh.length < 2) continue;
    final s = hh[0].split(':');
    final e = hh[1].split(':');
    if (s.length < 2 || e.length < 2) continue;
    final start = DateTime(now.year, now.month, now.day,
        int.tryParse(s[0]) ?? 0, int.tryParse(s[1]) ?? 0);
    var end = DateTime(now.year, now.month, now.day,
        int.tryParse(e[0]) ?? 0, int.tryParse(e[1]) ?? 0);
    // Range crosses midnight (e.g. 19:00–01:00).
    if (end.isBefore(start)) {
      end = end.add(const Duration(days: 1));
    }
    if (now.isAfter(start) && now.isBefore(end)) return end;
  }
  return null;
}

String _fmtClock(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

class _RestaurantStatus {
  final String label;
  final Color color;
  const _RestaurantStatus(this.label, this.color);
}

const Color _kStatusOpen = Color.fromRGBO(149, 220, 0, 1);
const Color _kStatusClosed = Color.fromRGBO(226, 120, 120, 1);
const Color _kStatusWarning = Color.fromRGBO(245, 183, 0, 1); // sol
const Color _kStatusUrgent = Color.fromRGBO(232, 82, 26, 1); // mojo

/// Combines open/closed + closing time + ETA into a single status descriptor.
/// "Cierra pronto" if the slot ends in <45 min. "Estará cerrado al llegar"
/// when ETA at ~60 km/h doesn't fit before close (or <10 min remaining).
_RestaurantStatus _statusFor(Restaurant r, double distanceMeters) {
  if (!r.open) {
    return const _RestaurantStatus('Cerrado', _kStatusClosed);
  }
  final close = _closingTimeNow(r);
  if (close == null) {
    return const _RestaurantStatus('Abierto', _kStatusOpen);
  }
  final closesIn = close.difference(DateTime.now()).inMinutes;
  final eta = _etaMinutes(distanceMeters);
  final hhmm = _fmtClock(close);

  if (closesIn < 10 || closesIn <= eta) {
    return _RestaurantStatus(
        'Estará cerrado al llegar · cierra $hhmm', _kStatusUrgent);
  }
  if (closesIn < 45) {
    return _RestaurantStatus('Cierra pronto · $hhmm', _kStatusWarning);
  }
  return _RestaurantStatus('Abierto hasta $hhmm', _kStatusOpen);
}

// ── Header (search + chips) widget ──────────────────────────────────────
class _MapHeader extends StatelessWidget {
  final List<ModelCategory> categories;
  final String? selectedCategoryId;
  final bool openActive;
  final String municipalityLabel;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onToggleOpen;
  final ValueChanged<String> onToggleCategory;
  final bool driveMode;
  final VoidCallback onExitDrive;
  final VoidCallback onIslandTap;

  const _MapHeader({
    Key? key,
    required this.categories,
    required this.selectedCategoryId,
    required this.openActive,
    required this.municipalityLabel,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onToggleOpen,
    required this.onToggleCategory,
    this.driveMode = false,
    required this.onExitDrive,
    required this.onIslandTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            brand.base.withOpacity(0.92),
            brand.base.withOpacity(0.0),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar (live filter) with municipality chip on the right.
            // Hidden in drive mode to avoid distracting input.
            if (!driveMode) Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: brand.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: brand.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: brand.textMuted, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Semantics(
                      identifier: 'mapa-search-field',
                      textField: true,
                      label: 'Buscar restaurantes',
                      child: TextField(
                        controller: searchController,
                        onChanged: onSearchChanged,
                        textInputAction: TextInputAction.search,
                        cursorColor: AppColors.atlantico,
                        style: TextStyle(
                          color: brand.textPrimary,
                          fontFamily: 'SF Pro Display',
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                          hintText: 'Buscar restaurantes...',
                          hintStyle: TextStyle(
                            color: brand.textMuted,
                            fontFamily: 'SF Pro Display',
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: searchController,
                    builder: (_, v, __) {
                      if (v.text.isEmpty) return const SizedBox(width: 4);
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onClearSearch,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.close_rounded,
                              color: brand.textMuted, size: 18),
                        ),
                      );
                    },
                  ),
                  Semantics(
                    identifier: 'mapa-island-chip',
                    button: true,
                    label: 'Cambiar de isla',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onIslandTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.atlantico, width: 1.4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              municipalityLabel,
                              style: TextStyle(
                                color: AppColors.atlantico,
                                fontFamily: 'SF Pro Display',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.expand_more,
                                size: 16, color: AppColors.atlantico),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!driveMode) const SizedBox(height: 12),
            // Quick filter pills row. In drive mode it sits at the very top
            // (no search bar above) and is prefixed by a "Salir modo coche"
            // pill so the user can leave drive mode without hunting for it.
            SizedBox(
              height: driveMode ? 44 : 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  if (driveMode) ...[
                    _DriveExitPill(onTap: onExitDrive),
                    const SizedBox(width: 8),
                  ],
                  _QuickPill(
                    identifier: 'mapa-pill-abierto',
                    label: 'ABIERTO AHORA',
                    active: openActive,
                    onTap: onToggleOpen,
                    big: driveMode,
                  ),
                  for (final c in categories.take(8)) ...[
                    const SizedBox(width: 8),
                    _QuickPill(
                      identifier: 'mapa-pill-${c.id}',
                      label: c.nombre.toUpperCase(),
                      active: selectedCategoryId == c.id,
                      onTap: () => onToggleCategory(c.id),
                      big: driveMode,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}

class _EnterDrivePill extends StatelessWidget {
  final VoidCallback onTap;
  const _EnterDrivePill({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.atlantico,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.atlantico.withOpacity(0.42),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.directions_car_filled,
                color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'MODO COCHE',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'SF Pro Display',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriveExitPill extends StatelessWidget {
  final VoidCallback onTap;
  const _DriveExitPill({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.atlantico,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.atlantico.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.directions_car_filled,
                color: Colors.white, size: 18),
            SizedBox(width: 6),
            Text(
              'SALIR MODO COCHE',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'SF Pro Display',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool big;
  final String identifier;

  const _QuickPill({
    Key? key,
    required this.label,
    required this.active,
    required this.onTap,
    required this.identifier,
    this.big = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Semantics(
      identifier: identifier,
      button: true,
      selected: active,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: big ? 20 : 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.atlantico : brand.surface,
          borderRadius: BorderRadius.circular(big ? 22 : 22),
          border: Border.all(
            color: active ? AppColors.atlantico : brand.border,
            width: 1.2,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.atlantico.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : const [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : brand.textPrimary,
            fontFamily: 'SF Pro Display',
            fontSize: big ? 13 : 12,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      ),
    ),
  );
  }
}
