import 'package:flutter/material.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:guachinches/utils/distance_utils.dart';

/// Tarjeta «Cerca de ti» (rediseño iOS 27): tarjeta de sitio de 240 de ancho,
/// foto de 150 con la distancia en cristal y el corazón, nombre 16/21 y
/// municipio + valoración (14/19).
class CardNearbyMinimap extends StatelessWidget {
  final NearbyRestaurant nearby;
  final VoidCallback onTap;

  const CardNearbyMinimap({
    super.key,
    required this.nearby,
    required this.onTap,
  });

  static const double width = 240;

  /// Alto total: 6 + foto 150 + 10 + 21 + 2 + 19 + 6 + 6 (texto escalado
  /// con el tamaño de texto del sistema; el carrusel lo limita a 1,3×).
  static double heightFor(BuildContext context) {
    final t = MediaQuery.textScalerOf(context);
    return 6 + 150 + 10 + t.scale(21) + 2 + t.scale(19) + 6 + 6 + 1;
  }

  /// «1834,2 km» no ayuda: por encima de 200 km se oculta el chip.
  static bool _sensible(String label) {
    final l = label.trim();
    if (!l.endsWith('km')) return true;
    final v = double.tryParse(
        l.replaceAll('km', '').replaceAll('.', '').replaceAll(',', '.').trim());
    return v == null || v * 1000 <= kGmMaxDistanceMeters;
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final r = nearby.restaurant;
    final dist = nearby.distanceLabel;
    return SizedBox(
      width: width,
      child: GmPlaceCard(
        restaurant: r,
        onTap: onTap,
        photoHeight: 150,
        twoLineTitle: false,
        textPadding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
        metaGap: 2,
        chip: _sensible(dist)
            ? GmPhotoChip(
                leading: GmIcon(GmIcons.navArrow,
                    size: 10, color: GmColors.atlantico),
                label: dist,
              )
            : null,
        meta: GmMetaRow(
          fontSize: 14,
          rating: r.avgRating,
          leading: Text(
            gmPlaceName(r.municipio),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GmText.sub(color: gm.label2),
          ),
        ),
      ),
    );
  }
}
