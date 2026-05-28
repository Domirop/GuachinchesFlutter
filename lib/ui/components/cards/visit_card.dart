import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/model/user_visit.dart';

class VisitCard extends StatelessWidget {
  final UserVisit visit;
  final VoidCallback? onTap;

  const VisitCard({super.key, required this.visit, this.onTap});

  String _relativeAge(DateTime visitedAt) {
    final now = DateTime.now();
    final diff = now.difference(visitedAt);
    if (diff.inDays >= 365) {
      final years = (diff.inDays / 365).floor();
      return 'hace $years ${years == 1 ? 'año' : 'años'}';
    } else if (diff.inDays >= 30) {
      final months = (diff.inDays / 30).floor();
      return 'hace $months ${months == 1 ? 'mes' : 'meses'}';
    } else if (diff.inDays >= 1) {
      return 'hace ${diff.inDays} ${diff.inDays == 1 ? 'día' : 'días'}';
    } else {
      return 'hace menos de un día';
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final rating = visit.rating;
    final note = visit.note;
    final photoUrl = visit.restaurantPhotoUrl;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: brand.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: brand.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: SizedBox(
                width: 88,
                height: 88,
                child: photoUrl != null && photoUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: brand.elevated,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: brand.elevated,
                          child: Icon(Icons.restaurant, color: brand.textMuted),
                        ),
                      )
                    : Container(
                        color: brand.elevated,
                        child: Icon(Icons.restaurant, color: brand.textMuted),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visit.restaurantName,
                      style: TextStyle(
                        color: brand.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'SF Pro Display',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _relativeAge(visit.visitedAt),
                      style: TextStyle(
                        color: brand.textSecondary,
                        fontSize: 12,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                    if (rating != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: List.generate(5, (i) {
                          return Icon(
                            i < rating ? Icons.star : Icons.star_border,
                            size: 14,
                            color: const Color(0xFFFFC107),
                          );
                        }),
                      ),
                    ],
                    if (note != null && note.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        note,
                        style: TextStyle(
                          color: brand.textSecondary,
                          fontSize: 13,
                          fontFamily: 'SF Pro Display',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
