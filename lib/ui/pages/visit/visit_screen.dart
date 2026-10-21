import 'dart:math' as math;

import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/core/app_route_observer.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/location/location_cubit.dart';
import 'package:guachinches/data/cubit/location/location_state.dart';
import 'package:guachinches/data/http_client.dart';
import 'package:guachinches/data/model/Visit.dart' as vm;
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/components/video/youtube_embed_sheet.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show GmPhoto, gmDisplayName, gmDistanceLabel, gmPlaceName;
import 'package:guachinches/ui/pages/restaurant_detail/ficha_logic.dart';
import 'package:guachinches/ui/pages/restaurant_detail/restaurant_detail_screen.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/ficha_visit_reels.dart'
    show FichaLovedSeal, FichaStoryAvatar;
import 'package:guachinches/ui/pages/restaurant_detail/widgets/ntk_box.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/pros_cons_section.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/services_chips_section.dart';
import 'package:guachinches/ui/pages/visit/visit_dishes_screen.dart';
import 'package:guachinches/ui/pages/visit/visit_presenter.dart';
import 'package:guachinches/ui/theme/gm_favorites.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:guachinches/utils/restaurant_type_label.dart';
import 'package:posthog_flutter/posthog_flutter.dart' show PostHogMaskWidget;
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams;
import 'package:url_launcher/url_launcher.dart';
import 'package:guachinches/utils/open_state.dart';
import 'package:video_player/video_player.dart';

/// Visita de Jonay y Joana como Reel (rediseño iOS 27 · tablero Visita):
/// el vídeo vertical a pantalla completa sobre negro, barras de historia,
/// botones de cristal (Cerrar · Sonido · Compartir), abajo el avatar con
/// anillo, el sitio, «Les encantó» y una cita literal, la tira de platos
/// como «stickers» y una hoja que asoma («Desliza para ver los platos y el
/// sitio») con el contenido de siempre: platos, el sitio, servicios, a favor
/// / en contra y lo que necesitas saber.
///
/// Reproducción (misma lógica de siempre): mp4 self-host con códec seguro
/// (H.264/HEVC) → en la propia pantalla, en bucle y en silencio con botón de
/// sonido; si no, la miniatura con play que abre el embed de YouTube. El
/// vídeo se pausa con la hoja abierta, al apilar otra pantalla y con la app
/// en segundo plano.
class VisitDetailPage extends StatefulWidget {
  final String visitId;
  final String? title;

  /// Visita ya cargada (p. ej. desde la ficha): se pinta al instante y se
  /// refresca en segundo plano.
  final vm.Visit? initialVisit;

  const VisitDetailPage({
    Key? key,
    required this.visitId,
    this.title,
    this.initialVisit,
  }) : super(key: key);

  @override
  State<VisitDetailPage> createState() => _VisitDetailPageState();
}

class _VisitDetailPageState extends State<VisitDetailPage>
    with WidgetsBindingObserver, RouteAware
    implements VisitDetailView {
  late RemoteRepository _repo;
  late VisitDetailPresenter _presenter;

  // Sin visita ni error = cargando.
  vm.Visit? _visit;
  String? _error;

  // Vídeo en la propia pantalla.
  VideoPlayerController? _video;
  bool _videoReady = false;
  bool _videoFailed = false;
  bool _muted = true;
  bool _userPaused = false;
  bool _covered = false; // otra pantalla encima
  bool _appActive = true;

  // Hoja de platos y sitio.
  final DraggableScrollableController _sheet = DraggableScrollableController();
  final ValueNotifier<double> _extent = ValueNotifier(0);
  bool _sheetOpen = false;

  /// Scroll de dentro de la hoja (lo da el DraggableScrollableSheet).
  ScrollController? _sheetScroll;
  // Abierta deja a la vista la fila de Cerrar · Sonido · Compartir.
  static const double _sheetMax = 0.85;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _repo = HttpRemoteRepository(sharedHttpClient);
    _presenter = VisitDetailPresenter(_repo, this);
    final initial = widget.initialVisit;
    if (initial != null) {
      _visit = initial;
      _initVideo(initial);
    }
    _presenter.loadVisit(widget.visitId);
    GmFavorites.instance.ensureLoaded();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) appRouteObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appRouteObserver.unsubscribe(this);
    _video?.dispose();
    _sheet.dispose();
    _extent.dispose();
    super.dispose();
  }

  // ===== VisitDetailView =====

  @override
  void showLoading() {
    // Con la visita ya pintada, el refresco va en silencio.
    if (!mounted || _visit != null) return;
    setState(() => _error = null);
  }

  @override
  void showVisit(vm.Visit visit) {
    if (!mounted) return;
    setState(() {
      _visit = visit;
      _error = null;
    });
    _initVideo(visit);
  }

  @override
  void showError(String message) {
    if (!mounted) return;
    if (_visit != null) {
      AppLogger.warn('visit-detail',
          'no se pudo refrescar la visita ${widget.visitId}: $message');
      return;
    }
    setState(() => _error = message);
  }

  // ===== Vídeo =====

  bool get _inline => _video != null && !_videoFailed;

  void _initVideo(vm.Visit v) {
    if (_video != null || !v.selfHostVideoPlayable) return;
    final c = VideoPlayerController.networkUrl(Uri.parse(v.videoFileUrl!));
    _video = c;
    c.initialize().then((_) {
      if (!mounted) return;
      c
        ..setVolume(_muted ? 0 : 1)
        ..setLooping(true);
      setState(() => _videoReady = true);
      _syncPlayback();
    }).catchError((Object e) {
      AppLogger.warn('visit-detail', 'no se pudo cargar el mp4 de ${v.id}: $e');
      if (mounted) setState(() => _videoFailed = true);
    });
  }

  /// Reproduce solo si nadie lo impide: pausa del usuario, hoja abierta,
  /// otra pantalla encima o app en segundo plano.
  void _syncPlayback() {
    final c = _video;
    if (c == null || !c.value.isInitialized) return;
    final play = !_userPaused && !_sheetOpen && !_covered && _appActive;
    if (play && !c.value.isPlaying) c.play();
    if (!play && c.value.isPlaying) c.pause();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    _syncPlayback();
  }

  @override
  void didPushNext() {
    _covered = true;
    _syncPlayback();
  }

  @override
  void didPopNext() {
    _covered = false;
    _syncPlayback();
  }

  void _toggleMute() {
    HapticFeedback.selectionClick();
    setState(() => _muted = !_muted);
    final c = _video;
    if (c != null && c.value.isInitialized) c.setVolume(_muted ? 0 : 1);
  }

  void _onVideoTap() {
    if (_inline && _videoReady) {
      setState(() => _userPaused = !_userPaused);
      _syncPlayback();
      return;
    }
    _playElsewhere();
  }

  Future<void> _openVideoExternal() async {
    final url = _visit?.videoUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      AppLogger.warn('visit-detail', 'no se pudo abrir $url: $e');
    }
  }

  /// Sin mp4 reproducible aquí: embed de YouTube in-app; último recurso,
  /// abrir fuera.
  Future<void> _playElsewhere() {
    final v = _visit;
    if (v == null) return Future.value();
    final ytId = fichaYoutubeId(v);
    if (ytId != null) {
      return YoutubeEmbedSheet.show(context, videoId: ytId, visit: v);
    }
    return _openVideoExternal();
  }

  bool get _hasAnyVideo {
    final v = _visit;
    if (v == null) return false;
    return v.selfHostVideoPlayable ||
        fichaYoutubeId(v) != null ||
        (v.videoUrl?.isNotEmpty == true);
  }

  // ===== Acciones =====

  void _share() {
    final name =
        _visit?.name ?? _visit?.restaurant?.nombre ?? widget.title ?? 'Visita';
    SharePlus.instance
        .share(ShareParams(text: '$name en ¿Dónde Comer Canarias?'));
  }

  void _goToRestaurant() {
    final restaurantId = _visit?.restaurantId;
    if (restaurantId == null || restaurantId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantDetailScreen(id: restaurantId),
      ),
    );
  }

  void _openDishes() {
    final v = _visit;
    if (v == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VisitDishesScreen(visit: v)),
    );
  }

  // ===== Hoja =====

  /// Alto de la hoja plegada: asa + «Desliza…» + zona del indicador de inicio.
  double _peekHeight(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final label =
        MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3).scale(18);
    return 20 + label + math.max(bottom - 6, 14);
  }

  bool _onSheetExtent(DraggableScrollableNotification n) {
    _extent.value = n.extent;
    final open = n.extent > n.minExtent + 0.08;
    if (open != _sheetOpen) {
      setState(() => _sheetOpen = open);
      _syncPlayback();
    }
    return false;
  }

  double _peekFraction(BuildContext context) =>
      (_peekHeight(context) / MediaQuery.sizeOf(context).height)
          .clamp(0.05, 0.3);

  /// Pliega la hoja del todo: si dentro se había bajado (platos, tarjeta del
  /// sitio), vuelve arriba; si no, la hoja quedaba plegada pero a medias,
  /// enseñando la tarjeta en vez de «Desliza para ver los platos».
  void _collapseSheet() {
    final inner = _sheetScroll;
    if (inner != null && inner.hasClients && inner.offset > 0) {
      inner.jumpTo(0);
    }
    _animateSheet(_peekFraction(context));
  }

  void _animateSheet(double to) {
    if (!_sheet.isAttached) return;
    if (GmMotion.reduced(context)) {
      _sheet.jumpTo(to);
      return;
    }
    _sheet.animateTo(to,
        duration: const Duration(milliseconds: 420), curve: GmMotion.settle);
  }

  // ===== Build =====

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (_visit != null) {
      body = _buildReel(context, _visit!);
    } else if (_error != null) {
      body = _ErrorView(
        message: _error!,
        onRetry: () => _presenter.loadVisit(widget.visitId),
        onClose: () => Navigator.pop(context),
      );
    } else {
      body = _LoadingView(onClose: () => Navigator.pop(context));
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Barra de estado clara: siempre hay vídeo (o negro) bajo el reloj.
      value: SystemUiOverlayStyle.light,
      child: PopScope(
        // Atrás con la hoja abierta: primero se pliega.
        canPop: !_sheetOpen,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _collapseSheet();
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: body,
        ),
      ),
    );
  }

  Widget _buildReel(BuildContext context, vm.Visit v) {
    final gm = GmColors.of(context);
    final media = MediaQuery.of(context);
    final top = media.padding.top;
    final peek = _peekHeight(context);
    final peekF = _peekFraction(context);
    final dishes = fichaNamedDishes(v);
    final showPlay = !_inline || _userPaused;

    return Semantics(
      identifier: 'visit-detail-content',
      child: Stack(
        children: [
          // ① El vídeo (o su miniatura) a sangre.
          Positioned.fill(
            child: Semantics(
              identifier: 'visit-detail-video',
              button: true,
              label: _inline
                  ? (_userPaused ? 'Reanudar el vídeo' : 'Pausar el vídeo')
                  : 'Ver el vídeo',
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _hasAnyVideo ? _onVideoTap : null,
                // Fuera de las capturas del session replay: cada fotograma
                // de vídeo cambiaría la captura (lectura de GPU por
                // segundo) y se grabaría el vídeo sin máscara.
                child: PostHogMaskWidget(
                  child: _VideoLayer(
                    visit: v,
                    video: _inline && _videoReady ? _video : null,
                  ),
                ),
              ),
            ),
          ),
          // Degradado: arriba para los botones, abajo para el texto y la tira.
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x80000000),
                      Color(0x00000000),
                      Color(0x00000000),
                      Color(0x9E000000),
                      Color(0xF5000000),
                      Color(0xFF000000),
                    ],
                    stops: [0, 0.18, 0.42, 0.62, 0.8, 1],
                  ),
                ),
              ),
            ),
          ),
          // Play / pausa en el centro de la zona libre (sobre el texto).
          if (_hasAnyVideo)
            Align(
              alignment: const Alignment(0, -0.32),
              child: IgnorePointer(
                ignoring: !showPlay,
                child: AnimatedOpacity(
                  opacity: showPlay ? 1 : 0,
                  duration: Duration(
                      milliseconds: GmMotion.reduced(context) ? 0 : 180),
                  child: Semantics(
                    identifier: 'visit-detail-play-button',
                    button: true,
                    label: 'Ver el vídeo',
                    excludeSemantics: true,
                    child: GmPressable(
                      onTap: _onVideoTap,
                      pressedScale: 0.9,
                      child: const _PlayDisc(),
                    ),
                  ),
                ),
              ),
            ),
          // ② Barra de historia (una: el avance del vídeo).
          if (_inline && _videoReady)
            Positioned(
              left: 16,
              right: 16,
              top: top,
              child: IgnorePointer(
                child: Semantics(
                  label: 'Avance del vídeo',
                  child: VisitStoryProgress(progress: _video!),
                ),
              ),
            ),
          // ④ Texto de la visita + tira de platos sobre el vídeo.
          Positioned(
            left: 0,
            right: 0,
            bottom: peek + 22,
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    // Los toques sobre el texto llegan al vídeo (pausa).
                    child: IgnorePointer(
                      child: GmRise(
                        trigger: GmTrigger.mount,
                        child: _ReelCaption(visit: v, title: widget.title),
                      ),
                    ),
                  ),
                  if (dishes.isNotEmpty) ...[
                    const SizedBox(height: 30),
                    GmRise(
                      trigger: GmTrigger.mount,
                      index: 2,
                      child: _DishStrip(dishes: dishes, onTap: _openDishes),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Velo sobre el vídeo al subir la hoja (tocar → plegar).
          Positioned.fill(
            child: ValueListenableBuilder<double>(
              valueListenable: _extent,
              builder: (_, e, __) {
                final t = ((e - peekF) / (_sheetMax - peekF)).clamp(0.0, 1.0);
                if (t <= 0) return const SizedBox.shrink();
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _animateSheet(peekF),
                  child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.55 * t)),
                );
              },
            ),
          ),
          // ③ Cerrar · Sonido · Compartir (sobre el velo: Cerrar sigue a mano
          // con la hoja abierta).
          Positioned(
            left: 16,
            right: 16,
            top: top + 14,
            child: Row(
              children: [
                GmToolbarButton(
                  icon: GmIcons.close,
                  iconSize: 16,
                  semanticLabel: 'Cerrar',
                  identifier: 'visit-detail-back-button',
                  onTap: () => Navigator.maybePop(context),
                ),
                const Spacer(),
                if (_inline) ...[
                  GmToolbarButton(
                    icon: _muted ? GmIcons.muted : GmIcons.volume,
                    semanticLabel: _muted ? 'Activar sonido' : 'Silenciar',
                    identifier: 'visit-detail-mute-button',
                    onTap: _toggleMute,
                  ),
                  const SizedBox(width: 10),
                ],
                GmToolbarButton(
                  icon: GmIcons.share,
                  semanticLabel: 'Compartir',
                  identifier: 'visit-detail-share-button',
                  onTap: _share,
                ),
              ],
            ),
          ),
          // ⑤ La hoja que asoma.
          NotificationListener<DraggableScrollableNotification>(
            onNotification: _onSheetExtent,
            child: DraggableScrollableSheet(
              controller: _sheet,
              initialChildSize: peekF,
              minChildSize: peekF,
              maxChildSize: _sheetMax,
              snap: true,
              builder: (ctx, scroll) {
                _sheetScroll = scroll;
                return Semantics(
                  identifier: 'visit-detail-sheet',
                  container: true,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: gm.canvas,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(28)),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x4D000000),
                            offset: Offset(0, -8),
                            blurRadius: 24),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(28)),
                      child: CustomScrollView(
                        controller: scroll,
                        slivers: [
                          SliverToBoxAdapter(
                            child: _SheetHandle(
                              height: peek,
                              open: _sheetOpen,
                              onTap: () =>
                                  _animateSheet(_sheetOpen ? peekF : _sheetMax),
                            ),
                          ),
                          SliverToBoxAdapter(child: _sheetContent(context, v)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Con la hoja abierta el gesto de volver de iOS no puede sacar de
          // la pantalla (PopScope la retiene para plegarla): este borde
          // izquierdo recoge ese mismo gesto y pliega la hoja. Plegada, el
          // gesto del sistema vuelve atrás como siempre.
          if (_sheetOpen)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 20,
              child: _EdgeBackSwipe(onBack: _collapseSheet),
            ),
        ],
      ),
    );
  }

  /// Contenido de la hoja: lo de siempre de la visita.
  Widget _sheetContent(BuildContext context, vm.Visit v) {
    final r = v.restaurant;
    final dishes = fichaNamedDishes(v);
    final loved = fichaLovedDishCount(v);
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ① Lo que probaron.
          if (dishes.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GmSectionHeader(
                title: 'Lo que probaron',
                eyebrow: GmEyebrow(
                  text: [
                    dishes.length == 1 ? '1 plato' : '${dishes.length} platos',
                    if (loved > 0)
                      loved == 1 ? '1 les encantó' : '$loved les encantaron',
                  ].join(' · '),
                ),
                identifier: 'visit-detail-dishes-title',
                onTap: _openDishes,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SheetDishGrid(dishes: dishes, onTap: _openDishes),
            ),
          ],

          // ② El sitio (+ guardar).
          if (r != null) ...[
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _RestaurantCard(
                      restaurant: r,
                      priceRange: v.priceRange,
                      onTap: _goToRestaurant,
                    ),
                  ),
                  if (v.restaurantId.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    // Guarda el LOCAL de la visita en los guardados de siempre
                    // (misma tabla que la ficha, Favoritos y los corazones).
                    ValueListenableBuilder<Set<String>>(
                      valueListenable: GmFavorites.instance,
                      builder: (_, ids, __) => _SaveCircle(
                        saved: ids.contains(v.restaurantId),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          GmFavorites.instance.toggle(v.restaurantId);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // ③ Servicios.
          if (ServicesChipsSection.shouldRender(v.services)) ...[
            const SizedBox(height: 20),
            ServicesChipsSection(services: v.services),
          ],

          // ④ A favor / en contra.
          if (ProsConsSection.shouldRender(v.highlights, v.lowlights)) ...[
            const SizedBox(height: 20),
            ProsConsSection(pros: v.highlights, cons: v.lowlights),
          ],

          // ⑤ Lo que necesitas saber.
          if (r != null) ...[
            const SizedBox(height: 20),
            NTKBox(
                restaurant: r,
                visit: v,
                instagram: v.instagram,
                title: 'Lo que necesitas saber'),
          ],
        ],
      ),
    );
  }
}

/// «1:48» desde «00:01:48» / «1:48» / «108». `null` si no hay dato.
String? visitMinute(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final parts =
      raw.trim().split(':').map((p) => int.tryParse(p.trim()) ?? 0).toList();
  int secs;
  if (parts.length == 1) {
    secs = parts[0];
  } else if (parts.length == 2) {
    secs = parts[0] * 60 + parts[1];
  } else {
    secs = parts[0] * 3600 + parts[1] * 60 + parts[2];
  }
  if (secs <= 0) return null;
  return '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';
}

/// La cita del reel (la mejor literal) y su pie factual: solo el minuto si
/// el backend lo da; si no, sin pie.
({String text, String? caption})? visitReelQuote(vm.Visit v) {
  final text = fichaReelQuote(v);
  if (text == null) return null;
  String? minute;
  for (final q in v.quotes) {
    if (fichaQuote(q.text) == text) {
      minute = visitMinute(q.timestamp);
      break;
    }
  }
  return (text: text, caption: minute == null ? null : 'Minuto $minute');
}

/// Vídeo a sangre (9:16 recortado a la pantalla) sobre su miniatura.
class _VideoLayer extends StatelessWidget {
  final vm.Visit visit;
  final VideoPlayerController? video;
  const _VideoLayer({required this.visit, this.video});

  @override
  Widget build(BuildContext context) {
    final thumbs = fichaReelThumbs(visit);
    final c = video;
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),
        GmPhoto(
          thumbs.firstOrNull,
          decodeWidth: 1080,
          fallbacks: thumbs.skip(1).toList(),
        ),
        if (c != null)
          FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: c.value.size.width,
              height: c.value.size.height,
              child: VideoPlayer(c),
            ),
          ),
      ],
    );
  }
}

class _PlayDisc extends StatelessWidget {
  const _PlayDisc();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: GmGlass(
        borderRadius: BorderRadius.circular(36),
        tint: const Color(0x4D1C1612),
        edge: const Color(0x80FFFFFF),
        edgeWidth: 0.5,
        blur: 20,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: GmIcon(GmIcons.play, size: 26, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Barra de historia: un solo tramo con el avance del vídeo (no hay una
/// línea de tiempo por platos que repartir en tramos).
class VisitStoryProgress extends StatelessWidget {
  final ValueListenable<VideoPlayerValue> progress;
  const VisitStoryProgress({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: progress,
      builder: (_, val, __) {
        final d = val.duration.inMilliseconds;
        final p = d <= 0 ? 0.0 : val.position.inMilliseconds / d;
        return Container(
          height: 3,
          decoration: BoxDecoration(
            color: const Color(0x59FFFFFF),
            borderRadius: BorderRadius.circular(2),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: p.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Borde izquierdo que reconoce el gesto de volver (arrastre hacia la
/// derecha) y llama a [onBack].
class _EdgeBackSwipe extends StatefulWidget {
  final VoidCallback onBack;
  const _EdgeBackSwipe({required this.onBack});

  @override
  State<_EdgeBackSwipe> createState() => _EdgeBackSwipeState();
}

class _EdgeBackSwipeState extends State<_EdgeBackSwipe> {
  double _dx = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) => _dx = 0,
      onHorizontalDragUpdate: (d) => _dx += d.delta.dx,
      onHorizontalDragEnd: (d) {
        if (_dx > 50 || (d.primaryVelocity ?? 0) > 400) widget.onBack();
      },
    );
  }
}

/// «Jonay y Joana · fecha · duración», el sitio 34/41, «Les encantó · tipo ·
/// municipio» y la cita literal.
class _ReelCaption extends StatelessWidget {
  final vm.Visit visit;
  final String? title;
  const _ReelCaption({required this.visit, this.title});

  static const _shadow = [Shadow(color: Color(0x66000000), blurRadius: 14)];

  @override
  Widget build(BuildContext context) {
    final v = visit;
    final r = v.restaurant;
    final name = gmDisplayName((r?.nombre.trim().isNotEmpty == true
            ? r!.nombre
            : (v.name?.trim().isNotEmpty == true ? v.name! : title)) ??
        '');
    final meta = [
      if (fichaDateFromIso(v.sortDate) != null) fichaDateFromIso(v.sortDate)!,
      if (fichaVisitDuration(v) != null) fichaVisitDuration(v)!,
    ];
    final type = restaurantTypeLabel(r?.type);
    final town = gmPlaceName(
        (r?.municipio.trim().isNotEmpty == true ? r!.municipio : v.zone) ?? '');
    final place = [if (type.isNotEmpty) type, if (town.isNotEmpty) town];
    final loved = fichaLoved(v);
    final quote = visitReelQuote(v);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            FichaStoryAvatar(
              thumbs: fichaReelThumbs(v),
              size: 32,
              photo: 26,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text.rich(
                TextSpan(
                  text: 'Jonay y Joana',
                  children: [
                    if (meta.isNotEmpty)
                      TextSpan(
                        text: '  · ${meta.join(' · ')}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Color(0xCCFFFFFF)),
                      ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GmText.sub(color: Colors.white, w: FontWeight.w600)
                    .copyWith(shadows: _shadow),
              ),
            ),
          ],
        ),
        if (name.isNotEmpty) ...[
          const SizedBox(height: 8),
          Semantics(
            header: true,
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GmText.largeTitle(color: Colors.white).copyWith(
                letterSpacing: -0.8,
                shadows: const [
                  Shadow(
                      color: Color(0x66000000),
                      blurRadius: 14,
                      offset: Offset(0, 2)),
                ],
              ),
            ),
          ),
        ],
        if (loved || place.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              if (loved) ...[
                const FichaLovedSeal(),
                const SizedBox(width: 8),
              ],
              if (place.isNotEmpty)
                Flexible(
                  child: Text(
                    place.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GmText.eyebrow(color: const Color(0xEBFFFFFF))
                        .copyWith(shadows: _shadow),
                  ),
                ),
            ],
          ),
        ],
        if (quote != null) ...[
          const SizedBox(height: 12),
          Text(
            quote.text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              height: 23 / 17,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              color: Colors.white,
              shadows: [Shadow(color: Color(0x80000000), blurRadius: 10)],
            ),
          ),
          if (quote.caption != null) ...[
            const SizedBox(height: 3),
            Text(
              quote.caption!,
              style: GmText.chip(
                  color: const Color(0xC7FFFFFF), w: FontWeight.w400),
            ),
          ],
        ],
      ],
    );
  }
}

/// Tira de platos sobre el vídeo: tarjetas de 92 en blanco translúcido con
/// foto, sello «Top» y el nombre en dos líneas (se desvanece por la derecha).
class _DishStrip extends StatelessWidget {
  final List<vm.VisitDish> dishes;
  final VoidCallback onTap;
  const _DishStrip({required this.dishes, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final nameH = MediaQuery.textScalerOf(context).scale(14) * 2;
    final h = 4 + 62 + 5 + nameH + 6;
    return Semantics(
      identifier: 'visit-detail-dish-strip',
      container: true,
      label: 'Platos de la visita',
      child: SizedBox(
        height: h + 20,
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => LinearGradient(
            colors: const [Colors.black, Colors.black, Colors.transparent],
            stops: [0, (rect.width - 28) / rect.width, 1],
          ).createShader(rect),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 18),
            clipBehavior: Clip.none,
            itemCount: dishes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final d = dishes[i];
              return GmPressable(
                onTap: onTap,
                semanticsLabel: d.name,
                child: Container(
                  width: 92,
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
                  decoration: BoxDecoration(
                    color: const Color(0xF0FFFFFF),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x4D000000),
                          offset: Offset(0, 6),
                          blurRadius: 16),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          height: 62,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              d.photoUrl != null
                                  ? GmPhoto(d.photoUrl, decodeWidth: 260)
                                  : const GmDishNoPhoto(
                                      glyphSize: 22, alwaysLight: true),
                              if (d.isTop)
                                Positioned(
                                  left: 4,
                                  top: 4,
                                  child: Container(
                                    height: 18,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xEBFFFFFF),
                                      borderRadius:
                                          BorderRadius.circular(GmRadius.pill),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GmIcon(GmIcons.star,
                                            size: 8, color: GmColors.star),
                                        const SizedBox(width: 3),
                                        const Text(
                                          'Top',
                                          style: TextStyle(
                                            fontSize: 10,
                                            height: 1.2,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1F1A14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        height: nameH,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Text(
                            d.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              height: 14 / 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F1A14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Asa de la hoja: grabber + «Desliza para ver los platos y el sitio» (con un
/// único empujoncito hacia arriba).
class _SheetHandle extends StatelessWidget {
  final double height;
  final bool open;
  final VoidCallback onTap;
  const _SheetHandle(
      {required this.height, required this.open, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: 'visit-detail-sheet-handle',
      button: true,
      label:
          open ? 'Plegar los platos y el sitio' : 'Ver los platos y el sitio',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: gm.sep,
                  borderRadius: BorderRadius.circular(GmRadius.pill),
                ),
              ),
              const SizedBox(height: 7),
              MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.3,
                child: GmOnce(
                  trigger: GmTrigger.mount,
                  duration: const Duration(milliseconds: 1100),
                  delay: const Duration(milliseconds: 1600),
                  builder: (_, t, child) => Transform.translate(
                    offset: Offset(
                        0,
                        gmKeyframes(
                            t, const [(0, 0), (0.4, -6), (0.7, 1), (1, 0)],
                            curve: GmMotion.settle)),
                    child: child,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GmIcon(open ? GmIcons.chevronDown : GmIcons.chevronUp,
                          size: 12, color: gm.label),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          open
                              ? 'Desliza para volver al vídeo'
                              : 'Desliza para ver los platos y el sitio',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GmText.sub(color: gm.label, w: FontWeight.w600)
                              .copyWith(height: 18 / 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// «Lo que probaron» dentro de la hoja: todos los platos en filas de tres.
class _SheetDishGrid extends StatelessWidget {
  final List<vm.VisitDish> dishes;
  final VoidCallback onTap;
  const _SheetDishGrid({required this.dishes, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cellH =
        6 + 84 + 8 + 4 + 6 + MediaQuery.textScalerOf(context).scale(18) * 2;
    final rows = <Widget>[];
    for (var i = 0; i < dishes.length; i += 3) {
      if (i > 0) rows.add(const SizedBox(height: 10));
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var k = 0; k < 3; k++) ...[
            if (k > 0) const SizedBox(width: 10),
            Expanded(
              child: i + k < dishes.length
                  ? SizedBox(
                      height: cellH,
                      child: GmDishCard(
                        dish: dishes[i + k],
                        cardRadius: GmRadius.tile,
                        photoRadius: 16,
                        photoHeight: 84,
                        nameLines: 2,
                        onTap: onTap,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ],
      ));
    }
    return Column(children: rows);
  }
}

/// Corazón de 52 (guardar la visita) junto a la cápsula principal.
class _SaveCircle extends StatelessWidget {
  final bool saved;
  final VoidCallback onTap;
  const _SaveCircle({required this.saved, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: 'visit-detail-save-button',
      button: true,
      toggled: saved,
      label: saved ? 'Quitar el local de guardados' : 'Guardar el local',
      excludeSemantics: true,
      child: GmPressable(
        onTap: onTap,
        pressedScale: 0.9,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: gm.card,
            shape: BoxShape.circle,
            boxShadow: gm.shadow1,
          ),
          alignment: Alignment.center,
          child: GmIcon(
            saved ? GmIcons.heartFilled : GmIcons.heart,
            size: 21,
            color: saved ? GmColors.heart : gm.label,
          ),
        ),
      ),
    );
  }
}

/// Tarjeta del local: mini mapa con chincheta, tipo con mantel, nombre y
/// «● Abierto · municipio · distancia» → ficha.
class _RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final String? priceRange;
  final VoidCallback onTap;
  const _RestaurantCard(
      {required this.restaurant, required this.onTap, this.priceRange});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final r = restaurant;
    final loc = context.watch<LocationCubit>().state;
    final dist = loc is LocationLoaded
        ? gmDistanceLabel(r, loc.latitude, loc.longitude)
        : null;
    final now = DateTime.now();
    final state = restaurantOpenState(r, now);
    // Sin horario fiable no se dice nada (nunca «Cerrado»).
    final hasSchedule = state.kind != OpenKind.unknown;
    final open = state.isOpen;
    final type = restaurantTypeLabel(r.type);
    final metaParts = <String>[
      if (r.municipio.trim().isNotEmpty) gmPlaceName(r.municipio),
      if (dist != null) dist,
      if (priceRange != null && priceRange!.trim().isNotEmpty)
        priceRange!.trim().replaceAll(r'$', '€'),
    ];

    return Semantics(
      identifier: 'visit-detail-restaurant-button',
      button: true,
      label: r.nombre,
      excludeSemantics: true,
      child: GmPressable(
        onTap: onTap,
        pressedScale: 0.98,
        child: GmCard(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: _MiniMap(gm: gm),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (type.isNotEmpty)
                        Row(
                          children: [
                            const SizedBox(
                              width: 11,
                              height: 11,
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(4)),
                                child: CustomPaint(
                                    painter: GmGinghamPainter(cell: 3.5)),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(type, style: GmText.chip(color: gm.bandInk)),
                          ],
                        ),
                      Text(
                        gmDisplayName(r.nombre),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GmText.cardTitle(color: gm.label)
                            .copyWith(letterSpacing: -0.25),
                      ),
                      Row(
                        children: [
                          if (hasSchedule) ...[
                            open
                                ? const GmOpenLabel()
                                : Text('Cerrado',
                                    style: GmText.eyebrow(color: gm.label2)),
                            if (metaParts.isNotEmpty)
                              Text(' · ', style: GmText.meta(color: gm.label2)),
                          ],
                          Flexible(
                            child: Text(
                              metaParts.join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GmText.meta(color: gm.label2),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GmIcon(GmIcons.chevronRight, size: 14, color: gm.label2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mini mapa (tablero Visita): banda crema, una calle y la chincheta que
/// cae una vez (estirar y encoger, 1,2 s).
class _MiniMap extends StatelessWidget {
  final GmColors gm;
  const _MiniMap({required this.gm});

  @override
  Widget build(BuildContext context) {
    return GmOnce(
      duration: const Duration(milliseconds: 1200),
      delay: const Duration(milliseconds: 500),
      builder: (_, t, __) => CustomPaint(painter: _MiniMapPainter(gm, t)),
    );
  }
}

class _MiniMapPainter extends CustomPainter {
  final GmColors gm;
  final double t;
  _MiniMapPainter(this.gm, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 56, size.height / 56);
    canvas.drawRect(
        const Rect.fromLTWH(0, 0, 56, 56), Paint()..color = gm.band);
    canvas.drawPath(
      Path()
        ..moveTo(-4, 38)
        ..cubicTo(10, 32, 18, 42, 30, 36)
        ..cubicTo(42, 30, 48, 22, 60, 26),
      Paint()
        ..color = gm.card
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    const ease = Cubic(0.4, 0, 0.2, 1);
    final ss = gmKeyframes(t, const [(0, 0.55), (0.4, 1.15), (0.8, 1), (1, 1)],
        curve: ease);
    canvas.save();
    canvas.translate(30, 40);
    canvas.scale(ss, ss);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 12, height: 4),
        Paint()..color = const Color(0x59003C5A));
    canvas.restore();
    final dy = gmKeyframes(
        t, const [(0, -8), (0.4, 0), (0.62, -2), (0.8, 0), (1, 0)],
        curve: ease);
    final sx = gmKeyframes(
        t, const [(0, 0.94), (0.4, 1.14), (0.62, 0.97), (0.8, 1), (1, 1)],
        curve: ease);
    final sy = gmKeyframes(
        t, const [(0, 1.08), (0.4, 0.84), (0.62, 1.04), (0.8, 1), (1, 1)],
        curve: ease);
    canvas.save();
    canvas.translate(30, 40 + dy);
    canvas.scale(sx, sy);
    canvas.translate(-30, -40);
    final pin = Path()
      ..moveTo(30, 40)
      ..cubicTo(30, 40, 21, 31.5, 21, 25)
      ..arcToPoint(const Offset(39, 25), radius: const Radius.circular(9))
      ..cubicTo(39, 31.5, 30, 40, 30, 40)
      ..close();
    canvas.drawPath(pin, Paint()..color = GmColors.atlantico);
    canvas.drawCircle(const Offset(30, 25), 3.4, Paint()..color = Colors.white);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MiniMapPainter old) =>
      old.t != t || old.gm != gm;
}

// ── Estados ───────────────────────────────────────────────────────────────────

/// Cargando: negro (como el reel) con Cerrar y un indicador.
class _LoadingView extends StatelessWidget {
  final VoidCallback onClose;
  const _LoadingView({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'visit-detail-skeleton',
      label: 'Cargando la visita',
      child: Stack(
        children: [
          const Center(
            child: CupertinoActivityIndicator(color: Colors.white, radius: 12),
          ),
          Positioned(
            left: 16,
            top: MediaQuery.paddingOf(context).top + 14,
            child: GmToolbarButton(
              icon: GmIcons.close,
              iconSize: 16,
              semanticLabel: 'Cerrar',
              identifier: 'visit-detail-back-button',
              onTap: onClose,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  const _ErrorView(
      {required this.message, required this.onRetry, required this.onClose});

  @override
  Widget build(BuildContext context) => Semantics(
        identifier: 'visit-detail-error',
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: GmText.body17(
                          color: Colors.white, w: FontWeight.w600),
                    ),
                    const SizedBox(height: 20),
                    GmCapsuleButton(
                      label: 'Reintentar',
                      identifier: 'visit-detail-retry-button',
                      onTap: onRetry,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              top: MediaQuery.paddingOf(context).top + 14,
              child: GmToolbarButton(
                icon: GmIcons.close,
                iconSize: 16,
                semanticLabel: 'Cerrar',
                identifier: 'visit-detail-back-button',
                onTap: onClose,
              ),
            ),
          ],
        ),
      );
}
