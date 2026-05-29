import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/model/Review.dart';
import 'package:guachinches/data/model/restaurant.dart';

class RatingSummary extends StatelessWidget {
  final Restaurant restaurant;

  const RatingSummary({super.key, required this.restaurant});

  static Map<int, int> distribution(List<Review> reviews) {
    final m = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final r in reviews) {
      final n = double.tryParse(r.rating)?.round() ?? 0;
      if (n >= 1 && n <= 5) m[n] = m[n]! + 1;
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final reviews = restaurant.valoraciones;
    final dist = distribution(reviews);
    final total = reviews.length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.brand.surface,
        border: Border.all(color: Colors.white.withOpacity(0.04)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                restaurant.avgRating.toStringAsFixed(1),
                style: AppTextStyles.displayHero(
                  size: 36,
                  color: AppColors.sol,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  final filled = i < restaurant.avgRating.round();
                  return Icon(
                    filled ? Icons.star : Icons.star_border,
                    color: AppColors.sol,
                    size: 13,
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                '$total reseñas',
                style: AppTextStyles.ui(
                  size: 9,
                  color: AppColors.crema.withOpacity(0.25),
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              children: [
                for (int s = 5; s >= 1; s--)
                  _RatingBar(
                    stars: s,
                    percentage: total == 0 ? 0 : dist[s]! / total,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingBar extends StatelessWidget {
  final int stars;
  final double percentage;

  const _RatingBar({required this.stars, required this.percentage});

  Color get _fill {
    switch (stars) {
      case 5:
        return AppColors.sol;
      case 4:
        return AppColors.arena;
      case 3:
        return AppColors.crema.withOpacity(0.15);
      default:
        return AppColors.mojo.withOpacity(0.25);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 12,
            child: Text(
              '$stars',
              style: AppTextStyles.ui(
                size: 9,
                color: context.brand.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Stack(
                children: [
                  Container(height: 4, color: context.brand.elevated),
                  FractionallySizedBox(
                    widthFactor: percentage.clamp(0.0, 1.0),
                    child: Container(height: 4, color: _fill),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 30,
            child: Text(
              '${(percentage * 100).round()}%',
              textAlign: TextAlign.right,
              style: AppTextStyles.ui(
                size: 9,
                color: context.brand.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
