import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/components/open_status_badge.dart';
import 'package:guachinches/ui/pages/restaurant_detail/restaurant_detail_screen.dart';

class CercaAhoraListCard extends StatelessWidget {
  final Restaurant restaurant;
  final String distance;

  const CercaAhoraListCard({
    super.key,
    required this.restaurant,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final r = restaurant;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RestaurantDetailScreen(id: r.id),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: brand.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: brand.border),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 96,
                height: 96,
                child: r.mainFoto.isNotEmpty
                    ? Image.network(
                        r.mainFoto,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _Placeholder(brand: brand),
                      )
                    : _Placeholder(brand: brand),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Distance pill
                  _DistancePill(distance: distance),
                  const SizedBox(height: 6),
                  // Name
                  Text(
                    r.nombre,
                    style: TextStyle(
                      color: brand.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      fontFamily: 'SF Pro Display',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Municipio
                  if (r.municipio.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      r.municipio,
                      style: TextStyle(
                        color: brand.textSecondary,
                        fontSize: 13,
                        fontFamily: 'SF Pro Display',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  // Status + rating row
                  Row(
                    children: [
                      OpenStatusBadge(
                        horariosJson: r.horariosJson,
                        fallbackOpen: r.open,
                      ),
                      if (r.avgRating > 0) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.sol,
                          size: 14,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          r.avgRating
                              .toStringAsFixed(1)
                              .replaceAll('.', ','),
                          style: TextStyle(
                            color: brand.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            fontFamily: 'SF Pro Display',
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
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final BrandColors brand;

  const _Placeholder({required this.brand});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: brand.elevated,
      child: Center(
        child: Icon(Icons.restaurant, color: brand.textMuted, size: 32),
      ),
    );
  }
}

class _DistancePill extends StatelessWidget {
  final String distance;

  const _DistancePill({required this.distance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.atlantico.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.place_rounded,
            color: AppColors.atlantico,
            size: 13,
          ),
          const SizedBox(width: 3),
          Text(
            distance,
            style: const TextStyle(
              color: AppColors.atlantico,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              fontFamily: 'SF Pro Display',
            ),
          ),
        ],
      ),
    );
  }
}
