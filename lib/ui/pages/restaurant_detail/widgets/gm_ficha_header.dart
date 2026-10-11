import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/data/cubit/location/location_cubit.dart';
import 'package:guachinches/data/cubit/location/location_state.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show GmPhoto, gmDisplayName, gmDistanceLabel, gmPlaceName;
import 'package:guachinches/ui/pages/restaurant_detail/ficha_logic.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:guachinches/utils/restaurant_type_label.dart';

/// Cabecera de la ficha de negocio (tablero FichaCompleta):
/// - Foto real a sangre (carrusel de las fotos del local; tocar abre la
///   galería), velo superior, botones de cristal Cerrar/Compartir y chip
///   «Ver las N fotos».
/// - Hoja con asa que se monta sobre la foto: antetítulo «Tipo · municipio»
///   con mantel, título 34/41, estado («● Abierto · hasta las 22:00» /
///   «Cerrado · abre el …»), meta («★ 5,0 · 3 reseñas · 22 km · ≈ 36 €»),
///   huecos opcionales (Temporada, Nº en isla), acciones tipo Apple Mapas,
///   características y la tarjeta vino de la última visita.
class GmFichaHeader extends StatelessWidget {
  final Restaurant restaurant;

  /// Visitas ya ordenadas (la más reciente primero).
  final List<Visit> visits;
  final bool isSaved;
  final VoidCallback onClose;
  final VoidCallback onShare;
  final VoidCallback onDirections;
  final VoidCallback? onCall;
  final VoidCallback onToggleSave;
  final ValueChanged<Visit> onOpenVisit;
  final ValueChanged<int> onOpenGallery;

  /// Alto de la foto; la hoja se monta [sheetOverlap] por encima.
  static const double photosHeight = 372;
  static const double sheetOverlap = 32;

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
    required this.onOpenGallery,
    this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: _PhotoHeader(
            restaurant: restaurant,
            onClose: onClose,
            onShare: onShare,
            onOpenGallery: onOpenGallery,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: photosHeight - sheetOverlap),
          // La sombra de la hoja solo debe caer hacia arriba, sobre la foto:
          // se recorta por abajo para que no oscurezca el lienzo siguiente.
          child: ClipRect(
            clipper: const _ShadowAboveOnly(),
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
        ),
      ],
    );
  }
}

/// Recorte que deja pasar lo que se pinta por encima y a los lados (la
/// sombra de la hoja) pero nada por debajo del borde inferior.
class _ShadowAboveOnly extends CustomClipper<Rect> {
  const _ShadowAboveOnly();

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(-60, -80, size.width + 60, size.height);

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}

// ── Foto a sangre ───────────────────────────────────────────────────────────

class _PhotoHeader extends StatefulWidget {
  final Restaurant restaurant;
  final VoidCallback onClose;
  final VoidCallback onShare;
  final ValueChanged<int> onOpenGallery;

  const _PhotoHeader({
    required this.restaurant,
    required this.onClose,
    required this.onShare,
    required this.onOpenGallery,
  });

  @override
  State<_PhotoHeader> createState() => _PhotoHeaderState();
}

class _PhotoHeaderState extends State<_PhotoHeader> {
  final _page = PageController();
  int _index = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urls = fichaPhotoUrls(widget.restaurant);
    final top = MediaQuery.paddingOf(context).top;
    final chipLabel = urls.length == 1
        ? 'Ver la foto'
        : _index > 0
            ? '${_index + 1} de ${urls.length}'
            : 'Ver las ${urls.length} fotos';
    return SizedBox(
      height: GmFichaHeader.photosHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFF1C120C)),
          if (urls.isNotEmpty)
            Semantics(
              identifier: 'restaurant-detail-photos',
              button: true,
              label: chipLabel,
              child: GestureDetector(
                onTap: () => widget.onOpenGallery(_index),
                child: PageView.builder(
                  controller: _page,
                  itemCount: urls.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) => GmPhoto(urls[i],
                      decodeWidth: 1200, alignment: const Alignment(0, 0.24)),
                ),
              ),
            ),
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x8C000000),
                    Color(0x00000000),
                    Color(0x00000000),
                    Color(0x4D000000),
                  ],
                  stops: [0, 0.28, 0.7, 1],
                ),
              ),
            ),
          ),
          if (urls.isNotEmpty)
            Positioned(
              right: 16,
              bottom: GmFichaHeader.sheetOverlap + 18,
              child: GestureDetector(
                onTap: () => widget.onOpenGallery(_index),
                child: _SheenOnce(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(GmRadius.pill),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                      child: MediaQuery.withClampedTextScaling(
                        maxScaleFactor: 1.3,
                        child: Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0x5714100C),
                            borderRadius: BorderRadius.circular(GmRadius.pill),
                            border: Border.all(
                                color: const Color(0x59FFFFFF), width: 0.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GmIcon(GmIcons.photos,
                                  size: 14, color: Colors.white),
                              const SizedBox(width: 5),
                              Text(chipLabel,
                                  style: GmText.eyebrow(color: Colors.white)),
                            ],
                          ),
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
                  onTap: widget.onClose,
                ),
                const Spacer(),
                GmToolbarButton(
                  icon: GmIcons.share,
                  semanticLabel: 'Compartir',
                  identifier: 'restaurant-detail-share-button',
                  onTap: widget.onShare,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Brillo que cruza el cristal una vez (Sistema: «brillo del cristal»).
class _SheenOnce extends StatelessWidget {
  final Widget child;
  const _SheenOnce({required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(GmRadius.pill),
              child: GmOnce(
                duration: const Duration(milliseconds: 1100),
                delay: const Duration(milliseconds: 1000),
                builder: (_, t, __) {
                  if (t <= 0 || t >= 1) return const SizedBox.shrink();
                  final x = -1.3 + 2.6 * GmMotion.ease.transform(t);
                  return FractionalTranslation(
                    translation: Offset(x, 0),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0x00FFFFFF),
                            Color(0x8CFFFFFF),
                            Color(0x00FFFFFF),
                          ],
                          stops: [0.3, 0.48, 0.66],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Hoja: título, estado, meta, acciones, chips, visita ─────────────────────

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

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final r = restaurant;
    final type = restaurantTypeLabel(r.type);
    final muni = gmPlaceName(r.municipio);
    final eyebrow =
        [if (type.isNotEmpty) type, if (muni.isNotEmpty) muni].join(' · ');
    final status = fichaStatus(r, DateTime.now());
    final loc = context.watch<LocationCubit>().state;
    final dist = loc is LocationLoaded
        ? gmDistanceLabel(r, loc.latitude, loc.longitude)
        : null;
    final price = fichaPriceLabel(r, visits);
    final reviews = r.valoraciones.length;
    final latest = visits.isNotEmpty ? visits.first : null;
    final features = fichaFeatures(r, visits);

    final meta2 = TextStyle(
      fontSize: 15,
      height: 20 / 15,
      fontWeight: FontWeight.w400,
      color: gm.label2,
    );

    final metaItems = <Widget>[
      if (r.avgRating > 0) GmRating(r.avgRating, fontSize: 15, starSize: 13),
      if (reviews > 0)
        Text(reviews == 1 ? '1 reseña' : '$reviews reseñas', style: meta2),
      if (dist != null) Text(dist, style: meta2),
      if (price != null) Text(price, style: meta2),
    ];
    final meta = <Widget>[];
    for (var i = 0; i < metaItems.length; i++) {
      if (i > 0) meta.add(Text(' · ', style: meta2));
      meta.add(metaItems[i]);
    }

    final slots = <Widget>[
      if (r.season != null && r.season!.trim().isNotEmpty)
        _Slot(
          icon: GmIcon(GmIcons.sun, size: 13, color: gm.label),
          label: 'Temporada',
        ),
      if (fichaShowRank(r))
        _Slot(
          icon: const GmGlyph(GmGlyphKind.medalla, size: 13),
          label: (r.island != null && r.island!.trim().isNotEmpty)
              ? 'Nº ${r.rankNumber} en ${r.island}'
              : 'Nº ${r.rankNumber}',
          gold: true,
        ),
    ];

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
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 9, 20, 0),
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
                if (status != null) ...[
                  const SizedBox(height: 4),
                  _StatusLine(status: status),
                ],
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 2,
                    children: meta,
                  ),
                ],
                if (slots.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: slots),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GmRise(
            trigger: GmTrigger.mount,
            index: 1,
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
                    child: _SaveAction(saved: isSaved, onTap: onToggleSave),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (features.isNotEmpty) ...[
          const SizedBox(height: 12),
          GmRise(
            trigger: GmTrigger.mount,
            index: 2,
            child: FichaFeatureChips(features: features),
          ),
        ],
        if (latest != null) ...[
          SizedBox(height: features.isNotEmpty ? 8 : 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GmRise(
              trigger: GmTrigger.mount,
              index: 3,
              child: _VisitTeaser(
                visit: latest,
                fallbackThumb: fichaPhotoUrls(r).firstOrNull,
                quote: fichaTeaserQuote(latest, r.shortQuotes),
                onTap: () => onOpenVisit(latest),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatusLine extends StatelessWidget {
  final FichaStatus status;
  const _StatusLine({required this.status});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final color = status.open ? gm.greenText : gm.closedText;
    final rest = TextStyle(
      fontSize: 15,
      height: 20 / 15,
      fontWeight: FontWeight.w400,
      color: gm.label2,
    );
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: GmLiveDot(
            live: status.open,
            color: status.open ? gm.green : gm.closedText,
          ),
        ),
        Text(
          status.open ? 'Abierto' : 'Cerrado',
          style: rest.copyWith(fontWeight: FontWeight.w700, color: color),
        ),
        if (status.rest != null) ...[
          Text(' · ', style: rest),
          Text(status.rest!, style: rest),
        ],
      ],
    );
  }
}

class _Slot extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool gold;
  const _Slot({required this.icon, required this.label, this.gold = false});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: gold ? const Color(0x33C9A96B) : gm.fill,
        borderRadius: BorderRadius.circular(GmRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 5),
          Text(
            label,
            style: GmText.eyebrow(
              color: gold ? gm.bandInk : gm.label,
              w: gold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final String icon;
  final String label;
  final bool primary;
  final VoidCallback onTap;
  final String identifier;
  final Widget? iconWidget;

  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.identifier,
    this.primary = false,
    this.iconWidget,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final ink = primary ? Colors.white : gm.accent;
    return Semantics(
      identifier: identifier,
      button: true,
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
                      color: Color(0x99005A8C),
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
              iconWidget ?? GmIcon(icon, size: 22, color: ink),
              const SizedBox(height: 3),
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
                      letterSpacing: -0.2,
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

/// Guardar / Guardado: el marcador se rellena y da un único squash.
class _SaveAction extends StatefulWidget {
  final bool saved;
  final VoidCallback onTap;
  const _SaveAction({required this.saved, required this.onTap});

  @override
  State<_SaveAction> createState() => _SaveActionState();
}

class _SaveActionState extends State<_SaveAction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 760), value: 1);

  @override
  void didUpdateWidget(covariant _SaveAction old) {
    super.didUpdateWidget(old);
    if (widget.saved && !old.saved && !GmMotion.reduced(context)) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final icon = AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final k = _c.value;
        final sx = gmKeyframes(k,
            const [(0, 0.8), (0.3, 1.18), (0.52, 0.94), (0.72, 1.03), (1, 1)],
            curve: GmMotion.spring);
        final sy = gmKeyframes(k,
            const [(0, 0.8), (0.3, 0.84), (0.52, 1.06), (0.72, 0.98), (1, 1)],
            curve: GmMotion.spring);
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(sx, sy, 1),
          child: child,
        );
      },
      child: GmIcon(
        widget.saved ? GmIcons.bookmarkFilled : GmIcons.bookmark,
        size: 22,
        color: gm.accent,
      ),
    );
    return Semantics(
      toggled: widget.saved,
      child: _Action(
        icon: GmIcons.bookmark,
        iconWidget: icon,
        label: widget.saved ? 'Guardado' : 'Guardar',
        identifier: 'restaurant-detail-save-button',
        onTap: widget.onTap,
      ),
    );
  }
}

/// Chips de características con glifos propios y fundido en el borde.
class FichaFeatureChips extends StatelessWidget {
  final List<FichaFeature> features;
  const FichaFeatureChips({super.key, required this.features});

  /// Glifos de color fijo (oscuros o tierra) sobre un disco crema en modo
  /// noche, como las losetas de especialidades de la home: si no, el cochino
  /// negro desaparece sobre la tarjeta oscura.
  static Widget _onDisc(Widget glyph, GmColors gm, {Color? bg}) {
    if (!gm.isDark) return glyph;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: bg ?? const Color(0xFFE9DCC2),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Transform.scale(scale: 0.82, child: glyph),
    );
  }

  static Widget? glyph(FichaFeatureGlyph g, GmColors gm) {
    switch (g) {
      case FichaFeatureGlyph.terraza:
      case FichaFeatureGlyph.vistas:
        return GmIcon(GmIcons.sun, size: 16, color: gm.label);
      case FichaFeatureGlyph.conV:
        return GmIcon(GmIcons.conV, size: 18, color: gm.label);
      case FichaFeatureGlyph.cabra:
        return GmIcon(GmIcons.cabraChip, size: 17, color: gm.label);
      case FichaFeatureGlyph.cochino:
        return _onDisc(const GmGlyph(GmGlyphKind.cochino, size: 17), gm);
      case FichaFeatureGlyph.pescado:
        return _onDisc(const GmGlyph(GmGlyphKind.vieja, size: 17), gm,
            bg: const Color(0xFFE1E8D2));
      case FichaFeatureGlyph.vino:
        return GmIcon(GmIcons.wineGlass, size: 16, color: gm.label);
      case FichaFeatureGlyph.aparcamiento:
        return GmIcon(GmIcons.parking, size: 16, color: gm.label);
      case FichaFeatureGlyph.accesible:
        return GmIcon(GmIcons.accessible, size: 16, color: gm.label);
      case FichaFeatureGlyph.mascotas:
        return _onDisc(GmIcon(GmIcons.paw, size: 16, color: gm.label), gm);
      case FichaFeatureGlyph.datafono:
        return GmIcon(GmIcons.card, size: 16, color: gm.label);
      case FichaFeatureGlyph.infantil:
      case FichaFeatureGlyph.sinGluten:
      case FichaFeatureGlyph.ninguno:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: SizedBox(
        height: 32 + 18,
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => LinearGradient(
            colors: const [Colors.black, Colors.black, Colors.transparent],
            stops: [0, (rect.width - 24) / rect.width, 1],
          ).createShader(rect),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            itemCount: features.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final f = features[i];
              final g = glyph(f.glyph, gm);
              return Container(
                height: 32,
                padding: EdgeInsets.fromLTRB(g == null ? 12 : 10, 0, 12, 0),
                decoration: BoxDecoration(
                  color: gm.card,
                  borderRadius: BorderRadius.circular(GmRadius.pill),
                  boxShadow: gm.shadow1,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (g != null) ...[g, const SizedBox(width: 6)],
                    Text(
                      f.label,
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
      ),
    );
  }
}

/// «Jonay y Joana estuvieron aquí» — tarjeta vino con la miniatura real del
/// vídeo, una cita literal y la fecha de la visita.
class _VisitTeaser extends StatelessWidget {
  final Visit visit;
  final String? quote;
  final VoidCallback onTap;

  /// Foto del local si la visita no trae miniatura.
  final String? fallbackThumb;
  const _VisitTeaser(
      {required this.visit,
      required this.quote,
      required this.onTap,
      this.fallbackThumb});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final date = fichaDateFromIso(visit.sortDate);
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
            gradient: const RadialGradient(
              center: Alignment.topRight,
              radius: 1.4,
              colors: [Color(0xFF4A2A22), GmColors.wine],
              stops: [0, 0.6],
            ),
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
                      Builder(builder: (_) {
                        final thumbs = [
                          ...fichaVisitThumbs(visit),
                          if (fallbackThumb != null) fallbackThumb!,
                        ];
                        return GmPhoto(thumbs.firstOrNull,
                            decodeWidth: 240,
                            fallbacks: thumbs.skip(1).toList());
                      }),
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
                      quote ?? 'Mira lo que probaron',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 21 / 16,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: GmColors.creamHi,
                      ),
                    ),
                    if (date != null) ...[
                      const SizedBox(height: 2),
                      Text('Visita del $date',
                          style: GmText.chip(
                              color: const Color(0xB8F2E8D5),
                              w: FontWeight.w400)),
                    ],
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
