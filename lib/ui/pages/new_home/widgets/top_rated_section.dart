import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/data/model/TopRestaurants.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show gmDisplayName, gmPlaceName;
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// «Mejor valorados · {isla}» — top 3 de la isla (rediseño iOS 27):
/// lista agrupada en una tarjeta con medallas oro/plata/bronce (la de oro
/// con un brillo, una vez), miniatura r14, nombre y subtítulo con elipsis y
/// la nota. El título lleva chevron → ranking completo.
///
/// Consume `getTopRestaurants()` ya filtrado por isla aguas arriba.
class TopRatedSection extends StatelessWidget {
  final List<TopRestaurants> restaurants;
  final String islandLabel;
  final ValueChanged<String> onRestaurantTap;
  final VoidCallback onSeeRanking;

  /// Tipo de local (p. ej. «Guachinche») por id, si se conoce.
  final String? Function(String id)? typeLabelFor;

  const TopRatedSection({
    super.key,
    required this.restaurants,
    required this.islandLabel,
    required this.onRestaurantTap,
    required this.onSeeRanking,
    this.typeLabelFor,
  });

  /// Un "top" creíble necesita al menos 3 entradas; si la isla no llega, la
  /// sección se oculta (mejor nada que un ranking de uno).
  static bool shouldRender(List<TopRestaurants> r) => r.length >= 3;

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final top = restaurants.take(3).toList();
    return Semantics(
      identifier: 'home-section-top-rated',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GmSectionHeader(
            eyebrow: GmEyebrow(
              leading: GmIcon(GmIcons.medal, size: 14, color: gm.label2),
              text: 'Valoración media',
            ),
            title: 'Mejor valorados · $islandLabel',
            onTap: onSeeRanking,
            identifier: 'home-top-rated-see-all',
          ),
          const SizedBox(height: 6),
          GmRise(
            index: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
              child: GmCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      for (var i = 0; i < top.length; i++) ...[
                        if (i > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 120),
                            child: Container(height: 1, color: gm.sep),
                          ),
                        _Row(
                          restaurant: top[i],
                          rank: i + 1,
                          typeLabel: typeLabelFor?.call(top[i].id),
                          onTap: () => onRestaurantTap(top[i].id),
                        ),
                      ],
                    ],
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

class _Row extends StatelessWidget {
  final TopRestaurants restaurant;
  final int rank;
  final String? typeLabel;
  final VoidCallback onTap;

  const _Row({
    required this.restaurant,
    required this.rank,
    required this.typeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final r = restaurant;
    final sub = [
      if (typeLabel != null && typeLabel!.isNotEmpty) typeLabel!,
      if (r.municipio.isNotEmpty) gmPlaceName(r.municipio),
    ].join(' · ');
    return GmPressable(
      onTap: onTap,
      pressedScale: 0.985,
      semanticsLabel: 'Puesto $rank, ${r.nombre}',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 16, 10),
          child: Row(
            children: [
              GmMedal(rank: rank),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(GmRadius.listIcon),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: r.imagen.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: r.imagen,
                          fit: BoxFit.cover,
                          memCacheWidth: 160,
                          placeholder: (_, __) => const GmFill(),
                          errorWidget: (_, __, ___) => const GmFill(),
                        )
                      : const GmFill(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      gmDisplayName(r.nombre),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GmText.cardTitle(color: gm.label)
                          .copyWith(letterSpacing: -0.25),
                    ),
                    if (sub.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GmText.sub(color: gm.label2),
                      ),
                    ],
                  ],
                ),
              ),
              if (r.avg > 0) ...[
                const SizedBox(width: 12),
                GmRating(r.avg, fontSize: 15),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Medalla 1/2/3 (oro, plata, bronce). La de oro cruza un brillo una vez.
class GmMedal extends StatelessWidget {
  final int rank;
  const GmMedal({super.key, required this.rank});

  static const _fills = {
    1: [Color(0xFFF3DFA8), Color(0xFFD6B675), Color(0xFFB08A48)],
    2: [Color(0xFFF4F4F6), Color(0xFFC9CCD3), Color(0xFF9EA2AB)],
    3: [Color(0xFFF2C9A2), Color(0xFFCD8F5C), Color(0xFF9C6236)],
  };
  static const _ink = {
    1: Color(0xFF3A2410),
    2: Color(0xFF2A2D33),
    3: Color(0xFF3A1C08),
  };

  @override
  Widget build(BuildContext context) {
    final fill = _fills[rank] ?? _fills[3]!;
    final medal = Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: const Alignment(-0.8, -1),
          end: const Alignment(0.8, 1),
          colors: fill,
          stops: const [0, 0.48, 1],
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x2E503714), offset: Offset(0, 2), blurRadius: 6),
        ],
      ),
      foregroundDecoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x66FFFFFF), Color(0x00FFFFFF)],
          stops: [0, 0.18],
        ),
      ),
      child: Text(
        '$rank',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: _ink[rank] ?? _ink[3],
        ),
      ),
    );
    if (rank != 1) return medal;
    return Stack(
      children: [
        medal,
        Positioned.fill(
          child: IgnorePointer(
            child: ClipOval(
              child: GmOnce(
                duration: const Duration(milliseconds: 1000),
                delay: const Duration(milliseconds: 2000),
                builder: (_, t, __) {
                  if (t <= 0 || t >= 1) return const SizedBox.shrink();
                  final x = -1.3 + 2.6 * GmMotion.ease.transform(t);
                  return FractionalTranslation(
                    translation: Offset(x, 0),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(-1, -0.4),
                          end: Alignment(1, 0.4),
                          colors: [
                            Color(0x00FFFFFF),
                            Color(0xD9FFFFFF),
                            Color(0x00FFFFFF),
                          ],
                          stops: [0.35, 0.5, 0.65],
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
