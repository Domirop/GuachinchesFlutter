import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/components/open_status_badge.dart';
import 'package:guachinches/ui/pages/details/details.dart';

class NearbyRestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final String distance;
  final String typeName;

  const NearbyRestaurantCard({
    Key? key,
    required this.restaurant,
    required this.distance,
    this.typeName = '',
  }) : super(key: key);

  static const double _cardWidth = 240.0;
  static const double _imageHeight = 150.0;

  @override
  Widget build(BuildContext context) {
    final String ratingText = restaurant.avgRating == 0
        ? ''
        : restaurant.avgRating.toStringAsFixed(1).replaceAll('.', ',');

    // Build "Municipio · Tipo" subtitle line
    final List<String> subtitleParts = [];
    if (restaurant.municipio.isNotEmpty) subtitleParts.add(restaurant.municipio);
    if (typeName.isNotEmpty) subtitleParts.add(typeName);
    final String subtitle = subtitleParts.join(' · ');

    return GestureDetector(
      onTap: () => GlobalMethods().pushPage(context, Details(restaurant.id)),
      child: SizedBox(
        width: _cardWidth,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            color: GlobalMethods.bgColorFilter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Image ──────────────────────────────────────────────
                Stack(
                  children: [
                    SizedBox(
                      width: _cardWidth,
                      height: _imageHeight,
                      child: restaurant.mainFoto.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: restaurant.mainFoto,
                              fit: BoxFit.cover,
                              memCacheWidth: 440,
                              errorWidget: (_, __, ___) => _placeholder(),
                              placeholder: (_, __) => _placeholder(),
                            )
                          : _placeholder(),
                    ),
                    // Distance pill — bottom left (blue, prominent)
                    Positioned(
                      bottom: 8,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: GlobalMethods.blueColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: GlobalMethods.blueColor.withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on,
                                size: 11, color: Colors.white),
                            const SizedBox(width: 3),
                            Text(
                              distance,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'SF Pro Display',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Info ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + rating
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              restaurant.nombre,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'SF Pro Display',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (ratingText.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Color.fromRGBO(28, 195, 137, 1),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              ratingText,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color.fromRGBO(28, 195, 137, 1),
                                fontFamily: 'SF Pro Display',
                              ),
                            ),
                          ],
                        ],
                      ),
                      // Municipio · Tipo
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                            fontFamily: 'SF Pro Display',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      // Open status badge
                      OpenStatusBadge(
                        horariosJson: restaurant.horariosJson,
                        fallbackOpen: restaurant.open,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: _cardWidth,
      height: _imageHeight,
      color: Colors.white10,
      child: const Center(
        child: Icon(Icons.restaurant, color: Colors.white24, size: 36),
      ),
    );
  }
}
