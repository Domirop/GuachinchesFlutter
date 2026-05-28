import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/data/model/user_info.dart';
import 'package:guachinches/ui/Others/new_review/new_review.dart';
import 'package:guachinches/ui/pages/restaurant_detail/restaurant_detail_screen.dart';

class ValoracionDetailScreen extends StatelessWidget {
  final Valoraciones valoracion;

  const ValoracionDetailScreen({super.key, required this.valoracion});

  int get _ratingStars =>
      int.tryParse(valoracion.rating)?.round() ??
      double.tryParse(valoracion.rating)?.round() ??
      0;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final stars = _ratingStars;
    final hasTitle = valoracion.title.trim().isNotEmpty;
    final hasReview = valoracion.review.trim().isNotEmpty;

    return Semantics(
      identifier: 'valoracion-detail-screen',
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
            'Tu reseña',
            style: AppTextStyles.displaySection(size: 13),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RestaurantHeader(brand: brand, restaurantName: valoracion.restaurantes?.nombre ?? 'Restaurante'),
              const SizedBox(height: 20),
              Row(
                children: [
                  ...List.generate(5, (i) => Icon(
                    i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 28,
                    color: AppColors.sol,
                  )),
                  const SizedBox(width: 8),
                  Text(
                    valoracion.rating,
                    style: AppTextStyles.ui(
                      size: 16,
                      weight: FontWeight.w700,
                      color: brand.textSecondary,
                    ),
                  ),
                ],
              ),
              if (hasTitle) ...[
                const SizedBox(height: 16),
                Text(
                  valoracion.title,
                  style: AppTextStyles.displayHero(size: 22),
                ),
              ],
              if (hasReview) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: brand.surface,
                    border: Border.all(color: brand.borderStrong),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    valoracion.review,
                    style: AppTextStyles.editorial(
                      size: 14,
                      color: brand.textSecondary,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              Semantics(
                identifier: 'valoracion-detail-edit-button',
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NewReview(
                          Restaurant(
                            id: valoracion.valoracionesNegocioId,
                            nombre: valoracion.restaurantes?.nombre ?? '',
                            direccion: valoracion.restaurantes?.direccion ?? '',
                          ),
                          valoracion.valoracionesUsuarioId,
                          '',
                        ),
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
                      'Editar valoración',
                      style: AppTextStyles.ui(
                        size: 15,
                        weight: FontWeight.w600,
                        color: AppColors.crema,
                      ),
                    ),
                  ),
                ),
              ),
              if (valoracion.restaurantes != null) ...[
                const SizedBox(height: 12),
                Semantics(
                  identifier: 'valoracion-detail-view-restaurant-button',
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RestaurantDetailScreen(
                            id: valoracion.valoracionesNegocioId,
                          ),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: brand.borderStrong),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Ver perfil del restaurante',
                        style: AppTextStyles.ui(
                          size: 15,
                          weight: FontWeight.w600,
                          color: brand.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RestaurantHeader extends StatelessWidget {
  final dynamic brand;
  final String restaurantName;

  const _RestaurantHeader({required this.brand, required this.restaurantName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: brand.surface,
        border: Border.all(color: brand.borderStrong),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.atlantico.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.restaurant_rounded,
              size: 22,
              color: AppColors.atlanticoClaro,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              restaurantName,
              style: AppTextStyles.displayHero(size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
