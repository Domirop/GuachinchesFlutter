import 'package:flutter/material.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/model/TopRestaurants.dart';
import 'package:guachinches/ui/components/section_header.dart';
import 'package:guachinches/ui/pages/new_home/widgets/card_ranking_numeric.dart';

/// "MEJOR VALORADOS · {ISLA}" — top 3 de la isla seleccionada por valoración.
///
/// Consume `getTopRestaurants()` (ranking del backend, ya con `avg` y `counter`
/// de reseñas) ya filtrado por isla aguas arriba (intersección con el pool de
/// la isla en `new_home_screen`). Reusa la card `CardRankingNumeric`, que ya
/// existía pero nunca se había cableado.
class TopRatedSection extends StatelessWidget {
  final List<TopRestaurants> restaurants;
  final String islandLabel;
  final ValueChanged<String> onRestaurantTap;
  final VoidCallback onSeeRanking;

  const TopRatedSection({
    super.key,
    required this.restaurants,
    required this.islandLabel,
    required this.onRestaurantTap,
    required this.onSeeRanking,
  });

  /// Un "top" creíble necesita al menos 3 entradas; si la isla no llega, la
  /// sección se oculta (mejor nada que un ranking de uno).
  static bool shouldRender(List<TopRestaurants> r) => r.length >= 3;

  @override
  Widget build(BuildContext context) {
    final top = restaurants.take(3).toList();
    return Semantics(
      identifier: 'home-section-top-rated',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Mejor valorados · $islandLabel',
            actionLabel: 'Ver ranking',
            onAction: onSeeRanking,
          ),
          for (var i = 0; i < top.length; i++) ...[
            CardRankingNumeric(
              restaurant: top[i],
              rank: i + 1,
              onTap: () => onRestaurantTap(top[i].id),
            ),
            if (i < top.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(height: 1, color: context.brand.border),
              ),
          ],
        ],
      ),
    );
  }
}
