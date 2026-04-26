import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:guachinches/data/model/TopRestaurants.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/components/open_status_badge.dart';
import 'package:guachinches/ui/pages/details/details.dart';

class TopRestaurantCard extends StatelessWidget {
  final TopRestaurants restaurant;

  /// 1-based ranking position. Pass `rank: index + 1` from the PageView.
  final int? rank;

  const TopRestaurantCard(this.restaurant, {Key? key, this.rank})
      : super(key: key);

  /// Medal colours for top 3 positions.
  Color _rankColor(int r) {
    if (r == 1) return const Color(0xFFFFD700); // gold
    if (r == 2) return const Color(0xFFC0C0C0); // silver
    if (r == 3) return const Color(0xFFCD7F32); // bronze
    return Colors.white70;
  }

  @override
  Widget build(BuildContext context) {
    final ratingText = restaurant.avg == 0
        ? ''
        : restaurant.avg.toStringAsFixed(1).replaceAll('.', ',');

    return GestureDetector(
      onTap: () => GlobalMethods().pushPage(context, Details(restaurant.id)),
      child: Container(
        height: 260,
        width: MediaQuery.of(context).size.width * 0.90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: GlobalMethods.bgColorFilter,
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // ── Background photo ─────────────────────────────────────────
            Positioned.fill(
              child: restaurant.imagen.isNotEmpty
                  ? Image.network(
                      restaurant.imagen,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _photoPlaceholder(),
                    )
                  : _photoPlaceholder(),
            ),

            // ── Gradient overlay (bottom) ────────────────────────────────
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.35, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.82),
                    ],
                  ),
                ),
              ),
            ),

            // ── Ranking badge — top left ─────────────────────────────────
            if (rank != null)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _rankColor(rank!).withOpacity(0.92),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (rank! <= 3)
                        const Text('🏆', style: TextStyle(fontSize: 11)),
                      if (rank! <= 3) const SizedBox(width: 4),
                      Text(
                        '#$rank',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Open/closed badge — top right ────────────────────────────
            Positioned(
              top: 12,
              right: 12,
              child: OpenStatusBadge(
                horariosJson: null,
                fallbackOpen: restaurant.open,
              ),
            ),

            // ── Bottom info bar ──────────────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name
                    Text(
                      restaurant.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontFamily: 'SF Pro Display',
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(blurRadius: 4, color: Colors.black54),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Rating + municipio row
                    Row(
                      children: [
                        if (ratingText.isNotEmpty) ...[
                          SvgPicture.asset(
                            'assets/images/star.fill.svg',
                            width: 14,
                            height: 14,
                            colorFilter: const ColorFilter.mode(
                                Colors.white, BlendMode.srcIn),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ratingText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'SF Pro Display',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white54,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            restaurant.municipio,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontFamily: 'SF Pro Display',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      color: GlobalMethods.bgColorFilter,
      child: const Center(
        child: Icon(Icons.restaurant, color: Colors.white24, size: 48),
      ),
    );
  }
}
