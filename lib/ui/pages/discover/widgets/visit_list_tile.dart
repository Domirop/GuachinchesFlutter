import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/model/Visit.dart';

/// Tarjeta horizontal de visita pensada para listado vertical (browser),
/// **expandible**: tap → despliega resumen completo, platos destacados,
/// highlights / lowlights, servicios y CTA para abrir la visita.
class VisitListTile extends StatefulWidget {
  final Visit visit;
  /// Navegación al detalle (la usa el botón "Ver visita completa").
  final VoidCallback onTap;

  const VisitListTile({
    super.key,
    required this.visit,
    required this.onTap,
  });

  @override
  State<VisitListTile> createState() => _VisitListTileState();
}

class _VisitListTileState extends State<VisitListTile> {
  bool _pressed = false;
  bool _expanded = false;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final v = widget.visit;
    final brand = context.brand;

    final photoUrl = v.thumbnail?.isNotEmpty == true
        ? v.thumbnail
        : v.restaurant?.mainFoto;
    final name = (v.name?.isNotEmpty == true
            ? v.name!
            : v.restaurant?.nombre ?? '')
        .trim();
    final hasYoutube = (v.videoUrl != null && v.videoUrl!.isNotEmpty) ||
        (v.youtubeVideoId != null && v.youtubeVideoId!.isNotEmpty);
    final caption = _captionFor(v);
    final zone = (v.zone?.isNotEmpty == true ? v.zone : v.restaurant?.municipio) ?? '';
    final rating = v.ratingImplicit;
    final priceRange = v.priceRange?.trim();
    final sentiment = v.overallSentiment;
    final dateLabel = _dateLabel(v.publishedAt ?? v.createdAt);

    return GestureDetector(
      // Tap fuera del botón de despliegue → abrir detalle.
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 130),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: brand.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _expanded
                  ? AppColors.atlantico.withOpacity(0.45)
                  : brand.border,
              width: _expanded ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_expanded ? 0.10 : 0.05),
                blurRadius: _expanded ? 18 : 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Collapsed row ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Thumbnail(
                      url: photoUrl,
                      hasVideo: hasYoutube,
                      fallbackColor: brand.elevated,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _CreatorRow(
                            creator: v.creator,
                            date: dateLabel,
                          ),
                          const SizedBox(height: 6),
                          if (name.isNotEmpty)
                            Text(
                              name.toUpperCase(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.displaySection(size: 15),
                            ),
                          const SizedBox(height: 5),
                          _MetaLine(
                            rating: rating,
                            zone: zone,
                            priceRange: priceRange,
                            sentiment: sentiment,
                          ),
                          if (caption != null &&
                              caption.isNotEmpty &&
                              !_expanded) ...[
                            const SizedBox(height: 7),
                            Text(
                              '"$caption"',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.editorial(
                                size: 12,
                                color: brand.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Solo este botón controla expandir/colapsar; el resto
                    // de la tarjeta navega al detalle.
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _toggle,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: AnimatedRotation(
                          turns: _expanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 220),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: _expanded
                                  ? AppColors.atlantico.withOpacity(0.18)
                                  : brand.elevated,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: _expanded
                                  ? AppColors.atlanticoClaro
                                  : brand.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ── Expanded body ──────────────────────────────────────────
              ClipRect(
                child: AnimatedAlign(
                  alignment: Alignment.topCenter,
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOut,
                  heightFactor: _expanded ? 1 : 0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: _expanded ? 1.0 : 0.0,
                    child: _ExpandedBody(
                      visit: v,
                      onOpen: widget.onTap,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String? _captionFor(Visit v) {
    if (v.extraText?.isNotEmpty == true) return v.extraText;
    if (v.quotes.isNotEmpty) return v.quotes.first.text;
    if (v.summary?.isNotEmpty == true) return v.summary;
    if (v.highlights.isNotEmpty) return v.highlights.first;
    return null;
  }

  static String _dateLabel(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt).inDays;
    if (diff < 1) return 'Hoy';
    if (diff < 2) return 'Ayer';
    if (diff < 7) return 'Hace ${diff}d';
    if (diff < 30) {
      final w = (diff / 7).floor();
      return 'Hace ${w}sem';
    }
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    if (dt.year == now.year) {
      return '${dt.day} ${months[dt.month - 1]}';
    }
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// ── Expanded body ──────────────────────────────────────────────────────────
class _ExpandedBody extends StatelessWidget {
  final Visit visit;
  final VoidCallback onOpen;

  const _ExpandedBody({required this.visit, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final v = visit;

    final summary = v.summary?.trim();
    final topDishes = v.dishes
        .where((d) => d.isTop || d.sentiment == 'loved')
        .toList();
    final fallbackDishes =
        topDishes.isEmpty ? v.dishes.take(4).toList() : topDishes.take(4).toList();
    final highlights = v.highlights.take(3).toList();
    final lowlights = v.lowlights.take(2).toList();
    final services = v.services.take(6).toList();
    final quote = v.quotes.isNotEmpty ? v.quotes.first.text : null;
    final hasAnyExtra = (summary != null && summary.isNotEmpty) ||
        fallbackDishes.isNotEmpty ||
        highlights.isNotEmpty ||
        lowlights.isNotEmpty ||
        services.isNotEmpty ||
        (quote != null && quote.isNotEmpty);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 1,
            margin: const EdgeInsets.only(bottom: 14),
            color: brand.border,
          ),
          if (quote != null && quote.isNotEmpty) ...[
            _Quote(text: quote, brand: brand),
            const SizedBox(height: 14),
          ],
          if (summary != null && summary.isNotEmpty) ...[
            Text(
              summary,
              style: AppTextStyles.ui(
                size: 13,
                color: brand.textPrimary,
              ).copyWith(height: 1.45),
            ),
            const SizedBox(height: 14),
          ],
          if (fallbackDishes.isNotEmpty) ...[
            _SectionLabel(
              icon: Icons.local_dining_rounded,
              label: topDishes.isNotEmpty ? 'PLATOS DESTACADOS' : 'PLATOS',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final d in fallbackDishes) _DishChip(dish: d),
              ],
            ),
            const SizedBox(height: 14),
          ],
          if (highlights.isNotEmpty) ...[
            _SectionLabel(
              icon: Icons.thumb_up_rounded,
              label: 'LO MEJOR',
              color: AppColors.laurisilva,
            ),
            const SizedBox(height: 6),
            for (final h in highlights)
              _BulletRow(
                icon: Icons.check_rounded,
                color: AppColors.laurisilva,
                text: h,
              ),
            const SizedBox(height: 12),
          ],
          if (lowlights.isNotEmpty) ...[
            _SectionLabel(
              icon: Icons.thumb_down_rounded,
              label: 'LO MENOS BUENO',
              color: AppColors.mojo,
            ),
            const SizedBox(height: 6),
            for (final l in lowlights)
              _BulletRow(
                icon: Icons.close_rounded,
                color: AppColors.mojo,
                text: l,
              ),
            const SizedBox(height: 12),
          ],
          if (services.isNotEmpty) ...[
            _SectionLabel(
              icon: Icons.room_service_rounded,
              label: 'SERVICIOS',
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in services) _ServiceChip(label: s),
              ],
            ),
            const SizedBox(height: 14),
          ],
          if (!hasAnyExtra)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'No hay información adicional disponible.',
                style: AppTextStyles.muted(size: 12),
              ),
            ),
          // Action button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.play_arrow_rounded,
                  size: 20, color: Colors.white),
              label: Text(
                'Ver visita completa',
                style: AppTextStyles.ui(
                  size: 13,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.atlantico,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _SectionLabel({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.atlanticoClaro;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.eyebrow(size: 11, color: c),
        ),
      ],
    );
  }
}

class _BulletRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _BulletRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.ui(
                size: 12,
                color: context.brand.textPrimary,
              ).copyWith(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _DishChip extends StatelessWidget {
  final VisitDish dish;
  const _DishChip({required this.dish});

  @override
  Widget build(BuildContext context) {
    final isTop = dish.isTop || dish.sentiment == 'loved';
    final color = isTop ? AppColors.sol : AppColors.atlantico;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isTop) ...[
            const Icon(Icons.star_rounded, size: 13, color: AppColors.sol),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              dish.name,
              style: AppTextStyles.ui(
                size: 12,
                weight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          if (dish.price != null) ...[
            const SizedBox(width: 6),
            Text(
              '${dish.price}€',
              style: AppTextStyles.ui(
                size: 11,
                weight: FontWeight.w600,
                color: color.withOpacity(0.85),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final String label;
  const _ServiceChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: brand.elevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: brand.border),
      ),
      child: Text(
        label,
        style: AppTextStyles.ui(
          size: 11,
          weight: FontWeight.w500,
          color: brand.textPrimary,
        ),
      ),
    );
  }
}

class _Quote extends StatelessWidget {
  final String text;
  final BrandColors brand;

  const _Quote({required this.text, required this.brand});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -2,
          top: -10,
          child: Text(
            '"',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 40,
              height: 1,
              fontWeight: FontWeight.w700,
              color: brand.textSecondary.withOpacity(0.18),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 4),
          child: Text(
            text,
            style: AppTextStyles.editorial(
              size: 13,
              color: brand.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Thumbnail ──────────────────────────────────────────────────────────────
class _Thumbnail extends StatelessWidget {
  final String? url;
  final bool hasVideo;
  final Color fallbackColor;

  const _Thumbnail({
    required this.url,
    required this.hasVideo,
    required this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 110,
        height: 110,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url != null && url!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                memCacheWidth: 320,
                placeholder: (_, __) => Container(color: fallbackColor),
                errorWidget: (_, __, ___) => Container(color: fallbackColor),
              )
            else
              Container(color: fallbackColor),
            if (hasVideo) ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0),
                      Colors.black.withOpacity(0.32),
                    ],
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 22,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Creator row ────────────────────────────────────────────────────────────
class _CreatorRow extends StatelessWidget {
  final String? creator;
  final String date;

  const _CreatorRow({required this.creator, required this.date});

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final hasCreator = creator?.isNotEmpty == true;
    return Row(
      children: [
        if (hasCreator)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.atlantico.withOpacity(0.14),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: AppColors.atlantico.withOpacity(0.4),
              ),
            ),
            child: Text(
              'POR ${creator!.toUpperCase()}',
              style: AppTextStyles.eyebrow(
                size: 10,
                color: AppColors.atlanticoClaro,
              ),
            ),
          ),
        if (hasCreator && date.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '·',
              style: AppTextStyles.ui(size: 10, color: brand.textMuted),
            ),
          ),
        if (date.isNotEmpty)
          Text(
            date,
            style: AppTextStyles.muted(size: 11),
          ),
      ],
    );
  }
}

// ── Meta line ──────────────────────────────────────────────────────────────
class _MetaLine extends StatelessWidget {
  final double? rating;
  final String zone;
  final String? priceRange;
  final String? sentiment;

  const _MetaLine({
    required this.rating,
    required this.zone,
    required this.priceRange,
    required this.sentiment,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final children = <Widget>[];
    if (rating != null && rating! > 0) {
      children.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 13, color: AppColors.sol),
            const SizedBox(width: 3),
            Text(
              rating!.toStringAsFixed(1),
              style: AppTextStyles.ui(
                size: 12,
                weight: FontWeight.w700,
                color: AppColors.sol,
              ),
            ),
          ],
        ),
      );
    }
    if (zone.isNotEmpty) {
      if (children.isNotEmpty) children.add(_dot(context));
      children.add(Flexible(
        child: Text(
          zone,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.ui(
            size: 12,
            color: brand.textPrimary,
          ),
        ),
      ));
    }
    if (priceRange != null && priceRange!.isNotEmpty) {
      if (children.isNotEmpty) children.add(_dot(context));
      children.add(Text(
        priceRange!.replaceAll(r'$', '€'),
        style: AppTextStyles.ui(
          size: 12,
          weight: FontWeight.w700,
          color: brand.textSecondary,
        ),
      ));
    }
    final sentimentChip = _sentimentChip(sentiment);
    if (sentimentChip != null) {
      if (children.isNotEmpty) children.add(const SizedBox(width: 8));
      children.add(sentimentChip);
    }
    if (children.isEmpty) return const SizedBox.shrink();
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 4,
      children: children,
    );
  }

  Widget _dot(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Text(
          '·',
          style: AppTextStyles.ui(
            size: 12,
            color: context.brand.textMuted,
          ),
        ),
      );

  Widget? _sentimentChip(String? sentiment) {
    if (sentiment == null || sentiment.isEmpty) return null;
    final (label, color) = switch (sentiment) {
      'muy_positivo' => ('Muy bueno', AppColors.laurisilva),
      'positivo' => ('Bueno', AppColors.atlantico),
      'neutro' => ('Neutro', AppColors.arena),
      'negativo' => ('Flojo', AppColors.mojo),
      _ => (null, null),
    };
    if (label == null || color == null) return null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.chipLabel(size: 9, color: color),
      ),
    );
  }
}
