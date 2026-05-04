import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/model/restaurant.dart';

class CategoriesChips extends StatelessWidget {
  final Restaurant restaurant;

  const CategoriesChips({super.key, required this.restaurant});

  static bool shouldRender(Restaurant r) => r.categoriaRestaurantes.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: restaurant.categoriaRestaurantes.map((c) {
          final label = c.categorias.nombre;
          if (label.isEmpty) return const SizedBox.shrink();
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            decoration: BoxDecoration(
              color: context.brand.surface,
              border: Border.all(color: Colors.white.withOpacity(0.06)),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              label.toUpperCase(),
              style: AppTextStyles.chipLabel(
                size: 9,
                color: AppColors.crema.withOpacity(0.75),
              ).copyWith(letterSpacing: 0.8),
            ),
          );
        }).toList(),
      ),
    );
  }
}
