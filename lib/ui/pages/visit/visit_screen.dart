import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/location/location_cubit.dart';
import 'package:guachinches/data/cubit/location/location_state.dart';
import 'package:guachinches/data/http_client.dart';
import 'package:guachinches/data/model/Visit.dart' as vm;
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show gmDisplayName, gmDistanceLabel, gmPlaceName;
import 'package:guachinches/ui/pages/restaurant_detail/restaurant_detail_screen.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/ntk_box.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/pros_cons_section.dart';
import 'package:guachinches/ui/pages/restaurant_detail/widgets/services_chips_section.dart';
import 'package:guachinches/ui/components/shimmer_box.dart';
import 'package:guachinches/ui/components/video/vertical_video_player.dart';
import 'package:guachinches/ui/components/video/youtube_embed_sheet.dart';
import 'package:guachinches/ui/pages/visit/visit_dishes_screen.dart';
import 'package:guachinches/ui/pages/visit/visit_presenter.dart';
import 'package:guachinches/ui/pages/visit/widgets/gm_visit_hero.dart';
import 'package:guachinches/ui/theme/gm_favorites.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:guachinches/utils/open_now_utils.dart';
import 'package:guachinches/utils/restaurant_type_label.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams;
import 'package:url_launcher/url_launcher.dart';

/// Detalle de una visita de Jonay y Joana (rediseño iOS 27 · tablero Visita):
/// vídeo a sangre con la hoja encima (r30), cápsula «Ver el vídeo» + corazón,
/// la cita en la tarjeta vino, «Lo que probaron» (→ [VisitDishesScreen]) y
/// la tarjeta del local. Debajo siguen servicios, a favor/en contra y lo que
/// necesitas saber, con los mismos datos de siempre.
class VisitDetailPage extends StatefulWidget {
  final String visitId;
  final String? title;

  /// Cuando se presenta dentro de un sheet glass: fondos transparentes (para
  /// que el frost se vea entre las tarjetas) y sin botón "atrás" (el sheet se
  /// cierra arrastrando o tocando fuera).
  final bool asSheet;

  const VisitDetailPage({
    Key? key,
    required this.visitId,
    this.title,
    this.asSheet = false,
  }) : super(key: key);

  @override
  State<VisitDetailPage> createState() => _VisitDetailPageState();
}

class _VisitDetailPageState extends State<VisitDetailPage>
    implements VisitDetailView {
  late RemoteRepository _repo;
  late VisitDetailPresenter _presenter;

  vm.Visit? _visit;
  bool _loading = true;
  String? _error;

  /// Barra de estado clara sobre el vídeo; oscura (en día) cuando la hoja de
  /// lienzo pasa bajo el reloj.
  final ScrollController _scroll = ScrollController();
  bool _overVideo = true;

  void _onScroll() {
    final top = MediaQuery.paddingOf(context).top;
    final over = _scroll.offset < GmVisitHero.height - 30 - top;
    if (over != _overVideo) setState(() => _overVideo = over);
  }

  @override
  void initState() {
    super.initState();
    _repo = HttpRemoteRepository(sharedHttpClient);
    _presenter = VisitDetailPresenter(_repo, this);
    _presenter.loadVisit(widget.visitId);
    _scroll.addListener(_onScroll);
    GmFavorites.instance.ensureLoaded();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  // ===== VisitDetailView =====

  @override
  void showLoading() {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
  }

  @override
  void showVisit(vm.Visit visit) {
    if (!mounted) return;
    setState(() {
      _visit = visit;
      _loading = false;
      _error = null;
    });
  }

  @override
  void showError(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _loading = false;
    });
  }

  // ===== Acciones =====

  Future<void> _openVideoExternal() async {
    final url = _visit?.videoUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  bool get _hasVideo {
    final v = _visit;
    if (v == null) return false;
    return v.selfHostVideoPlayable ||
        (v.youtubeVideoId?.trim().isNotEmpty == true) ||
        (v.videoUrl?.isNotEmpty == true);
  }

  /// Reproduce el vídeo del hero: mp4 self-host → reproductor in-app vertical;
  /// si no, embed de YouTube in-app; último recurso, abrir externo.
  Future<void> _playVideo() {
    final v = _visit;
    if (v == null) return Future.value();
    // mp4 self-host SOLO si el códec es reproducible en iOS (H.264/HEVC); si es
    // AV1/desconocido pintaría negro → fallback a YouTube embed.
    if (v.selfHostVideoPlayable) {
      return showVerticalVideo(context,
          url: v.videoFileUrl!, visit: v, onOpenRestaurant: _goToRestaurant);
    }
    final ytId = v.youtubeVideoId;
    if (ytId != null && ytId.trim().isNotEmpty) {
      return YoutubeEmbedSheet.show(context, videoId: ytId);
    }
    return _openVideoExternal();
  }

  void _share() {
    final name =
        _visit?.name ?? _visit?.restaurant?.nombre ?? widget.title ?? 'Visita';
    SharePlus.instance.share(ShareParams(text: '$name en ¿Dónde Comer Canarias?'));
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

  // ===== Build =====

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    // En sheet, los fondos van transparentes para dejar ver el cristal.
    final bg = widget.asSheet ? Colors.transparent : gm.canvas;
    if (_loading) {
      return Scaffold(
        backgroundColor: bg,
        body: const _LoadingView(),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: bg,
        body: _ErrorView(
          message: _error!,
          onRetry: () => _presenter.loadVisit(widget.visitId),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Barra de estado clara sobre el vídeo.
      value: (widget.asSheet || !_overVideo)
          ? (gm.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: bg,
        body: Stack(
          children: [
            _buildScrollContent(context),
            if (!widget.asSheet) GmTopScrim(visible: !_overVideo),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollContent(BuildContext context) {
    final gm = GmColors.of(context);
    final v = _visit!;
    final r = v.restaurant;
    final quote = _quoteFor(v);
    final dishes = v.dishes.where((d) => d.name.trim().isNotEmpty).toList();

    final sheet = Container(
      decoration: BoxDecoration(
        color: widget.asSheet ? gm.canvas.withValues(alpha: 0.92) : gm.canvas,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x2E000000), offset: Offset(0, -10), blurRadius: 30),
        ],
      ),
      padding: EdgeInsets.only(
          top: 20, bottom: MediaQuery.paddingOf(context).bottom + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ① Ver el vídeo + guardar.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GmRise(
              trigger: GmTrigger.mount,
              index: 1,
              child: Row(
                children: [
                  Expanded(
                    child: GmCapsuleButton(
                      height: 52,
                      fontSize: 17,
                      iconSize: 15,
                      icon: _hasVideo ? GmIcons.play : null,
                      label: _hasVideo ? _playLabel(v) : 'Ver el local',
                      identifier: _hasVideo
                          ? 'visit-detail-play-button'
                          : 'visit-detail-ver-local-button',
                      onTap: _hasVideo ? _playVideo : _goToRestaurant,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Guarda el LOCAL de la visita en los guardados de siempre
                  // (misma tabla que la ficha, Favoritos y los corazones).
                  if (v.restaurantId.isNotEmpty)
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
              ),
            ),
          ),

          // ② La cita, en la tarjeta vino.
          if (quote != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GmRise(
                trigger: GmTrigger.mount,
                index: 2,
                child: _QuoteCard(text: quote.$1, caption: quote.$2),
              ),
            ),
          ],

          // ③ Lo que probaron.
          if (dishes.isNotEmpty) ...[
            const SizedBox(height: 16),
            GmRise(
              trigger: GmTrigger.mount,
              index: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GmSectionHeader(
                      title: 'Lo que probaron',
                      identifier: 'visit-detail-dishes-title',
                      onTap: _openDishes,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < 3; i++) ...[
                          if (i > 0) const SizedBox(width: 10),
                          Expanded(
                            child: i < dishes.length
                                ? SizedBox(
                                    height: 6 + 84 + 8 + 4 + 6 +
                                        MediaQuery.textScalerOf(context)
                                                .scale(18) *
                                            2,
                                    child: GmDishCard(
                                      dish: dishes[i],
                                      cardRadius: GmRadius.tile,
                                      photoRadius: 16,
                                      photoHeight: 84,
                                      nameLines: 2,
                                      onTap: _openDishes,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ④ El local.
          if (r != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GmRise(
                trigger: GmTrigger.mount,
                index: 4,
                child: _RestaurantCard(
                  restaurant: r,
                  priceRange: v.priceRange,
                  onTap: _goToRestaurant,
                ),
              ),
            ),
          ],

          // ⑤ Servicios.
          if (ServicesChipsSection.shouldRender(v.services)) ...[
            const SizedBox(height: 20),
            ServicesChipsSection(services: v.services),
          ],

          // ⑥ A favor / en contra.
          if (ProsConsSection.shouldRender(v.highlights, v.lowlights)) ...[
            const SizedBox(height: 20),
            ProsConsSection(pros: v.highlights, cons: v.lowlights),
          ],

          // ⑦ Lo que necesitas saber.
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

    return Semantics(
      identifier: 'visit-detail-content',
      child: SingleChildScrollView(
        controller: _scroll,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: GmVisitHero.height,
              child: GmVisitHero(
                visit: v,
                asSheet: widget.asSheet,
                onPlayVideo: _playVideo,
                onShare: _share,
                onClose:
                    widget.asSheet ? null : () => Navigator.pop(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: GmVisitHero.height - 30),
              child: sheet,
            ),
          ],
        ),
      ),
    );
  }

  /// «Ver el vídeo · 4:12» (duración si la conocemos).
  String _playLabel(vm.Visit v) {
    final s = v.durationSeconds;
    if (s == null || s <= 0) return 'Ver el vídeo';
    final m = s ~/ 60;
    final ss = (s % 60).toString().padLeft(2, '0');
    return 'Ver el vídeo · $m:$ss';
  }

  /// (cita, pie). Primero una cita literal del vídeo; si no hay, el resumen.
  (String, String?)? _quoteFor(vm.Visit v) {
    for (final q in v.quotes) {
      final t = q.text.trim();
      if (t.isEmpty) continue;
      final text = t.startsWith('«') || t.startsWith('"') ? t : '«$t»';
      final ts = _minute(q.timestamp);
      return (text, ts == null ? 'Jonay y Joana' : 'Jonay y Joana · minuto $ts');
    }
    final summary = _summary(v);
    if (summary != null) return (summary, null);
    return null;
  }

  /// «00:01:48» / «1:48» / «108» → «1:48».
  String? _minute(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final t = raw.trim();
    final parts = t.split(':').map((p) => int.tryParse(p) ?? 0).toList();
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

  String? _summary(vm.Visit v) {
    if (v.summary?.isNotEmpty == true) return v.summary;
    if (v.extraText?.isNotEmpty == true) return v.extraText;
    final editorial = v.restaurant?.editorialBody;
    if (editorial != null && editorial.isNotEmpty) return editorial;
    return null;
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

/// La cita de la visita en la tarjeta vino + oro, con «»» que se balancea.
class _QuoteCard extends StatelessWidget {
  final String text;
  final String? caption;
  const _QuoteCard({required this.text, this.caption});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: GmColors.wine,
        borderRadius: BorderRadius.circular(GmRadius.card),
        border: gm.isDark ? Border.all(color: gm.wineEdge) : null,
        boxShadow: const [
          BoxShadow(
            color: Color(0xB32A0E14),
            offset: Offset(0, 14),
            blurRadius: 30,
            spreadRadius: -16,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.0,
                  colors: [Color(0x38C9A96B), Color(0x00C9A96B)],
                  stops: [0, 0.6],
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 4,
            child: GmOnce(
              duration: const Duration(milliseconds: 1200),
              delay: const Duration(milliseconds: 1400),
              builder: (_, t, child) {
                final rot = gmKeyframes(t, const [
                  (0, 8), (0.3, -4), (0.6, 12), (0.85, 7), (1, 8)
                ]);
                return Transform.rotate(
                    angle: rot * math.pi / 180, child: child);
              },
              child: const Opacity(
                opacity: 0.9,
                child: Text(
                  '»',
                  style: TextStyle(
                    fontSize: 44,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: GmColors.gold,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 36),
                  child: Text(
                    text,
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      height: 24 / 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                      color: GmColors.creamHi,
                    ),
                  ),
                ),
                if (caption != null) ...[
                  const SizedBox(height: 8),
                  Text(caption!, style: GmText.eyebrow(color: GmColors.gold)),
                ],
              ],
            ),
          ),
        ],
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
    final hasSchedule = r.horariosJson != null;
    final open = hasSchedule && isOpenNow(r.horariosJson, now);
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
                            Text(type,
                                style: GmText.chip(color: gm.bandInk)),
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
    canvas.drawRect(const Rect.fromLTWH(0, 0, 56, 56), Paint()..color = gm.band);
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
    final ss = gmKeyframes(t, const [(0, 0.55), (0.4, 1.15), (0.8, 1), (1, 1)], curve: ease);
    canvas.save();
    canvas.translate(30, 40);
    canvas.scale(ss, ss);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 12, height: 4),
        Paint()..color = const Color(0x59003C5A));
    canvas.restore();
    final dy = gmKeyframes(t, const [(0, -8), (0.4, 0), (0.62, -2), (0.8, 0), (1, 0)], curve: ease);
    final sx = gmKeyframes(t, const [(0, 0.94), (0.4, 1.14), (0.62, 0.97), (0.8, 1), (1, 1)], curve: ease);
    final sy = gmKeyframes(t, const [(0, 1.08), (0.4, 0.84), (0.62, 1.04), (0.8, 1), (1, 1)], curve: ease);
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
  bool shouldRepaint(covariant _MiniMapPainter old) => old.t != t || old.gm != gm;
}

// ── Estados ───────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'visit-detail-skeleton',
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero: marco de móvil vertical (9:16) centrado.
            Builder(builder: (context) {
              final w = (MediaQuery.of(context).size.width * 0.62)
                  .clamp(210.0, 280.0);
              return Padding(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 56, bottom: 4),
                child: Center(
                  child: ShimmerBox(width: w, height: w * 16 / 9, radius: 34),
                ),
              );
            }),
            const SizedBox(height: 16),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ShimmerBox(width: 220, height: 22, radius: 6),
            ),
            const SizedBox(height: 10),
            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ShimmerBox(width: 160, height: 16, radius: 6),
            ),
            const SizedBox(height: 20),
            // Paragraph block 1
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: double.infinity, height: 14, radius: 4),
                  const SizedBox(height: 8),
                  ShimmerBox(width: double.infinity, height: 14, radius: 4),
                  const SizedBox(height: 8),
                  ShimmerBox(width: 200, height: 14, radius: 4),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Paragraph block 2
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: double.infinity, height: 14, radius: 4),
                  const SizedBox(height: 8),
                  ShimmerBox(width: 240, height: 14, radius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Semantics(
        identifier: 'visit-detail-error',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: context.brand.textMuted, size: 32),
                const SizedBox(height: 12),
                Text(message,
                    style: AppTextStyles.ui(size: 13, color: context.brand.textSecondary),
                    textAlign: TextAlign.center),
                const SizedBox(height: 20),
                Semantics(
                  identifier: 'visit-detail-retry-button',
                  button: true,
                  child: ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.atlantico,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Reintentar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
