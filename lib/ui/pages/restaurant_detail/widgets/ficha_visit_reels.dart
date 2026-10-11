import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show GmPhoto;
import 'package:guachinches/ui/pages/restaurant_detail/ficha_logic.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/dishes_section.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/ficha_sections.dart'
    show FichaSayingsCarousel;
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

/// «Visitas de Jonay y Joana» con portadas tipo Reels (tablero FichaCompleta
/// · Sistema §07 «Portada de visita · tipo Reels»). El short ES la visita:
/// una sola sección con la cabecera del anillo de historia, las portadas 9:16
/// (la más reciente a 160 × 284 con anillo, las anteriores a 132 × 234 en
/// carrusel), los platos de la visita elegida con «Ver visita completa» y
/// «Lo que dicen en el vídeo».

/// Anillo de historia Atlántico → oro → naranja.
const fichaStoryRing = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFF0085C4),
    Color(0xFF4DAEDB),
    Color(0xFFC9A96B),
    Color(0xFFE0603A),
  ],
  stops: [0, 0.35, 0.75, 1],
);

/// Hueco del anillo (3 de degradado + 2 de lienzo) alrededor de la portada.
const double _ringPad = 5;

/// Avatar de Jonay y Joana con el anillo de historia: un fotograma de su
/// última visita recortado en círculo.
class FichaStoryAvatar extends StatelessWidget {
  final List<String> thumbs;
  final double size;
  final double photo;

  /// Color del hueco entre anillo y foto (el lienzo por defecto).
  final Color? gap;

  const FichaStoryAvatar({
    super.key,
    required this.thumbs,
    this.size = 46,
    this.photo = 40,
    this.gap,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
            gradient: fichaStoryRing, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Container(
          width: photo + 4,
          height: photo + 4,
          decoration:
              BoxDecoration(color: gap ?? gm.canvas, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: ClipOval(
            child: SizedBox(
              width: photo,
              height: photo,
              child: GmPhoto(
                thumbs.firstOrNull,
                decodeWidth: (photo * 3).round(),
                alignment: Alignment.center,
                fallbacks: thumbs.skip(1).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FichaVisitReels extends StatefulWidget {
  final Restaurant restaurant;

  /// Visitas ordenadas (la más reciente primero).
  final List<Visit> visits;

  /// Abre el reproductor de la visita.
  final ValueChanged<Visit> onOpenVisit;

  /// Cita del teaser de la cabecera (para no repetirla aquí).
  final String? teaserQuote;

  const FichaVisitReels({
    super.key,
    required this.restaurant,
    required this.visits,
    required this.onOpenVisit,
    this.teaserQuote,
  });

  @override
  State<FichaVisitReels> createState() => _FichaVisitReelsState();
}

class _FichaVisitReelsState extends State<FichaVisitReels> {
  String? _selectedId;

  void _tapCover(Visit v, bool selected) {
    if (selected) {
      widget.onOpenVisit(v);
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _selectedId = v.id);
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final r = widget.restaurant;
    final visits = widget.visits;
    final selected = fichaSelectedVisit(visits, _selectedId);
    if (selected == null) return const SizedBox.shrink();
    final venuePhoto = fichaPhotoUrls(r).firstOrNull;
    final single = visits.length == 1;
    final reduced = GmMotion.reduced(context);
    final fade = Duration(milliseconds: reduced ? 0 : 260);

    final teaser = widget.teaserQuote;
    final columnQuote = single
        ? fichaReelQuote(selected, exclude: [if (teaser != null) teaser])
        : null;
    final sayings = fichaVisitSayings(r, selected, exclude: [
      if (teaser != null) teaser,
      if (columnQuote != null) columnQuote,
    ]);

    Widget cover(int i) {
      final v = visits[i];
      final isSel = v.id == selected.id;
      return _ReelCover(
        visit: v,
        index: i,
        selected: isSel,
        venuePhoto: venuePhoto,
        onTap: () => _tapCover(v, isSel),
      );
    }

    final lead = fichaReelSize(0);
    final leadH = lead.height + _ringPad * 2;

    return Semantics(
      identifier: 'restaurant-detail-visits',
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabecera: avatar con anillo + «N visitas · YouTube Shorts».
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                FichaStoryAvatar(
                  thumbs: fichaReelThumbs(visits.first, venuePhoto: venuePhoto),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GmEyebrow(
                          text:
                              '${fichaVisitCount(visits.length)} · YouTube Shorts'),
                      Semantics(
                        header: true,
                        child: Text('Visitas de Jonay y Joana',
                            style: GmText.title2(color: gm.label)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Portadas.
          if (single)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  cover(0),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ReelInfo(
                      visit: selected,
                      quote: columnQuote,
                      height: leadH,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: leadH,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: visits.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => i == 0
                    ? cover(0)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          cover(i),
                          const SizedBox(height: 1),
                          MediaQuery.withClampedTextScaling(
                            maxScaleFactor: 1.3,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 9),
                              child: Text(
                                fichaDateFromIso(visits[i].sortDate) ?? '',
                                style: GmText.meta(color: gm.label2),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          const SizedBox(height: 10),
          // Platos de la visita elegida + «Ver visita completa».
          AnimatedSize(
            duration: Duration(milliseconds: reduced ? 0 : 320),
            curve: GmMotion.settle,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: fade,
              switchInCurve: GmMotion.ease,
              switchOutCurve: GmMotion.ease,
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topCenter,
                children: [...previous, if (current != null) current],
              ),
              child: Padding(
                key: ValueKey('dishes-${selected.id}'),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _OrderedCard(
                  visit: selected,
                  onOpenVisit: () => widget.onOpenVisit(selected),
                ),
              ),
            ),
          ),
          // «Lo que dicen en el vídeo».
          AnimatedSwitcher(
            duration: fade,
            switchInCurve: GmMotion.ease,
            switchOutCurve: GmMotion.ease,
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [...previous, if (current != null) current],
            ),
            child: sayings.isEmpty
                ? SizedBox(
                    key: ValueKey('say-${selected.id}'), width: double.infinity)
                : Semantics(
                    key: ValueKey('say-${selected.id}'),
                    identifier: 'restaurant-detail-visit-sayings',
                    container: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: GmEyebrow(text: 'Lo que dicen en el vídeo'),
                        ),
                        FichaSayingsCarousel(sayings: sayings),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Portada 9:16 de una visita (Sistema §07): miniatura a sangre, chips de
/// cristal con fecha corta y duración, «Les encantó» (solo muy positiva) y
/// la pila de platos con «+N». La elegida lleva el anillo de historia.
class _ReelCover extends StatelessWidget {
  final Visit visit;
  final int index;
  final bool selected;
  final String? venuePhoto;
  final VoidCallback onTap;

  const _ReelCover({
    required this.visit,
    required this.index,
    required this.selected,
    required this.onTap,
    this.venuePhoto,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final v = visit;
    final size = fichaReelSize(index);
    final thumbs = fichaReelThumbs(v, venuePhoto: venuePhoto);
    final shortDate = fichaShortDateFromIso(v.sortDate);
    final longDate = fichaDateFromIso(v.sortDate);
    final duration = fichaVisitDuration(v);
    final stack = fichaDishStack(v);
    final loved = fichaLoved(v);
    final reduced = GmMotion.reduced(context);

    final card = ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFF1C120C)),
            // Las miniaturas 16:9 de YouTube traen el cuadro vertical en el
            // centro: `cover` + centro lo recorta a sangre.
            GmPhoto(
              thumbs.firstOrNull,
              decodeWidth: (size.width * 3).round(),
              fallbacks: thumbs.skip(1).toList(),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x61000000),
                    Color(0x00000000),
                    Color(0x00000000),
                    Color(0xC7000000),
                  ],
                  stops: [0, 0.26, 0.48, 1],
                ),
              ),
            ),
            if (shortDate != null)
              Positioned(
                left: 8,
                top: 8,
                child: GmPhotoChip(label: shortDate, dark: true),
              ),
            if (duration != null)
              Positioned(
                right: 8,
                top: 8,
                // El glifo de reel solo en la portada grande: en las de 132
                // no caben los dos chips con glifo (tablero).
                child: GmPhotoChip(
                  label: duration,
                  dark: true,
                  leading: index == 0
                      ? GmIcon(GmIcons.reel, size: 13, color: Colors.white)
                      : null,
                ),
              ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (loved) FichaLovedSeal(compact: index > 0),
                    if (loved && stack.photos.isNotEmpty)
                      const SizedBox(height: 8),
                    if (stack.photos.isNotEmpty)
                      _DishStack(photos: stack.photos, more: stack.more),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Semantics(
      identifier: 'restaurant-detail-visit-cover-$index',
      button: true,
      selected: selected,
      label: selected
          ? 'Ver la visita${longDate == null ? '' : ' del $longDate'}'
          : 'Elegir la visita${longDate == null ? '' : ' del $longDate'}',
      excludeSemantics: true,
      child: GmPressable(
        onTap: onTap,
        pressedScale: 0.97,
        child: SizedBox(
          width: size.width + _ringPad * 2,
          height: size.height + _ringPad * 2,
          child: Stack(
            children: [
              // Anillo de historia: aparece/desaparece con un fundido suave al
              // cambiar de visita (sin mover nada de sitio).
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: selected ? 1 : 0,
                  duration: Duration(milliseconds: reduced ? 0 : 220),
                  curve: GmMotion.ease,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: fichaStoryRing,
                      borderRadius: BorderRadius.circular(23),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: gm.canvas,
                      borderRadius: BorderRadius.circular(21),
                    ),
                  ),
                ),
              ),
              Positioned(left: _ringPad, top: _ringPad, child: card),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pila de platos en círculo (28, borde blanco, solapados) + «+N».
class _DishStack extends StatelessWidget {
  final List<String> photos;
  final int more;
  const _DishStack({required this.photos, required this.more});

  @override
  Widget build(BuildContext context) {
    const d = 28.0;
    const step = d - 9;
    final width = d + step * (photos.length - 1);
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: width + 4,
            height: d + 4,
            child: Stack(
              children: [
                for (var i = photos.length - 1; i >= 0; i--)
                  Positioned(
                    left: i * step,
                    top: 0,
                    child: Container(
                      width: d + 4,
                      height: d + 4,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Color(0x4D000000),
                              offset: Offset(0, 2),
                              blurRadius: 6),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: ClipOval(
                        child: SizedBox(
                          width: d,
                          height: d,
                          child: GmPhoto(photos[i], decodeWidth: 96),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (more > 0)
            Transform.translate(
              offset: const Offset(-8, 0),
              child: Container(
                height: d + 4,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xE6FFFFFF),
                  borderRadius: BorderRadius.circular(GmRadius.pill),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$more',
                  style: GmText.chip(
                      color: const Color(0xFF1F1A14), w: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Columna a la derecha de la portada cuando solo hay una visita: fecha,
/// «Short · 1:35 · 6 platos», una cita literal y «Ver en YouTube».
class _ReelInfo extends StatelessWidget {
  final Visit visit;
  final String? quote;
  final double height;
  const _ReelInfo(
      {required this.visit, required this.quote, required this.height});

  Future<void> _openYoutube() async {
    final id = fichaYoutubeId(visit);
    final raw = id != null ? 'https://youtube.com/shorts/$id' : visit.videoUrl;
    final uri = Uri.tryParse(raw ?? '');
    if (uri == null) return;
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) AppLogger.warn('restaurant-detail', 'no se pudo abrir $uri');
    } catch (e) {
      AppLogger.warn('restaurant-detail', 'no se pudo abrir $uri: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final v = visit;
    final date = fichaDateFromIso(v.sortDate);
    final hasYoutube =
        fichaYoutubeId(v) != null || (v.videoUrl?.trim().isNotEmpty ?? false);
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 6, 0, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Última visita',
                      style: GmText.eyebrow(color: gm.label2)),
                  if (date != null) ...[
                    const SizedBox(height: 3),
                    Text(date,
                        style: GmText.guideTitle(color: gm.label)
                            .copyWith(letterSpacing: -0.3)),
                  ],
                  const SizedBox(height: 3),
                  Text(fichaReelMeta(v),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GmText.meta(color: gm.label2)),
                ],
              ),
              if (quote != null)
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Container(
                      padding: const EdgeInsets.only(left: 10),
                      decoration: const BoxDecoration(
                        border: Border(
                            left: BorderSide(color: GmColors.gold, width: 3)),
                      ),
                      child: Text(
                        quote!,
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          height: 21 / 15,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                          color: gm.label,
                        ),
                      ),
                    ),
                  ),
                ),
              if (hasYoutube)
                Semantics(
                  identifier: 'restaurant-detail-visit-youtube',
                  button: true,
                  label: 'Ver en YouTube',
                  excludeSemantics: true,
                  child: GmPressable(
                    onTap: _openYoutube,
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: gm.accentSoft,
                        borderRadius: BorderRadius.circular(GmRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GmIcon(GmIcons.play, size: 11, color: gm.accent),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text('Ver en YouTube',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GmText.sub(
                                    color: gm.accent, w: FontWeight.w600)),
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
    );
  }
}

/// «Lo que pidieron el 8 oct · 5 les encantaron» + rejilla de platos +
/// «Ver visita completa» (abre el reproductor).
class _OrderedCard extends StatelessWidget {
  final Visit visit;
  final VoidCallback onOpenVisit;
  const _OrderedCard({required this.visit, required this.onOpenVisit});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final v = visit;
    final dishes = fichaNamedDishes(v);
    final photoDishes = [
      for (final d in dishes)
        if (d.photoUrl != null) d
    ];
    return GmCard(
      radius: 26,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (dishes.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: GmEyebrow(text: fichaOrderedEyebrow(v)),
            ),
            const SizedBox(height: 8),
            FichaDishGrid(
              dishes: dishes,
              photoDishes: photoDishes,
              heroPrefix: '${v.id}-ficha',
              onTap: (d) {
                final idx = photoDishes.indexOf(d);
                if (idx < 0) return;
                showDishPhotoViewer(context,
                    dishes: photoDishes,
                    initialIndex: idx,
                    heroPrefix: '${v.id}-ficha');
              },
            ),
            const SizedBox(height: 8),
          ],
          Semantics(
            identifier: 'restaurant-detail-visit-full',
            button: true,
            label: 'Ver visita completa',
            excludeSemantics: true,
            child: GmPressable(
              onTap: onOpenVisit,
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: gm.accentSoft,
                  borderRadius: BorderRadius.circular(GmRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GmIcon(GmIcons.video, size: 18, color: gm.accent),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text('Ver visita completa',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GmText.body(
                              color: gm.accent, w: FontWeight.w600)),
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

/// Sello «Les encantó» (vino + oro), solo con visitas muy positivas.
class FichaLovedSeal extends StatelessWidget {
  /// Versión ajustada para las portadas pequeñas (132 de ancho).
  final bool compact;
  const FichaLovedSeal({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 9),
      decoration: BoxDecoration(
        color: GmColors.wine,
        borderRadius: BorderRadius.circular(GmRadius.pill),
        border: Border.all(color: const Color(0x80C9A96B)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GmIcon(GmIcons.thumb, size: compact ? 11 : 12, color: GmColors.gold),
          SizedBox(width: compact ? 4 : 5),
          Flexible(
            child: Text('Les encantó',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE8CF9A))),
          ),
        ],
      ),
    );
  }
}

/// Rejilla de platos de una visita (3 columnas, foto + nombre en 3 líneas).
class FichaDishGrid extends StatelessWidget {
  final List<VisitDish> dishes;
  final List<VisitDish> photoDishes;
  final ValueChanged<VisitDish> onTap;
  final String heroPrefix;
  const FichaDishGrid({
    super.key,
    required this.dishes,
    required this.photoDishes,
    required this.onTap,
    required this.heroPrefix,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final nameH =
        MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3).scale(16) *
            3;
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
