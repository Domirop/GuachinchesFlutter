import 'package:flutter/material.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/components/shimmer_box.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:guachinches/utils/open_state.dart';
import 'package:guachinches/utils/opening_later_utils.dart';

/// Bloque «Hoy» del rediseño iOS 27 (tablero InicioCompleto · sección 4).
///
/// - Antetítulo con punto vivo + momento del día + recuento.
/// - Título pulsable con chevron (misma navegación que el antiguo «Ver
///   todos»: búsqueda contextual con `openOnly`).
/// - Rejilla 2×2 de tarjetas de sitio. Por la mañana, como en el tablero:
///   2 tarjetas + la tarjeta «barraquito» que lleva a ver todos.
///
/// Modos: abiertos ahora (por defecto), [openingSoon] (fallback «abren
/// pronto» en islas donde la cocina arranca más tarde) y esqueleto
/// (`count == null`). La copy por hora es la de siempre, en tipo frase.
class TodayGridSection extends StatelessWidget {
  final int hour;
  final int minute;

  /// Total de sitios del pool contextual (recuento del antetítulo).
  /// `null` durante la carga → esqueleto.
  final int? count;

  /// Sitios a pintar (se usan hasta 4).
  final List<Restaurant> restaurants;

  final double? userLat;
  final double? userLon;

  final ValueChanged<String> onRestaurantTap;
  final VoidCallback? onSeeAll;

  /// Fallback «abren pronto»: no hay nada abierto ahora pero sí más tarde.
  final bool openingSoon;
  final String? zoneLabel;

  const TodayGridSection({
    super.key,
    required this.hour,
    this.minute = 0,
    required this.restaurants,
    required this.onRestaurantTap,
    this.count,
    this.userLat,
    this.userLon,
    this.onSeeAll,
    this.openingSoon = false,
    this.zoneLabel,
  });

  bool get _loading => count == null;

  static bool _isBreakfast(int hour) => hour >= 7 && hour <= 11;

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final copy = openingSoon
        ? TodayCopy(
            'En breve',
            (zoneLabel != null && zoneLabel!.trim().isNotEmpty)
                ? 'Abren pronto en $zoneLabel'
                : 'Abren pronto',
          )
        : copyForHour(hour, minute);

    final n = count;
    final countText = n == null
        ? null
        : openingSoon
            ? (n == 1 ? '1 abre hoy' : '$n abren hoy')
            : (n == 1 ? '1 abierto' : '$n abiertos');

    final eyebrow = GmEyebrow(
      leading: openingSoon
          ? const GmLiveDot(color: Color(0xFFE39B17))
          : GmLiveDot(live: !_loading),
      spans: [
        TextSpan(
          text: copy.eyebrow,
          style: TextStyle(
              color: openingSoon ? const Color(0xFFB07210) : gm.greenText),
        ),
        if (countText != null) ...[
          const TextSpan(text: '  ·  '),
          TextSpan(text: countText),
        ],
      ],
    );

    // Mañana: 2 tarjetas + tarjeta «barraquito» (tablero, momento mañana).
    final breakfastTile = !openingSoon &&
        !_loading &&
        onSeeAll != null &&
        _isBreakfast(hour) &&
        (n ?? 0) > 2 &&
        restaurants.length >= 2;
    // Rejilla sin huecos: número par de tarjetas (1 sola ocupa el ancho).
    var cards = restaurants.take(breakfastTile ? 2 : 4).toList();
    if (cards.length > 1 && cards.length.isOdd) {
      cards = cards.take(cards.length - 1).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GmRise(
          trigger: GmTrigger.mount,
          index: 1,
          child: GmSectionHeader(
            eyebrow: eyebrow,
            title: copy.title,
            onTap: openingSoon ? null : onSeeAll,
            identifier: 'home-today-see-all',
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
          child: _loading
              ? const _GridSkeleton()
              : _Grid(
                  restaurants: cards,
                  userLat: userLat,
                  userLon: userLon,
                  openingSoon: openingSoon,
                  onRestaurantTap: onRestaurantTap,
                  footer: breakfastTile
                      ? _BreakfastTile(
                          more: n! - cards.length,
                          total: n,
                          onTap: onSeeAll!,
                        )
                      : null,
                ),
        ),
      ],
    );
  }

  /// Copy por hora (la de siempre, ahora en tipo frase).
  static TodayCopy copyForHour(int hour, int minute) {
    final mins = hour * 60 + minute;
    if (hour >= 7 && hour <= 11) {
      return const TodayCopy('Hora del desayuno', 'Sitios para desayunar');
    }
    // Almuerzo: 12:00–15:29 en su hora punta…
    if (mins >= 12 * 60 && mins < 15 * 60 + 30) {
      return const TodayCopy('Hora del almuerzo', 'Sitios para almorzar');
    }
    // …y de 15:30 a 16:59 los que TODAVÍA siguen abiertos para almorzar.
    if (mins >= 15 * 60 + 30 && hour <= 16) {
      return const TodayCopy('Todavía abiertos', 'Sitios para almorzar');
    }
    if (hour >= 17 && hour <= 19) {
      return const TodayCopy('Golden hour', 'Terrazas al atardecer');
    }
    if (hour >= 20) {
      return const TodayCopy('Hora de la cena', 'Sitios para cenar');
    }
    return const TodayCopy('De madrugada', 'Sitios abiertos ahora');
  }
}

class TodayCopy {
  final String eyebrow;
  final String title;
  const TodayCopy(this.eyebrow, this.title);
}

// ── Rejilla 2 columnas ─────────────────────────────────────────────────────

class _Grid extends StatelessWidget {
  final List<Restaurant> restaurants;
  final double? userLat;
  final double? userLon;
  final bool openingSoon;
  final ValueChanged<String> onRestaurantTap;
  final Widget? footer;

  const _Grid({
    required this.restaurants,
    required this.userLat,
    required this.userLon,
    required this.openingSoon,
    required this.onRestaurantTap,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    Widget card(Restaurant r, int i, {double photoAspect = 4 / 3}) {
      final Widget leading;
      if (openingSoon) {
        final at = nextOpenLabel(r.horariosJson, now);
        leading = _OpensAt(label: at);
      } else {
        final open = isRestaurantOpenNow(r, now);
        leading = open ? const GmOpenLabel() : const SizedBox.shrink();
      }
      return GmRise(
        trigger: GmTrigger.mount,
        index: 2 + i,
        child: GmPlaceCard(
          restaurant: r,
          photoAspect: photoAspect,
          onTap: () => onRestaurantTap(r.id),
          chip: gmLocationChip(context, r,
              distanceLabel: gmDistanceLabel(r, userLat, userLon)),
          meta: GmMetaRow(leading: leading, rating: r.avgRating),
        ),
      );
    }

    final rows = <Widget>[];
    if (restaurants.length == 1) {
      // Un único sitio: tarjeta a todo el ancho con foto más apaisada.
      rows
        ..add(card(restaurants.first, 0, photoAspect: 2))
        ..add(const SizedBox(height: 12));
    }
    for (var i = 0; restaurants.length > 1 && i < restaurants.length; i += 2) {
      final right = i + 1 < restaurants.length ? restaurants[i + 1] : null;
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: card(restaurants[i], i)),
          const SizedBox(width: 12),
          Expanded(
            child: right == null ? const SizedBox.shrink() : card(right, i + 1),
          ),
        ],
      ));
      rows.add(const SizedBox(height: 12));
    }
    if (footer != null) {
      rows.add(GmRise(trigger: GmTrigger.mount, index: 2, child: footer!));
    } else if (rows.isNotEmpty) {
      rows.removeLast();
    }
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}

class _OpensAt extends StatelessWidget {
  final String? label;
  const _OpensAt({this.label});

  @override
  Widget build(BuildContext context) {
    if (label == null) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const GmLiveDot(color: Color(0xFFE39B17)),
        const SizedBox(width: 5),
        Text(
          'Abre a las $label',
          style: GmText.eyebrow(color: const Color(0xFFB07210)),
        ),
      ],
    );
  }
}

/// Tarjeta «barraquito» de la mañana (banda crema, glifo, «Ver los N sitios»).
class _BreakfastTile extends StatelessWidget {
  final int more;
  final int total;
  final VoidCallback onTap;

  const _BreakfastTile({
    required this.more,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return GmPressable(
      onTap: onTap,
      semanticsLabel: 'Ver los $total sitios con desayuno',
      child: Container(
        constraints: const BoxConstraints(minHeight: 213),
        padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
        decoration: BoxDecoration(
          color: gm.band,
          borderRadius: BorderRadius.circular(GmRadius.card),
          border: Border.all(color: gm.sep),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -36,
              bottom: -44,
              child: Container(
                width: 150,
                height: 150,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    Color(0x59C9A96B),
                    Color(0x00C9A96B),
                  ], stops: [
                    0,
                    0.7
                  ]),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: GmColors.creamHi,
                    shape: BoxShape.circle,
                    boxShadow: gm.shadow1,
                  ),
                  alignment: Alignment.center,
                  child: const GmGlyph(GmGlyphKind.barraquito, size: 34),
                ),
                const SizedBox(height: 7),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      more == 1
                          ? 'Y 1 sitio más con desayuno'
                          : 'Y $more sitios más con desayuno',
                      style: GmText.eyebrow(color: gm.bandInk),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Barraquito, bocadillo de pata y zumo natural',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GmText.poster(color: gm.label)
                          .copyWith(letterSpacing: -0.4),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
                  decoration: BoxDecoration(
                    color: gm.card,
                    borderRadius: BorderRadius.circular(GmRadius.pill),
                    boxShadow: gm.shadow1,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Ver los $total sitios',
                          style:
                              GmText.body(color: gm.label, w: FontWeight.w600)),
                      const SizedBox(width: 2),
                      GmIcon(GmIcons.chevronRight, size: 14, color: gm.label2),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Esqueleto de carga (misma rejilla 2×2) ─────────────────────────────────

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget cell() => const GmCard(
          child: Padding(
            padding: EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: ShimmerBox(
                    width: double.infinity,
                    height: double.infinity,
                    radius: GmRadius.photo,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(6, 11, 6, 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 40,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerBox(
                                width: double.infinity, height: 14, radius: 5),
                            SizedBox(height: 7),
                            ShimmerBox(width: 90, height: 14, radius: 5),
                          ],
                        ),
                      ),
                      SizedBox(height: 4),
                      ShimmerBox(width: 70, height: 13, radius: 5),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

    Widget row() => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cell()),
            const SizedBox(width: 12),
            Expanded(child: cell()),
          ],
        );

    return Column(
      children: [row(), const SizedBox(height: 12), row()],
    );
  }
}
