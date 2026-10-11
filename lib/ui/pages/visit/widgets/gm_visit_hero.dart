import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/core/app_route_observer.dart';
import 'package:guachinches/data/model/Visit.dart' as vm;
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show gmDisplayName;
import 'package:guachinches/ui/pages/restaurant_detail/widgets/dishes_section.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:video_player/video_player.dart';

/// Hero de la visita (tablero Visita): el vídeo a sangre (y las fotos de los
/// platos como páginas siguientes, tipo historia), barras de progreso
/// arriba, botones de cristal (Cerrar · Sonido · Compartir) y, abajo, el
/// antetítulo «Visita · fecha · duración», el título 34/41 y «Jonay y Joana»
/// con el sello «Les encantó» si la visita fue muy positiva.
///
/// Misma lógica de reproducción que el reel anterior: mp4 self-host H.264 →
/// autoplay en silencio en bucle (pausa al apilar otra pantalla); si no,
/// miniatura. Tocar el vídeo abre el reproductor completo ([onPlayVideo]);
/// tocar una foto abre el visor de platos.
class GmVisitHero extends StatefulWidget {
  final vm.Visit visit;
  final bool asSheet;
  final Future<void> Function() onPlayVideo;
  final VoidCallback? onClose;
  final VoidCallback onShare;

  static const double height = 384;

  const GmVisitHero({
    super.key,
    required this.visit,
    required this.onPlayVideo,
    required this.onShare,
    this.onClose,
    this.asSheet = false,
  });

  static const _months = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  /// «Visita · 8 oct 2026 · 4 min».
  static String eyebrowFor(vm.Visit v) {
    final parts = <String>['Visita'];
    final d = v.sortDate == null ? null : DateTime.tryParse(v.sortDate!);
    if (d != null) {
      final l = d.toLocal();
      parts.add('${l.day} ${_months[l.month - 1]} ${l.year}');
    }
    final s = v.durationSeconds;
    if (s != null && s > 0) parts.add('${(s / 60).ceil()} min');
    return parts.join(' · ');
  }

  @override
  State<GmVisitHero> createState() => _GmVisitHeroState();
}

class _GmVisitHeroState extends State<GmVisitHero> with RouteAware {
  final PageController _pages = PageController();
  int _index = 0;
  VideoPlayerController? _video;
  bool _ready = false;
  bool _muted = true;

  vm.Visit get v => widget.visit;

  List<vm.VisitDish> get _photoDishes =>
      [for (final d in v.dishes) if (d.photoUrl != null) d];

  bool get _hasVideo =>
      v.videoUrl?.isNotEmpty == true ||
      v.youtubeVideoId?.isNotEmpty == true ||
      v.thumbnail?.isNotEmpty == true;

  bool get _inline => !widget.asSheet && v.selfHostVideoPlayable;

  @override
  void initState() {
    super.initState();
    if (_inline) {
      final c = VideoPlayerController.networkUrl(Uri.parse(v.videoFileUrl!));
      _video = c;
      c.initialize().then((_) {
        if (!mounted) return;
        c
          ..setVolume(_muted ? 0 : 1)
          ..setLooping(true)
          ..play();
        setState(() => _ready = true);
      }).catchError((_) {/* se queda en miniatura */});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) appRouteObserver.subscribe(this, route);
  }

  @override
  void didPushNext() {
    final c = _video;
    if (c != null && c.value.isInitialized) c.pause();
  }

  @override
  void didPopNext() {
    final c = _video;
    if (mounted && c != null && c.value.isInitialized && _index == 0) c.play();
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _video?.dispose();
    _pages.dispose();
    super.dispose();
  }

  void _toggleMute() {
    setState(() {
      _muted = !_muted;
      final c = _video;
      if (c != null && c.value.isInitialized) c.setVolume(_muted ? 0 : 1);
    });
  }

  Future<void> _openFullscreen() async {
    final c = _video;
    if (c != null && c.value.isInitialized) await c.pause();
    await widget.onPlayVideo();
    if (mounted && c != null && c.value.isInitialized && _index == 0) c.play();
  }

  @override
  Widget build(BuildContext context) {
    final photos = _photoDishes;
    final pages = <Widget>[
      if (_hasVideo) _videoPage(),
      for (var i = 0; i < photos.length; i++)
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => showDishPhotoViewer(
            context,
            dishes: photos,
            initialIndex: i,
            heroPrefix: '${v.id}-reel',
          ),
          child: Hero(
            tag: '${v.id}-reel-dish-$i',
            child: _Img(url: photos[i].photoUrl),
          ),
        ),
    ];
    if (pages.isEmpty) pages.add(_Img(url: v.restaurant?.mainFoto));

    final top = MediaQuery.paddingOf(context).top;
    final title = gmDisplayName(
        (v.name?.isNotEmpty == true ? v.name! : v.restaurant?.nombre) ?? '');
    final loved = v.overallSentiment == 'muy_positivo';
    final showMute = _inline && _index == 0 && _hasVideo;

    return SizedBox(
      height: GmVisitHero.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: Colors.black,
            child: pages.length == 1
                ? pages.first
                : PageView(
                    controller: _pages,
                    onPageChanged: (i) {
                      setState(() => _index = i);
                      final c = _video;
                      if (c != null && c.value.isInitialized) {
                        i == 0 ? c.play() : c.pause();
                      }
                    },
                    children: pages,
                  ),
          ),
          // Degradado: arriba para los botones, abajo para el título.
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x73000000),
                    Color(0x00000000),
                    Color(0x00000000),
                    Color(0x94000000),
                    Color(0xBD000000),
                  ],
                  stops: [0, 0.22, 0.46, 0.8, 1],
                ),
              ),
            ),
          ),
          // Barras de progreso (una por página).
          if (pages.length > 1)
            Positioned(
              left: 16,
              right: 16,
              top: (widget.asSheet ? 10 : top + 2),
              child: IgnorePointer(
                child: _Segments(
                  count: pages.length,
                  index: _index,
                  video: _index == 0 && _ready ? _video : null,
                ),
              ),
            ),
          // Botones de herramientas de cristal.
          Positioned(
            left: 16,
            right: 16,
            top: (widget.asSheet ? 22 : top + 16),
            child: Row(
              children: [
                if (widget.onClose != null)
                  GmToolbarButton(
                    icon: GmIcons.close,
                    iconSize: 16,
                    semanticLabel: 'Cerrar',
                    identifier: 'visit-detail-back-button',
                    onTap: widget.onClose!,
                  ),
                const Spacer(),
                if (showMute) ...[
                  GmToolbarButton(
                    icon: _muted ? GmIcons.muted : GmIcons.volume,
                    semanticLabel:
                        _muted ? 'Activar sonido' : 'Silenciar',
                    identifier: 'visit-detail-mute-button',
                    onTap: _toggleMute,
                  ),
                  const SizedBox(width: 10),
                ],
                GmToolbarButton(
                  icon: GmIcons.share,
                  semanticLabel: 'Compartir',
                  identifier: 'visit-detail-share-button',
                  onTap: widget.onShare,
                ),
              ],
            ),
          ),
          // Antetítulo + título + autores.
          Positioned(
            left: 20,
            right: 20,
            bottom: 44,
            child: IgnorePointer(
              child: GmRise(
                trigger: GmTrigger.mount,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Opacity(
                      opacity: 0.9,
                      child: GmEyebrow(
                        leading: GmIcon(GmIcons.youtube,
                            size: 13, color: Colors.white),
                        text: GmVisitHero.eyebrowFor(v),
                        color: Colors.white,
                      ),
                    ),
                    if (title.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GmText.largeTitle(color: Colors.white)
                            .copyWith(letterSpacing: -0.8),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          (v.creator?.trim().isNotEmpty == true)
                              ? v.creator!.trim()
                              : 'Jonay y Joana',
                          style: GmText.body(
                              color: Colors.white, w: FontWeight.w500),
                        ),
                        if (loved) ...[
                          const SizedBox(width: 8),
                          Container(
                            height: 26,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius:
                                  BorderRadius.circular(GmRadius.pill),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.45),
                                  width: 0.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GmIcon(GmIcons.thumb,
                                    size: 13, color: Colors.white),
                                const SizedBox(width: 5),
                                Text('Les encantó',
                                    style: GmText.eyebrow(color: Colors.white)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _videoPage() {
    final c = _video;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openFullscreen,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _Img(url: v.thumbnail ?? v.restaurant?.mainFoto),
          if (_ready && c != null)
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: c.value.size.width,
                height: c.value.size.height,
                child: VideoPlayer(c),
              ),
            ),
          if (!_inline)
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.24),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5), width: 0.5),
                ),
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: GmIcon(GmIcons.play, size: 24, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Img extends StatelessWidget {
  final String? url;
  const _Img({this.url});

  @override
  Widget build(BuildContext context) {
    final u = url;
    if (u == null || u.isEmpty) return const ColoredBox(color: Colors.black);
    // Miniaturas de YouTube: pedimos la maxres y caemos a la original.
    final isYtHq = u.contains('i.ytimg.com') && u.contains('/hqdefault.');
    final primary = isYtHq ? u.replaceAll('/hqdefault.', '/maxresdefault.') : u;
    Widget img(String src, Widget Function() onError) => CachedNetworkImage(
          imageUrl: src,
          fit: BoxFit.cover,
          memCacheWidth: 1080,
          placeholder: (_, __) => const ColoredBox(color: Colors.black),
          errorWidget: (_, __, ___) => onError(),
        );
    return img(
        primary,
        () => isYtHq
            ? img(u, () => const ColoredBox(color: Colors.black))
            : const ColoredBox(color: Colors.black));
  }
}

/// Barras de historia: pasadas llenas, la actual (con el progreso del vídeo
/// si se está reproduciendo) y las siguientes al 35 %.
class _Segments extends StatelessWidget {
  final int count;
  final int index;
  final VideoPlayerController? video;

  const _Segments({required this.count, required this.index, this.video});

  @override
  Widget build(BuildContext context) {
    Widget bar(double fill) => Expanded(
          child: Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(2),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: fill.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        );

    final v = video;
    return Row(
      children: [
        for (var i = 0; i < count; i++)
          if (i == index && v != null)
            Expanded(
              child: Row(children: [
                ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: v,
                  builder: (_, val, __) {
                    final d = val.duration.inMilliseconds;
                    final p = d <= 0 ? 0.0 : val.position.inMilliseconds / d;
                    return bar(p);
                  },
                ),
              ]),
            )
          else
            bar(i <= index ? 1 : 0),
      ],
    );
  }
}
