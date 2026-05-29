import 'package:flutter/material.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/ui/components/video/youtube_embed_with_fallback.dart';
import 'package:url_launcher/url_launcher.dart';

class YoutubeEmbedSheet {
  YoutubeEmbedSheet._();

  static Future<void> show(
    BuildContext context, {
    required String videoId,
    int? startSeconds,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.black,
      builder: (sheetContext) {
        // Con aspect ratio 9/16 (Shorts) el player intenta ocupar toda la
        // altura disponible. Si no limitamos, en pantallas anchas mete
        // overflow. Cap a 80% del viewport y dejamos que el aspect ratio
        // recorte el ancho — el resultado es un Short centrado, alto y
        // estrecho, igual que en la app oficial.
        final maxHeight = MediaQuery.of(sheetContext).size.height * 0.80;
        return Semantics(
          identifier: 'youtube-embed-sheet-root',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetHeader(videoId: videoId, startSeconds: startSeconds),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: YoutubeEmbedWithFallback(
                  videoId: videoId,
                  startSeconds: startSeconds,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final String videoId;
  final int? startSeconds;

  const _SheetHeader({required this.videoId, this.startSeconds});

  Future<void> _openExternal(BuildContext context) async {
    // Path `/shorts/<id>` para que la app de YouTube los abra en formato
    // vertical (todos los IDs en este proyecto son Shorts).
    final uri = startSeconds != null
        ? Uri.parse('https://youtube.com/shorts/$videoId?t=$startSeconds')
        : Uri.parse('https://youtube.com/shorts/$videoId');
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        AppLogger.warn('youtube-embed', 'fallback_launch_failed');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo abrir el vídeo')),
          );
        }
      }
    } catch (e) {
      AppLogger.warn('youtube-embed', 'fallback_launch_failed');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el vídeo')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Semantics(
                identifier: 'youtube-embed-open-external-button',
                child: IconButton(
                  icon: const Icon(Icons.open_in_new, color: Colors.white),
                  tooltip: 'Abrir en YouTube',
                  onPressed: () => _openExternal(context),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
