import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_shapes.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/model/Visit.dart' as vm;
import 'package:maps_launcher/maps_launcher.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

/// Reproductor vertical a pantalla completa estilo reel (TikTok/Reels) adaptado
/// a DCC: vídeo a `BoxFit.cover` con autoplay+loop, overlay con el handle de la
/// marca + descripción, rail de acciones a la derecha (me gusta · guardar ·
/// cómo llegar · reserva ya), y la tarjeta del local abajo. Se cierra con el
/// botón de atrás o **arrastrando hacia abajo** (como el visor de fotos).
Future<void> showVerticalVideo(
  BuildContext context, {
  required String url,
  required vm.Visit visit,
  VoidCallback? onOpenRestaurant,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => VerticalVideoPlayer(
        url: url,
        visit: visit,
        onOpenRestaurant: onOpenRestaurant,
      ),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    ),
  );
}

class VerticalVideoPlayer extends StatefulWidget {
  final String url;
  final vm.Visit visit;
  final VoidCallback? onOpenRestaurant;

  const VerticalVideoPlayer({
    super.key,
    required this.url,
    required this.visit,
    this.onOpenRestaurant,
  });

  @override
  State<VerticalVideoPlayer> createState() => _VerticalVideoPlayerState();
}

class _VerticalVideoPlayerState extends State<VerticalVideoPlayer>
    with SingleTickerProviderStateMixin {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _error = false;
  bool _liked = false;
  bool _saved = false;

  // Arrastrar-para-cerrar (mismo patrón que el visor de fotos de plato).
  late final AnimationController _resetCtrl;
  Animation<double>? _resetAnim;
  double _dragDy = 0;
  static const double _dismissDistance = 140;
  static const double _dismissVelocity = 700;

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
    _resetCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        if (_resetAnim != null) setState(() => _dragDy = _resetAnim!.value);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    _resetCtrl.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (!_ready) return;
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  void _onDragUpdate(DragUpdateDetails d) {
    _resetCtrl.stop();
    setState(() => _dragDy += d.delta.dy);
  }

  void _onDragEnd(DragEndDetails d) {
    final v = d.velocity.pixelsPerSecond.dy;
    final dismiss = _dragDy.abs() > _dismissDistance ||
        (v.abs() > _dismissVelocity && _dragDy.abs() > 24);
    if (dismiss) {
      Navigator.of(context).maybePop();
    } else {
      _resetAnim = Tween<double>(begin: _dragDy, end: 0).animate(
        CurvedAnimation(parent: _resetCtrl, curve: Curves.easeOut),
      );
      _resetCtrl.forward(from: 0);
    }
  }

  // ── Acciones ──────────────────────────────────────────────────────────────

  Future<void> _directions() async {
    HapticFeedback.selectionClick();
    final v = widget.visit;
    final mapsUrl = v.googleMapsUrl;
    if (mapsUrl != null && mapsUrl.isNotEmpty) {
      final uri = Uri.parse(mapsUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    final r = v.restaurant;
    final name = v.name ?? r?.nombre ?? '';
    if (r != null && r.lat != 0 && r.lon != 0) {
      MapsLauncher.launchCoordinates(r.lat, r.lon, name);
    } else if (name.isNotEmpty) {
      MapsLauncher.launchQuery(name);
    }
  }

  String? get _phone {
    final p = widget.visit.phone;
    if (p != null && p.trim().isNotEmpty) return p;
    final rp = widget.visit.restaurant?.telefono;
    if (rp != null && rp.trim().isNotEmpty) return rp;
    return null;
  }

  Future<void> _call() async {
    final raw = _phone;
    if (raw == null) return;
    HapticFeedback.selectionClick();
    final sanitized = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: sanitized);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openRestaurant() {
    HapticFeedback.selectionClick();
    if (widget.onOpenRestaurant != null) {
      Navigator.of(context).maybePop();
      widget.onOpenRestaurant!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final progress = (_dragDy.abs() / 300).clamp(0.0, 1.0);
    final bgOpacity = 1.0 * (1 - progress * 0.65);
    final scale = 1 - progress * 0.12;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(color: Colors.black.withValues(alpha: bgOpacity)),
          ),
          Transform.translate(
            offset: Offset(0, _dragDy),
            child: Transform.scale(
              scale: scale,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _togglePlay,
                onVerticalDragUpdate: _onDragUpdate,
                onVerticalDragEnd: _onDragEnd,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _video(),
                    const _Scrim(),
                    if (_ready && !_controller.value.isPlaying)
                      const IgnorePointer(
                        child: Center(
                          child: Icon(Icons.play_arrow_rounded,
                              color: Colors.white70, size: 76),
                        ),
                      ),
                    _overlay(media),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _video() {
    if (_error) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No se pudo reproducir el vídeo',
              style: TextStyle(color: Colors.white70)),
        ),
      );
    }
    if (!_ready) {
      return Stack(
        fit: StackFit.expand,
        children: [
          if (widget.visit.thumbnail?.isNotEmpty == true)
            CachedNetworkImage(imageUrl: widget.visit.thumbnail!, fit: BoxFit.cover)
          else
            const ColoredBox(color: Colors.black),
          const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      );
    }
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: _controller.value.size.width,
        height: _controller.value.size.height,
        child: VideoPlayer(_controller),
      ),
    );
  }

  Widget _overlay(MediaQueryData media) {
    final v = widget.visit;
    final r = v.restaurant;
    const railW = 64.0;
    final cardBottom = media.padding.bottom + 12;

    return Stack(
      children: [
        // Atrás (arriba-izquierda).
        Positioned(
          top: media.padding.top + 8,
          left: 12,
          child: _GlassCircle(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
        // Barra de progreso (fina, sobre la tarjeta).
        if (_ready)
          Positioned(
            left: 0,
            right: 0,
            bottom: cardBottom + 92 + 10,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: VideoProgressIndicator(
                _controller,
                allowScrubbing: false,
                padding: EdgeInsets.zero,
                colors: const VideoProgressColors(
                  playedColor: AppColors.atlantico,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white12,
                ),
              ),
            ),
          ),
        // Rail (derecha): me gusta + guardar, levantado sobre los CTAs.
        Positioned(
          right: 8,
          bottom: cardBottom + 92 + 84,
          width: railW,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RailButton(
                icon: _liked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                label: 'Me gusta',
                tint: _liked ? AppColors.mojo : Colors.white,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _liked = !_liked);
                },
              ),
              const SizedBox(height: 18),
              _RailButton(
                icon: _saved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                label: 'Guardar',
                tint: _saved ? AppColors.atlanticoClaro : Colors.white,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _saved = !_saved);
                },
              ),
            ],
          ),
        ),
        // CTAs (abajo, sobre la tarjeta): cómo llegar + reserva ya.
        Positioned(
          left: 16,
          right: 16,
          bottom: cardBottom + 92 + 16,
          child: Row(
            children: [
              Expanded(
                child: _ActionPill(
                  icon: Icons.directions_rounded,
                  label: 'Cómo llegar',
                  onTap: _directions,
                ),
              ),
              if (_phone != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionPill(
                    icon: Icons.call_rounded,
                    label: 'Reserva ya',
                    filled: true,
                    onTap: _call,
                  ),
                ),
              ],
            ],
          ),
        ),
        // Tarjeta del local (abajo).
        if (r != null || (v.name?.isNotEmpty == true))
          Positioned(
            left: 12,
            right: 12,
            bottom: cardBottom,
            child: _LocalCard(
              visit: v,
              onTap: _openRestaurant,
            ),
          ),
      ],
    );
  }
}

// ── Scrim de legibilidad ────────────────────────────────────────────────────

class _Scrim extends StatelessWidget {
  const _Scrim();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.25, 0.6, 1.0],
            colors: [
              Colors.black54,
              Colors.transparent,
              Colors.black26,
              Colors.black87,
            ],
          ),
        ),
      ),
    );
  }
}

// ── Botón circular glass (atrás) ────────────────────────────────────────────

class _GlassCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassCircle({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

// ── Botón del rail (icono circular + label) ─────────────────────────────────

class _RailButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color tint;
  final VoidCallback onTap;

  const _RailButton({
    required this.icon,
    required this.label,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Icon(icon, color: tint, size: 24),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: AppTextStyles.ui(
              size: 10.5,
              color: Colors.white,
              weight: FontWeight.w600,
            ).copyWith(shadows: const [
              Shadow(color: Colors.black54, blurRadius: 4),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Pill de acción (Cómo llegar / Reserva ya) ───────────────────────────────

class _ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled
              ? AppColors.atlantico
              : Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: filled
                ? Colors.white.withValues(alpha: 0.28)
                : Colors.white.withValues(alpha: 0.28),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.ui(
                  size: 13, color: Colors.white, weight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tarjeta del local ───────────────────────────────────────────────────────

class _LocalCard extends StatelessWidget {
  final vm.Visit visit;
  final VoidCallback onTap;

  const _LocalCard({required this.visit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = visit.restaurant;
    final name = (visit.name?.isNotEmpty == true ? visit.name! : r?.nombre) ?? '';
    final photo = (r?.mainFoto.isNotEmpty == true)
        ? r!.mainFoto
        : (visit.thumbnail ?? '');
    final rating = r?.avgRating ?? 0;
    final open = r?.open ?? false;
    final location = [
      if (visit.zone?.isNotEmpty == true)
        visit.zone!
      else if (r?.municipio.isNotEmpty == true)
        r!.municipio,
      if (r?.island?.isNotEmpty == true) r!.island!,
    ].where((e) => e.trim().isNotEmpty).join(' · ');

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: SizedBox(
                width: 60,
                height: 60,
                child: photo.isNotEmpty
                    ? CachedNetworkImage(imageUrl: photo, fit: BoxFit.cover)
                    : const ColoredBox(color: Colors.white12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'EL LOCAL DEL VÍDEO',
                    style: AppTextStyles.eyebrow(
                        size: 9, color: AppColors.atlanticoClaro),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.displaySection(
                            size: 14, color: Colors.white)
                        .copyWith(letterSpacing: 0.4),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (rating > 0) ...[
                        const Icon(Icons.star_rounded,
                            size: 14, color: AppColors.sol),
                        const SizedBox(width: 3),
                        Text(
                          rating.toStringAsFixed(1),
                          style: AppTextStyles.ui(
                              size: 12,
                              color: Colors.white,
                              weight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: open ? AppColors.laurisilva : Colors.white38,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        open ? 'Abierto' : 'Cerrado',
                        style: AppTextStyles.ui(
                            size: 12,
                            color: open ? AppColors.laurisilva : Colors.white60,
                            weight: FontWeight.w600),
                      ),
                      if (location.isNotEmpty) ...[
                        Text('  ·  ',
                            style: AppTextStyles.ui(
                                size: 12, color: Colors.white38)),
                        Flexible(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.ui(
                                size: 12, color: Colors.white70),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.atlantico,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chevron_right_rounded,
                  color: Colors.white, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}
