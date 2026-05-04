import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/utils/distance_utils.dart';

/// Card "Cerca de ti" — Fase 1: fondo estilizado con marcador.
/// Fase 2: Google Maps Static API como imagen de fondo.
class CardNearbyMinimap extends StatefulWidget {
  final NearbyRestaurant nearby;
  final VoidCallback onTap;

  const CardNearbyMinimap({
    super.key,
    required this.nearby,
    required this.onTap,
  });

  @override
  State<CardNearbyMinimap> createState() => _CardNearbyMinimapState();
}

class _CardNearbyMinimapState extends State<CardNearbyMinimap> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.nearby.restaurant;
    final dist = widget.nearby.distanceLabel;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: SizedBox(
          width: 160,
          height: 160,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Fondo mapa estilizado (placeholder Fase 1)
                Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.8,
                      colors: [
                        AppColors.atlantico.withOpacity(0.25),
                        context.brand.surface,
                      ],
                    ),
                  ),
                ),
                // Grid de calles simulado
                CustomPaint(painter: _MapGridPainter()),
                // Marcador central
                const Center(
                  child: Icon(
                    Icons.location_on_rounded,
                    color: AppColors.atlantico,
                    size: 28,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black38)],
                  ),
                ),
                // Degradado inferior
                Positioned(
                  bottom: 0, left: 0, right: 0, height: 90,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, context.brand.surface],
                      ),
                    ),
                  ),
                ),
                // Pill distancia
                Positioned(
                  top: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: context.brand.glass,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 9, color: AppColors.atlanticoClaro),
                        const SizedBox(width: 3),
                        Text(
                          dist,
                          style: AppTextStyles.ui(
                            size: 9,
                            weight: FontWeight.w600,
                            color: context.brand.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Info inferior
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          r.nombre.toUpperCase(),
                          style: AppTextStyles.displaySection(size: 11),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              r.municipio,
                              style: AppTextStyles.muted(size: 9),
                            ),
                            const SizedBox(width: 6),
                            if (r.avgRating > 0)
                              Row(children: [
                                const Icon(Icons.star_rounded,
                                    size: 9, color: AppColors.sol),
                                const SizedBox(width: 2),
                                Text(
                                  r.avgRating.toStringAsFixed(1),
                                  style: AppTextStyles.muted(size: 9,
                                      color: AppColors.sol),
                                ),
                              ]),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.crema.withOpacity(0.04)
      ..strokeWidth = 1;
    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
