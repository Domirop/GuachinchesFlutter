import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_shapes.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/model/Visit.dart' as vm;
import 'package:guachinches/ui/pages/restaurant_detail/widgets/dishes_section.dart';
import 'package:video_player/video_player.dart';

/// Hero de la visita estilo "reel": el vídeo (y, si las hay, las fotos de los
/// platos) montados dentro de un **marco de móvil flotante** 9:16 sobre el
/// lienzo crema, en un carrusel con dots — como un Story/Reel embebido.
///
/// - Vídeo self-host reproducible (H.264) → **autoplay muted en bucle** dentro
///   del marco, con botón de silencio; al tocar abre el reproductor a pantalla
///   completa con sonido ([onPlayVideo]).
/// - Vídeo solo-YouTube (o dentro de un sheet) → thumbnail + play → [onPlayVideo].
/// - Cada plato con foto añade una página al carrusel; al tocar abre el visor.
class VisitReelHero extends StatefulWidget {
  final vm.Visit visit;
  final bool asSheet;
  final VoidCallback onPlayVideo;

  const VisitReelHero({
    super.key,
    required this.visit,
    required this.onPlayVideo,
    this.asSheet = false,
  });

  /// ¿Hay algo que mostrar en el hero (vídeo o al menos una foto de plato)?
  static bool hasMedia(vm.Visit v) =>
      (v.videoUrl?.isNotEmpty == true) ||
      v.dishes.any((d) => d.photoUrl != null);

  @override
  State<VisitReelHero> createState() => _VisitReelHeroState();
}

class _VisitReelHeroState extends State<VisitReelHero> {
  final PageController _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  List<vm.VisitDish> get _photoDishes =>
      [for (final d in widget.visit.dishes) if (d.photoUrl != null) d];

  bool get _hasVideo => widget.visit.videoUrl?.isNotEmpty == true;

  @override
  Widget build(BuildContext context) {
    final v = widget.visit;
    final photos = _photoDishes;
    final media = MediaQuery.of(context);

    // El marco va centrado y ocupa ~62% del ancho, a 9:16, con un techo de
    // tamaño para no comerse pantallas grandes.
    final frameW = (media.size.width * 0.62).clamp(210.0, 280.0);
    final frameH = frameW * 16 / 9;

    // Hueco superior: en pantalla deja sitio a los botones flotantes; en sheet
    // basta un respiro bajo el grabber.
    final topPad =
        widget.asSheet ? 14.0 : media.padding.top + 56.0;

    final pages = <Widget>[
      if (_hasVideo)
        _VideoPage(
          visit: v,
          inline: !widget.asSheet && v.selfHostVideoPlayable,
          onTap: widget.onPlayVideo,
        ),
      for (var i = 0; i < photos.length; i++)
        _PhotoPage(
          dish: photos[i],
          heroTag: '${v.id}-reel-dish-$i',
          onTap: () => showDishPhotoViewer(
            context,
            dishes: photos,
            initialIndex: i,
            heroPrefix: '${v.id}-reel',
          ),
        ),
    ];

    return Column(
      children: [
        SizedBox(height: topPad),
        Center(
          child: _PhoneFrame(
            width: frameW,
            height: frameH,
            child: pages.length == 1
                ? pages.first
                : PageView(
                    controller: _pages,
                    onPageChanged: (i) => setState(() => _index = i),
                    children: pages,
                  ),
          ),
        ),
        if (pages.length > 1) ...[
          const SizedBox(height: 14),
          _Dots(count: pages.length, index: _index),
        ],
        const SizedBox(height: 18),
      ],
    );
  }
}

// ── Marco de móvil flotante ───────────────────────────────────────────────

class _PhoneFrame extends StatelessWidget {
  final double width;
  final double height;
  final Widget child;

  const _PhoneFrame({
    required this.width,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: brand.base,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: brand.surface, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 34,
            spreadRadius: 0,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(29),
        child: ColoredBox(color: Colors.black, child: child),
      ),
    );
  }
}

// ── Página vídeo ──────────────────────────────────────────────────────────

class _VideoPage extends StatelessWidget {
  final vm.Visit visit;

  /// true → reproductor inline (autoplay muted loop). false → thumbnail + play.
  final bool inline;
  final VoidCallback onTap;

  const _VideoPage({
    required this.visit,
    required this.inline,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (inline) {
      return _InlineReel(
        url: visit.videoFileUrl!,
        thumbnail: visit.thumbnail,
        onTapFullscreen: onTap,
      );
    }
    // Thumbnail + play (YouTube o dentro de sheet).
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _Thumb(url: visit.thumbnail),
          const _Scrim(),
          const Center(child: _PlayBadge()),
        ],
      ),
    );
  }
}

class _InlineReel extends StatefulWidget {
  final String url;
  final String? thumbnail;
  final VoidCallback onTapFullscreen;

  const _InlineReel({
    required this.url,
    required this.thumbnail,
    required this.onTapFullscreen,
  });

  @override
  State<_InlineReel> createState() => _InlineReelState();
}

class _InlineReelState extends State<_InlineReel> {
  late final VideoPlayerController _c;
  bool _ready = false;
  bool _muted = true;

  @override
  void initState() {
    super.initState();
    _c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _c.initialize().then((_) {
      if (!mounted) return;
      _c
        ..setVolume(0)
        ..setLooping(true)
        ..play();
      setState(() => _ready = true);
    }).catchError((_) {/* se queda en thumbnail */});
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _toggleMute() {
    setState(() {
      _muted = !_muted;
      _c.setVolume(_muted ? 0 : 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTapFullscreen,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail debajo hasta que el primer frame esté listo.
          _Thumb(url: widget.thumbnail),
          if (_ready)
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: _c.value.size.width,
                height: _c.value.size.height,
                child: VideoPlayer(_c),
              ),
            ),
          const _Scrim(),
          // Botón de silencio (abajo-izquierda), como en un reel.
          Positioned(
            left: 12,
            bottom: 12,
            child: _GlassPill(
              onTap: _toggleMute,
              child: Icon(
                _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Página foto de plato ────────────────────────────────────────────────────

class _PhotoPage extends StatelessWidget {
  final vm.VisitDish dish;
  final String heroTag;
  final VoidCallback onTap;

  const _PhotoPage({
    required this.dish,
    required this.heroTag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: heroTag,
            child: CachedNetworkImage(
              imageUrl: dish.photoUrl!,
              fit: BoxFit.cover,
              memCacheWidth: 720,
              placeholder: (_, __) => const ColoredBox(color: Colors.black),
              errorWidget: (_, __, ___) => const ColoredBox(
                color: Colors.black,
                child: Icon(Icons.restaurant_rounded,
                    color: Colors.white24, size: 40),
              ),
            ),
          ),
          const _Scrim(),
          // Nombre del plato sobreimpreso abajo.
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Text(
              dish.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Piezas compartidas ──────────────────────────────────────────────────────

class _Thumb extends StatelessWidget {
  final String? url;
  const _Thumb({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return const ColoredBox(color: Colors.black);
    }
    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      placeholder: (_, __) => const ColoredBox(color: Colors.black),
      errorWidget: (_, __, ___) => const ColoredBox(color: Colors.black),
    );
  }
}

class _Scrim extends StatelessWidget {
  const _Scrim();

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.55, 1.0],
            colors: [Colors.black26, Colors.transparent, Colors.black45],
          ),
        ),
      ),
    );
  }
}

class _PlayBadge extends StatelessWidget {
  const _PlayBadge();

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Icon(Icons.play_arrow_rounded,
                color: AppColors.atlantico, size: 36),
          ),
        ),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _GlassPill({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.38),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int index;
  const _Dots({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == index
                  ? AppColors.atlantico
                  : context.brand.textMuted,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
      ],
    );
  }
}
