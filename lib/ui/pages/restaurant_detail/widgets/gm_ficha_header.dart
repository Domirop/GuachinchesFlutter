import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/data/cubit/location/location_cubit.dart';
import 'package:guachinches/data/cubit/location/location_state.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show GmPhoto, gmDisplayName, gmDistanceLabel, gmPlaceName;
import 'package:guachinches/ui/pages/restaurant_detail/restaurant_photos_gallery.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:guachinches/utils/open_now_utils.dart';
import 'package:guachinches/utils/opening_later_utils.dart';
import 'package:guachinches/utils/restaurant_type_label.dart';

/// Cabecera de la ficha (rediseño iOS 27 · tablero Ficha):
/// - Fotos en carrusel de tarjetas sobre el fondo desenfocado de la primera,
///   con botones de cristal «Cerrar» y «Compartir».
/// - Hoja r32 con asa: antetítulo «Tipo · municipio» con mantel, título
///   34/41, línea «● Abierto hasta las 22:00 · ★ 4,8 · 22 km», fila de
///   acciones tipo Mapas (Cómo llegar · Llamar · Visita · Guardar), chips de
///   características con fundido al borde y la tarjeta vino de la visita.
class GmFichaHeader extends StatelessWidget {
  final Restaurant restaurant;
  final List<Visit> visits;
  final bool isSaved;
  final VoidCallback onClose;
  final VoidCallback onShare;
  final VoidCallback onDirections;
  final VoidCallback? onCall;
  final VoidCallback onToggleSave;
  final ValueChanged<Visit> onOpenVisit;

  /// Alto de la zona de fotos; la hoja se monta 26 pt por encima.
  static const double photosHeight = 344;
  static const double sheetOverlap = 26;

  const GmFichaHeader({
    super.key,
    required this.restaurant,
    required this.visits,
    required this.isSaved,
    required this.onClose,
    required this.onShare,
    required this.onDirections,
    required this.onToggleSave,
    required this.onOpenVisit,
    this.onCall,
  });

  List<String> get _photoUrls {
    final urls = restaurant.fotos
        .map((f) => f.photoUrl ?? '')
        .where((u) => u.isNotEmpty)
        .toList();
    if (urls.isEmpty && restaurant.mainFoto.isNotEmpty) {
      return [restaurant.mainFoto];
    }
    return urls;
  }

  void _openGallery(BuildContext context, int at) {
    final urls = _photoUrls;
    if (urls.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RestaurantPhotosGallery(
          urls: urls,
          initialIndex: at,
          restaurantName: restaurant.nombre,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final top = MediaQuery.paddingOf(context).top;
    final urls = _photoUrls;

    final photos = SizedBox(
      height: photosHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFF1C120C)),
          if (urls.isNotEmpty)
            Positioned(
              left: -40,
              right: -40,
              top: -40,
              bottom: -40,
              // El desenfoque a pantalla completa se rasteriza aparte.
              child: RepaintBoundary(
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.matrix(<double>[
                      0.92, 0.12, 0.0, 0, 0, //
                      0.04, 0.96, 0.0, 0, 0, //
                      0.0, 0.12, 0.84, 0, 0, //
                      0, 0, 0, 1, 0,
                    ]),
                    child: CachedNetworkImage(
                      imageUrl: urls.first,
                      fit: BoxFit.cover,
                      memCacheWidth: 300,
                      placeholder: (_, __) => const SizedBox.shrink(),
                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x6B000000),
                  Color(0x0D000000),
                  Color(0x2E000000)
                ],
                stops: [0, 0.4, 1],
              ),
            ),
          ),
          if (urls.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              top: top + 56,
              height: 196,
              child: GmRise(
                trigger: GmTrigger.mount,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: urls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (ctx, i) => Semantics(
                    identifier: i == 0 ? 'restaurant-detail-photos' : null,
                    button: true,
                    label: 'Foto ${i + 1} de ${urls.length}',
                    child: GmPressable(
                      onTap: () => _openGallery(ctx, i),
                      child: Container(
                        width: 148,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(GmRadius.tile),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x2EFFFFFF), spreadRadius: 1),
                            BoxShadow(
                              color: Color(0x8C000000),
                              offset: Offset(0, 14),
                              blurRadius: 30,
                              spreadRadius: -10,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(GmRadius.tile),
                          child: GmPhoto(urls[i], decodeWidth: 450),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 16,
            right: 16,
            top: top + 2,
            child: Row(
              children: [
                GmToolbarButton(
                  icon: GmIcons.close,
                  iconSize: 16,
                  semanticLabel: 'Cerrar',
                  identifier: 'restaurant-detail-back-button',
                  onTap: onClose,
                ),
                const Spacer(),
                GmToolbarButton(
                  icon: GmIcons.share,
                  semanticLabel: 'Compartir',
                  identifier: 'restaurant-detail-share-button',
                  onTap: onShare,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Stack(
      children: [
        Positioned(left: 0, right: 0, top: 0, child: photos),
        Padding(
          padding: const EdgeInsets.only(top: photosHeight - sheetOverlap),
          child: Container(
            decoration: BoxDecoration(
              color: gm.canvas,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x2E000000),
                    offset: Offset(0, -10),
                    blurRadius: 30),
              ],
            ),
            padding: const EdgeInsets.only(top: 8),
            child: _SheetTop(
              restaurant: restaurant,
              visits: visits,
              isSaved: isSaved,
              onDirections: onDirections,
              onCall: onCall,
              onToggleSave: onToggleSave,
              onOpenVisit: onOpenVisit,
            ),
          ),
        ),
      ],
    );
  }
}

class _SheetTop extends StatelessWidget {
  final Restaurant restaurant;
  final List<Visit> visits;
  final bool isSaved;
  final VoidCallback onDirections;
  final VoidCallback? onCall;
  final VoidCallback onToggleSave;
  final ValueChanged<Visit> onOpenVisit;

  const _SheetTop({
    required this.restaurant,
    required this.visits,
    required this.isSaved,
    required this.onDirections,
    required this.onCall,
    required this.onToggleSave,
    required this.onOpenVisit,
  });

  /// «hasta las 22:00» si está abierto y sabemos a qué hora cierra.
  static String? _closesAt(Map<String, dynamic>? json, DateTime now) {
    if (json == null) return null;
    try {
      final periods = json['periods'] as List?;
      if (periods == null) return null;
      final day = now.weekday % 7;
      final nowMin = now.hour * 60 + now.minute;
      for (final p in periods) {
        final o = p['open'];
        final c = p['close'];
        if (o == null || c == null || o['day'] != day) continue;
        final ot = o['time'] as String;
        final ct = c['time'] as String;
        final om =
            int.parse(ot.substring(0, 2)) * 60 + int.parse(ot.substring(2, 4));
        var cm =
            int.parse(ct.substring(0, 2)) * 60 + int.parse(ct.substring(2, 4));
        if (c['day'] != day) cm += 24 * 60;
        if (nowMin >= om && nowMin < cm) {
          return 'hasta las ${ct.substring(0, 2)}:${ct.substring(2, 4)}';
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final r = restaurant;
    final now = DateTime.now();
    final type = restaurantTypeLabel(r.type);
    final muni = gmPlaceName(r.municipio);
    final eyebrow =
        [if (type.isNotEmpty) type, if (muni.isNotEmpty) muni].join(' · ');
    final hasSchedule = r.horariosJson != null;
    final open = hasSchedule && isOpenNow(r.horariosJson, now);
    final until = open ? _closesAt(r.horariosJson, now) : null;
    final opensAt =
        !open && hasSchedule ? nextOpenLabel(r.horariosJson, now) : null;
    final loc = context.watch<LocationCubit>().state;
    final dist = loc is LocationLoaded
        ? gmDistanceLabel(r, loc.latitude, loc.longitude)
        : null;

    final metaStyle = TextStyle(
      fontSize: 15,
      height: 20 / 15,
      fontWeight: FontWeight.w400,
      color: gm.label2,
    );
    final dot = Text('  ·  ', style: metaStyle);
    final meta = <Widget>[
      if (hasSchedule)
        open
            ? const GmOpenLabel(fontSize: 15)
            : Text('Cerrado',
                style: metaStyle.copyWith(fontWeight: FontWeight.w600)),
      if (until != null) ...[
        const SizedBox(width: 6),
        Text(until, style: metaStyle)
      ],
      if (opensAt != null) ...[
        const SizedBox(width: 6),
        Text('abre a las $opensAt', style: metaStyle),
      ],
      if (r.avgRating > 0) ...[
        if (hasSchedule) dot,
        GmRating(r.avgRating, fontSize: 15, starSize: 13),
      ],
      if (dist != null) ...[
        if (hasSchedule || r.avgRating > 0) dot,
        Text(dist, style: metaStyle),
      ],
    ];

    final latest = visits.isNotEmpty ? visits.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: gm.sep,
              borderRadius: BorderRadius.circular(GmRadius.pill),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Antetítulo + título + meta.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GmRise(
            trigger: GmTrigger.mount,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow.isNotEmpty)
                  GmEyebrow(
                    leading: const SizedBox(
                      width: 14,
                      height: 14,
                      child: ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        child:
                            CustomPaint(painter: GmGinghamPainter(cell: 3.5)),
                      ),
                    ),
                    text: eyebrow,
                    color: gm.bandInk,
                  ),
                const SizedBox(height: 2),
                Text(
                  gmDisplayName(r.nombre),
                  style: GmText.largeTitle(color: gm.label)
                      .copyWith(letterSpacing: -0.8),
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: meta,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Acciones tipo Apple Mapas.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GmRise(
            trigger: GmTrigger.mount,
            index: 1,
            // Botones de alto fijo (como Apple Mapas): texto hasta 1,2×.
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.2,
              child: Row(
                children: [
                  Expanded(
                    child: _Action(
                      icon: GmIcons.car,
                      label: 'Cómo llegar',
                      primary: true,
                      identifier: 'restaurant-detail-maps-button',
                      onTap: onDirections,
                    ),
                  ),
                  if (onCall != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _Action(
                        icon: GmIcons.phone,
                        label: 'Llamar',
                        identifier: 'restaurant-detail-call-button',
                        onTap: onCall!,
                      ),
                    ),
                  ],
                  if (latest != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _Action(
                        icon: GmIcons.video,
                        label: 'Visita',
                        identifier: 'restaurant-detail-visit-button',
                        onTap: () => onOpenVisit(latest),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Action(
                      icon: isSaved ? GmIcons.bookmarkFilled : GmIcons.bookmark,
                      label: isSaved ? 'Guardado' : 'Guardar',
                      identifier: 'restaurant-detail-save-button',
                      selected: isSaved,
                      onTap: onToggleSave,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Características.
        if (r.categoriaRestaurantes.isNotEmpty) ...[
          const SizedBox(height: 16),
          GmRise(
            trigger: GmTrigger.mount,
            index: 2,
            child: _FeatureChips(restaurant: r),
          ),
        ],
        // Tarjeta vino de la visita.
        if (latest != null) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GmRise(
              trigger: GmTrigger.mount,
              index: 3,
              child: _VisitTeaser(
                visit: latest,
                onTap: () => onOpenVisit(latest),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Action extends StatelessWidget {
  final String icon;
  final String label;
  final bool primary;
  final bool selected;
  final VoidCallback onTap;
  final String identifier;

  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.identifier,
    this.primary = false,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final ink = primary ? Colors.white : gm.accent;
    return Semantics(
      identifier: identifier,
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GmPressable(
        onTap: onTap,
        pressedScale: 0.94,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: primary ? null : gm.card,
            gradient: primary ? GmColors.accentFill : null,
            borderRadius: BorderRadius.circular(GmRadius.tile),
            boxShadow: primary
                ? const [
                    BoxShadow(
                      color: Color(0x99006496),
                      offset: Offset(0, 10),
                      blurRadius: 20,
                      spreadRadius: -8,
                    ),
                  ]
                : gm.shadow1,
          ),
          foregroundDecoration: primary
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(GmRadius.tile),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x33FFFFFF), Color(0x00FFFFFF)],
                    stops: [0, 0.1],
                  ),
                )
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GmIcon(icon, size: 22, color: ink),
              const SizedBox(height: 3),
              // «Cómo llegar» no debe rozar los bordes del botón.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 13,
                      height: 16 / 13,
                      fontWeight: FontWeight.w600,
                      color: ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chips de características con fundido en el borde derecho (sangran).
class _FeatureChips extends StatelessWidget {
  final Restaurant restaurant;
  const _FeatureChips({required this.restaurant});

  static Widget? _iconFor(String name, GmColors gm) {
    final n = name.toLowerCase();
    if (n.contains('vino') || n.contains('cosecha')) {
      return GmIcon(GmIcons.wineGlass, size: 15, color: gm.label);
    }
    if (n.contains('cabra')) return const GmGlyph(GmGlyphKind.cabra, size: 16);
    if (n.contains('cochino')) {
      return const GmGlyph(GmGlyphKind.cochino, size: 16);
    }
    if (n.contains('pescado') || n.contains('marisco')) {
      return const GmGlyph(GmGlyphKind.vieja, size: 16);
    }
    if (n.contains('terraza') || n.contains('vistas')) {
      return GmIcon(GmIcons.sun, size: 16, color: gm.label);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final names = restaurant.categoriaRestaurantes
        .map((c) => c.categorias.nombre.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (names.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 32 + 16,
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => LinearGradient(
          colors: const [Colors.black, Colors.black, Colors.transparent],
          stops: [0, (rect.width - 24) / rect.width, 1],
        ).createShader(rect),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          itemCount: names.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final icon = _iconFor(names[i], gm);
            return Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: gm.card,
                borderRadius: BorderRadius.circular(GmRadius.pill),
                boxShadow: gm.shadow1,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[icon, const SizedBox(width: 6)],
                  Text(
                    names[i],
                    style: TextStyle(
                      fontSize: 14,
                      height: 18 / 14,
                      fontWeight: FontWeight.w500,
                      color: gm.label,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// «Jonay y Joana estuvieron aquí» — tarjeta vino con la miniatura y la cita.
class _VisitTeaser extends StatelessWidget {
  final Visit visit;
  final VoidCallback onTap;
  const _VisitTeaser({required this.visit, required this.onTap});

  String _line() {
    for (final q in visit.quotes) {
      final t = q.text.trim();
      if (t.isNotEmpty) return t.startsWith('«') ? t : '«$t»';
    }
    final s = visit.summary?.trim();
    if (s != null && s.isNotEmpty) return s;
    final e = visit.extraText?.trim();
    if (e != null && e.isNotEmpty) return e;
    return 'Mira lo que probaron';
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final thumb = visit.thumbnail?.isNotEmpty == true
        ? visit.thumbnail
        : visit.restaurant?.mainFoto;
    return Semantics(
      identifier: 'restaurant-detail-visit-card',
      button: true,
      child: GmPressable(
        onTap: onTap,
        pressedScale: 0.98,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
          decoration: BoxDecoration(
            color: GmColors.wine,
            borderRadius: BorderRadius.circular(GmRadius.card),
            border: gm.isDark ? Border.all(color: gm.wineEdge) : null,
            boxShadow: const [
              BoxShadow(
                color: Color(0xB32A0E14),
                offset: Offset(0, 14),
                blurRadius: 30,
                spreadRadius: -16,
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      GmPhoto(thumb, decodeWidth: 200),
                      Center(
                        child: ClipOval(
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: Container(
                              width: 28,
                              height: 28,
                              color: Colors.white.withValues(alpha: 0.28),
                              alignment: Alignment.center,
                              child: GmIcon(GmIcons.play,
                                  size: 10, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Jonay y Joana estuvieron aquí',
                        style: GmText.chip(color: GmColors.gold)),
                    const SizedBox(height: 2),
                    Text(
                      _line(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 20 / 15,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: GmColors.creamHi,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GmIcon(GmIcons.chevronRight, size: 14, color: GmColors.gold),
            ],
          ),
        ),
      ),
    );
  }
}
