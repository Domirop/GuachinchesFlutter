import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/local/sql_lite_local_repository.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/restaurant_detail/restaurant_detail_screen.dart';

class FavoritoDetailScreen extends StatelessWidget {
  final Restaurant restaurant;

  const FavoritoDetailScreen({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final r = restaurant;

    return Semantics(
      identifier: 'favorito-detail-screen',
      child: Scaffold(
        backgroundColor: brand.base,
        appBar: AppBar(
          backgroundColor: brand.base,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: brand.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Guardado',
            style: AppTextStyles.displaySection(size: 13),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroCard(brand: brand, restaurant: r),
              const SizedBox(height: 24),
              Semantics(
                identifier: 'favorito-detail-view-restaurant-button',
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RestaurantDetailScreen(id: r.id),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.atlantico,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Ver perfil completo',
                      style: AppTextStyles.ui(
                        size: 15,
                        weight: FontWeight.w600,
                        color: AppColors.crema,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                identifier: 'favorito-detail-remove-button',
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _confirmRemove(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.mojo),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Quitar de favoritos',
                      style: AppTextStyles.ui(
                        size: 15,
                        weight: FontWeight.w600,
                        color: AppColors.mojo,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Quitar de favoritos'),
        content: Text('¿Seguro que quieres quitar "${restaurant.nombre}" de tus favoritos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          Semantics(
            identifier: 'favorito-detail-confirm-remove-button',
            child: TextButton(
              onPressed: () {
                SqlLiteLocalRepository().removeRestaurant(restaurant.id);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) Navigator.pop(context, true);
              },
              child: Text(
                'Quitar',
                style: const TextStyle(color: AppColors.mojo),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final dynamic brand;
  final Restaurant restaurant;

  const _HeroCard({required this.brand, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    return Container(
      decoration: BoxDecoration(
        color: brand.surface,
        border: Border.all(color: brand.borderStrong),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (r.mainFoto.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                r.mainFoto,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: brand.elevated,
                  alignment: Alignment.center,
                  child: Icon(Icons.restaurant_rounded, color: brand.textMuted, size: 48),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.nombre,
                  style: AppTextStyles.displayHero(size: 24),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: AppColors.sol),
                    const SizedBox(width: 4),
                    Text(
                      r.avgRating > 0 ? r.avgRating.toStringAsFixed(1) : 'n/d',
                      style: AppTextStyles.ui(
                        size: 13,
                        weight: FontWeight.w700,
                        color: brand.textPrimary,
                      ),
                    ),
                    if (r.municipio.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text('·', style: AppTextStyles.ui(size: 13, color: brand.textMuted)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          r.municipio,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.ui(size: 13, color: brand.textSecondary),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
