import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guachinches/ui/pages/advance_search/list_logic.dart'
    show listOpenLabel;
import 'package:guachinches/ui/pages/advance_search/map_clusters.dart';
import 'package:guachinches/ui/pages/map/map_logic.dart';
import 'package:guachinches/ui/pages/map/map_pins.dart';
import 'package:guachinches/ui/pages/map/map_style.dart';
import 'package:guachinches/ui/pages/map/widgets/map_chrome.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show gmDisplayName, gmPlaceName;
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:guachinches/utils/open_state.dart';

/// Datos vivos que el mapa le pasa al modo coche: posición, rumbo y sitios
/// (con su distancia ya calculada). [active] pasa a `false` cuando el
/// detector ve que el coche se ha parado: la pantalla se cierra sola.
class MapDriveController extends ChangeNotifier {
  double? lat;
  double? lon;
  double heading = 0;
  List<MapSite> sites = const [];
  final ValueNotifier<bool> active = ValueNotifier(true);

  void update(
      {double? lat, double? lon, double? heading, List<MapSite>? sites}) {
    if (lat != null) this.lat = lat;
    if (lon != null) this.lon = lon;
    if (heading != null) this.heading = heading;
    if (sites != null) this.sites = sites;
    notifyListeners();
  }

  @override
  void dispose() {
    active.dispose();
    super.dispose();
  }
}

/// Hoja «¿Vas en coche?» (tablero MapaCoche · sugerencia).
class MapDriveSuggestionSheet extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onDismiss;
  const MapDriveSuggestionSheet(
      {super.key, required this.onConfirm, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Semantics(
      identifier: 'mapa-drive-suggest',
      container: true,
      child: Container(
        decoration: BoxDecoration(
          color: gm.canvas,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x2E000000),
                offset: Offset(0, -10),
                blurRadius: 30),
          ],
        ),
        padding: EdgeInsets.fromLTRB(24, 8, 24, math.max(bottom, 16) + 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                  color: gm.sep, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(height: 17),
            Container(
              width: 64,
              height: 64,
              decoration:
                  BoxDecoration(color: gm.accentSoft, shape: BoxShape.circle),
              child: Center(
                  child: GmIcon(GmIcons.car, size: 34, color: gm.accent)),
            ),
            const SizedBox(height: 16),
            Text('¿Vas en coche?',
                textAlign: TextAlign.center,
                style: GmText.title2(color: gm.label)),
            const SizedBox(height: 8),
            Text(
              'El modo coche enseña en grande los sitios abiertos cerca de '
              'ti, con la distancia y los minutos para llegar.',
              textAlign: TextAlign.center,
              style: GmText.body17(color: gm.label2),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GmIcon(GmIcons.person, size: 14, color: gm.label2),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Si conduces, que lo toque quien va de copiloto.',
                    textAlign: TextAlign.center,
                    style: GmText.meta(color: gm.label2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: GmCapsuleButton(
                identifier: 'mapa-drive-suggest-accept',
                label: 'Activar modo coche',
                height: 52,
                fontSize: 17,
                onTap: onConfirm,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: GmSoftCapsuleButton(
                identifier: 'mapa-drive-suggest-dismiss',
                label: 'Ahora no',
                height: 52,
                fontSize: 17,
                onTap: onDismiss,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modo coche a pantalla completa (tablero MapaCoche): se empuja sobre la
/// barra de pestañas para esconderla. Solo sitios abiertos o sin horario
/// confirmado, tarjetas grandes con «Ir», «Estará cerrado al llegar» y
/// «Salir del modo coche».
class MapDriveScreen extends StatefulWidget {
  final MapDriveController controller;
  final VoidCallback onExit;
  final void Function(MapSite site) onGo;

  const MapDriveScreen({
    super.key,
    required this.controller,
    required this.onExit,
    required this.onGo,
  });

  @override
  State<MapDriveScreen> createState() => _MapDriveScreenState();
}

class _MapDriveScreenState extends State<MapDriveScreen> {
  final Completer<GoogleMapController> _map = Completer();
  final PageController _pages = PageController(viewportFraction: 0.86);
  late final MapPinFactory _pins = MapPinFactory(onReady: _repaint);
  int _focus = 0;
  double _zoom = 16;
  bool _closing = false;

  MapDriveController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onUpdate);
    _c.active.addListener(_onActive);
  }

  @override
  void dispose() {
    _c.removeListener(_onUpdate);
    _c.active.removeListener(_onActive);
    _pins.dispose();
    _pages.dispose();
    super.dispose();
  }

  void _repaint() {
    if (mounted) setState(() {});
  }

  void _onActive() {
    if (!_c.active.value && !_closing && mounted) {
      _closing = true;
      Navigator.of(context).maybePop();
    }
  }

  void _onUpdate() {
    if (!mounted) return;
    setState(() {});
    _follow();
  }

  Future<void> _follow() async {
    final lat = _c.lat, lon = _c.lon;
    if (lat == null || lon == null || !_map.isCompleted) return;
    final c = await _map.future;
    final (tLat, tLon) = projectAhead(lat, lon, _c.heading, 240);
    await c.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: LatLng(tLat, tLon),
      zoom: 16,
      tilt: 55,
      bearing: _c.heading,
    )));
  }

  Set<Marker> _markers(List<MapSite> cands, bool dark) {
    final out = <Marker>{};
    if (cands.isEmpty) return out;
    final focus = _focus.clamp(0, cands.length - 1);
    final clusters =
        mapClusters([for (final s in cands) (s.lat, s.lon)], _zoom, radius: 50);
    for (final cl in clusters) {
      final members = [
        for (final m in cl.members)
          if (m != focus) m
      ];
      if (members.isEmpty) continue;
      if (members.length == 1) {
        final s = cands[members.first];
        final b = _pins.pin(s.kind, MapPinVariant.normal, dark: dark, size: 44);
        if (b == null) continue;
        out.add(Marker(
          markerId: MarkerId(s.id),
          position: LatLng(s.lat, s.lon),
          icon: b.icon,
          anchor: b.anchor,
          zIndexInt: 1,
          onTap: () => _goToCard(members.first),
        ));
        continue;
      }
      final b = _pins.cluster(members.length, dark: dark, size: 46);
      if (b == null) continue;
      final lat = members.map((m) => cands[m].lat).reduce((a, b) => a + b) /
          members.length;
      final lon = members.map((m) => cands[m].lon).reduce((a, b) => a + b) /
          members.length;
      out.add(Marker(
        markerId: MarkerId('drive-cluster-${cands[members.first].id}'),
        position: LatLng(lat, lon),
        icon: b.icon,
        anchor: b.anchor,
        onTap: () => _goToCard(members.first),
      ));
    }
    final s = cands[focus];
    final b = _pins.pin(s.kind, MapPinVariant.selected,
        dark: dark, label: gmDisplayName(s.restaurant.nombre));
    if (b != null) {
      out.add(Marker(
        markerId: MarkerId(s.id),
        position: LatLng(s.lat, s.lon),
        icon: b.icon,
        anchor: b.anchor,
        zIndexInt: 5,
      ));
    }
    return out;
  }

  void _goToCard(int i) {
    setState(() => _focus = i);
    if (_pages.hasClients) {
      _pages.animateToPage(i,
          duration: const Duration(milliseconds: 320), curve: GmMotion.settle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final media = MediaQuery.of(context);
    final cands = driveCandidates(_c.sites);
    final lat = _c.lat ?? 28.45, lon = _c.lon ?? -16.44;
    final cardW = math.min(330.0, media.size.width - 48);

    return Scaffold(
      backgroundColor: gm.mapLand,
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                  target: LatLng(lat, lon),
                  zoom: 16,
                  tilt: 55,
                  bearing: _c.heading),
              style: mapStyleFor(gm),
              markers: _markers(cands, gm.isDark),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              buildingsEnabled: false,
              indoorViewEnabled: false,
              padding:
                  EdgeInsets.only(top: media.padding.top + 120, bottom: 230),
              onMapCreated: (c) {
                if (!_map.isCompleted) _map.complete(c);
                _follow();
              },
              onCameraMove: (p) => _zoom = p.zoom,
            ),
          ),
          // Velo superior para leer los controles sobre el mapa.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: media.padding.top + 150,
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
          Positioned(
            left: GmSpace.gutter,
            right: GmSpace.gutter,
            top: media.padding.top + 2,
            child: MapGlassCapsule(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: gm.accentSoft, shape: BoxShape.circle),
                    child: Center(
                        child: GmIcon(GmIcons.car, size: 24, color: gm.accent)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Modo coche',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GmText.guideTitle(color: gm.glassInk)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  GmSoftCapsuleButton(
                    identifier: 'mapa-drive-exit',
                    label: 'Salir del modo coche',
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    onTap: widget.onExit,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: GmSpace.gutter,
            top: media.padding.top + 74,
            right: 90,
            child: Align(
              alignment: Alignment.centerLeft,
              child: MapInfoPill(
                identifier: 'mapa-drive-count',
                text: driveOpenCount(cands),
                dot: true,
                height: 44,
                fontSize: 16,
              ),
            ),
          ),
          Positioned(
            right: GmSpace.gutter,
            top: media.padding.top + 70,
            child: MapRoundButton(
              identifier: 'mapa-drive-center',
              icon: kMapLocateIcon,
              label: 'Centrar en mi ubicación',
              size: 56,
              iconSize: 24,
              onTap: _follow,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: math.max(media.padding.bottom, 12) + 8,
            child: cands.isEmpty
                ? Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
                    child: _DriveEmptyCard(),
                  )
                : SizedBox(
                    height: 196,
                    child: PageView.builder(
                      controller: _pages,
                      padEnds: false,
                      itemCount: cands.length,
                      onPageChanged: (i) => setState(() => _focus = i),
                      itemBuilder: (_, i) => Padding(
                        padding: EdgeInsets.only(
                            left: i == 0 ? GmSpace.gutter : 6, right: 6),
                        child: SizedBox(
                          width: cardW,
                          child: MapDriveCard(
                            site: cands[i],
                            eyebrow: driveCardEyebrow(i, cands.length),
                            onGo: () => widget.onGo(cands[i]),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DriveEmptyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: gm.card,
        borderRadius: BorderRadius.circular(28),
        boxShadow: gm.shadow2,
      ),
      child: Text(
        'Nada abierto cerca ahora. Seguimos mirando mientras conduces.',
        style: GmText.body17(color: gm.label, w: FontWeight.w600),
      ),
    );
  }
}

/// Tarjeta grande del modo coche: loseta del tipo, nombre 22, estado 17 y
/// «1,7 km · 4 min» + «Ir».
class MapDriveCard extends StatelessWidget {
  final MapSite site;
  final String eyebrow;
  final VoidCallback onGo;

  const MapDriveCard({
    super.key,
    required this.site,
    required this.eyebrow,
    required this.onGo,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final r = site.restaurant;
    final name = gmDisplayName(r.nombre);
    final meters = site.meters ?? 0;
    final eta = driveEtaMinutes(meters);
    final st = driveStatus(site.open, eta);
    final meta =
        site.typeLabel.isNotEmpty ? site.typeLabel : gmPlaceName(r.municipio);

    Widget status;
    String? tail;
    if (st.closedOnArrival) {
      status = _statusRow(GmIcon(GmIcons.clock, size: 16, color: gm.closedText),
          'Estará cerrado al llegar', gm.closedText);
      if (st.closesAt != null) tail = 'Cierra a las ${st.closesAt}';
    } else {
      final l = listOpenLabel(site.open);
      final Color c;
      final Widget mark;
      switch (l.kind) {
        case OpenKind.open:
          c = gm.greenText;
          mark = GmLiveDot(color: gm.green, size: 9);
        case OpenKind.closingSoon:
          c = gm.warnText;
          mark = GmLiveDot(color: gm.warnText, size: 9);
        case OpenKind.closed:
          c = gm.closedText;
          mark = GmLiveDot(color: gm.closedText, size: 9);
        case OpenKind.unknown:
          c = gm.label2;
          mark = GmIcon(GmIcons.clock, size: 16, color: gm.label2);
      }
      status = _statusRow(mark, l.text, c);
    }

    return Semantics(
      identifier: 'mapa-drive-card-${r.id}',
      container: true,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.2,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: gm.card,
            borderRadius: BorderRadius.circular(28),
            boxShadow: gm.shadow2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  MapTypeTile(site.kind, size: 52, glyph: 32, radius: 16),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meta.isEmpty ? eyebrow : '$eyebrow · $meta',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GmText.eyebrow(color: gm.label2),
                        ),
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 22,
                            height: 27 / 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.45,
                            color: gm.label,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  status,
                  if (tail != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 23),
                      child: Text(tail, style: GmText.body(color: gm.label2)),
                    ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: mapKm(meters),
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: gm.label),
                        children: [
                          TextSpan(
                            text: ' · $eta min',
                            style: TextStyle(
                                fontWeight: FontWeight.w500, color: gm.label2),
                          ),
                        ],
                      ),
                      style: const TextStyle(fontSize: 17, height: 22 / 17),
                    ),
                  ),
                  Semantics(
                    label: 'Cómo llegar a $name',
                    child: GmCapsuleButton(
                      identifier: 'mapa-drive-go-${r.id}',
                      label: 'Ir',
                      height: 52,
                      fontSize: 17,
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      leading:
                          GmIcon(GmIcons.car, size: 20, color: Colors.white),
                      onTap: onGo,
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

  Widget _statusRow(Widget mark, String text, Color color) => Row(
        children: [
          SizedBox(width: 16, height: 22, child: Center(child: mark)),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17,
                height: 22 / 17,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      );
}
