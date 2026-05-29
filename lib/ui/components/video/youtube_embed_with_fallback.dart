// DO NOT load youtube.com/watch?v= in a raw WebView or extract MP4 streams.
// Both violate YouTube's Terms of Service and will get the app banned.
// Always use the official IFrame Player API via youtube_player_iframe.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class YoutubeEmbedWithFallback extends StatefulWidget {
  final String videoId;
  final int? startSeconds;

  /// Default 9/16 porque en este proyecto TODOS los vídeos son Shorts. Si
  /// algún día se añaden vídeos horizontales, el caller puede pasar 16/9.
  final double aspectRatio;
  final VoidCallback? onClose;

  const YoutubeEmbedWithFallback({
    super.key,
    required this.videoId,
    this.startSeconds,
    this.aspectRatio = 9 / 16,
    this.onClose,
  });

  @override
  State<YoutubeEmbedWithFallback> createState() =>
      _YoutubeEmbedWithFallbackState();
}

class _YoutubeEmbedWithFallbackState extends State<YoutubeEmbedWithFallback> {
  YoutubePlayerController? _controller;
  StreamSubscription<YoutubePlayerValue>? _subscription;
  Timer? _timeoutTimer;
  bool _failed = false;
  bool _playbackStarted = false;

  @override
  void initState() {
    super.initState();
    if (widget.videoId.isEmpty || widget.videoId.length != 11) return;
    _initController();
  }

  void _initController() {
    try {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: widget.videoId,
        autoPlay: true,
        startSeconds: widget.startSeconds?.toDouble(),
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          strictRelatedVideos: true,
        ),
      );
      AppLogger.info('youtube-embed', 'mounted videoId=${widget.videoId}');
      _subscription = _controller!.listen(_onPlayerValue);
      _timeoutTimer = Timer(const Duration(seconds: 8), _onTimeout);
    } catch (e, st) {
      AppLogger.error('youtube-embed', e, st);
      _failed = true;
    }
  }

  void _onPlayerValue(YoutubePlayerValue value) {
    final state = value.playerState;
    AppLogger.info('youtube-embed', 'state_change state=$state');

    if (state == PlayerState.playing || state == PlayerState.buffering) {
      _playbackStarted = true;
      _timeoutTimer?.cancel();
    }

    if (value.error != YoutubeError.none && !_failed) {
      AppLogger.warn('youtube-embed', 'error code=${value.error.code}');
      AppLogger.warn('youtube-embed', 'fallback_triggered reason=error');
      if (mounted) setState(() => _failed = true);
    }
  }

  void _onTimeout() {
    if (!_playbackStarted && !_failed && mounted) {
      AppLogger.warn('youtube-embed', 'fallback_triggered reason=timeout');
      setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _subscription?.cancel();
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool invalidId =
        widget.videoId.isEmpty || widget.videoId.length != 11;

    Widget content;
    if (invalidId || _failed || _controller == null) {
      content = Semantics(
        identifier: 'youtube-embed-fallback',
        child: _FallbackBlock(
          videoId: widget.videoId,
          startSeconds: widget.startSeconds,
        ),
      );
    } else {
      content = Semantics(
        identifier: 'youtube-embed-player',
        child: YoutubePlayer(
          controller: _controller!,
          aspectRatio: widget.aspectRatio,
        ),
      );
    }

    return Semantics(
      identifier: 'youtube-embed-container',
      child: content,
    );
  }
}

class _FallbackBlock extends StatelessWidget {
  final String videoId;
  final int? startSeconds;

  const _FallbackBlock({required this.videoId, this.startSeconds});

  Future<void> _openExternal(BuildContext context) async {
    // En este proyecto los videoIds vienen de `Restaurant.shortVideoId` o
    // `Visit.youtubeVideoId` — siempre son Shorts. Usamos el path
    // `/shorts/<id>` para que la app de YouTube los abra en formato
    // vertical (no en el player horizontal de vídeos largos).
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
      } else {
        AppLogger.info('youtube-embed', 'fallback_launch_success');
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
    // Thumbnail del Short. El HQ de YouTube viene 16/9, así que con
    // `BoxFit.cover` dentro de un 9/16 recortamos lados y queda vertical.
    // Calculamos altura con `LayoutBuilder` para evitar el overflow del
    // `AspectRatio` dentro de `Column` con altura limitada: reservamos
    // ~80px para el botón "Abrir en YouTube" + spacing y dejamos el resto
    // al thumb, respetando el ratio 9/16 si cabe.
    final thumbnailUrl = 'https://img.youtube.com/vi/$videoId/0.jpg';
    return LayoutBuilder(builder: (context, constraints) {
      const reservedForButton = 80.0;
      final availableHeight =
          (constraints.maxHeight - reservedForButton).clamp(120.0, 1200.0);
      final fromWidth = constraints.maxWidth * 16 / 9;
      final thumbHeight =
          fromWidth < availableHeight ? fromWidth : availableHeight;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: thumbHeight,
            child: Center(
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: Image.network(
                  thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: AppColors.glassDark),
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        Semantics(
          identifier: 'youtube-embed-open-external-button',
          child: GestureDetector(
            onTap: () => _openExternal(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.atlantico,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Abrir en YouTube',
                style: AppTextStyles.ui(
                  size: 13,
                  weight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
    });
  }
}
