import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/model/Review.dart';

class ReviewCard extends StatelessWidget {
  final Review review;

  const ReviewCard({super.key, required this.review});

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
