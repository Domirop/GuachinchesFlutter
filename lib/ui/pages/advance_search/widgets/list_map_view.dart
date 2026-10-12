import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/ui/pages/advance_search/list_theme.dart';
import 'package:guachinches/ui/pages/advance_search/widgets/list_cards.dart';
import 'package:guachinches/ui/pages/advance_search/widgets/list_glyph.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show GmPhoto, gmDisplayName, gmPlaceName;
import 'package:guachinches/ui/pages/restaurant_detail/widgets/ficha_sections.dart'
    show gmLightMapStyle;
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// Vista «Mapa» de la lista (tablero ListaMapa): mapa claro como el de la
/// ficha, chinchetas con el glifo del tema y, abajo, el carrusel de
/// tarjetas «En el mapa». Tocar una chincheta lleva a su tarjeta; pasar de
/// tarjeta centra el mapa en su sitio.
class ListMapView extends StatefulWidget {
  final List<ListCardData> items;
  final ListTheme theme;
  final String eyebrow;

  /// Hay algo abierto ahora (punto vivo verde); si no, antetítulo gris.
  final bool live;
  final ValueChanged<ListCardData> onOpen;
  final double topInset;

  const ListMapView({
    super.key,
    required this.items,
    required this.theme,
    required this.eyebrow,
    required this.onOpen,
    this.live = true,
    this.topInset = 0,
  });

  @override
  State<ListMapView> createState() => _ListMapViewState();
}

class _ListMapViewState extends State<ListMapView> {
  final Completer<GoogleMapController> _map = Completer();
  final PageController _pages = PageController(viewportFraction: 0.86);
  int _selected = 0;
  BitmapDescriptor? _pin;
  BitmapDescriptor? _pinOn;
  bool? _pinsDark;

  List<ListCardData> get _located => [
        for (final d in widget.items)
          if (d.restaurant.lat != 0 || d.restaurant.lon != 0) d
      ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dark = GmColors.of(context).isDark;
    if (_pinsDark != dark) {
      _pinsDark = dark;
      _buildPins(dark);
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _buildPins(bool dark) async {
    final dpr =
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    try {
      final normal = await _renderPin(widget.theme, dark, 38, dpr);
      final big = await _renderPin(widget.theme, dark, 54, dpr);
      if (!mounted) return;
      setState(() {
        _pin = normal;
        _pinOn = big;
      });
    } catch (e) {
      // Sin chincheta propia se usa la de Google.
      AppLogger.warn('list-map', 'no se pudo pintar la chincheta: $e');
    }
  }

  /// Chincheta: disco blanco con borde de la tinta del tema y el glifo.
  static Future<BitmapDescriptor> _renderPin(
      ListTheme theme, bool dark, double size, double dpr) async {
    final px = (size * dpr).round();
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final r = px / 2;
    final ink = theme.inkDay;
    c.drawCircle(
        Offset(r, r + px * 0.04),
        r * 0.92,
        Paint()
          ..color = const Color(0x40000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    c.drawCircle(Offset(r, r), r * 0.9, Paint()..color = Colors.white);
    c.drawCircle(
        Offset(r, r),
        r * 0.9,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = px * 0.06
          ..color = ink);
    final svg = ListThemeGlyph.svgFor(theme.glyph, ink);
    if (svg.isNotEmpty) {
      final info = await vg.loadPicture(SvgStringLoader(svg), null);
      final g = px * 0.52;
      c.save();
      c.translate(r - g / 2, r - g / 2);
      c.scale(g / info.size.width, g / info.size.height);
      c.drawPicture(info.picture);
      c.restore();
      info.picture.dispose();
    }
    final img = await rec.endRecording().toImage(px, px);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List(),
        imagePixelRatio: dpr);
  }

  Set<Marker> _markers() {
    final out = <Marker>{};
    final items = _located;
    for (var i = 0; i < items.length; i++) {
      final r = items[i].restaurant;
      final on = i == _selected;
      out.add(Marker(
        markerId: MarkerId(r.id),
        position: LatLng(r.lat, r.lon),
        icon: (on ? _pinOn : _pin) ?? BitmapDescriptor.defaultMarker,
        anchor: const Offset(0.5, 0.5),
        zIndexInt: on ? 2 : 1,
        onTap: () {
          setState(() => _selected = i);
          _pages.animateToPage(i,
              duration: const Duration(milliseconds: 320),
              curve: GmMotion.settle);
        },
      ));
    }
    return out;
  }

  Future<void> _fit() async {
    final items = _located;
    if (items.isEmpty) return;
    final c = await _map.future;
    if (items.length == 1) {
      await c.moveCamera(CameraUpdate.newLatLngZoom(
          LatLng(items.first.restaurant.lat, items.first.restaurant.lon), 14));
      return;
    }
    var minLat = 90.0, maxLat = -90.0, minLon = 180.0, maxLon = -180.0;
    for (final d in items) {
      minLat = math.min(minLat, d.restaurant.lat);
      maxLat = math.max(maxLat, d.restaurant.lat);
      minLon = math.min(minLon, d.restaurant.lon);
      maxLon = math.max(maxLon, d.restaurant.lon);
    }
    await c.moveCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(
            southwest: LatLng(minLat, minLon),
            northeast: LatLng(maxLat, maxLon)),
        56));
  }

  Future<void> _focus(int i) async {
    final items = _located;
    if (i < 0 || i >= items.length) return;
    final c = await _map.future;
    await c.animateCamera(CameraUpdate.newLatLng(
        LatLng(items[i].restaurant.lat, items[i].restaurant.lon)));
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final items = _located;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final first = items.isEmpty
        ? const LatLng(28.29, -16.52)
        : LatLng(items.first.restaurant.lat, items.first.restaurant.lon);

    return Semantics(
      identifier: 'advanced-search-map',
      container: true,
      child: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: gm.mapLand,
              child: GoogleMap(
                key: ValueKey(gm.isDark),
                initialCameraPosition: CameraPosition(target: first, zoom: 10),
                style: gmLightMapStyle(gm),
                markers: _markers(),
                padding: EdgeInsets.only(top: widget.topInset, bottom: 210),
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
                onMapCreated: (c) {
                  if (!_map.isCompleted) _map.complete(c);
                  _fit();
                },
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(0, 8, 0, bottom + 10),
              decoration: BoxDecoration(
                color: gm.canvas,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 24,
                      offset: Offset(0, -6)),
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
                            borderRadius: BorderRadius.circular(GmRadius.pill)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: GmEyebrow(
                        leading:
                            widget.live ? const GmLiveDot(live: true) : null,
                        text: widget.eyebrow,
                        color: widget.live ? gm.greenText : gm.label2,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: Text(
                        items.isEmpty ? 'Nada que situar' : 'En el mapa',
                        style: GmText.title2(color: gm.label),
                      ),
                    ),
                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                        child: Text(
                            'Ningún resultado tiene ubicación en el mapa.',
                            style: GmText.sub(color: gm.label2)),
                      )
                    else
                      SizedBox(
                        height: 124,
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
                                left: i == 0 ? 16 : 6, right: 6),
                            child: _MapCard(
                              data: items[i],
                              theme: widget.theme,
                              onTap: () => widget.onOpen(items[i]),
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
  final ListCardData data;
  final ListTheme theme;
  final VoidCallback onTap;
  const _MapCard(
      {required this.data, required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final r = data.restaurant;
    final muni = gmPlaceName(r.municipio);
    return GmPressable(
      onTap: onTap,
      semanticsLabel: r.nombre,
      child: GmCard(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(GmRadius.photo),
                child: SizedBox(
                  width: 92,
                  height: 108,
                  child: (data.photo == null || data.photo!.isEmpty)
                      ? ListNoPhoto(theme, glyphSize: 34)
                      : GmPhoto(data.photo, decodeWidth: 300),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(gmDisplayName(r.nombre),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GmText.guideTitle(color: gm.label)),
                    Text(
                      [
                        if (data.typeLabel != null) data.typeLabel!,
                        if (muni.isNotEmpty) muni,
                        if (data.distance != null) data.distance!,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GmText.meta(color: gm.label2),
                    ),
                    const SizedBox(height: 2),
                    ListOpenStatus(data.open),
                  ],
                ),
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}
