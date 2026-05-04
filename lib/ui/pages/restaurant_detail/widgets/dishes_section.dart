import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/model/Visit.dart';

class DishesSection extends StatelessWidget {
  final List<VisitDish> dishes;

  const DishesSection({super.key, required this.dishes});

  static bool shouldRender(List<VisitDish> dishes) => dishes.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LO QUE PEDIMOS',
            style: AppTextStyles.displaySection(
              size: 11,
              color: AppColors.atlantico,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: context.brand.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.brand.border),
            ),
            child: Column(
              children: dishes.asMap().entries.map((e) {
                final isLast = e.key == dishes.length - 1;
                return _DishRow(dish: e.value, isLast: isLast);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DishRow extends StatelessWidget {
  final VisitDish dish;
  final bool isLast;

  const _DishRow({required this.dish, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: context.brand.border),
              ),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: dish.isTop ? AppColors.laurisilva : Colors.grey.shade600,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              dish.name,
              style: AppTextStyles.ui(
                size: 12,
                color: context.brand.textPrimary,
              ),
            ),
          ),
          if (dish.isTop)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.laurisilva.withOpacity(0.15),
                border: Border.all(
                    color: AppColors.laurisilva.withOpacity(0.4)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'TOP',
                style: AppTextStyles.chipLabel(
                  size: 9,
                  color: AppColors.laurisilva,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
