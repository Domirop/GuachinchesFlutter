import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/model/Visit.dart';

/// Card de visita Jonay & Joana — estilo "póster" como la web: foto/vídeo a
/// sangre en formato vertical, badge de fecha del vídeo arriba-izquierda, botón
/// de play arriba-derecha, y al pie (sobre degradado) zona + título grande +
/// descripción italic.
class CardVisit extends StatefulWidget {
  final Visit visit;
  final VoidCallback onTap;

  const CardVisit({super.key, required this.visit, required this.onTap});

  static const double cardWidth = 210;
  static const double cardHeight = 348;

  @override
  State<CardVisit> createState() => _CardVisitState();
}

class _CardVisitState extends State<CardVisit> {
  bool _pressed = false;

  static const _months = [
    'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
    'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC',
  ];

  @override
  Widget build(BuildContext context) {
    final v = widget.visit;
    final photoUrl =
        v.thumbnail?.isNotEmpty == true ? v.thumbnail : v.restaurant?.mainFoto;
    final name =
        (v.name?.isNotEmpty == true ? v.name! : v.restaurant?.nombre) ?? '';
    final hasYoutube = (v.videoUrl != null && v.videoUrl!.isNotEmpty) ||
        (v.youtubeVideoId != null && v.youtubeVideoId!.isNotEmpty);
    final caption = _captionFor(v);
    final location = (v.zone?.isNotEmpty == true
            ? v.zone
            : (v.restaurant?.municipio ?? v.restaurant?.island)) ??
        '';
    final dateLabel = _formatVideoDate(v.sortDate);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 130),
        child: Container(
          width: CardVisit.cardWidth,
          height: CardVisit.cardHeight,
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
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildPhoto(context, photoUrl),
              // Degradado superior (contraste de badge + play).
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 96,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.32),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Degradado inferior largo (legibilidad del texto).
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 210,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.55, 1.0],
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.45),
                        Colors.black.withOpacity(0.85),
                      ],
                    ),
                  ),
                ),
              ),
              // ── Fila superior: fecha del vídeo + play ──────────────────
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (dateLabel != null) _DateBadge(label: dateLabel),
                    const Spacer(),
                    if (hasYoutube) const _PlayCircle(),
                  ],
                ),
              ),
              // ── Pie: zona + título + descripción ───────────────────────
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (location.isNotEmpty)
                      Text(
                        location.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.eyebrow(
                          size: 10,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    if (location.isNotEmpty) const SizedBox(height: 4),
                    if (name.isNotEmpty)
                      Text(
                        name.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        // Título de card unificado del home (displaySection 16).
                        style: AppTextStyles.displaySection(
                          size: 16,
                          color: Colors.white,
                        ).copyWith(letterSpacing: 0.3, height: 1.15),
                      ),
                    if (caption != null && caption.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.editorial(
                          size: 12,
                          color: Colors.white.withOpacity(0.82),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _formatVideoDate(String? iso) {
    if (iso == null) return null;
    final d = DateTime.tryParse(iso);
    if (d == null) return null;
    final yy = (d.year % 100).toString().padLeft(2, '0');
    return '${d.day} ${_months[d.month - 1]} $yy';
  }

  String? _captionFor(Visit v) {
    if (v.extraText?.isNotEmpty == true) return v.extraText;
    if (v.quotes.isNotEmpty) return v.quotes.first.text;
    if (v.summary?.isNotEmpty == true) return v.summary;
    if (v.highlights.isNotEmpty) return v.highlights.first;
    return null;
  }

  Widget _buildPhoto(BuildContext context, String? url) {
    if (url == null || url.isEmpty) {
      return Container(color: context.brand.elevated);
    }
    final placeholder = Container(color: context.brand.elevated);

    // Los thumbnails de YouTube llegan como `hqdefault.jpg` (480×360), que al
    // recortarse a vertical se ve blando. Pedimos `maxresdefault.jpg`
    // (1280×720) y, si ese vídeo no lo tiene (404), caemos al hqdefault.
    final isYtHq =
        url.contains('i.ytimg.com') && url.contains('/hqdefault.');
    final primary =
        isYtHq ? url.replaceAll('/hqdefault.', '/maxresdefault.') : url;

    // memCacheWidth ~= ancho de la card en píxeles físicos (210pt @3x ≈ 630).
    const decodeWidth = 640;

    return CachedNetworkImage(
      imageUrl: primary,
      fit: BoxFit.cover,
      memCacheWidth: decodeWidth,
      placeholder: (_, __) => placeholder,
      errorWidget: (_, __, ___) => isYtHq
          ? CachedNetworkImage(
              imageUrl: url, // fallback hqdefault original
              fit: BoxFit.cover,
              memCacheWidth: decodeWidth,
              placeholder: (_, __) => placeholder,
              errorWidget: (_, __, ___) => placeholder,
            )
          : placeholder,
    );
  }
}

/// Badge de fecha del vídeo (arriba-izquierda), pill translúcido oscuro.
class _DateBadge extends StatelessWidget {
  final String label;

  const _DateBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.42),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.eyebrow(
          size: 10,
          color: Colors.white,
        ).copyWith(letterSpacing: 1.2),
      ),
    );
  }
}

class _PlayCircle extends StatelessWidget {
  const _PlayCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(
        Icons.play_arrow_rounded,
        size: 30,
        color: Color(0xFF1A1A1A),
      ),
    );
  }
}
