import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';

/// Sheet ascendente con lenguaje **liquid glass iOS 26**: esquinas superiores
/// muy redondeadas, grabber, cabecera opcional con título centrado, material
/// translúcido (`BackdropFilter` + `brand.glass`) y un brillo especular sutil
/// en el borde superior — el mismo material del bottom-nav flotante.
///
/// El frost se ve donde el `child` no sea opaco: con contenido ligero (listas,
/// toggles) el sheet entero es cristal; con una página opaca el frost queda en
/// el chrome (grabber + cabecera + borde) y el cuerpo se lee nítido.
Future<T?> showGlassSheet<T>(
  BuildContext context, {
  required Widget child,
  double heightFactor = 0.92,
  bool showGrabber = true,
  String? title,
  VoidCallback? onClose,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.42),
    builder: (_) => GlassSheetShell(
      heightFactor: heightFactor,
      showGrabber: showGrabber,
      title: title,
      onClose: onClose,
      child: child,
    ),
  );
}

/// Carcasa visual del sheet glass. Reutilizable fuera de [showGlassSheet] si se
/// necesita control de altura propio (p.ej. `DraggableScrollableSheet`).
class GlassSheetShell extends StatelessWidget {
  final Widget child;
  final double heightFactor;
  final bool showGrabber;

  /// Si se informa, dibuja una cabecera con el título centrado.
  final String? title;

  /// Acción de cierre (chevron a la izquierda de la cabecera). Si es null y hay
  /// `title`, no se dibuja botón — solo el título centrado.
  final VoidCallback? onClose;

  static const double _radius = 28;

  const GlassSheetShell({
    super.key,
    required this.child,
    this.heightFactor = 0.92,
    this.showGrabber = true,
    this.title,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Brillo especular del borde superior (más visible en oscuro).
    final edgeHighlight =
        Colors.white.withOpacity(isDark ? 0.22 : 0.45);

    return FractionallySizedBox(
      heightFactor: heightFactor,
      widthFactor: 1,
      child: ClipRRect(
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(_radius)),
        child: BackdropFilter(
          // Frost fuerte tipo iOS 26.
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: brand.glass,
              border: Border(top: BorderSide(color: edgeHighlight, width: 1)),
            ),
            child: Stack(
              children: [
                // Capa "leche" crema: neutraliza el tinte que el material coge
                // del fondo (en claro el cristal crema se volvía verdoso sobre
                // el mar). Mantiene translucidez pero limpia el color.
                if (!isDark)
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: ColoredBox(color: Color(0x2BF8F1E2)),
                    ),
                  ),
                // Sheen especular: degradado de luz en el tercio superior.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 150,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(isDark ? 0.14 : 0.28),
                            Colors.white.withOpacity(0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    if (showGrabber) _Grabber(brand: brand),
                    if (title != null)
                      _Header(
                        title: title!,
                        onClose: onClose,
                        brand: brand,
                      ),
                    Expanded(child: child),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Grabber extends StatelessWidget {
  final BrandColors brand;
  const _Grabber({required this.brand});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Container(
        width: 38,
        height: 5,
        decoration: BoxDecoration(
          color: brand.textMuted.withOpacity(0.45),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback? onClose;
  final BrandColors brand;

  const _Header({
    required this.title,
    required this.onClose,
    required this.brand,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Text(
              title,
              style: AppTextStyles.ui(
                size: 16,
                color: brand.textPrimary,
                weight: FontWeight.w700,
              ),
            ),
          ),
          if (onClose != null)
            Positioned(
              left: 6,
              child: IconButton(
                onPressed: onClose,
                icon: Icon(Icons.chevron_left_rounded,
                    color: brand.textPrimary, size: 28),
                splashRadius: 22,
              ),
            ),
        ],
      ),
    );
  }
}
