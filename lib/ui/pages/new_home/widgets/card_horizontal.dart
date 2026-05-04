import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/model/restaurant.dart';

/// Card horizontal (scroll) con foto de fondo, badges y panel de info.
/// Ancho fijo 220, alto 200.
class CardHorizontal extends StatefulWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;
  final bool showNewBadge;
  final bool showOpenBadge;
  final bool showYoutubeBadge;
  final String? rankingNumber; // '01', '02', etc.
  final String? eyebrow;      // 'GUACHINCHE · TEMPORADA'

  const CardHorizontal({
    super.key,
    required this.restaurant,
    required this.onTap,
    this.showNewBadge = false,
    this.showOpenBadge = false,
    this.showYoutubeBadge = false,
    this.rankingNumber,
    this.eyebrow,
  });

  @override
  State<CardHorizontal> createState() => _CardHorizontalState();
}

class _CardHorizontalState extends State<CardHorizontal> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.restaurant;
    final priceRange = '8–15€'; // Fase 2: campo real
    final daysSince = _daysSince(r.updatedAt);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 130),
        child: SizedBox(
          width: 220,
          height: 200,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Foto de fondo
                _buildPhoto(r.mainFoto),
                // Degradado inferior
                Positioned(
                  bottom: 0, left: 0, right: 0, height: 120,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          context.brand.surface.withOpacity(0.85),
                          context.brand.surface,
                        ],
                      ),
                    ),
                  ),
                ),
                // Número decorativo
                if (widget.rankingNumber != null)
                  Positioned(
                    right: 8, bottom: 36,
                    child: Text(
                      widget.rankingNumber!,
                      style: AppTextStyles.displayHero(size: 56)
                          .copyWith(color: Colors.white.withOpacity(0.13)),
                    ),
                  ),
                // Badges superiores
                Positioned(
                  top: 10, left: 10,
                  child: Row(children: [
                    if (widget.showNewBadge) _Badge('NUEVO', AppColors.mojo),
                    if (widget.showOpenBadge) ...[
                      if (widget.showNewBadge) const SizedBox(width: 4),
                      _Badge('ABIERTO', AppColors.laurisilva),
                    ],
                    if (widget.showYoutubeBadge) ...[
                      if (widget.showOpenBadge || widget.showNewBadge) const SizedBox(width: 4),
                      _Badge('▶ VIDEO', AppColors.mojo),
                    ],
                  ]),
                ),
                // Panel inferior
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.eyebrow != null)
                          Text(
                            widget.eyebrow!,
                            style: AppTextStyles.eyebrow(size: 8),
                          ),
                        const SizedBox(height: 3),
                        Text(
                          r.nombre.toUpperCase(),
                          style: AppTextStyles.displaySection(size: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.star_rounded, color: AppColors.sol, size: 11),
                          const SizedBox(width: 3),
                          Text(
                            r.avgRating > 0 ? r.avgRating.toStringAsFixed(1) : '—',
                            style: AppTextStyles.ui(size: 10, color: AppColors.sol),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '· ${r.municipio}',
                            style: AppTextStyles.muted(size: 10),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '· $priceRange',
                            style: AppTextStyles.muted(size: 10),
                          ),
                          if (daysSince != null) ...[
                            const Spacer(),
                            Text(
                              'hace ${daysSince}d',
                              style: AppTextStyles.muted(size: 9),
                            ),
                          ],
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto(String? url) {
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        memCacheWidth: 440,
        placeholder: (_, __) => Container(color: context.brand.surface),
        errorWidget: (_, __, ___) => Container(color: context.brand.surface),
      );
    }
    return Container(color: context.brand.surface);
  }

  int? _daysSince(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      final d = DateTime.tryParse(dateStr);
      if (d == null) return null;
      return DateTime.now().difference(d).inDays;
    } catch (_) {
      return null;
    }
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.ui(
          size: 9,
          weight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
