import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/model/TopRestaurants.dart';

/// Card ranking estilo "01 / 02 / 03" con foto thumb.
class CardRankingNumeric extends StatefulWidget {
  final TopRestaurants restaurant;
  final int rank;
  final VoidCallback onTap;

  const CardRankingNumeric({
    super.key,
    required this.restaurant,
    required this.rank,
    required this.onTap,
  });

  @override
  State<CardRankingNumeric> createState() => _CardRankingNumericState();
}

class _CardRankingNumericState extends State<CardRankingNumeric> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.restaurant;
    final rankStr = widget.rank.toString().padLeft(2, '0');

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            children: [
              // Número de ranking (tinta fantasma theme-aware).
              SizedBox(
                width: 34,
                child: Text(
                  rankStr,
                  style: AppTextStyles.displayHero(size: 26).copyWith(
                    color: context.brand.textPrimary.withOpacity(0.22),
                  ),
                ),
              ),
              // Foto thumb.
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: r.imagen.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: r.imagen,
                          fit: BoxFit.cover,
                          memCacheWidth: 120,
                          placeholder: (_, __) => Container(color: context.brand.surface),
                          errorWidget: (_, __, ___) => _thumbFallback(context),
                        )
                      : _thumbFallback(context),
                ),
              ),
              const SizedBox(width: 14),
              // Nombre + municipio. Expanded + ellipsis = nunca desborda.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.nombre.toUpperCase(),
                      style: AppTextStyles.displaySection(size: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      r.municipio,
                      style: AppTextStyles.muted(size: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Badge de rating: la señal de credibilidad, scannable y de ancho
              // fijo (no participa en el overflow del bloque de texto).
              if (r.avg > 0) _RatingBadge(avg: r.avg),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: context.brand.textMuted,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbFallback(BuildContext context) => Container(
        color: context.brand.surface,
        child: Icon(
          Icons.restaurant_rounded,
          size: 22,
          color: context.brand.textMuted,
        ),
      );
}

/// Badge de valoración: estrella + nota, fondo sol tenue. Ancho intrínseco
/// (no se estira), así que es inmune al overflow del bloque de texto.
class _RatingBadge extends StatelessWidget {
  final double avg;
  const _RatingBadge({required this.avg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.sol.withOpacity(0.16),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.sol, size: 13),
          const SizedBox(width: 3),
          Text(
            avg.toStringAsFixed(1),
            style: AppTextStyles.ui(
              size: 12,
              color: context.brand.textPrimary,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
