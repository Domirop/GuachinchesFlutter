import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/model/Review.dart';
import 'package:guachinches/data/model/restaurant.dart';

class ReviewsSection extends StatelessWidget {
  final Restaurant restaurant;

  const ReviewsSection({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final reviews = restaurant.valoraciones;
    final hasReviews = reviews.isNotEmpty;
    final visible = reviews.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RESEÑAS',
            style: AppTextStyles.displaySection(size: 11),
          ),
          const SizedBox(height: 12),
          if (!hasReviews)
            Text(
              'Aún no hay reseñas',
              style: AppTextStyles.ui(
                size: 11,
                color: context.brand.textMuted,
              ),
            )
          else ...[
            _RatingSummary(restaurant: restaurant),
            const SizedBox(height: 14),
            ...visible.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ReviewCard(review: r),
                )),
            if (reviews.length > 3)
              Center(
                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ver todas las reseñas — próximamente'),
                      ),
                    );
                  },
                  child: Text(
                    'VER TODAS LAS RESEÑAS →',
                    style: AppTextStyles.displaySection(size: 11)
                        .copyWith(color: AppColors.atlanticoClaro),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _RatingSummary extends StatelessWidget {
  final Restaurant restaurant;

  const _RatingSummary({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final reviews = restaurant.valoraciones;
    final dist = _distribution(reviews);
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

  Map<int, int> _distribution(List<Review> reviews) {
    final m = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final r in reviews) {
      final n = double.tryParse(r.rating)?.round() ?? 0;
      if (n >= 1 && n <= 5) m[n] = m[n]! + 1;
    }
    return m;
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

class _ReviewCard extends StatelessWidget {
  final Review review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final user = review.usuario;
    final name = user?.nombre ?? 'Anónimo';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final ratingNum = double.tryParse(review.rating)?.round() ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.brand.surface,
        border: Border.all(color: Colors.white.withOpacity(0.04)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: AppColors.atlantico,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: AppTextStyles.displaySection(size: 11)
                      .copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name.toUpperCase(),
                  style: AppTextStyles.displaySection(size: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return Icon(
                    i < ratingNum ? Icons.star : Icons.star_border,
                    color: AppColors.sol,
                    size: 11,
                  );
                }),
              ),
            ],
          ),
          if (review.review.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.review,
              style: AppTextStyles.editorial(
                size: 11,
                color: context.brand.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
