import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_shapes.dart';
import 'package:guachinches/config/app_spacing.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/components/shimmer_box.dart';
import 'package:guachinches/utils/distance_utils.dart';
import 'package:guachinches/utils/open_now_utils.dart';

/// Alto reservado para el título de las cards del grid: 2 líneas de Oswald 13
/// (fontSize 13 × line-height 1.2 × 2 ≈ 31.2, +slack). Constante compartida por
/// la card y su esqueleto para que ambos tengan exactamente la misma altura.
const double _kTitleTwoLineHeight = 32;

/// Sección "HOY EN…" en formato **panel + grid** (inspirado en las tarjetas de
/// ofertas tipo marketplace, adaptado a la voz del app).
///
/// - Panel crema redondeado con sombra suave.
/// - Cabecera: badge con el NÚMERO de sitios + título hora-aware + "Ver todos".
/// - Grid 2×2 de hasta 4 cards (foto 4:3 + badge abierto + nombre + rating).
///
/// Sustituye al combo `HourAwareBanner` + carrusel `CardHorizontal` para el
/// estado "abiertos ahora". El fallback "abren pronto" y el modo madrugada
/// siguen usando el carrusel clásico (otro contexto).
class TodayGridSection extends StatelessWidget {
  final int hour;

  /// Total de sitios que pasan el filtro contextual (el número del badge).
  /// `null` durante la carga → muestra esqueleto.
  final int? count;

  /// Top a pintar en el grid (máx 4). Vacío + count null = loading.
  final List<Restaurant> restaurants;

  final double? userLat;
  final double? userLon;

  final ValueChanged<String> onRestaurantTap;
  final VoidCallback? onSeeAll;

  const TodayGridSection({
    super.key,
    required this.hour,
    required this.restaurants,
    required this.onRestaurantTap,
    this.count,
    this.userLat,
    this.userLon,
    this.onSeeAll,
  });

  bool get _loading => count == null;

  @override
  Widget build(BuildContext context) {
    final copy = _copyForHour(hour);
    final cards = restaurants.take(4).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter, 12, AppSpacing.gutter, 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cremaSoft,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: context.brand.border, width: 1),
          boxShadow: AppShadows.soft(),
        ),
        clipBehavior: Clip.hardEdge,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                count: count,
                eyebrow: copy.eyebrow,
                title: copy.title,
                onSeeAll: onSeeAll,
              ),
              const SizedBox(height: 14),
              if (_loading)
                const _GridSkeleton()
              else
                _Grid(
                  restaurants: cards,
                  userLat: userLat,
                  userLon: userLon,
                  onRestaurantTap: onRestaurantTap,
                ),
            ],
          ),
        ),
      ),
    );
  }

  static _TodayCopy _copyForHour(int hour) {
    if (hour >= 7 && hour <= 11) {
      return const _TodayCopy('HORA DEL DESAYUNO', 'Sitios para desayunar');
    }
    if (hour >= 12 && hour <= 13) {
      return const _TodayCopy('HORA DEL ALMUERZO', 'Sitios para almorzar');
    }
    if (hour >= 14 && hour <= 16) {
      return const _TodayCopy('LA SOBREMESA', 'Sitios para la sobremesa');
    }
    if (hour >= 17 && hour <= 19) {
      return const _TodayCopy('GOLDEN HOUR', 'Terrazas al atardecer');
    }
    if (hour >= 20) {
      return const _TodayCopy('HORA DE LA CENA', 'Sitios para cenar');
    }
    return const _TodayCopy('DE MADRUGADA', 'Sitios abiertos ahora');
  }
}

class _TodayCopy {
  final String eyebrow;
  final String title;
  const _TodayCopy(this.eyebrow, this.title);
}

// ── Cabecera: badge número + eyebrow/título + "Ver todos" ──────────────────

class _Header extends StatelessWidget {
  final int? count;
  final String eyebrow;
  final String title;
  final VoidCallback? onSeeAll;

  const _Header({
    required this.count,
    required this.eyebrow,
    required this.title,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Badge con el número (sustituye al icono de la referencia).
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.atlantico.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: FittedBox(
            child: Text(
              count != null ? '$count' : '·',
              style: AppTextStyles.displayHero(size: 20)
                  .copyWith(color: AppColors.atlantico),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const _LiveDot(),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      eyebrow,
                      style: AppTextStyles.eyebrow(size: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                title,
                style: AppTextStyles.displaySection(
                  size: 17,
                  color: context.brand.textPrimary,
                ).copyWith(letterSpacing: 0.3),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (onSeeAll != null) ...[
          const SizedBox(width: 8),
          Semantics(
            identifier: 'home-today-see-all',
            child: GestureDetector(
              onTap: onSeeAll,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Ver todos ›',
                  style: AppTextStyles.ui(
                    size: 11,
                    color: AppColors.atlanticoClaro,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.laurisilva.withOpacity(0.22),
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.laurisilva,
          ),
        ),
      ),
    );
  }
}

// ── Grid 2×2 (filas de 2 con Expanded → sin overflow) ──────────────────────

class _Grid extends StatelessWidget {
  final List<Restaurant> restaurants;
  final double? userLat;
  final double? userLon;
  final ValueChanged<String> onRestaurantTap;

  const _Grid({
    required this.restaurants,
    required this.userLat,
    required this.userLon,
    required this.onRestaurantTap,
  });

  String? _distanceLabel(Restaurant r) {
    if (userLat == null || userLon == null) return null;
    if (r.lat == 0.0 && r.lon == 0.0) return null;
    return formatDistance(
        haversineDistanceMeters(userLat!, userLon!, r.lat, r.lon));
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final rows = <Widget>[];
    for (var i = 0; i < restaurants.length; i += 2) {
      final left = restaurants[i];
      final right = i + 1 < restaurants.length ? restaurants[i + 1] : null;
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _Card(
              restaurant: left,
              open: left.horariosJson != null &&
                  isOpenNow(left.horariosJson, now),
              distanceLabel: _distanceLabel(left),
              onTap: () => onRestaurantTap(left.id),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: right == null
                ? const SizedBox.shrink()
                : _Card(
                    restaurant: right,
                    open: right.horariosJson != null &&
                        isOpenNow(right.horariosJson, now),
                    distanceLabel: _distanceLabel(right),
                    onTap: () => onRestaurantTap(right.id),
                  ),
          ),
        ],
      ));
      if (i + 2 < restaurants.length) {
        rows.add(const SizedBox(height: 12));
      }
    }
    return Column(children: rows);
  }
}

class _Card extends StatefulWidget {
  final Restaurant restaurant;
  final bool open;
  final String? distanceLabel;
  final VoidCallback onTap;

  const _Card({
    required this.restaurant,
    required this.open,
    required this.distanceLabel,
    required this.onTap,
  });

  @override
  State<_Card> createState() => _CardState();
}

class _CardState extends State<_Card> {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _photo(context, r.mainFoto),
                    // Vignette superior para contraste del badge.
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 44,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.28),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (widget.open)
                      const Positioned(
                        top: 8,
                        left: 8,
                        child: _MiniBadge('ABIERTO', AppColors.laurisilva),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Alto reservado para 2 líneas (font 13 × height 1.2 × 2 ≈ 31.2)
            // → todas las cards quedan idénticas tenga el título 1 ó 2 líneas,
            //   y la fila de rating arranca siempre a la misma altura.
            SizedBox(
              height: _kTitleTwoLineHeight,
              width: double.infinity,
              child: Text(
                r.nombre.toUpperCase(),
                style: AppTextStyles.displaySection(size: 13)
                    .copyWith(letterSpacing: 0.2, height: 1.2),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                        r.avgRating > 0 ? r.avgRating.toStringAsFixed(1) : '—',
                        style: AppTextStyles.ui(
                          size: 11,
                          weight: FontWeight.w700,
                          color: AppColors.sol,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                if (widget.distanceLabel != null) ...[
                  const Icon(Icons.near_me_rounded,
                      color: AppColors.atlanticoClaro, size: 11),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      widget.distanceLabel!,
                      style: AppTextStyles.ui(
                        size: 11,
                        weight: FontWeight.w700,
                        color: AppColors.atlanticoClaro,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else
                  Flexible(
                    child: Text(
                      r.municipio,
                      style: AppTextStyles.muted(size: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _photo(BuildContext context, String? url) {
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        memCacheWidth: 360,
        placeholder: (_, __) => Container(color: context.brand.surface),
        errorWidget: (_, __, ___) => Container(color: context.brand.surface),
      );
    }
    return Container(color: context.brand.surface);
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 3, 9, 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.ui(
              size: 9,
              weight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Esqueleto de carga (mismo layout 2×2) ──────────────────────────────────

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget cell() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ShimmerBox(
                width: double.infinity,
                height: double.infinity,
                radius: 14,
              ),
            ),
            const SizedBox(height: 8),
            // Reserva el mismo alto de título (2 líneas) con dos barras.
            const SizedBox(
              height: _kTitleTwoLineHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: double.infinity, height: 12, radius: 4),
                  SizedBox(height: 6),
                  ShimmerBox(width: 90, height: 12, radius: 4),
                ],
              ),
            ),
            const SizedBox(height: 5),
            const ShimmerBox(width: 70, height: 12, radius: 4),
          ],
        );

    Widget row() => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cell()),
            const SizedBox(width: 12),
            Expanded(child: cell()),
          ],
        );

    return Column(
      children: [
        row(),
        const SizedBox(height: 12),
        row(),
      ],
    );
  }
}
