import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/utils/distance_utils.dart';

/// Card "Cerca de ti" — foto del restaurante con pill de distancia.
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

  Widget _buildPhoto(BuildContext context, String? url) {
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        memCacheWidth: 440,
        placeholder: (_, __) => Container(color: context.brand.surface),
        errorWidget: (_, __, ___) => Container(color: context.brand.surface),
      );
    }
    return Container(color: context.brand.surface);
  }

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
        child: Container(
          // Métricas estándar de card del home (igual que CardHorizontal):
          // la fila "Cerca de ti" no debe verse más pequeña que sus vecinas.
          width: 220,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Foto del restaurante
                _buildPhoto(context, r.mainFoto),
                // Vignette superior (mejora contraste de la pill)
                Positioned(
                  top: 0, left: 0, right: 0, height: 60,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.28),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Degradado inferior — más largo y suave
                Positioned(
                  bottom: 0, left: 0, right: 0, height: 110,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.5, 1.0],
                        colors: [
                          Colors.transparent,
                          context.brand.surface.withOpacity(0.90),
                          context.brand.surface,
                        ],
                      ),
                    ),
                  ),
                ),
                // Pill distancia
                Positioned(
                  top: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 10, color: AppColors.atlanticoClaro),
                        const SizedBox(width: 3),
                        Text(
                          dist,
                          style: AppTextStyles.ui(
                            size: 10,
                            weight: FontWeight.w700,
                            color: Colors.white,
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
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          r.nombre.toUpperCase(),
                          // Título de card unificado del home (displaySection 16).
                          style: AppTextStyles.displaySection(size: 16)
                              .copyWith(height: 1.15, letterSpacing: 0.3),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                r.municipio,
                                style: AppTextStyles.muted(size: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (r.avgRating > 0) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.star_rounded,
                                  size: 12, color: AppColors.sol),
                              const SizedBox(width: 2),
                              Text(
                                r.avgRating.toStringAsFixed(1),
                                style: AppTextStyles.ui(
                                  size: 11,
                                  weight: FontWeight.w700,
                                  color: AppColors.sol,
                                ),
                              ),
                            ],
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

