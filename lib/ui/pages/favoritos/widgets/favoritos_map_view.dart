import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/advance_search/list_logic.dart'
    show listDisplayRating;
import 'package:guachinches/ui/pages/advance_search/map_clusters.dart';
import 'package:guachinches/ui/pages/favoritos/favoritos_logic.dart';
import 'package:guachinches/ui/pages/favoritos/widgets/favoritos_widgets.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show GmPhoto, gmDisplayName;
import 'package:guachinches/ui/pages/restaurant_detail/widgets/ficha_sections.dart'
    show gmLightMapStyle;
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:guachinches/utils/open_state.dart';

/// Vista «Mapa» de Guardados (tablero Guardados · mapa): mapa claro de la
/// ficha, chinchetas de corazón (la elegida, grande), burbuja roja cuando se
/// pisan y, abajo, la hoja «N guardados» con el carrusel de tarjetas.
class FavoritosMapView extends StatefulWidget {
  final List<Restaurant> items;
  final ValueChanged<Restaurant> onOpen;
  final ValueChanged<Restaurant> onRemove;
  final double topInset;

  const FavoritosMapView({
    super.key,
    required this.items,
    required this.onOpen,
    required this.onRemove,
    this.topInset = 0,
  });

  @override
  State<FavoritosMapView> createState() => _FavoritosMapViewState();
}

class _FavoritosMapViewState extends State<FavoritosMapView> {
  final Completer<GoogleMapController> _map = Completer();
  final PageController _pages = PageController(viewportFraction: 0.84);
  int _selected = 0;
  BitmapDescriptor? _pin;
  BitmapDescriptor? _pinOn;
  final Map<int, BitmapDescriptor> _bubbles = {};
  double _zoom = 10;
  double? _pendingZoom;

  List<Restaurant> get _located => [
        for (final r in widget.items)
          if (favoritosHasLocation(r)) r
      ];

  @override
  void initState() {
    super.initState();
    _buildPins();
  }

  @override
  void didUpdateWidget(covariant FavoritosMapView old) {
    super.didUpdateWidget(old);
    final n = _located.length;
    if (_selected >= n) _selected = n == 0 ? 0 : n - 1;
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  double get _dpr =>
      WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;

  Future<void> _buildPins() async {
    try {
      final normal = await _renderPin(34, _dpr);
      final big = await _renderPin(52, _dpr);
      if (!mounted) return;
      setState(() {
        _pin = normal;
        _pinOn = big;
      });
    } catch (e) {
      // Sin chincheta propia se usa la de Google.
      AppLogger.warn('favoritos-map', 'no se pudo pintar la chincheta: $e');
    }
  }

  /// Disco blanco con aro rojo y corazón lleno.
  static Future<BitmapDescriptor> _renderPin(double size, double dpr) async {
    final px = (size * dpr).round();
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final r = px / 2;
    c.drawCircle(
        Offset(r, r + px * 0.05),
        r * 0.9,
        Paint()
          ..color = const Color(0x40000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    c.drawCircle(Offset(r, r), r * 0.86, Paint()..color = Colors.white);
    c.drawCircle(
        Offset(r, r),
        r * 0.86,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = px * 0.07
          ..color = GmColors.heart);
    final svg = GmIcons.heartFilled.replaceAll('currentColor', '#FF3B5C');
    final info = await vg.loadPicture(SvgStringLoader(svg), null);
    final g = px * 0.5;
    c.save();
    c.translate(r - g / 2, r - g / 2 + px * 0.02);
    c.scale(g / info.size.width, g / info.size.height);
    c.drawPicture(info.picture);
    c.restore();
    info.picture.dispose();
    final img = await rec.endRecording().toImage(px, px);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List(),
        imagePixelRatio: dpr);
  }

  /// Burbuja roja con el número de guardados que se pisan.
  static Future<BitmapDescriptor> _renderBubble(int n, double dpr) async {
    final px = (40 * dpr).round();
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final r = px / 2;
    c.drawCircle(
        Offset(r, r + px * 0.04),
        r * 0.92,
        Paint()
          ..color = const Color(0x40000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    c.drawCircle(Offset(r, r), r * 0.9, Paint()..color = Colors.white);
    c.drawCircle(Offset(r, r), r * 0.76, Paint()..color = GmColors.badgeRed);
    final tp = TextPainter(
      text: TextSpan(
        text: '$n',
        style: TextStyle(
            fontSize: px * 0.4,
            fontWeight: FontWeight.w800,
            color: Colors.white),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(r - tp.width / 2, r - tp.height / 2));
    final img = await rec.endRecording().toImage(px, px);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List(),
        imagePixelRatio: dpr);
  }

  Future<void> _buildBubble(int n) async {
    if (_bubbles.containsKey(n)) return;
    try {
      final icon = await _renderBubble(n, _dpr);
      if (!mounted) return;
      setState(() => _bubbles[n] = icon);
    } catch (e) {
      AppLogger.warn('favoritos-map', 'no se pudo pintar la burbuja: $e');
    }
  }

  Set<Marker> _markers() {
    final items = _located;
    final out = <Marker>{};
    final clusters = mapClusters(
      [for (final r in items) (r.lat, r.lon)],
      _zoom,
      radius: 38,
    );
    for (final cl in clusters) {
      final members = [
        for (final m in cl.members)
          if (m != _selected || cl.members.length == 1) m
      ];
      if (cl.members.contains(_selected) && cl.members.length > 1) {
        out.add(_single(items, _selected));
      }
      if (members.length == 1) {
        out.add(_single(items, members.first));
        continue;
      }
      if (members.isEmpty) continue;
      final n = members.length;
      final icon = _bubbles[n];
      if (icon == null) _buildBubble(n);
      final lat = members.map((m) => items[m].lat).reduce((a, b) => a + b) / n;
      final lon = members.map((m) => items[m].lon).reduce((a, b) => a + b) / n;
      out.add(Marker(
        markerId: MarkerId('cluster-${items[members.first].id}-$n'),
        position: LatLng(lat, lon),
        icon: icon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
        anchor: const Offset(0.5, 0.5),
        zIndexInt: 1,
        onTap: () => _zoomInto([for (final m in members) items[m]]),
      ));
    }
    return out;
  }

  Marker _single(List<Restaurant> items, int i) {
    final r = items[i];
    final on = i == _selected;
    return Marker(
      markerId: MarkerId(r.id),
      position: LatLng(r.lat, r.lon),
      icon: (on ? _pinOn : _pin) ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
      anchor: const Offset(0.5, 0.5),
      zIndexInt: on ? 3 : 2,
      onTap: () {
        setState(() => _selected = i);
        if (_pages.hasClients) {
          _pages.animateToPage(i,
              duration:
                  Duration(milliseconds: GmMotion.reduced(context) ? 0 : 320),
              curve: GmMotion.settle);
        }
      },
    );
  }

  LatLngBounds? _bounds(List<Restaurant> group) {
    if (group.isEmpty) return null;
    var minLat = 90.0, maxLat = -90.0, minLon = 180.0, maxLon = -180.0;
    for (final r in group) {
      minLat = math.min(minLat, r.lat);
      maxLat = math.max(maxLat, r.lat);
      minLon = math.min(minLon, r.lon);
      maxLon = math.max(maxLon, r.lon);
    }
    return LatLngBounds(
        southwest: LatLng(minLat, minLon), northeast: LatLng(maxLat, maxLon));
  }

  Future<void> _zoomInto(List<Restaurant> group) async {
    final c = await _map.future;
    final b = _bounds(group);
    if (b == null) return;
    if ((b.northeast.latitude - b.southwest.latitude).abs() < 1e-5 &&
        (b.northeast.longitude - b.southwest.longitude).abs() < 1e-5) {
      await c.animateCamera(
          CameraUpdate.newLatLngZoom(b.southwest, math.min(_zoom + 3, 19)));
      return;
    }
    await c.animateCamera(CameraUpdate.newLatLngBounds(b, 72));
  }

  Future<void> _fit() async {
    final items = _located;
    if (items.isEmpty) return;
    final c = await _map.future;
    if (items.length == 1) {
      await c.moveCamera(CameraUpdate.newLatLngZoom(
          LatLng(items.first.lat, items.first.lon), 14));
      return;
    }
    await c.moveCamera(CameraUpdate.newLatLngBounds(_bounds(items)!, 56));
  }

  Future<void> _focus(int i) async {
    final items = _located;
    if (i < 0 || i >= items.length) return;
    final c = await _map.future;
    await c.animateCamera(
        CameraUpdate.newLatLng(LatLng(items[i].lat, items[i].lon)));
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final items = _located;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final now = DateTime.now();
    final open =
        widget.items.where((r) => restaurantOpenState(r, now).isOpen).length;
    final first = items.isEmpty
        ? const LatLng(28.29, -16.52)
        : LatLng(items.first.lat, items.first.lon);

    return Semantics(
      identifier: 'favoritos-map',
      container: true,
      child: Stack(
        children: [
          Positioned.fill(
            child: Semantics(
              label: 'Mapa de tus ${widget.items.length} guardados',
              child: ColoredBox(
                color: gm.mapLand,
                child: GoogleMap(
                  key: ValueKey(gm.isDark),
                  initialCameraPosition:
                      CameraPosition(target: first, zoom: 10),
                  style: gmLightMapStyle(gm),
                  markers: _markers(),
                  padding: EdgeInsets.only(top: widget.topInset, bottom: 220),
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: false,
                  onMapCreated: (c) {
                    if (!_map.isCompleted) _map.complete(c);
                    _fit();
                  },
                  onCameraMove: (p) => _pendingZoom = p.zoom,
                  onCameraIdle: () {
                    final z = _pendingZoom;
                    if (z != null && (z - _zoom).abs() > 0.05) {
                      setState(() => _zoom = z);
                    }
                  },
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: widget.topInset + 30,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [gm.edgeTop0, gm.edgeFade0],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(0, 7, 0, bottom + 12),
              decoration: BoxDecoration(
                color: gm.canvas,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x24000000),
                      blurRadius: 30,
                      offset: Offset(0, -10)),
                ],
              ),
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.3,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 5,
                        decoration: BoxDecoration(
                            color: gm.sep,
                            borderRadius: BorderRadius.circular(3)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 13, 20, 0),
                      child: GmEyebrow(
                        leading: open > 0 ? const GmLiveDot() : null,
                        text: favoritosOpenEyebrow(open),
                        color: open > 0 ? gm.greenText : gm.label2,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Semantics(
                        header: true,
                        child: Text(favoritosMapTitle(widget.items.length),
                            style: GmText.title2(color: gm.label)),
                      ),
                    ),
                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                        child: Text(
                            'Ninguno de tus guardados tiene ubicación en el mapa.',
                            style: GmText.sub(color: gm.label2)),
                      )
                    else
                      SizedBox(
                        height: 100,
                        child: PageView.builder(
                          controller: _pages,
                          padEnds: false,
                          itemCount: items.length,
                          onPageChanged: (i) {
                            setState(() => _selected = i);
                            _focus(i);
                          },
                          itemBuilder: (_, i) => Padding(
                            padding: EdgeInsets.only(
                                left: i == 0 ? 16 : 5, right: 5),
                            child: _MapCard(
                              restaurant: items[i],
                              now: now,
                              onTap: () => widget.onOpen(items[i]),
                              onRemove: () => widget.onRemove(items[i]),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  final Restaurant restaurant;
  final DateTime now;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _MapCard({
    required this.restaurant,
    required this.now,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final r = restaurant;
    final name = gmDisplayName(r.nombre);
    final meta = favoritosMeta(r);
    final rating = listDisplayRating(r);
    return GmPressable(
      onTap: onTap,
      semanticsIdentifier: 'favoritos-map-card-${r.id}',
      semanticsLabel: name,
      child: GmCard(
        padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                  width: 80,
                  height: 80,
                  child: GmPhoto(r.mainFoto, decodeWidth: 240)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GmText.body17(color: gm.label, w: FontWeight.w600)
                          .copyWith(height: 22 / 17)),
                  if (meta.isNotEmpty || rating > 0)
                    Text.rich(
                      TextSpan(children: [
                        if (meta.isNotEmpty) TextSpan(text: meta),
                        if (meta.isNotEmpty && rating > 0)
                          const TextSpan(text: ' · '),
                        if (rating > 0) ...[
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: GmIcon(GmIcons.star,
                                size: 12, color: GmColors.star),
                          ),
                          TextSpan(
                            text: ' ${GmRating.format(rating)}',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, color: gm.label),
                          ),
                        ],
                      ]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GmText.meta(color: gm.label2),
                    ),
                  const SizedBox(height: 2),
                  FavOpenLine(restaurantOpenState(r, now)),
                ],
              ),
            ),
            FavRemoveHeart(
              restaurantId: r.id,
              name: name,
              onRemove: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
