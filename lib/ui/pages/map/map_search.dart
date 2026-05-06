import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/cubit/restaurants/map/restaurant_map_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/map/restaurant_map_state.dart';
import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/data/model/Municipality.dart';
import 'package:guachinches/data/model/Types.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/map/map_search_presenter.dart';
import 'package:guachinches/ui/pages/restaurant_detail/restaurant_detail_screen.dart';
import 'package:http/http.dart';
import 'package:maps_launcher/maps_launcher.dart';

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
  String _municipalityLabel = 'TENERIFE';

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

  @override
  void initState() {
    super.initState();
    remoteRepository = HttpRemoteRepository(Client());
    restaurantsCubit = context.read<RestaurantMapCubit>();
    presenter = MapSearchPresenter(this, remoteRepository, restaurantsCubit);

    presenter.getIsland();
    presenter.getAllTypes();
    presenter.getAllMunicipalities('76ac0bec-4bc1-41a5-bc60-e528e0c12f4d');
    presenter.getAllCategories();

    _driving.isDriving.addListener(_onDrivingChanged);
    _startLiveLocation();
    _buildDotIcons();
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
    final visible = _allRestaurants.where((r) {
      if (r.lat == 0.0 && r.lon == 0.0) return false;
      return bounds.contains(LatLng(r.lat, r.lon));
    }).toList();

    visible.sort((a, b) => _distanceTo(a).compareTo(_distanceTo(b)));

    if (!mounted) return;
    setState(() {
      _visibleRestaurants = visible;
      // Keep selection if still visible, otherwise pick the closest visible.
      if (_selectedRestaurantId == null ||
          !visible.any((r) => r.id == _selectedRestaurantId)) {
        _selectedRestaurantId = visible.isNotEmpty ? visible.first.id : null;
      }
    });

    // Sync the PageView to the selected restaurant.
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
        zoom: 17,
        tilt: 60,
        bearing: _lastHeading,
      );
    }
  }

  Future<void> _animateToUser(
      {double zoom = 15, double tilt = 0, double bearing = 0}) async {
    final controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: currentLocation,
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
      _animateToUser(zoom: 17, tilt: 60, bearing: _lastHeading);
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
    final double scale = selected ? 3.6 : 3.0; // selected slightly bigger
    const double pad = 10;
    const double h = 30;
    const double tailW = 8;
    const double tailH = 6;

    // Decide label text first so we can size to it.
    final ratingText =
        r.avgRating > 0 ? r.avgRating.toStringAsFixed(1) : 'n/d';

    // Layout text to measure required width.
    final ratingPainter = TextPainter(
      text: TextSpan(
        text: ratingText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontFamily: 'SF Pro Display',
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    ratingPainter.layout();

    const double dotSize = 7;
    const double dotGap = 5;
    final double w = pad + dotSize + dotGap + ratingPainter.width + pad;
    final double totalW = w;
    final double totalH = h + tailH;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(scale, scale);

    final bgPaint = Paint()..color = const Color(0xFF1B1D22);
    final pillRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      const Radius.circular(10),
    );

    // Drop shadow
    canvas.drawRRect(
      pillRRect.shift(const Offset(0, 2)),
      Paint()
        ..color = const Color(0x55000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawRRect(pillRRect, bgPaint);

    // Border (highlighted when selected)
    final borderPaint = Paint()
      ..color = selected
          ? GlobalMethods.blueColor
          : Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 2 : 1;
    canvas.drawRRect(pillRRect, borderPaint);

    // Status dot (open/closed)
    final dotColor = r.open
        ? const Color.fromRGBO(149, 220, 0, 1)
        : const Color.fromRGBO(226, 120, 120, 1);
    canvas.drawCircle(
      Offset(pad + dotSize / 2, h / 2),
      dotSize / 2,
      Paint()..color = dotColor,
    );

    // Rating text
    ratingPainter.paint(
      canvas,
      Offset(pad + dotSize + dotGap, (h - ratingPainter.height) / 2),
    );

    // Tail (downward triangle)
    final tailPath = Path()
      ..moveTo(w / 2 - tailW / 2, h - 0.5)
      ..lineTo(w / 2 + tailW / 2, h - 0.5)
      ..lineTo(w / 2, h + tailH)
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
      _cardsPageController.animateToPage(
        idx,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
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
          final nearest = sorted.isNotEmpty ? sorted.first : null;
          final others = sorted.length > 1 ? sorted.sublist(1) : <Restaurant>[];

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: GoogleMap(
                  mapType: MapType.normal,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  compassEnabled: false,
                  zoomControlsEnabled: false,
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

              // ── Header (search + filter chips) ─────────────────────────
              if (!isDriving)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _MapHeader(
                    categories: categories,
                    selectedCategoryId: _quickCategoryId,
                    openActive: _quickOpen,
                    municipalityLabel: _municipalityLabel,
                    searchController: _searchController,
                    onSearchChanged: _onSearchChanged,
                    onClearSearch: _clearSearch,
                    onToggleOpen: _toggleOpenFilter,
                    onToggleCategory: _toggleCategory,
                  ),
                ),

              // ── Drive-mode banner ──────────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: isDriving
                      ? _DriveModeBanner(
                          key: const ValueKey('drive-banner'),
                          onExit: _exitDriveMode,
                        )
                      : const SizedBox.shrink(
                          key: ValueKey('drive-banner-empty')),
                ),
              ),

              // ── Center-on-user FAB ─────────────────────────────────────
              Positioned(
                bottom: isDriving ? 140 : 142,
                right: 16,
                child: FloatingActionButton.small(
                  heroTag: 'centerOnUser',
                  backgroundColor: context.brand.surface,
                  onPressed: () => _animateToUser(
                    zoom: isDriving ? 17 : 15,
                    tilt: isDriving ? 60 : 0,
                    bearing: isDriving ? _lastHeading : 0,
                  ),
                  child: Icon(Icons.my_location,
                      color: context.brand.textPrimary, size: 20),
                ),
              ),

              // ── Bottom: drive-mode pill list OR nearby carousel ────────
              if (isDriving)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _DriveNearbyStrip(
                    nearest: nearest,
                    others: others.take(8).toList(),
                    distanceTo: _distanceTo,
                  ),
                )
              else if (_visibleRestaurants.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 12,
                  height: 116,
                  child: _FloatingCardCarousel(
                    restaurants: _visibleRestaurants,
                    pageController: _cardsPageController,
                    onPageChanged: _onCardPageChanged,
                    distanceTo: _distanceTo,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _applyQuickFilters() {
    restaurantsCubit.getFilterMapRestaurants(
      categories: _quickCategoryId == null ? <String>[] : [_quickCategoryId!],
      municipalities: const <String>[],
      types: const <String>[],
      text: _searchText,
      isOpen: _quickOpen,
      islandId: islandId.isEmpty
          ? '76ac0bec-4bc1-41a5-bc60-e528e0c12f4d'
          : islandId,
    );
  }

  void _toggleOpenFilter() {
    setState(() => _quickOpen = !_quickOpen);
    _applyQuickFilters();
  }

  void _toggleCategory(String id) {
    setState(() => _quickCategoryId = _quickCategoryId == id ? null : id);
    _applyQuickFilters();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      setState(() => _searchText = value);
      _applyQuickFilters();
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() => _searchText = '');
    _applyQuickFilters();
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

  void onPosition(Position p) {
    final speed = p.speed.isFinite && p.speed >= 0 ? p.speed : 0.0;
    _samples.add(speed);
    if (_samples.length > _kDriveSampleWindow) {
      _samples.removeAt(0);
    }
    final med = _median(_samples);
    if (!isDriving.value &&
        _samples.length >= _kDriveMinSamplesToEnter &&
        med > _kEnterDriveSpeed) {
      isDriving.value = true;
    } else if (isDriving.value && med < _kExitDriveSpeed) {
      isDriving.value = false;
    }
  }

  void forceExit() {
    _samples.clear();
    isDriving.value = false;
  }

  void dispose() {
    isDriving.dispose();
  }

  static double _median(List<double> values) {
    if (values.isEmpty) return 0;
    final sorted = [...values]..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[mid];
    return (sorted[mid - 1] + sorted[mid]) / 2.0;
  }
}

// ── Drive-mode banner ───────────────────────────────────────────────────
class _DriveModeBanner extends StatelessWidget {
  final VoidCallback onExit;
  const _DriveModeBanner({Key? key, required this.onExit}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: GlobalMethods.blueColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.directions_car_filled,
                    color: Colors.white, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Modo coche',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'SF Pro Display',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Hemos detectado que vas en el coche. Te mostramos los restaurantes mientras conduces.',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'SF Pro Display',
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onExit,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Salir',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'SF Pro Display',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Drive-mode bottom strip (compact, large-touch) ──────────────────────
class _DriveNearbyStrip extends StatelessWidget {
  final Restaurant? nearest;
  final List<Restaurant> others;
  final double Function(Restaurant) distanceTo;

  const _DriveNearbyStrip({
    Key? key,
    required this.nearest,
    required this.others,
    required this.distanceTo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            GlobalMethods.bgColor,
            GlobalMethods.bgColor.withOpacity(0.0),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (nearest != null) _DriveNearestCard(restaurant: nearest!, distanceMeters: distanceTo(nearest!)),
          if (others.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, i) => _DrivePill(
                  restaurant: others[i],
                  distanceMeters: distanceTo(others[i]),
                ),
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: others.length,
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
  const _DriveNearestCard(
      {Key? key, required this.restaurant, required this.distanceMeters})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: GlobalMethods.bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
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
              children: [
                Text(
                  'MÁS CERCANO',
                  style: TextStyle(
                    color: GlobalMethods.blueColor,
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'SF Pro Display',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${restaurant.open ? "Abierto" : "Cerrado"} · ${_fmtDistance(distanceMeters)} · ${_fmtDriveMinutes(distanceMeters)}',
                  style: TextStyle(
                    color: restaurant.open
                        ? const Color.fromRGBO(149, 220, 0, 1)
                        : const Color.fromRGBO(226, 120, 120, 1),
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
  const _DrivePill(
      {Key? key, required this.restaurant, required this.distanceMeters})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RestaurantDetailScreen(id: restaurant.id),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2D36),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _dotColorForRestaurant(restaurant),
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
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'SF Pro Display',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _fmtDistance(distanceMeters),
              style: const TextStyle(
                color: Colors.white60,
                fontFamily: 'SF Pro Display',
                fontSize: 12,
              ),
            ),
          ],
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
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: _FloatingMapCard(
            restaurant: r,
            distanceMeters: distanceTo(r),
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
    return GestureDetector(
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
                  Text(
                    r.nombre.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.displayHero(
                      size: 16,
                      color: brand.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _StatusLine(restaurant: r, brand: brand),
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
      );
  }
}

/// Línea de estado: "● Cerrado · Candelaria · 12-22€"
class _StatusLine extends StatelessWidget {
  final Restaurant restaurant;
  final BrandColors brand;
  const _StatusLine({required this.restaurant, required this.brand});

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    final statusColor = r.open ? AppColors.laurisilva : AppColors.mojo;
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
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            r.open ? 'Abierto' : 'Cerrado',
            style: AppTextStyles.ui(
              size: 11,
              weight: FontWeight.w700,
              color: statusColor,
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
          color: GlobalMethods.blueColor,
          borderRadius: BorderRadius.circular(big ? 20 : 12),
          boxShadow: [
            BoxShadow(
              color: GlobalMethods.blueColor.withOpacity(0.35),
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

Color _dotColorForRestaurant(Restaurant r) {
  // Stable color from id hash so the dot row reads as a varied palette
  // similar to the screenshot (orange, yellow, green).
  const palette = [
    Color(0xFFE49B4F), // orange
    Color(0xFFE7C34A), // yellow
    Color(0xFF6FCF97), // green
    Color(0xFFE2787B), // salmon
    Color(0xFF56C7E0), // teal
    Color(0xFFB388FF), // violet
  ];
  if (r.id.isEmpty) return palette[0];
  final idx = r.id.codeUnits.fold<int>(0, (a, b) => a + b) % palette.length;
  return palette[idx];
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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar (live filter) with municipality chip on the right.
            Container(
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
                    child: TextField(
                      controller: searchController,
                      onChanged: onSearchChanged,
                      textInputAction: TextInputAction.search,
                      cursorColor: GlobalMethods.blueColor,
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: GlobalMethods.blueColor, width: 1.4),
                    ),
                    child: Text(
                      municipalityLabel,
                      style: TextStyle(
                        color: GlobalMethods.blueColor,
                        fontFamily: 'SF Pro Display',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Quick filter pills row.
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _QuickPill(
                    label: 'ABIERTO AHORA',
                    active: openActive,
                    onTap: onToggleOpen,
                  ),
                  for (final c in categories.take(8)) ...[
                    const SizedBox(width: 8),
                    _QuickPill(
                      label: c.nombre.toUpperCase(),
                      active: selectedCategoryId == c.id,
                      onTap: () => onToggleCategory(c.id),
                    ),
                  ],
                ],
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

  const _QuickPill({
    Key? key,
    required this.label,
    required this.active,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? GlobalMethods.blueColor : brand.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: active ? GlobalMethods.blueColor : brand.border,
            width: 1.2,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: GlobalMethods.blueColor.withOpacity(0.35),
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
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}
