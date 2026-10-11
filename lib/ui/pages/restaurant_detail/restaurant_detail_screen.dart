import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/model/Video.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/details/details_presenter.dart';
import 'package:guachinches/data/http_client.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:share_plus/share_plus.dart';

import 'package:guachinches/ui/components/shimmer_box.dart';
import 'package:guachinches/ui/pages/visit/visit_screen.dart';
import 'package:guachinches/ui/theme/gm_favorites.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/ai_insights_section.dart';
import 'widgets/editorial_section.dart';
import 'widgets/gm_ficha_header.dart';
import 'widgets/list_appearances_section.dart';
import 'widgets/map_section.dart';
import 'widgets/ntk_box.dart';
import 'widgets/reviews_section.dart';
import 'widgets/visits_by_restaurant_section.dart';
import 'widgets/youtube_short_section.dart';

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
          for (final item in detail.items) {
            if (item.restaurantId == widget.id) {
              return ListAppearance(list: l, position: item.position);
            }
          }
          return null;
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
          AppLogger.warn('restaurant-detail', 'Error enriching visit ${v.id}: $e');
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
    Share.share('${r.nombre} en ¿Dónde Comer Canarias?');
  }

  /// Llamar: mismo saneado que la fila de teléfono de «Detalles».
  Future<void> _call() async {
    final phone = _restaurant?.telefono ?? '';
    if (phone.isEmpty) return;
    final sanitized = phone.replaceAll(RegExp(r'[^\d+]'), '');
    try {
      await launchUrl(Uri(scheme: 'tel', path: sanitized));
    } catch (_) {
      // Sin dialer disponible (p.ej. simulador): no-op.
    }
  }

  void _openVisit(Visit v) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VisitDetailPage(visitId: v.id)),
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
    if (_error) {
      return Scaffold(
        backgroundColor: gm.canvas,
        body: _DetailError(
          onBack: () => Navigator.pop(context),
          onRetry: _retryLoad,
        ),
      );
    }
    final r = _restaurant;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Barra de estado clara sobre las fotos (fondo oscuro desenfocado).
      value: (_loading || r == null || !_overPhoto)
          ? (gm.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: gm.canvas,
        body: (_loading || r == null)
            ? const _DetailSkeleton()
            : Stack(
                children: [
                  _buildScrollContent(),
                  GmTopScrim(visible: !_overPhoto),
                ],
              ),
      ),
    );
  }

  Widget _buildScrollContent() {
    final r = _restaurant!;
    return Semantics(
      identifier: 'restaurant-detail-content',
      child: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          SliverToBoxAdapter(
            child: GmFichaHeader(
              restaurant: r,
              visits: _visits,
              isSaved: _isSaved,
              onClose: () => Navigator.pop(context),
              onShare: _share,
              onDirections: _openMaps,
              onCall: r.telefono.isNotEmpty ? _call : null,
              onToggleSave: _toggleSave,
              onOpenVisit: _openVisit,
            ),
          ),
          SliverToBoxAdapter(child: _buildBody(r)),
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(Restaurant r) {
    final hasShort = YoutubeShortSection.shouldRender(r);
    final hasEditorial = EditorialSection.shouldRender(r);
    final hasVisits = VisitsByRestaurantSection.shouldRender(_visits);
    final hasAiInsights = AiInsightsSection.shouldRender(_visits);
    final hasListAppearances =
        ListAppearancesSection.shouldRender(_listAppearances);

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Detalles (horario, teléfono, dirección…).
          NTKBox(restaurant: r),
          if (hasShort) ...[
            const SizedBox(height: 28),
            YoutubeShortSection(restaurant: r),
          ],
          if (hasEditorial) ...[
            const SizedBox(height: 28),
            EditorialSection(restaurant: r),
          ],
          if (hasVisits) ...[
            const SizedBox(height: 28),
            VisitsByRestaurantSection(visits: _visits),
          ],
          if (hasAiInsights) ...[
            const SizedBox(height: 28),
            AiInsightsSection(visits: _visits),
          ],
          if (hasListAppearances) ...[
            const SizedBox(height: 28),
            ListAppearancesSection(appearances: _listAppearances),
          ],
          const _SectionDivider(),
          MapSection(restaurant: r),
          const _SectionDivider(),
          ReviewsSection(
            restaurant: r,
            onReviewSubmitted: () => _presenter.getRestaurantById(widget.id),
          ),
        ],
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onRetry;

  const _DetailError({required this.onBack, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: 'restaurant-detail-error',
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GmToolbarButton(
                icon: GmIcons.chevronLeft,
                iconSize: 20,
                light: true,
                semanticLabel: 'Volver',
                identifier: 'restaurant-detail-error-back',
                onTap: onBack,
              ),
              const Spacer(),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.cloud_off_rounded, size: 56, color: gm.label2),
                    const SizedBox(height: 18),
                    Text(
                      'No pudimos cargar el restaurante',
                      textAlign: TextAlign.center,
                      style: GmText.title2(color: gm.label),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Revisa tu conexión e inténtalo de nuevo.',
                      textAlign: TextAlign.center,
                      style: GmText.body(color: gm.label2),
                    ),
                    const SizedBox(height: 24),
                    GmCapsuleButton(
                      label: 'Reintentar',
                      identifier: 'restaurant-detail-retry-button',
                      onTap: onRetry,
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      child: Container(
        height: 1,
        color: context.brand.border,
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'restaurant-detail-skeleton',
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero
            ShimmerBox(
              width: double.infinity,
              height: 340,
              radius: 0,
            ),
            const SizedBox(height: 16),
            // Title line
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ShimmerBox(width: 200, height: 22, radius: 6),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ShimmerBox(width: 140, height: 16, radius: 6),
            ),
            const SizedBox(height: 16),
            // Chips row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  ShimmerBox(width: 72, height: 28, radius: 14),
                  const SizedBox(width: 8),
                  ShimmerBox(width: 88, height: 28, radius: 14),
                  const SizedBox(width: 8),
                  ShimmerBox(width: 64, height: 28, radius: 14),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Paragraph lines
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: double.infinity, height: 14, radius: 4),
                  const SizedBox(height: 8),
                  ShimmerBox(width: double.infinity, height: 14, radius: 4),
                  const SizedBox(height: 8),
                  ShimmerBox(width: 220, height: 14, radius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
