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

  /// Cuando viene informado pinta un badge `ABRE HH:MM` (color sol).
  /// Mutuamente excluyente con `showOpenBadge`: usamos uno u otro según
  /// si el restaurante está abierto ahora o abre más tarde hoy.
  final String? openingLabel; // ej. '13:30'

  const CardHorizontal({
    super.key,
    required this.restaurant,
    required this.onTap,
    this.showNewBadge = false,
    this.showOpenBadge = false,
    this.showYoutubeBadge = false,
    this.rankingNumber,
    this.eyebrow,
    this.openingLabel,
  });

  @override
  State<CardHorizontal> createState() => _CardHorizontalState();
}

class _CardHorizontalState extends State<CardHorizontal> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.restaurant;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 130),
        child: Container(
          width: 220,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Foto de fondo
                _buildPhoto(r.mainFoto),
                // Vignette superior (mejora contraste de badges sobre fondos claros)
                Positioned(
                  top: 0, left: 0, right: 0, height: 70,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.22),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Degradado inferior — más suave y largo
                Positioned(
                  bottom: 0, left: 0, right: 0, height: 130,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.45, 1.0],
                        colors: [
                          Colors.transparent,
                          context.brand.surface.withOpacity(0.92),
                          context.brand.surface,
                        ],
                      ),
                    ),
                  ),
                ),
                // Número decorativo
                if (widget.rankingNumber != null)
                  Positioned(
                    right: 8, bottom: 38,
                    child: Text(
                      widget.rankingNumber!,
                      style: AppTextStyles.displayHero(size: 56)
                          .copyWith(color: Colors.white.withOpacity(0.13)),
                    ),
                  ),
                // Badges superiores. ABIERTO (verde) y ABRE HH:MM (sol) son
                // mutuamente excluyentes — uno comunica "ya puedes ir", el
                // otro "anótalo, abre en breve".
                Positioned(
                  top: 10, left: 10,
                  child: Row(children: [
                    if (widget.showNewBadge) const _Badge('NUEVO', AppColors.mojo),
                    if (widget.showOpenBadge) ...[
                      if (widget.showNewBadge) const SizedBox(width: 4),
                      const _Badge('ABIERTO', AppColors.laurisilva, withDot: true),
                    ] else if (widget.openingLabel != null) ...[
                      if (widget.showNewBadge) const SizedBox(width: 4),
                      _Badge('ABRE ${widget.openingLabel!}',
                          AppColors.sol, withDot: true),
                    ],
                    if (widget.showYoutubeBadge) ...[
                      if (widget.showOpenBadge ||
                          widget.openingLabel != null ||
                          widget.showNewBadge)
                        const SizedBox(width: 4),
                      const _Badge('▶ VIDEO', AppColors.mojo),
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
                        if (widget.eyebrow != null) ...[
                          Text(
                            widget.eyebrow!,
                            style: AppTextStyles.eyebrow(size: 8)
                                .copyWith(letterSpacing: 1.2),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          r.nombre.toUpperCase(),
                          style: AppTextStyles.displaySection(size: 13)
                              .copyWith(letterSpacing: 0.3, height: 1.15),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(children: [
                          // Pill de rating
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.sol.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: AppColors.sol, size: 11),
                                const SizedBox(width: 2),
                                Text(
                                  r.avgRating > 0
                                      ? r.avgRating.toStringAsFixed(1)
                                      : '—',
                                  style: AppTextStyles.ui(
                                    size: 10.5,
                                    weight: FontWeight.w700,
                                    color: AppColors.sol,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              r.municipio,
                              style: AppTextStyles.muted(size: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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

}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final bool withDot;

  const _Badge(this.label, this.color, {this.withDot = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(withDot ? 7 : 10, 4, 10, 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (withDot) ...[
            Container(
              width: 6, height: 6,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: AppTextStyles.ui(
              size: 9,
              weight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
