import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/model/restaurant.dart';

class VisitPillsRow extends StatelessWidget {
  final Restaurant restaurant;

  const VisitPillsRow({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (restaurant.avgRating > 0)
            _Pill(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 12, color: AppColors.sol),
                  const SizedBox(width: 4),
                  Text(
                    restaurant.avgRating.toStringAsFixed(1),
                    style: AppTextStyles.chipLabel(
                      size: 11,
                      color: AppColors.sol,
                    ),
                  ),
                ],
              ),
            ),
          if (restaurant.minPrice != null && restaurant.maxPrice != null) ...[
            const SizedBox(width: 8),
            _Pill(
              child: Text(
                '${restaurant.minPrice}–${restaurant.maxPrice}€',
                style: AppTextStyles.chipLabel(
                  size: 11,
                  color: AppColors.crema,
                ),
              ),
            ),
          ],
          if (_avgPrice() != null) ...[
            const SizedBox(width: 8),
            _Pill(
              child: Text(
                '~ ${_avgPrice()}€ / persona',
                style: AppTextStyles.chipLabel(
                  size: 11,
                  color: AppColors.crema,
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
          _OpenPill(isOpen: restaurant.open),
        ],
      ),
    );
  }

  String? _avgPrice() {
    if (restaurant.minPrice == null || restaurant.maxPrice == null) return null;
    final avg = (restaurant.minPrice! + restaurant.maxPrice!) / 2;
    return avg % 1 == 0 ? avg.toInt().toString() : avg.toStringAsFixed(1);
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
