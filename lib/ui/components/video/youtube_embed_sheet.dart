// DO NOT load youtube.com/watch?v= in a raw WebView or extract MP4 streams.
// Both violate YouTube's Terms of Service and will get the app banned.
// Always use the official IFrame Player API (youtube_player_iframe) through
// YoutubeEmbedWithFallback.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/ui/components/video/youtube_embed_with_fallback.dart';
import 'package:guachinches/ui/components/video/youtube_sheet_logic.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show GmPhoto;
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

/// Hoja negra con el Short de YouTube incrustado (tablero `VideoYouTube`):
/// asa, Cerrar y «Abrir en YouTube» de cristal, marco vertical 9:16 r20 con
/// el player oficial y, debajo, «Jonay y Joana · fecha · duración» y el
/// sitio. Si YouTube no deja incrustarlo (o falla / tarda), el marco muestra
/// el póster desenfocado con «Ver en YouTube».
class YoutubeEmbedSheet {
  YoutubeEmbedSheet._();

  /// [visit] rellena lo que no se pase explícitamente (sitio, tipo ·
  /// municipio, fecha, duración y póster).
  static Future<void> show(
    BuildContext context, {
    required String videoId,
    int? startSeconds,
    Visit? visit,
    String? placeName,
    String? placeMeta,
    String? publishedAtIso,
    int? durationSeconds,
    String? posterUrl,
  }) {
    final info = YoutubeSheetInfo.resolve(
      visit: visit,
      placeName: placeName,
      placeMeta: placeMeta,
      publishedAtIso: publishedAtIso,
      durationSeconds: durationSeconds,
      posterUrl: posterUrl,
    );
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.black,
      barrierColor: const Color(0x80000000),
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      sheetAnimationStyle:
          GmMotion.reduced(context) ? AnimationStyle.noAnimation : null,
      builder: (_) => YoutubeEmbedSheetBody(
        videoId: videoId,
        startSeconds: startSeconds,
        info: info,
      ),
    );
  }
}

/// Icono «abrir fuera» (cuadro con flecha), dibujado como en el tablero.
const String youtubeExternalIcon =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
    'stroke="currentColor" stroke-width="2.4" stroke-linecap="round" '
    'stroke-linejoin="round"><path d="M14 4h6v6"/><path d="M20 4l-9 9"/>'
    '<path d="M18 14v4a2 2 0 01-2 2H6a2 2 0 01-2-2V8a2 2 0 012-2h4"/></svg>';

const _frameBg = Color(0xFF161412);
const _white72 = Color(0xB8FFFFFF);

Future<void> _openExternal(
    BuildContext context, String videoId, int? startSeconds) async {
  final uri = youtubeExternalUri(videoId, startSeconds: startSeconds);
  void fail() {
    AppLogger.warn('youtube-embed', 'fallback_launch_failed');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el vídeo')),
      );
    }
  }

  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (launched) {
      AppLogger.info('youtube-embed', 'external_launch_success');
    } else {
      fail();
    }
  } catch (e, st) {
    AppLogger.error('youtube-embed', e, st);
    fail();
  }
}

/// Contenido de la hoja (público para tests).
class YoutubeEmbedSheetBody extends StatefulWidget {
  final String videoId;
  final int? startSeconds;
  final YoutubeSheetInfo info;

  const YoutubeEmbedSheetBody({
    super.key,
    required this.videoId,
    this.startSeconds,
    this.info = const YoutubeSheetInfo(),
  });

  @override
  State<YoutubeEmbedSheetBody> createState() => _YoutubeEmbedSheetBodyState();
}

class _YoutubeEmbedSheetBodyState extends State<YoutubeEmbedSheetBody> {
  late bool _fallback = !youtubeIdLooksValid(widget.videoId);

  void _open() => _openExternal(context, widget.videoId, widget.startSeconds);

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final poster =
        youtubePosterUrl(widget.videoId, posterUrl: widget.info.posterUrl);
    return LayoutBuilder(builder: (context, c) {
      final textScale = MediaQuery.textScalerOf(context).scale(1);
      // Asa + fila de botones (18 + 44 + 14), hueco (16), pie (~47 · escala)
      // y margen inferior.
      final chrome = 18 + 44 + 14 + 16 + 47 * textScale + 16 + safeBottom;
      final avail = c.maxHeight.isFinite
          ? c.maxHeight
          : MediaQuery.sizeOf(context).height;
      var frameH = math.min(avail * 0.63, avail - chrome - 24);
      frameH = math.min(frameH, (c.maxWidth - 32) * 16 / 9);
      frameH = math.max(frameH, 160);
      final frameW = frameH * 9 / 16;

      return Semantics(
        identifier: 'youtube-embed-sheet-root',
        explicitChildNodes: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 7),
            Center(
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0x4DFFFFFF),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _SheetGlassButton(
                    identifier: 'youtube-embed-close-button',
                    semanticLabel: 'Cerrar',
                    onTap: () => Navigator.of(context).maybePop(),
                    circle: true,
                    child: GmIcon(GmIcons.close, size: 18, color: Colors.white),
                  ),
                  const Spacer(),
                  if (!_fallback)
                    _SheetGlassButton(
                      identifier: 'youtube-embed-open-external-button',
                      onTap: _open,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GmIcon(youtubeExternalIcon,
                              size: 16, color: Colors.white),
                          SizedBox(width: 7),
                          Text(
                            'Abrir en YouTube',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: SizedBox(
                width: frameW,
                height: frameH,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: ColoredBox(
                    color: _frameBg,
                    child: YoutubeEmbedWithFallback(
                      videoId: widget.videoId,
                      startSeconds: widget.startSeconds,
                      backgroundColor: _frameBg,
                      loadingBuilder: (_) => const _FrameLoading(),
                      onFallback: () {
                        if (mounted && !_fallback) {
                          setState(() => _fallback = true);
                        }
                      },
                      fallbackBuilder: (_) =>
                          _FrameFallback(posterUrl: poster, onOpen: _open),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SheetFooter(info: widget.info, poster: poster),
            ),
            SizedBox(height: 16 + safeBottom),
          ],
        ),
      );
    });
  }
}

/// Botón de cristal claro sobre negro (blanco .14): círculo 44 o cápsula 44.
class _SheetGlassButton extends StatelessWidget {
  final String identifier;
  final String? semanticLabel;
  final VoidCallback onTap;
  final Widget child;
  final bool circle;

  const _SheetGlassButton({
    required this.identifier,
    required this.onTap,
    required this.child,
    this.semanticLabel,
    this.circle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: identifier,
      label: semanticLabel,
      button: true,
      child: GmPressable(
        onTap: onTap,
        pressedScale: circle ? 0.9 : 0.95,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          child: GmGlass(
            borderRadius: BorderRadius.circular(GmRadius.pill),
            tint: const Color(0x24FFFFFF),
            edge: const Color(0x59FFFFFF),
            edgeWidth: 0.5,
            blur: 20,
            child: circle
                ? SizedBox(width: 44, height: 44, child: Center(child: child))
                : Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child:
                        Center(widthFactor: 1, heightFactor: 1, child: child),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Marco cargando: #161412 + indicador (quieto con «reducir movimiento»).
class _FrameLoading extends StatelessWidget {
  const _FrameLoading();

  @override
  Widget build(BuildContext context) {
    final reduced = GmMotion.reduced(context);
    return ColoredBox(
      color: _frameBg,
      child: Center(
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            value: reduced ? 0.25 : null,
            strokeWidth: 2.4,
            strokeCap: StrokeCap.round,
            color: const Color(0xB3FFFFFF),
            backgroundColor: const Color(0x2EFFFFFF),
            semanticsLabel: 'Cargando vídeo',
          ),
        ),
      ),
    );
  }
}

/// Respaldo dentro del marco: póster desenfocado y oscurecido, copia y
/// «Ver en YouTube».
class _FrameFallback extends StatelessWidget {
  final String? posterUrl;
  final VoidCallback onOpen;

  const _FrameFallback({required this.posterUrl, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final url = posterUrl;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (url != null)
          ExcludeSemantics(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(color: _frameBg),
              ),
            ),
          ),
        const ColoredBox(color: Color(0x8C000000)),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Semantics(
              liveRegion: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Este vídeo no se puede ver aquí',
                    textAlign: TextAlign.center,
                    style: GmText.poster(color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'YouTube no deja reproducirlo dentro de la app. Ábrelo '
                    'allí y vuelves cuando quieras.',
                    textAlign: TextAlign.center,
                    style: GmText.body(color: const Color(0xCCFFFFFF))
                        .copyWith(height: 21 / 15),
                  ),
                  const SizedBox(height: 18),
                  GmCapsuleButton(
                    label: 'Ver en YouTube',
                    identifier: 'youtube-embed-open-external-button',
                    leading: const GmIcon(youtubeExternalIcon,
                        size: 16, color: Colors.white),
                    onTap: onOpen,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// «Jonay y Joana · 8 oct 2026 · 1:35» y «Casa Ángela  Guachinche moderno ·
/// La Victoria».
class _SheetFooter extends StatelessWidget {
  final YoutubeSheetInfo info;
  final String? poster;

  const _SheetFooter({required this.info, required this.poster});

  @override
  Widget build(BuildContext context) {
    final meta = youtubeCreditMeta(
      publishedAtIso: info.publishedAtIso,
      durationSeconds: info.durationSeconds,
    );
    final place = info.placeName;
    final placeMeta = info.placeMeta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _CreditAvatar(poster: poster),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(children: [
                  const TextSpan(
                    text: 'Jonay y Joana',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  if (meta.isNotEmpty) TextSpan(text: meta),
                ]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GmText.meta(color: _white72),
              ),
            ),
          ],
        ),
        if (place != null) ...[
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(children: [
              TextSpan(text: place),
              if (placeMeta != null) ...[
                const WidgetSpan(child: SizedBox(width: 8)),
                TextSpan(
                  text: placeMeta,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                    color: _white72,
                  ),
                ),
              ],
            ]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GmText.poster(color: Colors.white),
          ),
        ],
      ],
    );
  }
}

/// Avatar de Jonay y Joana (28): anillo Atlántico → oro, hueco negro de 2 y
/// un fotograma del vídeo. Versión ligera de `FichaStoryAvatar` (la de la
/// ficha arrastra todo su grafo de imports a este componente).
class _CreditAvatar extends StatelessWidget {
  final String? poster;
  const _CreditAvatar({required this.poster});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 28,
        height: 28,
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0085C4), GmColors.gold],
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration:
              const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
          child: ClipOval(child: GmPhoto(poster, decodeWidth: 72)),
        ),
      ),
    );
  }
}
