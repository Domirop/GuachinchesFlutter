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
              // Número de ranking
              SizedBox(
                width: 36,
                child: Text(
                  rankStr,
                  style: AppTextStyles.displayHero(size: 24).copyWith(
                    color: AppColors.crema.withOpacity(0.20),
                  ),
                ),
              ),
              // Foto thumb
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: r.imagen.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: r.imagen,
                          fit: BoxFit.cover,
                          memCacheWidth: 104,
                          placeholder: (_, __) => Container(color: context.brand.surface),
                          errorWidget: (_, __, ___) => Container(color: context.brand.surface),
                        )
                      : Container(color: context.brand.surface),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.nombre.toUpperCase(),
                      style: AppTextStyles.displaySection(size: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          r.municipio,
                          style: AppTextStyles.muted(size: 10),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.star_rounded,
                            color: AppColors.sol, size: 11),
                        const SizedBox(width: 2),
                        Text(
                          r.avg.toStringAsFixed(1),
                          style: AppTextStyles.ui(
                            size: 10,
                            color: AppColors.sol,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '· ${r.counter} reseñas',
                          style: AppTextStyles.muted(size: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.brand.textPrimary,
                size: 16,
                shadows: const [],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
