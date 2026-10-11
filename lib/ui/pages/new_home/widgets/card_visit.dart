import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show gmDisplayName, gmPlaceName;
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';

/// Póster de visita de Jonay y Joana (rediseño iOS 27): foto a sangre r28,
/// degradado, fecha en cristal oscuro, botón play de cristal (con un único
/// pulso en el primer póster), sello vino «Les encantó» solo si la visita
/// fue muy positiva, municipio, título 20/25 y la cita en cursiva.
class CardVisit extends StatelessWidget {
  final Visit visit;
  final VoidCallback onTap;

  /// Solo el primer póster del carrusel emite el pulso del botón play.
  final bool pulse;

  const CardVisit({
    super.key,
    required this.visit,
    required this.onTap,
    this.pulse = false,
  });

  /// Clave del botón play (tests).
  static const playKey = ValueKey('card-visit-play');

  static const double cardWidth = 204;
  static const double cardHeight = 306;

  static const _months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  /// «8 oct» (año en curso) · «8 oct 2025» (otro año).
  static String? formatVideoDate(String? iso) {
    if (iso == null) return null;
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return null;
    final base = '${d.day} ${_months[d.month - 1]}';
    return d.year == DateTime.now().year ? base : '$base ${d.year}';
  }

  /// Cita del póster. Prioridad de siempre (texto extra → cita → resumen →
  /// destacado); las citas literales van entre comillas latinas.
  static String? captionFor(Visit v) {
    if (v.extraText?.isNotEmpty == true) return v.extraText;
    if (v.quotes.isNotEmpty && v.quotes.first.text.trim().isNotEmpty) {
      final q = v.quotes.first.text.trim();
      return q.startsWith('«') || q.startsWith('"') ? q : '«$q»';
    }
    if (v.summary?.isNotEmpty == true) return v.summary;
    if (v.highlights.isNotEmpty) return v.highlights.first;
    return null;
  }

  /// «Les encantó» solo cuando el análisis del vídeo dice muy positivo.
  static bool loved(Visit v) => v.overallSentiment == 'muy_positivo';

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final v = visit;
    final photoUrl =
        v.thumbnail?.isNotEmpty == true ? v.thumbnail : v.restaurant?.mainFoto;
    final name = gmDisplayName(
        (v.name?.isNotEmpty == true ? v.name! : v.restaurant?.nombre) ?? '');
    final hasYoutube = (v.videoUrl != null && v.videoUrl!.isNotEmpty) ||
        (v.youtubeVideoId != null && v.youtubeVideoId!.isNotEmpty);
    final caption = captionFor(v);
    final location = gmPlaceName((v.zone?.isNotEmpty == true
            ? v.zone
            : (v.restaurant?.municipio ?? v.restaurant?.island)) ??
        '');
    final dateLabel = formatVideoDate(v.sortDate);

    // Póster de tamaño fijo: el texto escala como mucho a 1,3×.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: GmPressable(
        onTap: onTap,
        semanticsLabel: name,
        child: Container(
          width: cardWidth,
          height: cardHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(GmRadius.poster),
            boxShadow: gm.shadow2,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(GmRadius.poster),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _Photo(url: photoUrl),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x47000000),
                        Color(0x00000000),
                        Color(0x00000000),
                        Color(0xDB000000),
                      ],
                      stops: [0, 0.24, 0.40, 1],
                    ),
                  ),
                ),
                if (dateLabel != null)
                  Positioned(
                    left: 12,
                    top: 12,
                    child: _BlurChip(
                        child: GmPhotoChip(label: dateLabel, dark: true)),
                  ),
                if (hasYoutube)
                  Positioned(
                    right: 12,
                    top: 12,
                    child: _PlayGlass(key: CardVisit.playKey, pulse: pulse),
                  ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (loved(v)) ...[
                        const LovedSeal(),
                        const SizedBox(height: 6),
                      ],
                      if (location.isNotEmpty)
                        Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GmText.chip(
                              color: Colors.white.withValues(alpha: 0.85)),
                        ),
                      if (location.isNotEmpty) const SizedBox(height: 2),
                      if (name.isNotEmpty)
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GmText.poster(color: Colors.white),
                        ),
                      if (caption != null && caption.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          caption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GmText.meta(
                                  color: Colors.white.withValues(alpha: 0.94))
                              .copyWith(fontStyle: FontStyle.italic),
                        ),
                      ],
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
}

/// Sello vino + oro «Les encantó».
class LovedSeal extends StatelessWidget {
  const LovedSeal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: GmColors.wine,
        borderRadius: BorderRadius.circular(GmRadius.pill),
        border: Border.all(color: const Color(0x80C9A96B)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GmIcon(GmIcons.thumb, size: 12, color: GmColors.gold),
          const SizedBox(width: 5),
          const Text(
            'Les encantó',
            style: TextStyle(
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFFE8CF9A),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlurChip extends StatelessWidget {
  final Widget child;
  const _BlurChip({required this.child});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(GmRadius.pill),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
          child: child,
        ),
      );
}

/// Botón play de cristal (36). Con [pulse], un único anillo a 1,2 s.
class _PlayGlass extends StatelessWidget {
  final bool pulse;
  const _PlayGlass({super.key, required this.pulse});

  @override
  Widget build(BuildContext context) {
    final button = ClipOval(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.24),
            shape: BoxShape.circle,
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.5), width: 0.5),
          ),
          alignment: Alignment.center,
          child: GmIcon(GmIcons.play, size: 13, color: Colors.white),
        ),
      ),
    );
    if (!pulse) return button;
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: GmOnce(
              duration: const Duration(milliseconds: 1600),
              delay: const Duration(milliseconds: 1200),
              builder: (_, t, __) {
                if (t <= 0 || t >= 1) return const SizedBox.shrink();
                final e = const Cubic(0, 0, 0.2, 1).transform(t);
                return Transform.scale(
                  scale: 1 + 0.7 * e,
                  child: Opacity(
                    opacity: 0.9 * (1 - e),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.85),
                            width: 1.5),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          button,
        ],
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  final String? url;
  const _Photo({this.url});

  @override
  Widget build(BuildContext context) {
    final u = url;
    const placeholder = GmFill();
    if (u == null || u.isEmpty) return placeholder;

    // Los thumbnails de YouTube llegan como `hqdefault.jpg` (480×360), que al
    // recortarse a vertical se ve blando. Pedimos `maxresdefault.jpg`
    // (1280×720) y, si ese vídeo no lo tiene (404), caemos al hqdefault.
    final isYtHq = u.contains('i.ytimg.com') && u.contains('/hqdefault.');
    final primary = isYtHq ? u.replaceAll('/hqdefault.', '/maxresdefault.') : u;
    const decodeWidth = 640;

    return CachedNetworkImage(
      imageUrl: primary,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      memCacheWidth: decodeWidth,
      placeholder: (_, __) => placeholder,
      errorWidget: (_, __, ___) => isYtHq
          ? CachedNetworkImage(
              imageUrl: u,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              memCacheWidth: decodeWidth,
              placeholder: (_, __) => placeholder,
              errorWidget: (_, __, ___) => placeholder,
            )
          : placeholder,
    );
  }
}
