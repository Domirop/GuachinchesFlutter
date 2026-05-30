import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
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

  /// Color de la banda lateral izquierda. Por defecto `tierra` (marrón
  /// canario cálido) — coincide con la sensación del banner de hora. Si
  /// quieres distinguir el modo "abren pronto" puedes pasar `sol`.
  final Color accent;

  const ContextualSectionCard({
    super.key,
    required this.child,
    this.accent = AppColors.tierra,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Más margen vertical externo (16↓) para separarse del siguiente
      // bloque del scroll. 12↑ mantiene el aire con el callout anterior.
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cremaSoft,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: context.brand.border, width: 1),
          boxShadow: [
            // Sombra más amplia y suave → la card se siente "asentada"
            // sobre el fondo en vez de pegada como un parche.
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 22,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banda lateral cálida — pista visual de "bloque contextual".
              // 3px se integra mejor (4px llamaba demasiado la atención).
              Container(width: 3, color: accent),
              Expanded(
                child: Padding(
                  // Interior: respiro arriba (10) y abajo (20) para que el
                  // carrusel no toque el borde de la card. 20↓ es el que
                  // hace que el nombre/rating de la última fila respire.
                  padding: const EdgeInsets.only(top: 10, bottom: 20),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
