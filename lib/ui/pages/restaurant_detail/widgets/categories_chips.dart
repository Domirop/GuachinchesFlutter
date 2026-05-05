import 'package:flutter/material.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/model/restaurant.dart';

class CategoriesChips extends StatelessWidget {
  final Restaurant restaurant;

  const CategoriesChips({super.key, required this.restaurant});

  static bool shouldRender(Restaurant r) => r.categoriaRestaurantes.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final labels = restaurant.categoriaRestaurantes
        .map((c) => c.categorias.nombre)
        .where((l) => l.isNotEmpty)
        .toList();
    if (labels.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: labels.map((l) => _CategoryChip(label: l)).toList(),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  const _CategoryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: context.brand.elevated,
        border: Border.all(color: context.brand.borderStrong),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.chipLabel(
          size: 10,
          color: context.brand.textPrimary,
        ),
      ),
    );
  }
}
