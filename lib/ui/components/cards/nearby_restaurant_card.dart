import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/details/details.dart';
import 'package:guachinches/utils/horarios_utils.dart';

/// Card de "Cerca de ti". Mismo lenguaje visual que [CardHorizontal] (foto a
/// sangre + panel flotante, tokens de marca, rating dorado, nombre Oswald) para
/// que la fila no desentone con el resto del home. Conserva su seña propia: el
/// **pill de distancia** sobre la foto.
class NearbyRestaurantCard extends StatefulWidget {
  final Restaurant restaurant;
  final String distance;
  final String typeName;

  const NearbyRestaurantCard({
    Key? key,
    required this.restaurant,
    required this.distance,
    this.typeName = '',
  }) : super(key: key);

  static const double cardWidth = 220.0;
  static const double cardHeight = 200.0;

  @override
  State<NearbyRestaurantCard> createState() => _NearbyRestaurantCardState();
}

class _NearbyRestaurantCardState extends State<NearbyRestaurantCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.restaurant;

    // Estado abierto/cerrado real (igual que OpenStatusBadge).
    final status = r.horariosJson != null
        ? getOpenStatus(r.horariosJson, DateTime.now())
        : (r.open ? 'Abierto' : 'Cerrado');
    final bool isOpen = status == 'Abierto';

    final subtitleParts = <String>[
      if (r.municipio.isNotEmpty) r.municipio,
      if (widget.typeName.isNotEmpty) widget.typeName,
    ];
    final subtitle = subtitleParts.join(' · ');

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () => GlobalMethods().pushPage(context, Details(r.id)),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 130),
        child: Container(
          width: NearbyRestaurantCard.cardWidth,
          height: NearbyRestaurantCard.cardHeight,
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
                _buildPhoto(context, r.mainFoto),
                // Vignette superior (contraste de badges sobre fotos claras).
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 70,
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
                // Degradado inferior hacia el surface.
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 130,
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
                // Badges superiores: distancia (atlántico) + estado.
                Positioned(
                  top: 10,
                  left: 10,
                  child: Row(
                    children: [
                      _Pill(
                        label: widget.distance,
                        color: AppColors.atlantico,
                        icon: Icons.location_on_rounded,
                      ),
                      const SizedBox(width: 4),
                      _Pill(
                        label: isOpen ? 'ABIERTO' : 'CERRADO',
                        color: isOpen ? AppColors.laurisilva : AppColors.mojo,
                        withDot: isOpen,
                      ),
                    ],
                  ),
                ),
                // Panel inferior.
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          r.nombre.toUpperCase(),
                          style: AppTextStyles.displaySection(size: 16)
                              .copyWith(letterSpacing: 0.3, height: 1.15),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            // Pill de rating (dorado, como el resto del home).
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.sol.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(8),
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
                                      size: 11,
                                      weight: FontWeight.w700,
                                      color: AppColors.sol,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (subtitle.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  subtitle,
                                  style: AppTextStyles.muted(size: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
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

  Widget _buildPhoto(BuildContext context, String url) {
    if (url.isNotEmpty) {
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

/// Pill flotante de la card (distancia / estado), estilo unificado del home.
class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool withDot;

  const _Pill({
    required this.label,
    required this.color,
    this.icon,
    this.withDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(icon != null || withDot ? 7 : 10, 4, 10, 4),
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
          if (icon != null) ...[
            Icon(icon, size: 11, color: Colors.white),
            const SizedBox(width: 3),
          ] else if (withDot) ...[
            Container(
              width: 6,
              height: 6,
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
              size: 10,
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
