import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'dart:async';

class ShortItem {
  final String url;
  final String title;
  final String businessName;
  final String location;
  final String priceHint; // ej: "€€ · Guachinche"
  final double rating; // ej: 4.7
  final String description;

  ShortItem({
    required this.url,
    required this.title,
    required this.businessName,
    required this.location,
    required this.priceHint,
    required this.rating,
    required this.description,
  });
}

class VerifiedVisitsScreen extends StatefulWidget {
  const VerifiedVisitsScreen();

  @override
  State<VerifiedVisitsScreen> createState() => _VerifiedVisitsScreenState();
}

class _VerifiedVisitsScreenState extends State<VerifiedVisitsScreen>
    with WidgetsBindingObserver {
  final List<ShortItem> items = [
    ShortItem(
      url: 'https://www.youtube.com/shorts/bbZj8M-JMB0',
      title: 'Las mejores papas arrugadas 🤤',
      businessName: 'Guachinche La Maestra',
      location: 'La Orotava, Tenerife',
      priceHint: '€ · Guachinche',
      rating: 4.8,
      description:
      'Papas arrugadas con mojo rojo y verde, vino propio y ambiente familiar. Perfecto para ir en grupo.',
    ),
    // Añade más items si quieres
  ];

  final Map<int, YoutubePlayerController> _controllers = {};
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _muted = false;

  // Blindaje de zonas clicables del iFrame
  static const double _topShieldHeight = 90; // barra del canal
  static const double _bottomShieldHeight = 0; // pon >0 si quieres bloquear la franja inferior

  // Debounce para forzar playbackRate=1.0 al arrastrar sheet/scroll
  Timer? _rateDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _activateControllerFor(0);
    WidgetsBinding.instance.addPostFrameCallback((_) => _playOnly(0));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelRateDebounce();
    _pauseAndCloseAll();
    _pageController.dispose();
    super.dispose();
  }

  void _cancelRateDebounce() {
    _rateDebounce?.cancel();
    _rateDebounce = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      for (final c in _controllers.values) {
        try {
          c.pauseVideo();
        } catch (_) {}
      }
    }
  }

  // ====== CONTROLADORES ======

  void _activateControllerFor(int index) {
    if (_controllers.containsKey(_currentIndex) && _currentIndex != index) {
      final prev = _controllers[_currentIndex];
      try {
        prev?.pauseVideo();
        prev?.stopVideo();
        prev?.close();
      } catch (_) {}
      _controllers.remove(_currentIndex);
    }

    if (!_controllers.containsKey(index)) {
      final id = _extractYoutubeId(items[index].url);
      if (id == null) return;

      final controller = YoutubePlayerController.fromVideoId(
        videoId: id,
        autoPlay: false, // evita solapes
        params: YoutubePlayerParams(
          showControls: false,
          showFullscreenButton: true,
          loop: true,
          enableCaption: false,
          strictRelatedVideos: true,
          playsInline: true,
        ),
      );

      if (_muted) controller.mute();
      controller.setPlaybackRate(1.0);

      _controllers[index] = controller;
    }

    _currentIndex = index;
  }

  void _playOnly(int index) {
    _controllers.forEach((i, c) {
      if (i == index) return;
      try {
        c.pauseVideo();
        c.stopVideo();
      } catch (_) {}
    });

    _activateControllerFor(index);
    final current = _controllers[index];
    if (current == null) return;

    try {
      current.setPlaybackRate(1.0);
      current.playVideo();
    } catch (_) {}
  }

  void _pauseAndCloseAll() {
    for (final c in _controllers.values) {
      try {
        c.pauseVideo();
        c.stopVideo();
        c.close();
      } catch (_) {}
    }
    _controllers.clear();
  }

  // ====== NAV / CAMBIOS DE PÁGINA ======

  void _onPageChanged(int index) {
    _activateControllerFor(index);
    _playOnly(index);
    setState(() {}); // refresca overlays
  }

  // ====== UTIL ======

  String? _extractYoutubeId(String url) {
    final shorts = RegExp(r'youtube\.com/shorts/([a-zA-Z0-9_-]{6,})');
    final watch = RegExp(r'[?&]v=([a-zA-Z0-9_-]{6,})');
    final youtu = RegExp(r'youtu\.be/([a-zA-Z0-9_-]{6,})');

    final s = shorts.firstMatch(url)?[1];
    if (s != null) return s;
    final w = watch.firstMatch(url)?[1];
    if (w != null) return w;
    final y = youtu.firstMatch(url)?[1];
    if (y != null) return y;
    return null;
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    final c = _controllers[_currentIndex];
    if (c == null) return;
    _muted ? c.mute() : c.unMute();
  }

  void _forceRateOneDebounced() {
    _cancelRateDebounce();
    _rateDebounce = Timer(const Duration(milliseconds: 80), () {
      final c = _controllers[_currentIndex];
      try {
        c?.setPlaybackRate(1.0);
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _pauseAndCloseAll();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Forzamos rate 1.0 cuando hay scroll vertical del feed
            NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n is ScrollUpdateNotification) _forceRateOneDebounced();
                return false;
              },
              child: PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: items.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final controller = _controllers[index];
                  final isCurrent = index == _currentIndex && controller != null;

                  return Stack(
                    children: [
                      const Positioned.fill(child: ColoredBox(color: Colors.black)),

                      // === PLAYER EN CONTENEDOR CUADRADO CENTRADO ===
                      if (isCurrent)
                        Positioned.fill(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final side = MediaQuery.of(context).size.width;
                              return Center(
                                child: SizedBox(
                                  width: side,
                                  height: side,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: YoutubeValueBuilder(
                                      controller: controller!,
                                      builder: (context, value) {
                                        if (value.playerState == PlayerState.ended) {
                                          controller.seekTo(seconds: 0);
                                          controller.playVideo();
                                        }
                                        if (value.playbackRate != null &&
                                            value.playbackRate != 1.0) {
                                          controller.setPlaybackRate(1.0);
                                        }
                                        // Player + escudos para bloquear taps en barra canal (y opcional inferior)
                                        return Stack(
                                          children: [
                                            YoutubePlayer(
                                              key: ValueKey('yt-$index'),
                                              controller: controller,
                                              aspectRatio: 1.0,
                                            ),
                                            // 🔒 Escudo superior (barra del canal)
                                            Positioned(
                                              top: 0,
                                              left: 0,
                                              right: 0,
                                              height: _topShieldHeight,
                                              child: GestureDetector(
                                                behavior: HitTestBehavior.opaque,
                                                onTap: () {},
                                                onDoubleTap: () {},
                                                onLongPress: () {},
                                              ),
                                            ),
                                            // (Opcional) 🔒 Escudo inferior
                                            if (_bottomShieldHeight > 0)
                                              Positioned(
                                                bottom: 0,
                                                left: 0,
                                                right: 0,
                                                height: _bottomShieldHeight,
                                                child: GestureDetector(
                                                  behavior: HitTestBehavior.opaque,
                                                  onTap: () {},
                                                ),
                                              ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      // Overlay con info mínima
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 140,
                        child: _MiniInfoCard(item: items[index]),
                      ),

                      // Botonera flotante
                      Positioned(
                        right: 16,
                        bottom: 160,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _IconCircleButton(
                              icon: Icons.volume_off_rounded,
                              active: _muted,
                              onTap: _toggleMute,
                              tooltip: _muted ? 'Activar sonido' : 'Silenciar',
                            ),
                            const SizedBox(height: 14),
                            _IconCircleButton(
                              icon: Icons.favorite_border_rounded,
                              onTap: () {},
                              tooltip: 'Guardar',
                            ),
                            const SizedBox(height: 14),
                            _IconCircleButton(
                              icon: Icons.share_rounded,
                              onTap: () {},
                              tooltip: 'Compartir',
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Sheet con info del negocio + refuerzo rate 1.0 al arrastrar
            NotificationListener<DraggableScrollableNotification>(
              onNotification: (n) {
                _forceRateOneDebounced();
                return false;
              },
              child: DraggableScrollableSheet(
                initialChildSize: 0.12,
                minChildSize: 0.12,
                maxChildSize: 0.85,
                snap: true,
                builder: (context, scrollController) {
                  final item = items[_currentIndex];
                  return Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF121212),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 44,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.businessName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              _RatingChip(rating: item.rating),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${item.location} · ${item.priceHint}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.description,
                            style: const TextStyle(color: Colors.white70, height: 1.35),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _ActionPill(
                                icon: Icons.restaurant_menu_rounded,
                                label: 'Ver carta',
                                onTap: () {},
                              ),
                              _ActionPill(
                                icon: Icons.map_rounded,
                                label: 'Cómo llegar',
                                onTap: () {},
                              ),
                              _ActionPill(
                                icon: Icons.reviews_rounded,
                                label: 'Reseñas',
                                onTap: () {},
                              ),
                              _ActionPill(
                                icon: Icons.bookmark_added_rounded,
                                label: 'Guardar',
                                onTap: () {},
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: Colors.white12, height: 1),
                          const SizedBox(height: 14),
                          const Text(
                            'Experiencia verificada',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Visitado por nuestro equipo. Vídeo grabado en el local. Información contrastada con el negocio.',
                            style: TextStyle(color: Colors.white70, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Barra superior simple
            SafeArea(
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () {
                      _pauseAndCloseAll();
                      Navigator.of(context).pop();
                    },
                  ),
                  const Spacer(),
                  const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Text(
                      'Visitas verificadas',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniInfoCard extends StatelessWidget {
  final ShortItem item;
  const _MiniInfoCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${item.businessName} · ${item.location}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.15,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white),
        ],
      ),
    );
  }
}

class _IconCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final String? tooltip;

  const _IconCircleButton({
    required this.icon,
    required this.onTap,
    this.active = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final child = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.white24,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: active ? Colors.black : Colors.white,
        ),
      ),
    );

    return tooltip == null ? child : Tooltip(message: tooltip!, child: child);
  }
}

class _RatingChip extends StatelessWidget {
  final double rating;
  const _RatingChip({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionPill({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white10,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
