import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/model/Visit.dart';

/// Card visita Jonay & Joana — diseño split:
/// - Foto arriba con badge YouTube (si hay videoUrl)
/// - Panel cream-soft abajo con título uppercase + cita italic
class CardVisit extends StatefulWidget {
  final Visit visit;
  final VoidCallback onTap;

  const CardVisit({super.key, required this.visit, required this.onTap});

  @override
  State<CardVisit> createState() => _CardVisitState();
}

class _CardVisitState extends State<CardVisit> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final v = widget.visit;
    final photoUrl = v.thumbnail?.isNotEmpty == true
        ? v.thumbnail
        : v.restaurant?.mainFoto;
    final name = (v.name?.isNotEmpty == true ? v.name! : v.restaurant?.nombre) ?? '';
    final hasYoutube = (v.videoUrl != null && v.videoUrl!.isNotEmpty) ||
        (v.youtubeVideoId != null && v.youtubeVideoId!.isNotEmpty);
    final caption = _captionFor(v);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 130),
        child: Container(
          width: 200,
          decoration: BoxDecoration(
            color: context.brand.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.brand.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Foto + badge YouTube + play overlay + título ─
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: SizedBox(
                  height: 200,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildPhoto(context, photoUrl),
                      // Degradado superior suave (mejora contraste del badge)
                      Positioned(
                        top: 0, left: 0, right: 0, height: 70,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.25),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Degradado oscuro al pie para legibilidad del título
                      Positioned(
                        bottom: 0, left: 0, right: 0, height: 110,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Play overlay central (clave visual de vídeo)
                      if (hasYoutube)
                        const Center(child: _PlayCircle()),
                      // Título sobre la foto
                      if (name.isNotEmpty)
                        Positioned(
                          left: 12, right: 12, bottom: 12,
                          child: Text(
                            name.toUpperCase(),
                            style: AppTextStyles.displaySection(
                              size: 14,
                              color: Colors.white,
                            ).copyWith(
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.6),
                                  blurRadius: 8,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // ── Separador sutil entre foto y panel ───
              Container(
                height: 1,
                color: Colors.black.withOpacity(0.06),
              ),
              // ── Panel cita editorial ─────────────────
              if (caption != null && caption.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Comilla decorativa tenue
                          Positioned(
                            left: -2, top: -8,
                            child: Text(
                              '"',
                              style: TextStyle(
                                fontFamily: 'SF Pro Display',
                                fontSize: 36,
                                height: 1,
                                fontWeight: FontWeight.w700,
                                color: context.brand.textSecondary.withOpacity(0.18),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 14, top: 4),
                            child: Text(
                              caption,
                              style: AppTextStyles.editorial(
                                size: 12,
                                color: context.brand.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Footer CTA
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Ver visita',
                            style: AppTextStyles.ui(
                              size: 11,
                              weight: FontWeight.w600,
                              color: AppColors.atlantico,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 13,
                            color: AppColors.atlantico,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String? _captionFor(Visit v) {
    if (v.extraText?.isNotEmpty == true) return v.extraText;
    if (v.quotes.isNotEmpty) return v.quotes.first.text;
    if (v.summary?.isNotEmpty == true) return v.summary;
    if (v.highlights.isNotEmpty) return v.highlights.first;
    return null;
  }

  Widget _buildPhoto(BuildContext context, String? url) {
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        memCacheWidth: 400,
        placeholder: (_, __) => Container(color: context.brand.elevated),
        errorWidget: (_, __, ___) => Container(color: context.brand.elevated),
      );
    }
    return Container(color: context.brand.elevated);
  }
}

class _PlayCircle extends StatelessWidget {
  const _PlayCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
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
        size: 32,
        color: Color(0xFF1A1A1A),
      ),
    );
  }
}
