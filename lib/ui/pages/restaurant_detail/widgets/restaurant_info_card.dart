import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/data/model/restaurant.dart';

class RestaurantInfoCard extends StatelessWidget {
  final Restaurant restaurant;
  final Visit? visit;
  final VoidCallback? onTap;

  const RestaurantInfoCard({
    super.key,
    required this.restaurant,
    this.visit,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = (visit?.name?.isNotEmpty == true ? visit!.name! : restaurant.nombre);
    final location = _location();
    final photoUrl = restaurant.mainFoto.isNotEmpty
        ? restaurant.mainFoto
        : (visit?.thumbnail ?? '');

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.brand.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.brand.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 72,
                height: 72,
                child: photoUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: context.brand.elevated),
                        errorWidget: (_, __, ___) =>
                            _placeholder(context),
                      )
                    : _placeholder(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name.toUpperCase(),
                    style: AppTextStyles.displaySection(
                      size: 14,
                      color: context.brand.textPrimary,
                    ).copyWith(letterSpacing: 0.6, height: 1.15),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.place_outlined,
                            size: 12, color: context.brand.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: AppTextStyles.ui(
                              size: 11,
                              color: context.brand.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'VER MÁS',
                        style: AppTextStyles.eyebrow(
                          size: 10,
                          color: AppColors.atlantico,
                        ).copyWith(letterSpacing: 1.0),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 13, color: AppColors.atlantico),
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

  String _location() {
    final parts = <String>[];
    final zone = visit?.zone?.isNotEmpty == true ? visit!.zone! : null;
    final municipio =
        restaurant.municipio.isNotEmpty == true ? restaurant.municipio : null;
    final address = visit?.address?.isNotEmpty == true ? visit!.address! : null;

    if (zone != null) parts.add(zone);
    if (municipio != null && municipio != zone) parts.add(municipio);
    if (parts.isEmpty && address != null) return address;
    return parts.join(' · ');
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: context.brand.elevated,
      alignment: Alignment.center,
      child: Icon(
        Icons.restaurant_outlined,
        size: 24,
        color: context.brand.textMuted,
      ),
    );
  }
}
