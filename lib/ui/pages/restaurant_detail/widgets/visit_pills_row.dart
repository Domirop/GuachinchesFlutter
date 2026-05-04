import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/data/model/restaurant.dart';

class VisitPillsRow extends StatelessWidget {
  final Restaurant restaurant;
  final Visit? visit;

  const VisitPillsRow({super.key, required this.restaurant, this.visit});

  @override
  Widget build(BuildContext context) {
    final rating = visit?.ratingImplicit ?? restaurant.avgRating;
    final priceRange = visit?.priceRange;
    final perPerson = _perPerson();
    final isOpen = restaurant.open;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (rating > 0)
            _Pill(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 12, color: AppColors.sol),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: AppTextStyles.chipLabel(
                      size: 11,
                      color: AppColors.sol,
                    ),
                  ),
                ],
              ),
            ),
          if (priceRange != null && priceRange.isNotEmpty) ...[
            const SizedBox(width: 8),
            _Pill(
              child: Text(
                _toEuros(priceRange),
                style: AppTextStyles.chipLabel(
                  size: 11,
                  color: context.brand.textPrimary,
                ),
              ),
            ),
          ] else if (restaurant.minPrice != null &&
              restaurant.maxPrice != null) ...[
            const SizedBox(width: 8),
            _Pill(
              child: Text(
                '${restaurant.minPrice}–${restaurant.maxPrice}€',
                style: AppTextStyles.chipLabel(
                  size: 11,
                  color: context.brand.textPrimary,
                ),
              ),
            ),
          ],
          if (perPerson != null) ...[
            const SizedBox(width: 8),
            _Pill(
              child: Text(
                '~$perPerson€ / persona',
                style: AppTextStyles.ui(
                  size: 11,
                  weight: FontWeight.w600,
                  color: context.brand.textPrimary,
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
          _OpenPill(isOpen: isOpen),
        ],
      ),
    );
  }

  String _toEuros(String range) => range.replaceAll(r'$', '€');

  String? _perPerson() {
    final approx = visit?.priceApprox;
    if (approx != null) {
      return approx % 1 == 0
          ? approx.toInt().toString()
          : approx.toStringAsFixed(1);
    }
    if (restaurant.minPrice != null && restaurant.maxPrice != null) {
      final avg = (restaurant.minPrice! + restaurant.maxPrice!) / 2;
      return avg % 1 == 0 ? avg.toInt().toString() : avg.toStringAsFixed(1);
    }
    return null;
  }
}

class _Pill extends StatelessWidget {
  final Widget child;
  const _Pill({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        border: Border.all(color: context.brand.borderStrong),
        borderRadius: BorderRadius.circular(100),
        color: context.brand.surface,
      ),
      child: child,
    );
  }
}

class _OpenPill extends StatelessWidget {
  final bool isOpen;
  const _OpenPill({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? AppColors.laurisilva : AppColors.mojo;
    final label = isOpen ? 'ABIERTO' : 'CERRADO';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.chipLabel(size: 11, color: color),
          ),
        ],
      ),
    );
  }
}
