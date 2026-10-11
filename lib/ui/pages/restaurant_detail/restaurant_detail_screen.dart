import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/http_client.dart';
import 'package:guachinches/data/model/Video.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/curated_list_detail/curated_list_detail_screen.dart';
import 'package:guachinches/ui/pages/details/details_presenter.dart';
import 'package:guachinches/ui/pages/restaurant_detail/ficha_logic.dart';
import 'package:guachinches/ui/pages/restaurant_detail/restaurant_photos_gallery.dart';
import 'package:guachinches/ui/pages/visit/visit_screen.dart';
import 'package:guachinches/ui/theme/gm_favorites.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams;
import 'package:url_launcher/url_launcher.dart';

import 'widgets/ficha_sections.dart';
import 'widgets/ficha_visit_reels.dart';
import 'widgets/gm_ficha_header.dart';
import 'widgets/reviews_section.dart';

/// Ficha de negocio (rediseño iOS 27 · tableros FichaCompleta y
/// FichaSinVisitas). Con visitas: cabecera → Detalles → Editorial → Short →
/// Visitas → Resumen con IA → Fotos → Listas → Reseñas. Sin visitas:
/// Detalles → Fotos → Listas → Reseñas. Mismos datos, cargas y acciones de
/// siempre; sin barra fija abajo (las acciones van arriba).
class RestaurantDetailScreen extends StatefulWidget {
  final String id;
  final RemoteRepository? repository;

  const RestaurantDetailScreen({
    super.key,
    required this.id,
    this.repository,
  });

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen>
    implements DetailView {
  late final RemoteRepository _repo;
  late final DetailPresenter _presenter;
  final ScrollController _scrollCtrl = ScrollController();

  Restaurant? _restaurant;
  List<Visit> _visits = const [];
  List<ListAppearance> _listAppearances = const [];
  bool _loading = true;
  bool _error = false;
  bool _isSaved = false;

  /// La barra de estado va clara mientras hay foto debajo y oscura (en día)
  /// cuando la hoja de lienzo ya pasa bajo el reloj.
  bool _overPhoto = true;

  void _onScroll() {
    final top = MediaQuery.paddingOf(context).top;
    final over = _scrollCtrl.offset <
        GmFichaHeader.photosHeight - GmFichaHeader.sheetOverlap - top;
    if (over != _overPhoto) setState(() => _overPhoto = over);
  }

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? HttpRemoteRepository(sharedHttpClient);
    _presenter = DetailPresenter(_repo, this);
    _loadRestaurant();
    _loadIsFav();
    _loadVisits();
    _loadListAppearances();
    _scrollCtrl.addListener(_onScroll);
  }

  /// Favorito es secundario: si la capa local falla (DB no disponible) sólo se
  /// pierde el estado del icono, nunca debe tumbar la pantalla ni filtrar un
  /// error async sin capturar.
  Future<void> _loadIsFav() async {
    try {
      await _presenter.getIsFav(widget.id);
    } catch (e, st) {
      AppLogger.error('restaurant-detail', e, st);
    }
  }

  Future<void> _loadRestaurant() async {
    try {
      await _presenter.getRestaurantById(widget.id);
    } catch (e, st) {
      AppLogger.error('restaurant-detail', e, st);
      if (!mounted) return;
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  void _retryLoad() {
    setState(() {
      _error = false;
      _loading = true;
    });
    _loadRestaurant();
  }

  Future<void> _loadListAppearances() async {
    try {
      final lists = await _repo.getCuratedLists();
      final futures = lists.map((l) async {
        try {
          final detail = await _repo.getCuratedListById(l.id);
          final rank = fichaListRank(
              [for (final it in detail.items) (it.restaurantId, it.position)],
              widget.id);
          if (rank == null) return null;
          return ListAppearance(
              list: l, position: rank, total: detail.items.length);
        } catch (e) {
          AppLogger.warn('restaurant-detail', 'Error loading list ${l.id}: $e');
          return null;
        }
      });
      final results = await Future.wait(futures);
      final appearances = results.whereType<ListAppearance>().toList()
        ..sort((a, b) => a.position.compareTo(b.position));
      if (!mounted) return;
      setState(() => _listAppearances = appearances);
    } catch (e) {
      AppLogger.warn('restaurant-detail', 'Error loading curated lists: $e');
    }
  }

  Future<void> _loadVisits() async {
    try {
      final basics = await _repo.getVisitsByRestaurant(widget.id);
      if (!mounted) return;
      setState(() => _visits = basics);
      // Compat endpoint omite highlights/lowlights/quotes — los traemos vía
      // getVisitById en paralelo para alimentar la sección de IA.
      _enrichVisits(basics);
    } catch (e) {
      AppLogger.warn('restaurant-detail', 'Error loading visits: $e');
    }
  }

  Future<void> _enrichVisits(List<Visit> basics) async {
    final full = await Future.wait(
      basics.map((v) async {
        try {
          return await _repo.getVisitById(v.id);
        } catch (e) {
          AppLogger.warn(
              'restaurant-detail', 'Error enriching visit ${v.id}: $e');
          return v;
        }
      }),
    );
    if (!mounted) return;
    setState(() => _visits = full);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── DetailView ────────────────────────────────────

  @override
  void setRestaurant(Restaurant restaurant) {
    if (!mounted) return;
    // Un id inexistente devuelve un registro vacío (sin id ni nombre): eso es
    // un error de carga, no una ficha en blanco.
    if (restaurant.id.isEmpty && restaurant.nombre.trim().isEmpty) {
      AppLogger.warn('restaurant-detail', 'ficha vacía para ${widget.id}');
      setState(() {
        _error = true;
        _loading = false;
      });
      return;
    }
    setState(() {
      _restaurant = restaurant;
      _loading = false;
    });
  }

  @override
  void setVisit(Visit? visit) {}

  @override
  void setRestaurantVideos(List<Video> videos) {}

  @override
  void setFav(bool correct) {
    if (mounted) setState(() => _isSaved = correct);
    // Los corazones de la home leen la misma tabla local: resincroniza.
    GmFavorites.instance.ensureLoaded(force: true);
  }

  @override
  void setUserId(String id) {}

  @override
  void refreshScreen() {
    if (mounted) setState(() {});
  }

  @override
  void updateVideos() {}

  @override
  void goToLogin() {}

  // ── Acciones ──────────────────────────────────────

  void _toggleSave() => _presenter.saveFavRestaurant(widget.id);

  void _share() {
    final r = _restaurant;
    if (r == null) return;
    SharePlus.instance
        .share(ShareParams(text: '${r.nombre} en ¿Dónde Comer Canarias?'));
  }

  void _openGallery(int at) {
    final r = _restaurant;
    if (r == null) return;
    final urls = fichaPhotoUrls(r);
    if (urls.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RestaurantPhotosGallery(
          urls: urls,
          initialIndex: at.clamp(0, urls.length - 1),
          restaurantName: r.nombre,
        ),
      ),
    );
  }

  void _openList(ListAppearance a) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CuratedListDetailScreen(list: a.list)),
    );
  }

  /// Llamar: mismo saneado que la fila de teléfono de «Detalles».
  Future<void> _call() async {
    final phone = _restaurant?.telefono ?? '';
    if (phone.isEmpty) return;
    final sanitized = phone.replaceAll(RegExp(r'[^\d+]'), '');
    try {
      await launchUrl(Uri(scheme: 'tel', path: sanitized));
    } catch (e) {
      // Sin dialer disponible (p. ej. simulador).
      AppLogger.warn('restaurant-detail', 'no se pudo llamar: $e');
    }
  }

  void _openVisit(Visit v) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => VisitDetailPage(visitId: v.id, initialVisit: v)),
    );
  }

  void _openMaps() {
    final r = _restaurant;
    if (r == null) return;
    if (r.lat != 0 && r.lon != 0) {
      MapsLauncher.launchCoordinates(r.lat, r.lon, r.nombre);
    } else {
      MapsLauncher.launchQuery(r.nombre);
    }
  }

  // ── Build ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final r = _restaurant;
    final overPhoto = !_error && !_loading && r != null && _overPhoto;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Barra de estado clara sobre la foto; oscura (de día) sobre el lienzo.
      value: overPhoto
          ? SystemUiOverlayStyle.light
          : (gm.isDark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark),
      child: Scaffold(
        backgroundColor: gm.canvas,
        body: _error
            ? _DetailError(
                onBack: () => Navigator.pop(context),
                onRetry: _retryLoad,
              )
            : (_loading || r == null)
                ? _DetailSkeleton(onBack: () => Navigator.pop(context))
                : Stack(
                    children: [
                      _buildScrollContent(r),
                      GmTopScrim(visible: !_overPhoto),
                    ],
                  ),
      ),
    );
  }

  Widget _buildScrollContent(Restaurant r) {
    final visits = fichaSortedVisits(_visits);
    final hasVisits = visits.isNotEmpty;
    final photos = fichaPhotoUrls(r);
    final ai = fichaAiSummary(visits);
    final onCall = r.telefono.trim().isNotEmpty ? _call : null;

    // Orden del tablero: con visitas (FichaCompleta) o sin (FichaSinVisitas).
    final sections = <Widget>[
      FichaDetails(
        restaurant: r,
        visits: visits,
        onOpenMaps: _openMaps,
        onCall: onCall,
      ),
      if (hasVisits && FichaEditorial.shouldRender(r))
        FichaEditorial(restaurant: r),
      // El short ES la visita: una sola sección con portadas tipo Reels.
      if (hasVisits)
        FichaVisitReels(
          restaurant: r,
          visits: visits,
          onOpenVisit: _openVisit,
          teaserQuote: fichaTeaserQuote(visits.first, r.shortQuotes),
        ),
      if (hasVisits && !ai.isEmpty) FichaAiSummaryCard(summary: ai),
      if (FichaPhotos.shouldRender(photos))
        FichaPhotos(urls: photos, onOpen: _openGallery),
      if (_listAppearances.isNotEmpty)
        FichaLists(appearances: _listAppearances, onTap: _openList),
      ReviewsSection(
        restaurant: r,
        onReviewSubmitted: () => _presenter.getRestaurantById(widget.id),
      ),
    ];

    return Semantics(
      identifier: 'restaurant-detail-content',
      child: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          SliverToBoxAdapter(
            child: GmFichaHeader(
              restaurant: r,
              visits: visits,
              isSaved: _isSaved,
              onClose: () => Navigator.pop(context),
              onShare: _share,
              onDirections: _openMaps,
              onCall: onCall,
              onToggleSave: _toggleSave,
              onOpenVisit: _openVisit,
              onOpenGallery: _openGallery,
            ),
          ),
          for (final s in sections)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 32),
                child: GmRise(child: s),
              ),
            ),
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 44),
          ),
        ],
      ),
    );
  }
}

/// Error a pantalla completa (Ficha · error): volcán triste + Reintentar,
/// con el botón Cerrar arriba.
class _DetailError extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onRetry;

  const _DetailError({required this.onBack, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: 'restaurant-detail-error',
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomPaint(
                    size: const Size(110, 77),
                    painter: _SadVolcano(gm),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pudimos cargar el restaurante',
                    textAlign: TextAlign.center,
                    style: GmText.title2(color: gm.label),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Revisa tu conexión e inténtalo de nuevo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 16,
                        height: 22 / 16,
                        fontWeight: FontWeight.w400,
                        color: gm.label2),
                  ),
                  const SizedBox(height: 20),
                  GmCapsuleButton(
                    label: 'Reintentar',
                    identifier: 'restaurant-detail-retry-button',
                    onTap: onRetry,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: MediaQuery.paddingOf(context).top + 2,
            child: GmToolbarButton(
              icon: GmIcons.close,
              iconSize: 16,
              light: true,
              semanticLabel: 'Cerrar',
              identifier: 'restaurant-detail-error-back',
              onTap: onBack,
            ),
          ),
        ],
      ),
    );
  }
}

class _SadVolcano extends CustomPainter {
  final GmColors gm;
  _SadVolcano(this.gm);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 70);
    final body = Path()
      ..moveTo(6, 68)
      ..lineTo(34, 34)
      ..cubicTo(37, 30.6, 40, 29.9, 42.6, 31.8)
      ..lineTo(46.9, 34.8)
      ..cubicTo(50.1, 37, 53.5, 37, 56.7, 34.8)
      ..lineTo(61, 31.8)
      ..cubicTo(63.6, 29.9, 66.6, 30.6, 69.6, 34)
      ..lineTo(94, 68)
      ..close();
    canvas.drawPath(body, Paint()..color = gm.volcFill);
    canvas.drawPath(
        body,
        Paint()
          ..color = gm.sep
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
    final ink = Paint()..color = gm.volcInk;
    canvas.drawCircle(const Offset(42.5, 50), 2.8, ink);
    canvas.drawCircle(const Offset(57.5, 50), 2.8, ink);
    canvas.drawPath(
      Path()
        ..moveTo(45, 59)
        ..quadraticBezierTo(50, 55.2, 55, 59),
      Paint()
        ..color = gm.volcInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SadVolcano old) => old.gm != gm;
}

/// Esqueleto con la misma forma que la ficha (Ficha · cargando). Bloques
/// planos (sin barrido) y un botón Cerrar disponible mientras carga.
class _DetailSkeleton extends StatelessWidget {
  final VoidCallback onBack;
  const _DetailSkeleton({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    Widget sk(double? w, double h, [double r = 10]) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: gm.fill,
            borderRadius: BorderRadius.circular(r),
          ),
        );
    return Semantics(
      identifier: 'restaurant-detail-skeleton',
      label: 'Cargando el restaurante',
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: GmFichaHeader.photosHeight,
            child: ColoredBox(color: gm.fill),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: GmFichaHeader.photosHeight - GmFichaHeader.sheetOverlap,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: gm.canvas,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
              child: LayoutBuilder(
                builder: (_, c) {
                  final w = c.maxWidth;
                  return SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        sk(w * 0.62, 14),
                        const SizedBox(height: 12),
                        sk(w * 0.58, 34, 12),
                        const SizedBox(height: 12),
                        sk(w * 0.44, 14),
                        const SizedBox(height: 12),
                        sk(w * 0.70, 14),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            for (var i = 0; i < 4; i++) ...[
                              if (i > 0) const SizedBox(width: 8),
                              Expanded(child: sk(null, 64, 22)),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            sk(96, 32, 999),
                            const SizedBox(width: 8),
                            sk(80, 32, 999),
                            const SizedBox(width: 8),
                            sk(120, 32, 999),
                          ],
                        ),
                        const SizedBox(height: 16),
                        sk(double.infinity, 84, 24),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: MediaQuery.paddingOf(context).top + 2,
            child: GmToolbarButton(
              icon: GmIcons.close,
              iconSize: 16,
              light: true,
              semanticLabel: 'Cerrar',
              identifier: 'restaurant-detail-back-button',
              onTap: onBack,
            ),
          ),
        ],
      ),
    );
  }
}
