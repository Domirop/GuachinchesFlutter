import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_shapes.dart';
import 'package:guachinches/config/app_spacing.dart';
import 'package:guachinches/config/brand_colors.dart';

/// Envoltorio visual de la sección "HOY EN ..." (banner contextual + carrusel
/// de restaurantes). Fondo crema, banda lateral cálida y borde redondeado —
/// agrupa banner y cards en un mismo bloque para que se lean como una unidad
/// en vez de dos elementos sueltos.
///
/// El `child` típicamente es:
/// ```
/// Column(children: [HourAwareBanner(...), _buildHorizontalRow(...)])
/// ```
/// El padding interno es 0 horizontal para que el scroll de cards corte por
/// el borde derecho (efecto "asoma siguiente") — el scroll trae su propio
/// padding inicial. Vertical: 6 top + 14 bottom para no apretar el banner.
class ContextualSectionCard extends StatelessWidget {
  final Widget child;

  const ContextualSectionCard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Margen externo: 12↑ aire con el bloque anterior, 24↓ separación con el
      // siguiente (grid 8pt). Horizontal = gutter estándar del home.
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter, 12, AppSpacing.gutter, 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cremaSoft,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: context.brand.border, width: 1),
          boxShadow: AppShadows.soft(),
        ),
        clipBehavior: Clip.hardEdge,
        // Sin banda lateral. Respiro arriba (8) y abajo (14): el carrusel
        // interno usa Clip.none, así que la sombra de las cards cae dentro de
        // este padding sin recortarse.
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 14),
          child: child,
        ),
      ),
    );
  }
}
