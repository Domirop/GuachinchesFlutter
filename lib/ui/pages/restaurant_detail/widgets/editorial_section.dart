import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/model/restaurant.dart';

class EditorialSection extends StatelessWidget {
  final Restaurant restaurant;

  const EditorialSection({super.key, required this.restaurant});

  static bool shouldRender(Restaurant r) =>
      (r.editorialQuote != null && r.editorialQuote!.isNotEmpty) ||
      (r.editorialBody != null && r.editorialBody!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (restaurant.editorialQuote != null &&
              restaurant.editorialQuote!.isNotEmpty)
            Container(
              padding: const EdgeInsets.only(left: 12),
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppColors.atlantico, width: 3),
                ),
              ),
              child: Text(
                restaurant.editorialQuote!,
                style: AppTextStyles.editorial(
                  size: 13,
                  color: AppColors.crema.withOpacity(0.85),
                ),
              ),
            ),
          if (restaurant.editorialBody != null &&
              restaurant.editorialBody!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              restaurant.editorialBody!,
              style: AppTextStyles.editorial(
                size: 12,
                color: context.brand.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
