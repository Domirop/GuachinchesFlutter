import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guachinches/data/model/Visit.dart' as vm;
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show GmPhoto, gmDisplayName;
import 'package:guachinches/ui/pages/restaurant_detail/widgets/dishes_section.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams;

/// Platos de una visita (tablero VisitaPlatos): título grande «Lo que
/// probaron», subtítulo con recuentos, tarjeta crema «Si vas, pide» (solo si
/// hay platos destacados) y rejilla 2 columnas de platos con el sello «Top».
/// Tocar un plato con foto abre el visor de fotos de siempre.
class VisitDishesScreen extends StatelessWidget {
  final vm.Visit visit;

  const VisitDishesScreen({super.key, required this.visit});

  static bool _loved(vm.VisitDish d) => d.sentiment == 'loved';

  /// «**Tomates rellenos** y favada, churritos.» a partir de los destacados.
  static List<InlineSpan>? recommendation(List<vm.VisitDish> dishes) {
    final tops = [for (final d in dishes) if (d.isTop && d.name.trim().isNotEmpty) d.name.trim()];
    if (tops.isEmpty) return null;
    String lower(String s) => s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);
    final rest = tops.skip(1).take(3).map(lower).toList();
    final tail = rest.isEmpty
        ? '.'
        : rest.length == 1
            ? ' y ${rest.first}.'
            : ', ${rest.sublist(0, rest.length - 1).join(', ')} y ${rest.last}.';
    return [
      TextSpan(
          text: tops.first,
          style: const TextStyle(fontWeight: FontWeight.w700)),
      TextSpan(text: tail),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final dishes = visit.dishes.where((d) => d.name.trim().isNotEmpty).toList();
    final name = gmDisplayName(
        (visit.name?.isNotEmpty == true ? visit.name! : visit.restaurant?.nombre) ?? '');
    final lovedCount = dishes.where(_loved).length;
    final subtitle = [
      if (name.isNotEmpty) name,
      dishes.length == 1 ? '1 plato' : '${dishes.length} platos',
      if (lovedCount > 0)
        lovedCount == 1 ? '1 les encantó' : '$lovedCount les encantaron',
    ].join(' · ');
    final rec = recommendation(dishes);
    final photoDishes = [for (final d in dishes) if (d.photoUrl != null) d];
    final top = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: gm.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
      backgroundColor: gm.canvas,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: top + 52 + 4)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.list(children: [
                  GmRise(
                    trigger: GmTrigger.mount,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Lo que probaron',
                              style: GmText.largeTitle(color: gm.label)
                                  .copyWith(letterSpacing: -0.8)),
                          const SizedBox(height: 2),
                          Text(subtitle, style: GmText.body(color: gm.label2)),
                        ],
                      ),
                    ),
                  ),
                  if (rec != null) ...[
                    const SizedBox(height: 16),
                    GmRise(
                      trigger: GmTrigger.mount,
                      index: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: gm.band,
                          borderRadius: BorderRadius.circular(GmRadius.card),
                          border: Border.all(color: gm.sep),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: GmColors.wine,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0x8CC9A96B)),
                              ),
                              alignment: Alignment.center,
                              child: GmIcon(GmIcons.thumb,
                                  size: 18, color: GmColors.gold),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Si vas, pide',
                                      style: GmText.eyebrow(color: gm.bandInk)),
                                  Text.rich(
                                    TextSpan(children: rec),
                                    style: TextStyle(
                                      fontSize: 15,
                                      height: 21 / 15,
                                      fontWeight: FontWeight.w400,
                                      color: gm.label,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ]),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    16, 0, 16, MediaQuery.paddingOf(context).bottom + 40),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    // Foto 4:3 + nombre entero en dos líneas:
                    // (ancho − 12) · ¾ + 24 + 2 líneas de 18.
                    mainAxisExtent:
                        ((MediaQuery.sizeOf(context).width - 44) / 2 - 12) *
                                3 /
                                4 +
                            24 +
                            MediaQuery.textScalerOf(context).scale(18) * 2,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final d = dishes[i];
                      final photoIndex = photoDishes.indexOf(d);
                      return GmRise(
                        trigger: GmTrigger.mount,
                        index: 2 + i.clamp(0, 6),
                        child: GmDishCard(
                          dish: d,
                          nameLines: 2,
                          heroTag: photoIndex >= 0
                              ? '${visit.id}-platos-$photoIndex'
                              : null,
                          onTap: photoIndex < 0
                              ? null
                              : () => showDishPhotoViewer(
                                    ctx,
                                    dishes: photoDishes,
                                    initialIndex: photoIndex,
                                    heroPrefix: '${visit.id}-platos',
                                  ),
                        ),
                      );
                    },
                    childCount: dishes.length,
                  ),
                ),
              ),
            ],
          ),
          // Fundido inferior.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 90,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [gm.edgeFade0, gm.edgeFade1],
                    stops: const [0, 0.7],
                  ),
                ),
              ),
            ),
          ),
          // Barra de herramientas: volver + compartir (cristal claro).
          Positioned(
            left: 16,
            right: 16,
            top: top + 4,
            child: Row(
              children: [
                GmToolbarButton(
                  icon: GmIcons.chevronLeft,
                  iconSize: 20,
                  light: true,
                  semanticLabel: 'Volver a la visita',
                  identifier: 'visit-dishes-back-button',
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const Spacer(),
                GmToolbarButton(
                  icon: GmIcons.share,
                  iconSize: 19,
                  light: true,
                  semanticLabel: 'Compartir',
                  identifier: 'visit-dishes-share-button',
                  onTap: () => SharePlus.instance.share(ShareParams(
                      text:
                          'Lo que probaron Jonay y Joana en $name · ¿Dónde Comer Canarias?')),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

/// Tarjeta de plato: tarjeta blanca r24 con foto r18 (4:3), sello «Top» y
/// nombre 13/18 · 600 ([nameLines] líneas; dos en «Lo que probaron» para
/// que se lea entero).
class GmDishCard extends StatelessWidget {
  final vm.VisitDish dish;
  final String? heroTag;
  final VoidCallback? onTap;
  final double photoRadius;
  final double cardRadius;
  final double? photoHeight;
  final int nameLines;

  const GmDishCard({
    super.key,
    required this.dish,
    this.heroTag,
    this.onTap,
    this.photoRadius = GmRadius.photo,
    this.cardRadius = GmRadius.card,
    this.photoHeight,
    this.nameLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    Widget photo = dish.photoUrl != null
        ? GmPhoto(dish.photoUrl, decodeWidth: 520)
        : const GmDishNoPhoto(glyphSize: 30);
    if (heroTag != null) photo = Hero(tag: heroTag!, child: photo);
    final img = ClipRRect(
      borderRadius: BorderRadius.circular(photoRadius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          photo,
          if (dish.isTop)
            Positioned(
              left: 8,
              top: 8,
              child: GmPhotoChip(
                leading: GmIcon(GmIcons.star, size: 10, color: GmColors.star),
                label: 'Top',
              ),
            ),
        ],
      ),
    );
    return GmPressable(
      onTap: onTap,
      semanticsLabel: dish.name,
      child: GmCard(
        radius: cardRadius,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (photoHeight != null)
                SizedBox(height: photoHeight, child: img)
              else
                Expanded(child: img),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 8, 6, 4),
                child: SizedBox(
                  height: MediaQuery.textScalerOf(context).scale(18) * nameLines,
                  child: Text(
                    dish.name,
                    maxLines: nameLines,
                    overflow: TextOverflow.ellipsis,
                    style: GmText.eyebrow(color: gm.label)
                        .copyWith(letterSpacing: -0.24),
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

/// Hueco de un plato sin foto: banda crema con el glifo de plato (mismo
/// aspecto en la ficha, la tira del reel y «Lo que probaron»), en lugar de
/// una tarjeta gris vacía.
class GmDishNoPhoto extends StatelessWidget {
  final double glyphSize;

  /// Colores fijos claros (tarjetas blancas sobre el vídeo del reel).
  final bool alwaysLight;

  const GmDishNoPhoto({super.key, this.glyphSize = 26, this.alwaysLight = false});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final bg = alwaysLight ? const Color(0xFFF2E8D5) : gm.band;
    final ink = alwaysLight ? const Color(0xFF8A6A3A) : gm.bandInk;
    return ColoredBox(
      color: bg,
      child: Center(
        child: GmIcon(GmIcons.dish,
            size: glyphSize, color: ink.withValues(alpha: 0.7)),
      ),
    );
  }
}
