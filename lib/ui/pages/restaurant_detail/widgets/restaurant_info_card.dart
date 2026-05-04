import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/model/restaurant.dart';

class RestaurantInfoCard extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantInfoCard({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final municipio = restaurant.municipio ?? '';
    final priceLabel = _priceLabel();
    final subtitle = _buildSubtitle();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.atlantico,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (municipio.isNotEmpty || priceLabel.isNotEmpty)
            Text(
              [municipio.toUpperCase(), priceLabel]
                  .where((s) => s.isNotEmpty)
                  .join(' · '),
              style: AppTextStyles.eyebrow(
                size: 9,
                color: Colors.white.withOpacity(0.75),
              ),
            ),
          const SizedBox(height: 6),
          Text(
            restaurant.nombre.toUpperCase(),
            style: AppTextStyles.displayHero(
              size: 24,
              color: Colors.white,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.editorial(
                size: 12,
                color: Colors.white.withOpacity(0.75),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _priceLabel() {
    if (restaurant.minPrice != null && restaurant.maxPrice != null) {
      return '${restaurant.minPrice}–${restaurant.maxPrice}€';
    }
    return '';
  }

  String _buildSubtitle() {
    final parts = <String>[];
    final type = restaurant.type;
    if (type != null && type.isNotEmpty && type.toLowerCase() != 'vacio') {
      parts.add(_capitalize(type));
    }
    if (restaurant.categoriaRestaurantes.isNotEmpty) {
      final catName = restaurant.categoriaRestaurantes.first.categorias?.nombre;
      if (catName != null && catName.isNotEmpty) {
        parts.add(_capitalize(catName));
      }
    }
    return parts.join(' · ');
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
}
