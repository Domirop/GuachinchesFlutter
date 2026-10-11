import 'package:flutter/material.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';

/// Cápsula de búsqueda (señuelo → abre la búsqueda avanzada).
/// Rediseño iOS 27: blanca, sombra cálida y lupa. El placeholder nombra la
/// zona elegida o, si no hay, la isla («Buscar en Tenerife»). Sin micrófono:
/// la app no tiene búsqueda por voz y un icono que no hace nada confunde.
class SearchFieldDynamic extends StatelessWidget {
  final String? zone;
  final VoidCallback onTap;

  const SearchFieldDynamic({
    super.key,
    this.zone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final placeholder =
        zone != null ? 'Buscar en $zone' : 'Buscar restaurante';

    return Semantics(
      identifier: 'home-search-field',
      button: true,
      label: placeholder,
      excludeSemantics: true,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: GmPressable(
          onTap: onTap,
          pressedScale: 0.985,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: gm.card,
              borderRadius: BorderRadius.circular(GmRadius.pill),
              boxShadow: gm.shadow1,
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                GmIcon(GmIcons.search, size: 19, color: gm.label2),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    placeholder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GmText.body17(color: gm.label2),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
