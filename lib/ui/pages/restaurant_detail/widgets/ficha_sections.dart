import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guachinches/data/cubit/location/location_cubit.dart';
import 'package:guachinches/data/cubit/location/location_state.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/components/curated_hero_image.dart';
import 'package:guachinches/ui/components/glass_sheet.dart';
import 'package:guachinches/ui/components/video/vertical_video_player.dart';
import 'package:guachinches/ui/components/video/youtube_embed_sheet.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show GmPhoto, gmDisplayName, gmDistanceLabel, gmPlaceName;
import 'package:guachinches/ui/pages/restaurant_detail/ficha_logic.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/dishes_section.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/reviews_section.dart'
    show FichaPillButton;
import 'package:guachinches/ui/pages/visit/visit_screen.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

/// Secciones de la ficha de negocio bajo la cabecera (tablero
/// FichaCompleta / FichaSinVisitas): Detalles con mapa claro, Editorial, El
/// short, Visitas, Resumen con IA, Fotos y Aparece en listas.

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

Future<void> _openUrl(String url) async {
  final u = url.startsWith('http') ? url : 'https://$url';
  final uri = Uri.tryParse(u);
  if (uri == null) {
    AppLogger.warn('restaurant-detail', 'enlace no válido: $url');
    return;
  }
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    // Sin app/navegador disponible (p. ej. simulador).
    AppLogger.warn('restaurant-detail', 'no se pudo abrir $u: $e');
  }
}

/// Cabecera de sección de la ficha (antetítulo opcional + título 22/28).
class FichaSectionHead extends StatelessWidget {
  final String title;
  final Widget? eyebrow;
  final VoidCallback? onTap;
  final String? identifier;
  const FichaSectionHead(
      {super.key, required this.title, this.eyebrow, this.onTap, this.identifier});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: GmSectionHeader(
          title: title,
          eyebrow: eyebrow,
          onTap: onTap,
          identifier: identifier,
        ),
      );
}

// ── Detalles + mapa claro ───────────────────────────────────────────────────

class FichaDetails extends StatefulWidget {
  final Restaurant restaurant;

  /// Visitas ordenadas (la más reciente primero).
  final List<Visit> visits;
  final VoidCallback onOpenMaps;
  final VoidCallback? onCall;

  const FichaDetails({
    super.key,
    required this.restaurant,
    required this.visits,
    required this.onOpenMaps,
    this.onCall,
  });

  @override
  State<FichaDetails> createState() => _FichaDetailsState();
}

class _FichaDetailsState extends State<FichaDetails> {
  bool _week = false;

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final r = widget.restaurant;
    final latest = widget.visits.isNotEmpty ? widget.visits.first : null;
    final week = fichaWeek(r, DateTime.now());
    final footnote = fichaScheduleFootnote(r);
    final phone = r.telefono.trim().isNotEmpty
        ? r.telefono.trim()
        : (latest?.phone?.trim() ?? '');
    final address = r.direccion.trim().isNotEmpty
        ? r.direccion
        : (latest?.address ?? '');
    final reservation = r.reservationInfo?.trim();
    final reservationUrl = r.reservationLink ??
        ((reservation != null &&
                (reservation.startsWith('http') ||
                    reservation.startsWith('www')))
            ? reservation
            : null);
    String? phoneHint;
    if (reservation != null &&
        reservation.isNotEmpty &&
        !reservation.startsWith('http') &&
        !reservation.startsWith('www')) {
      phoneHint = reservation;
    } else if (fichaTakesReservations(widget.visits)) {
      phoneHint = 'Se reserva por teléfono';
    }
    final instagram = (r.instagramLink != null)
        ? fichaInstagramHandle(r.instagramLink!)
        : latest?.instagram?.trim();
    final menu = r.menuLink;
    final website = (r.website?.trim().isNotEmpty == true)
        ? r.website!.trim()
        : latest?.website?.trim();

    final rows = <Widget>[];
    if (week != null) {
      rows.add(_ScheduleRow(
        hours: week.hours,
        today: week.today,
        expanded: _week,
        footnote: footnote,
        onToggle: () => setState(() => _week = !_week),
      ));
    }
    if (phone.isNotEmpty) {
      rows.add(_Row(
        icon: GmIcons.phone,
        tint: gm.accentSoft,
        ink: gm.accent,
        label: 'Teléfono',
        value: phone,
        hint: phoneHint,
        identifier: 'restaurant-detail-phone-row',
        onTap: widget.onCall,
      ));
    }
    if (address.trim().isNotEmpty) {
      rows.add(_Row(
        icon: GmIcons.placeFilled,
        tint: const Color(0x38C9A96B),
        ink: gm.bandInk,
        label: 'Dirección',
        value: fichaAddressLines(address),
      ));
    }
    if (instagram != null && instagram.isNotEmpty) {
      final handle = instagram.startsWith('@') ? instagram : '@$instagram';
      rows.add(_Row(
        icon: GmIcons.instagram,
        tint: const Color(0x24C13584),
        ink: const Color(0xFFB0306E),
        label: 'Instagram',
        value: handle,
        identifier: 'restaurant-detail-instagram-row',
        onTap: () => _openUrl(r.instagramLink != null &&
                r.instagramLink!.startsWith('http')
            ? r.instagramLink!
            : 'https://instagram.com/${handle.replaceFirst('@', '')}'),
      ));
    }
    if (menu != null) {
      rows.add(_Row(
        icon: GmIcons.menu,
        tint: gm.accentSoft,
        ink: gm.accent,
        label: 'Carta',
        value: 'Ver la carta',
        identifier: 'restaurant-detail-menu-row',
        onTap: () => _openUrl(menu),
      ));
    }
    if (website != null && website.isNotEmpty) {
      rows.add(_Row(
        icon: GmIcons.globe,
        tint: gm.fill,
        ink: gm.label,
        label: 'Web',
        value: website.replaceFirst(RegExp(r'^https?://(www\.)?'), ''),
        identifier: 'restaurant-detail-web-row',
        onTap: () => _openUrl(website),
      ));
    }
    if (reservationUrl != null) {
      rows.add(_Row(
        icon: GmIcons.calendar,
        tint: gm.okSoft,
        ink: gm.greenText,
        label: 'Reservar mesa',
        value: 'Reservar en su web',
        identifier: 'restaurant-detail-reserve-row',
        onTap: () => _openUrl(reservationUrl),
      ));
    }
    rows.add(_Row(
      icon: GmIcons.map,
      tint: gm.fill,
      ink: gm.label,
      value: 'Abrir en Mapas',
      strong: true,
      identifier: 'restaurant-detail-open-maps-row',
      onTap: widget.onOpenMaps,
    ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FichaSectionHead(title: 'Detalles'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
          child: GmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (r.lat != 0 && r.lon != 0)
                  _LightMap(restaurant: r, onTap: widget.onOpenMaps),
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 58),
                      child: Container(height: 1, color: gm.sep),
                    ),
                  rows[i],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String icon;
  final Color tint;
  final Color ink;
  final String? label;
  final String value;
  final String? hint;
  final VoidCallback? onTap;
  final bool strong;
  final String? identifier;

  const _Row({
    required this.icon,
    required this.tint,
    required this.ink,
    required this.value,
    this.label,
    this.hint,
    this.onTap,
    this.strong = false,
    this.identifier,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 58),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 16, 10),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                  color: tint, borderRadius: BorderRadius.circular(9)),
              alignment: Alignment.center,
              child: GmIcon(icon, size: 15, color: ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (label != null)
                    Text(label!,
                        style: TextStyle(
                            fontSize: 13,
                            height: 17 / 13,
                            fontWeight: FontWeight.w400,
                            color: gm.label2)),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      height: 21 / 16,
                      fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
                      color: gm.label,
                    ),
                  ),
                  if (hint != null)
                    Text(hint!,
                        style: GmText.chip(color: gm.label2, w: FontWeight.w400)),
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              GmIcon(GmIcons.chevronRight, size: 14, color: gm.label2),
            ],
          ],
        ),
      ),
    );
    if (onTap == null) return content;
    return Semantics(
      identifier: identifier,
      button: true,
      child: GmPressable(onTap: onTap, pressedScale: 0.985, child: content),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  final List<String> hours;
  final int today;
  final bool expanded;
  final String? footnote;
  final VoidCallback onToggle;

  const _ScheduleRow({
    required this.hours,
    required this.today,
    required this.expanded,
    required this.footnote,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final reduced = GmMotion.reduced(context);
    final rowStyle = TextStyle(
      fontSize: 15,
      height: 20 / 15,
      fontWeight: FontWeight.w400,
      color: gm.label,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Semantics(
      identifier: 'restaurant-detail-schedule-row',
      container: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 16, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                    color: gm.okSoft, borderRadius: BorderRadius.circular(9)),
                alignment: Alignment.center,
                child: GmIcon(GmIcons.clock, size: 16, color: gm.greenText),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Horario',
                                style: TextStyle(
                                    fontSize: 13,
                                    height: 17 / 13,
                                    fontWeight: FontWeight.w400,
                                    color: gm.label2)),
                            Text('Hoy · ${hours[today]}',
                                style: TextStyle(
                                    fontSize: 16,
                                    height: 21 / 16,
                                    fontWeight: FontWeight.w400,
                                    color: gm.label)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Semantics(
                        identifier: 'restaurant-detail-schedule-toggle',
                        button: true,
                        expanded: expanded,
                        child: GmPressable(
                          onTap: onToggle,
                          child: FichaPillButton(
                            label: expanded ? 'Ocultar' : 'Ver horario',
                            trailing: expanded
                                ? GmIcons.chevronUp
                                : GmIcons.chevronDown,
                          ),
                        ),
                      ),
                    ],
                  ),
                  AnimatedSize(
                    duration: Duration(milliseconds: reduced ? 0 : 320),
                    curve: GmMotion.settle,
                    alignment: Alignment.topCenter,
                    child: !expanded
                        ? const SizedBox(width: double.infinity)
                        : Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              children: [
                                for (var d = 0; d < 7; d++)
                                  Container(
                                    constraints:
                                        const BoxConstraints(minHeight: 30),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: d == today ? gm.accentSoft : null,
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            fichaWeekDays[d],
                                            style: rowStyle.copyWith(
                                              color: gm.label2,
                                              fontWeight: d == today
                                                  ? FontWeight.w700
                                                  : FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          hours[d],
                                          textAlign: TextAlign.right,
                                          style: rowStyle.copyWith(
                                            fontWeight: d == today
                                                ? FontWeight.w700
                                                : FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                  ),
                  if (footnote != null) ...[
                    const SizedBox(height: 6),
                    Text(footnote!,
                        style: GmText.chip(color: gm.label2, w: FontWeight.w400)),
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

/// Mapa real en estilo claro (o noche) del sistema, sin gestos: tocar abre
/// Mapas. Chincheta vino con el volcán que cae una vez y chip de distancia.
class _LightMap extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;
  const _LightMap({required this.restaurant, required this.onTap});

  static String styleFor(GmColors gm) => '''
[
  {"elementType":"geometry","stylers":[{"color":"${_hex(gm.mapLand)}"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"${_hex(gm.mapLabel)}"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"${_hex(gm.mapLand)}"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative.locality","elementType":"labels","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative.neighborhood","elementType":"labels","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"visibility":"on"},{"color":"${_hex(gm.mapPark)}"}]},
  {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"${_hex(gm.mapRoad)}"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"${_hex(gm.isDark ? const Color(0xFF0E1A22) : const Color(0xFFE2D9C6))}"}]},
  {"featureType":"road.highway","elementType":"geometry.fill","stylers":[{"color":"${_hex(gm.mapMajor)}"}]},
  {"featureType":"road.arterial","elementType":"labels","stylers":[{"visibility":"off"}]},
  {"featureType":"road.local","elementType":"labels","stylers":[{"visibility":"off"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"${_hex(gm.mapSea)}"}]},
  {"featureType":"water","elementType":"labels","stylers":[{"visibility":"off"}]}
]''';

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final r = restaurant;
    final loc = context.watch<LocationCubit>().state;
    final dist = loc is LocationLoaded
        ? gmDistanceLabel(r, loc.latitude, loc.longitude)
        : null;
    final target = LatLng(r.lat, r.lon);
    return Semantics(
      identifier: 'restaurant-detail-map',
      button: true,
      label: 'Abrir la ubicación en Mapas',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 156,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: gm.mapLand),
              AbsorbPointer(
                child: GoogleMap(
                  key: ValueKey(gm.isDark),
                  initialCameraPosition:
                      CameraPosition(target: target, zoom: 13.6),
                  style: styleFor(gm),
                  liteModeEnabled: true,
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: false,
                  scrollGesturesEnabled: false,
                  zoomGesturesEnabled: false,
                  rotateGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                ),
              ),
              // La chincheta se dibuja encima: su punta cae en el centro.
              const Positioned.fill(child: Center(child: _VolcanoPin())),
              if (dist != null)
                Positioned(
                  left: 10,
                  top: 10,
                  child: GmPhotoChip(
                    leading: GmIcon(GmIcons.navArrow,
                        size: 11, color: GmColors.atlantico),
                    label: dist,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VolcanoPin extends StatelessWidget {
  const _VolcanoPin();

  @override
  Widget build(BuildContext context) {
    const ease = Cubic(0.4, 0, 0.2, 1);
    // 28×40 pin: la punta (abajo) debe quedar en el centro del mapa.
    return Transform.translate(
      offset: const Offset(0, -20),
      child: GmOnce(
        duration: const Duration(milliseconds: 1200),
        delay: const Duration(milliseconds: 500),
        builder: (_, t, __) {
          final dy = gmKeyframes(t,
              const [(0, -8), (0.4, 0), (0.62, -2), (0.8, 0), (1, 0)],
              curve: ease);
          final sx = gmKeyframes(t,
              const [(0, 0.94), (0.4, 1.14), (0.62, 0.97), (0.8, 1), (1, 1)],
              curve: ease);
          final sy = gmKeyframes(t,
              const [(0, 1.08), (0.4, 0.84), (0.62, 1.04), (0.8, 1), (1, 1)],
              curve: ease);
          final ss = gmKeyframes(t,
              const [(0, 0.55), (0.4, 1.15), (0.8, 1), (1, 1)],
              curve: ease);
          return SizedBox(
            width: 30,
            height: 44,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  bottom: -1,
                  child: Transform.scale(
                    scale: ss,
                    child: Container(
                      width: 18,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0x4D002846),
                        borderRadius: BorderRadius.all(Radius.elliptical(9, 3)),
                      ),
                    ),
                  ),
                ),
                Transform(
                  alignment: Alignment.bottomCenter,
                  transform: Matrix4.translationValues(0, dy, 0)
                    ..multiply(Matrix4.diagonal3Values(sx, sy, 1)),
                  child: CustomPaint(
                    size: const Size(30, 42),
                    painter: _PinPainter(),
                    child: const SizedBox(
                      width: 30,
                      height: 42,
                      child: Padding(
                        padding: EdgeInsets.only(top: 7),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: GmGlyph(GmGlyphKind.volcan, size: 14),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    const r = 14.0;
    final path = Path()
      ..moveTo(cx, size.height - 1)
      ..cubicTo(cx, size.height - 1, cx - r, 26, cx - r, 15)
      ..arcToPoint(Offset(cx + r, 15), radius: const Radius.circular(r))
      ..cubicTo(cx + r, 26, cx, size.height - 1, cx, size.height - 1)
      ..close();
    canvas.drawPath(path, Paint()..color = GmColors.wine);
    canvas.drawPath(
        path,
        Paint()
          ..color = GmColors.creamHi
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    canvas.drawCircle(Offset(cx, 15), 8.5, Paint()..color = GmColors.creamHi);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Editorial ───────────────────────────────────────────────────────────────

class FichaEditorial extends StatelessWidget {
  final Restaurant restaurant;
  const FichaEditorial({super.key, required this.restaurant});

  static bool shouldRender(Restaurant r) =>
      (r.editorialQuote?.trim().isNotEmpty ?? false) ||
      (r.editorialBody?.trim().isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final quote = restaurant.editorialQuote?.trim();
    final body = restaurant.editorialBody?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FichaSectionHead(
          title: 'En palabras de Jonay y Joana',
          eyebrow: GmEyebrow(
            leading: const SizedBox(
              width: 13,
              height: 13,
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(4)),
                child: CustomPaint(painter: GmGinghamPainter(cell: 3.5)),
              ),
            ),
            text: 'Editorial',
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: GmSpace.titleInset),
          padding: const EdgeInsets.only(left: 16),
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: GmColors.gold, width: 3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (quote != null && quote.isNotEmpty)
                Text(
                  quote,
                  style: TextStyle(
                    fontSize: 19,
                    height: 26 / 19,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                    color: gm.label,
                  ),
                ),
              if (quote != null &&
                  quote.isNotEmpty &&
                  body != null &&
                  body.isNotEmpty)
                const SizedBox(height: 8),
              if (body != null && body.isNotEmpty)
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 16,
                    height: 23 / 16,
                    fontWeight: FontWeight.w400,
                    color: gm.label2,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── El short ────────────────────────────────────────────────────────────────

class FichaShort extends StatelessWidget {
  final Restaurant restaurant;
  final List<Visit> visits;
  const FichaShort({super.key, required this.restaurant, required this.visits});

  static bool shouldRender(Restaurant r) =>
      r.shortVideoId != null && r.shortVideoId!.trim().isNotEmpty;

  void _open(BuildContext context) =>
      YoutubeEmbedSheet.show(context, videoId: restaurant.shortVideoId!);

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final r = restaurant;
    final duration = fichaDuration(raw: r.shortDuration);
    final title = (r.shortDescription?.trim().isNotEmpty ?? false)
        ? r.shortDescription!.trim().split('\n').first
        : gmDisplayName(r.nombre);
    final thumb = (r.shortThumbnailUrl?.isNotEmpty ?? false)
        ? r.shortThumbnailUrl
        : 'https://i.ytimg.com/vi/${r.shortVideoId}/hqdefault.jpg';
    final sayings = fichaSayings(r, visits);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FichaSectionHead(
          title: 'El short de Jonay y Joana',
          eyebrow: GmEyebrow(
            leading: GmIcon(GmIcons.youtube, size: 13, color: gm.label2),
            text: 'YouTube Shorts',
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
          child: GmCard(
            radius: GmRadius.hero,
            padding: const EdgeInsets.all(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  identifier: 'restaurant-detail-short-poster',
                  button: true,
                  label: 'Ver el short en YouTube',
                  excludeSemantics: true,
                  child: GmPressable(
                    onTap: () => _open(context),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        width: 120,
                        height: 213,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            GmPhoto(thumb, decodeWidth: 400),
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0x4D000000),
                                    Color(0x00000000),
                                    Color(0x00000000),
                                    Color(0x73000000),
                                  ],
                                  stops: [0, 0.3, 0.7, 1],
                                ),
                              ),
                            ),
                            const Positioned(
                              left: 8,
                              top: 8,
                              child: GmPhotoChip(label: 'Short', dark: true),
                            ),
                            if (duration != null)
                              Positioned(
                                right: 8,
                                bottom: 8,
                                child:
                                    GmPhotoChip(label: duration, dark: true),
                              ),
                            const Center(child: _PulsePlay()),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: SizedBox(
                    height: 213,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 10, 8, 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: GmText.guideTitle(color: gm.label)
                                    .copyWith(letterSpacing: -0.3),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                duration == null
                                    ? 'Jonay y Joana'
                                    : 'Jonay y Joana · $duration',
                                style: TextStyle(
                                    fontSize: 13,
                                    height: 17 / 13,
                                    fontWeight: FontWeight.w400,
                                    color: gm.label2),
                              ),
                            ],
                          ),
                          Semantics(
                            identifier: 'restaurant-detail-short-youtube',
                            button: true,
                            child: GmPressable(
                              onTap: () => _open(context),
                              child: Container(
                                constraints:
                                    const BoxConstraints(minHeight: 40),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: gm.accentSoft,
                                  borderRadius:
                                      BorderRadius.circular(GmRadius.pill),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GmIcon(GmIcons.play,
                                        size: 11, color: gm.accent),
                                    const SizedBox(width: 7),
                                    Text('Ver en YouTube',
                                        style: GmText.sub(
                                            color: gm.accent,
                                            w: FontWeight.w600)),
                                  ],
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
          ),
        ),
        if (sayings.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: GmEyebrow(text: 'Lo que dicen'),
          ),
          FichaSayingsCarousel(sayings: sayings),
        ],
      ],
    );
  }
}

/// Un único pulso del botón play (Sistema: «botón del primer póster»).
class _PulsePlay extends StatelessWidget {
  const _PulsePlay();

  @override
  Widget build(BuildContext context) {
    final button = ClipOval(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.26),
            shape: BoxShape.circle,
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.55), width: 0.5),
          ),
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.only(left: 2),
            child: GmIcon(GmIcons.play, size: 16, color: Colors.white),
          ),
        ),
      ),
    );
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: GmOnce(
              duration: const Duration(milliseconds: 1600),
              delay: const Duration(milliseconds: 1200),
              builder: (_, t, __) {
                if (t <= 0 || t >= 1) return const SizedBox.shrink();
                final e = const Cubic(0, 0, 0.2, 1).transform(t);
                return Transform.scale(
                  scale: 1 + 0.7 * e,
                  child: Opacity(
                    opacity: 0.9 * (1 - e),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.85),
                            width: 1.5),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          button,
        ],
      ),
    );
  }
}

/// «Lo que dicen»: citas literales con marca Positivo / Ojo (ámbar).
class FichaSayingsCarousel extends StatelessWidget {
  final List<FichaSaying> sayings;
  const FichaSayingsCarousel({super.key, required this.sayings});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final scale = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);
    final height = 24 + 8 + scale.scale(22) * 4 + 28 + 6;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: SizedBox(
        height: height,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          itemCount: sayings.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final s = sayings[i];
            return SizedBox(
              width: 246,
              child: GmCard(
                radius: GmRadius.tile,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                      decoration: BoxDecoration(
                        color: s.warning ? gm.warnSoft : gm.okSoft,
                        borderRadius: BorderRadius.circular(GmRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GmIcon(s.warning ? GmIcons.warn : GmIcons.check,
                              size: 12,
                              color: s.warning ? gm.warnText : gm.greenText),
                          const SizedBox(width: 5),
                          Text(
                            s.warning ? 'Ojo' : 'Positivo',
                            style: GmText.chip(
                                color: s.warning ? gm.warnText : gm.greenText,
                                w: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        s.text,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          height: 22 / 16,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                          letterSpacing: -0.2,
                          color: gm.label,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Visitas ─────────────────────────────────────────────────────────────────

/// Reproduce el vídeo de la visita (misma lógica de siempre): mp4 self-host
/// reproducible → reproductor vertical in-app; si no, embed de YouTube.
Future<void> fichaPlayVisit(BuildContext context, Visit v) {
  if (v.selfHostVideoPlayable) {
    return showVerticalVideo(context, url: v.videoFileUrl!, visit: v);
  }
  final yt = v.youtubeVideoId;
  if (yt != null && yt.trim().isNotEmpty) {
    return YoutubeEmbedSheet.show(context, videoId: yt);
  }
  return Future.value();
}

class FichaVisits extends StatefulWidget {
  /// Visitas ordenadas (la más reciente primero).
  final List<Visit> visits;
  const FichaVisits({super.key, required this.visits});

  @override
  State<FichaVisits> createState() => _FichaVisitsState();
}

class _FichaVisitsState extends State<FichaVisits> {
  late Set<String> _open = {
    if (widget.visits.isNotEmpty) widget.visits.first.id
  };

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final n = widget.visits.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FichaSectionHead(
          title: 'Visitas de Jonay y Joana',
          eyebrow: GmEyebrow(
            leading: GmIcon(GmIcons.youtube, size: 13, color: gm.label2),
            text: n == 1 ? '1 visita' : '$n visitas',
          ),
        ),
        for (var i = 0; i < n; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
            child: _VisitCard(
              visit: widget.visits[i],
              expanded: _open.contains(widget.visits[i].id),
              onToggle: () => setState(() {
                final id = widget.visits[i].id;
                _open = {..._open};
                _open.contains(id) ? _open.remove(id) : _open.add(id);
              }),
            ),
          ),
        ],
      ],
    );
  }
}

class _VisitCard extends StatelessWidget {
  final Visit visit;
  final bool expanded;
  final VoidCallback onToggle;
  const _VisitCard(
      {required this.visit, required this.expanded, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final v = visit;
    final date = fichaDateFromIso(v.sortDate) ?? 'Visita';
    final dishes = v.dishes.where((d) => d.name.trim().isNotEmpty).toList();
    final photoDishes = [for (final d in dishes) if (d.photoUrl != null) d];
    final lovedDishes = dishes.where((d) => d.sentiment == 'loved').length;
    final reduced = GmMotion.reduced(context);

    return GmCard(
      radius: GmRadius.guide,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            identifier: 'restaurant-detail-visit-toggle',
            button: true,
            expanded: expanded,
            label: expanded ? 'Plegar visita del $date' : 'Ver visita del $date',
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 2, 4, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(date,
                          style: GmText.body17(
                              color: gm.label, w: FontWeight.w600)),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                          color: gm.fill, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: GmIcon(
                          expanded ? GmIcons.chevronUp : GmIcons.chevronDown,
                          size: 14,
                          color: gm.label2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: Duration(milliseconds: reduced ? 0 : 320),
            curve: GmMotion.settle,
            alignment: Alignment.topCenter,
            child: !expanded
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(
                          identifier: 'restaurant-detail-visit-video',
                          button: true,
                          label: 'Ver el vídeo de la visita',
                          excludeSemantics: true,
                          child: GmPressable(
                            onTap: () => fichaPlayVisit(context, v),
                            pressedScale: 0.985,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: SizedBox(
                                height: 190,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    const ColoredBox(color: Color(0xFF1C120C)),
                                    GmPhoto(fichaVisitThumb(v),
                                        decodeWidth: 900,
                                        fallbacks: fichaVisitThumbs(v)),
                                    const DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Color(0x00000000),
                                            Color(0x8C000000),
                                          ],
                                          stops: [0.5, 1],
                                        ),
                                      ),
                                    ),
                                    Center(
                                      child: ClipOval(
                                        child: BackdropFilter(
                                          filter: ui.ImageFilter.blur(
                                              sigmaX: 7, sigmaY: 7),
                                          child: Container(
                                            width: 56,
                                            height: 56,
                                            color: Colors.white
                                                .withValues(alpha: 0.26),
                                            alignment: Alignment.center,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 2),
                                              child: GmIcon(GmIcons.play,
                                                  size: 18,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (fichaLoved(v))
                                      Positioned(
                                        left: 14,
                                        bottom: 12,
                                        child: _LovedSeal(),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (dishes.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: GmEyebrow(
                              text: lovedDishes > 0
                                  ? 'Lo que pidieron · ${lovedDishes == 1 ? '1 les encantó' : '$lovedDishes les encantaron'}'
                                  : 'Lo que pidieron',
                            ),
                          ),
                          const SizedBox(height: 8),
                          _DishGrid(
                            dishes: dishes,
                            onTap: (d) {
                              final idx = photoDishes.indexOf(d);
                              if (idx < 0) return;
                              showDishPhotoViewer(context,
                                  dishes: photoDishes,
                                  initialIndex: idx,
                                  heroPrefix: '${v.id}-ficha');
                            },
                            heroPrefix: '${v.id}-ficha',
                            photoDishes: photoDishes,
                          ),
                        ],
                        const SizedBox(height: 12),
                        Semantics(
                          identifier: 'restaurant-detail-visit-full',
                          button: true,
                          child: GmPressable(
                            onTap: () => showGlassSheet(
                              context,
                              child: VisitDetailPage(
                                  visitId: v.id, asSheet: true),
                            ),
                            child: Container(
                              margin: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                              constraints: const BoxConstraints(minHeight: 44),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: gm.accentSoft,
                                borderRadius:
                                    BorderRadius.circular(GmRadius.pill),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GmIcon(GmIcons.video,
                                      size: 18, color: gm.accent),
                                  const SizedBox(width: 7),
                                  Flexible(
                                    child: Text('Ver visita completa',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GmText.body(
                                            color: gm.accent,
                                            w: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LovedSeal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: GmColors.wine,
        borderRadius: BorderRadius.circular(GmRadius.pill),
        border: Border.all(color: const Color(0x80C9A96B)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GmIcon(GmIcons.thumb, size: 12, color: GmColors.gold),
          const SizedBox(width: 5),
          const Text('Les encantó',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE8CF9A))),
        ],
      ),
    );
  }
}

class _DishGrid extends StatelessWidget {
  final List<VisitDish> dishes;
  final List<VisitDish> photoDishes;
  final ValueChanged<VisitDish> onTap;
  final String heroPrefix;
  const _DishGrid({
    required this.dishes,
    required this.photoDishes,
    required this.onTap,
    required this.heroPrefix,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final nameH = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3).scale(16) * 3;
    Widget cell(VisitDish d) {
      final idx = photoDishes.indexOf(d);
      Widget photo = d.photoUrl != null
          ? GmPhoto(d.photoUrl, decodeWidth: 300)
          : const GmFill();
      if (idx >= 0) photo = Hero(tag: '$heroPrefix-dish-$idx', child: photo);
      return GmPressable(
        onTap: d.photoUrl == null ? null : () => onTap(d),
        semanticsLabel: d.name,
        child: GmCard(
          radius: 20,
          padding: const EdgeInsets.all(5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: SizedBox(
                  height: 76,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      photo,
                      if (d.isTop)
                        Positioned(
                          left: 5,
                          top: 5,
                          child: GmPhotoChip(
                            leading: GmIcon(GmIcons.star,
                                size: 9, color: GmColors.star),
                            label: 'Top',
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(3, 6, 3, 2),
                child: SizedBox(
                  height: nameH,
                  child: MediaQuery.withClampedTextScaling(
                    maxScaleFactor: 1.3,
                    child: Text(
                      d.name,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 16 / 12,
                        fontWeight: FontWeight.w600,
                        color: gm.label,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final rows = <Widget>[];
    for (var i = 0; i < dishes.length; i += 3) {
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var k = 0; k < 3; k++) ...[
            if (k > 0) const SizedBox(width: 8),
            Expanded(
              child: i + k < dishes.length
                  ? cell(dishes[i + k])
                  : const SizedBox.shrink(),
            ),
          ],
        ],
      ));
      if (i + 3 < dishes.length) rows.add(const SizedBox(height: 8));
    }
    return Column(children: rows);
  }
}

// ── Resumen con IA ──────────────────────────────────────────────────────────

class FichaAiSummaryCard extends StatelessWidget {
  final FichaAiSummary summary;
  const FichaAiSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    Widget item(String text, bool pro) => Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: pro ? gm.okSoft : gm.warnSoft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: GmIcon(pro ? GmIcons.check : GmIcons.warn,
                    size: 12, color: pro ? gm.greenText : gm.warnText),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(text,
                    style: TextStyle(
                        fontSize: 15,
                        height: 21 / 15,
                        fontWeight: FontWeight.w400,
                        color: gm.label)),
              ),
            ],
          ),
        );
    final n = summary.visitCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FichaSectionHead(
          title: 'Resumen con IA',
          eyebrow: GmEyebrow(
            leading: GmIcon(GmIcons.sparkle, size: 14, color: GmColors.gold),
            text: 'A partir de las visitas',
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
          child: GmCard(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (summary.pros.isNotEmpty) ...[
                  Text('A favor',
                      style: GmText.eyebrow(
                          color: gm.greenText, w: FontWeight.w700)),
                  for (final p in summary.pros) item(p, true),
                ],
                if (summary.pros.isNotEmpty && summary.cons.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Container(height: 1, color: gm.sep),
                  ),
                if (summary.cons.isNotEmpty) ...[
                  Text('En contra',
                      style: GmText.eyebrow(
                          color: gm.warnText, w: FontWeight.w700)),
                  for (final c in summary.cons) item(c, false),
                ],
                const SizedBox(height: 16),
                Text(
                  'Lo resume una IA a partir de ${n == 1 ? '1 visita' : '$n visitas'}. Puede equivocarse.',
                  style: GmText.chip(color: gm.label2, w: FontWeight.w400),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Fotos ───────────────────────────────────────────────────────────────────

class FichaPhotos extends StatelessWidget {
  final List<String> urls;
  final ValueChanged<int> onOpen;
  const FichaPhotos({super.key, required this.urls, required this.onOpen});

  static bool shouldRender(List<String> urls) => urls.length >= 2;

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final more = urls.length - 3;
    Widget tile(int i, {Widget? overlay}) => GestureDetector(
          onTap: () => onOpen(i),
          child: Stack(
            fit: StackFit.expand,
            children: [
              GmPhoto(urls[i], decodeWidth: 600),
              if (overlay != null) overlay,
            ],
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FichaSectionHead(
          title: 'Fotos',
          identifier: 'restaurant-detail-photos-title',
          onTap: () => onOpen(0),
          eyebrow: GmEyebrow(
            leading: GmIcon(GmIcons.photos, size: 14, color: gm.label2),
            text: '${urls.length} fotos del sitio',
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
          child: Semantics(
            identifier: 'restaurant-detail-photo-mosaic',
            button: true,
            label: 'Abrir la galería',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(GmRadius.card),
              child: SizedBox(
                height: 230,
                child: urls.length == 2
                    ? Row(
                        children: [
                          Expanded(child: tile(0)),
                          const SizedBox(width: 6),
                          Expanded(child: tile(1)),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(flex: 2, child: tile(0)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              children: [
                                Expanded(child: tile(1)),
                                const SizedBox(height: 6),
                                Expanded(
                                  child: tile(
                                    2,
                                    overlay: more > 0
                                        ? Container(
                                            color: const Color(0x80140C08),
                                            alignment: Alignment.center,
                                            child: Text('+$more',
                                                style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white)),
                                          )
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Aparece en listas ───────────────────────────────────────────────────────

class FichaLists extends StatelessWidget {
  final List<ListAppearance> appearances;
  final ValueChanged<ListAppearance> onTap;
  const FichaLists({super.key, required this.appearances, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FichaSectionHead(title: 'Aparece en listas'),
        for (var i = 0; i < appearances.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
            child: Semantics(
              identifier: 'restaurant-detail-list-${appearances[i].list.id}',
              button: true,
              child: GmPressable(
                onTap: () => onTap(appearances[i]),
                pressedScale: 0.98,
                child: GmCard(
                  radius: GmRadius.hero,
                  padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: SizedBox(
                          width: 96,
                          height: 96,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      appearances[i]
                                          .list
                                          .accent
                                          .withValues(alpha: 0.55),
                                      appearances[i]
                                          .list
                                          .accent
                                          .withValues(alpha: 0.15),
                                    ],
                                  ),
                                ),
                              ),
                              if (appearances[i].list.heroAsset != null)
                                CuratedHeroImage(
                                    source: appearances[i].list.heroAsset!)
                              else if (appearances[i].list.heroEmoji != null)
                                Center(
                                  child: Text(appearances[i].list.heroEmoji!,
                                      style: const TextStyle(fontSize: 44)),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fichaListLabel(
                                  appearances[i].list.eyebrow,
                                  appearances[i].position,
                                  appearances[i].total > 0
                                      ? appearances[i].total
                                      : appearances[i].list.count),
                              style: GmText.chip(
                                  color: gm.bandInk, w: FontWeight.w700),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              gmDisplayName(appearances[i].list.title),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GmText.body17(
                                  color: gm.label, w: FontWeight.w600),
                            ),
                            if (appearances[i].list.location.trim().isNotEmpty)
                              Text(
                                gmPlaceName(appearances[i].list.location),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 13,
                                    height: 17 / 13,
                                    fontWeight: FontWeight.w400,
                                    color: gm.label2),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                            color: gm.fill, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: GmIcon(GmIcons.chevronRight,
                            size: 13, color: gm.label),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
