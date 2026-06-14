import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:video_player/video_player.dart';

/// Reproductor vertical in-app estilo TikTok para los mp4 self-host (S3,
/// backend migration 033): full-screen negro, vídeo a `BoxFit.cover`, autoplay
/// + loop, tap pausa/reanuda, barra de progreso y botón de cerrar.
Future<void> showVerticalVideo(BuildContext context, String url) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => VerticalVideoPlayer(url: url),
    ),
  );
}

class VerticalVideoPlayer extends StatefulWidget {
  final String url;
  const VerticalVideoPlayer({super.key, required this.url});

  @override
  State<VerticalVideoPlayer> createState() => _VerticalVideoPlayerState();
}

class _VerticalVideoPlayerState extends State<VerticalVideoPlayer> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller.initialize().then((_) {
      if (!mounted) return;
      _controller
        ..setLooping(true)
        ..play();
      setState(() => _ready = true);
    }).catchError((_) {
      if (mounted) setState(() => _error = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (!_ready) return;
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggle,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            if (_ready)
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              ),
            if (!_ready && !_error)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            if (_error)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No se pudo reproducir el vídeo',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            // Overlay de pausa.
            if (_ready && !_controller.value.isPlaying)
              const IgnorePointer(
                child: Center(
                  child: Icon(Icons.play_arrow_rounded,
                      color: Colors.white70, size: 76),
                ),
              ),
            // Cerrar.
            Positioned(
              top: media.padding.top + 8,
              right: 12,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ),
            // Progreso.
            if (_ready)
              Positioned(
                left: 0,
                right: 0,
                bottom: media.padding.bottom + 6,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: VideoProgressIndicator(
                    _controller,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: AppColors.atlantico,
                      bufferedColor: Colors.white24,
                      backgroundColor: Colors.white12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
