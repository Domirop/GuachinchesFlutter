import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
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

import 'package:guachinches/ui/components/bottom_cta_bar.dart';
import 'package:guachinches/ui/components/shimmer_box.dart';
import 'widgets/ai_insights_section.dart';
import 'widgets/categories_chips.dart';
import 'widgets/detail_hero.dart';
import 'widgets/editorial_section.dart';
import 'widgets/floating_buttons.dart';
import 'widgets/list_appearances_section.dart';
import 'widgets/map_section.dart';
import 'widgets/ntk_box.dart';
import 'widgets/reviews_section.dart';
import 'widgets/section_navbar.dart';
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
  int _activeSection = 0;

  static const _labels = ['Vídeo', 'Info', 'Mapa', 'Reseñas'];
  final _videoKey = GlobalKey();
  final _infoKey = GlobalKey();
  final _mapKey = GlobalKey();
  final _reviewsKey = GlobalKey();

  List<GlobalKey> get _sectionKeys =>
      [_videoKey, _infoKey, _mapKey, _reviewsKey];

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
        } catch (_) {
          return null;
        }
      });
      final results = await Future.wait(futures);
      final appearances = results.whereType<ListAppearance>().toList()
        ..sort((a, b) => a.position.compareTo(b.position));
      if (!mounted) return;
      setState(() => _listAppearances = appearances);
    } catch (_) {
      // silent — listas opcionales
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
    } catch (_) {
      // silent — visits are optional
    }
  }

  Future<void> _enrichVisits(List<Visit> basics) async {
    final full = await Future.wait(
      basics.map((v) async {
        try {
          return await _repo.getVisitById(v.id);
        } catch (_) {
          return v;
        }
      }),
    );
    if (!mounted) return;
    setState(() => _visits = full);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  double _navbarFootprint(BuildContext context) =>
      MediaQuery.of(context).padding.top + 44;

  void _onScroll() {
    if (!mounted) return;
    final threshold = _navbarFootprint(context) + 12;
    for (int i = _sectionKeys.length - 1; i >= 0; i--) {
      final ctx = _sectionKeys[i].currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final dy = box.localToGlobal(Offset.zero).dy;
      if (dy <= threshold) {
        if (_activeSection != i) setState(() => _activeSection = i);
        return;
      }
    }
    if (_activeSection != 0) setState(() => _activeSection = 0);
  }

  void _scrollToSection(int index) {
    final ctx = _sectionKeys[index].currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final viewport = RenderAbstractViewport.of(box);
    final reveal = viewport.getOffsetToReveal(box, 0.0).offset;
    final target = (reveal - _navbarFootprint(context))
        .clamp(0.0, _scrollCtrl.position.maxScrollExtent);
    _scrollCtrl.animateTo(
      target,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
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
    if (_error) {
      return Scaffold(
        backgroundColor: context.brand.base,
        body: _DetailError(
          onBack: () => Navigator.pop(context),
          onRetry: _retryLoad,
        ),
      );
    }
    final r = _restaurant;
    return Scaffold(
      backgroundColor: context.brand.base,
      body: Stack(
        children: [
          if (_loading || r == null)
            const _DetailSkeleton()
          else
            _buildScrollContent(),
          DetailFloatingButtons(
            isSaved: _isSaved,
            onBack: () => Navigator.pop(context),
            onToggleSave: _toggleSave,
            backIdentifier: 'restaurant-detail-back-button',
            saveIdentifier: 'restaurant-detail-save-button',
          ),
        ],
      ),
      bottomNavigationBar: r == null
          ? null
          : BottomCtaBar(
              onPrimary: _openMaps,
              onSecondary: _share,
              primaryIdentifier: 'restaurant-detail-maps-button',
              secondaryIdentifier: 'restaurant-detail-share-button',
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
          SliverToBoxAdapter(child: DetailHero(restaurant: r)),
          SliverPersistentHeader(
            pinned: true,
            delegate: SectionNavbarDelegate(
              labels: _labels,
              activeIndex: _activeSection,
              onTap: _scrollToSection,
            ),
          ),
          SliverToBoxAdapter(child: _buildBody(r)),
        ],
      ),
    );
  }

  Widget _buildBody(Restaurant r) {
    final hasShort = YoutubeShortSection.shouldRender(r);
    final hasEditorial = EditorialSection.shouldRender(r);
    final hasCategories = CategoriesChips.shouldRender(r);
    final hasVisits = VisitsByRestaurantSection.shouldRender(_visits);
    final hasAiInsights = AiInsightsSection.shouldRender(_visits);
    final hasListAppearances =
        ListAppearancesSection.shouldRender(_listAppearances);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Sección 1: Vídeo
          KeyedSubtree(
            key: _videoKey,
            child: hasShort
                ? Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: YoutubeShortSection(restaurant: r),
                  )
                : const SizedBox(height: 4),
          ),
          if (hasShort) const _SectionDivider(),
          // Sección 2: Info
          KeyedSubtree(
            key: _infoKey,
            child: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasEditorial) ...[
                    EditorialSection(restaurant: r),
                    const SizedBox(height: 18),
                  ],
                  NTKBox(restaurant: r),
                  if (hasCategories) ...[
                    const SizedBox(height: 14),
                    CategoriesChips(restaurant: r),
                  ],
                  if (hasVisits) ...[
                    const SizedBox(height: 22),
                    VisitsByRestaurantSection(visits: _visits),
                  ],
                  if (hasAiInsights) ...[
                    const SizedBox(height: 22),
                    AiInsightsSection(visits: _visits),
                  ],
                  if (hasListAppearances) ...[
                    const SizedBox(height: 22),
                    ListAppearancesSection(appearances: _listAppearances),
                  ],
                ],
              ),
            ),
          ),
          const _SectionDivider(),
          // Sección 3: Mapa
          KeyedSubtree(
            key: _mapKey,
            child: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: MapSection(restaurant: r),
            ),
          ),
          const _SectionDivider(),
          // Sección 4: Reseñas
          KeyedSubtree(
            key: _reviewsKey,
            child: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: ReviewsSection(
                restaurant: r,
                onReviewSubmitted: () =>
                    _presenter.getRestaurantById(widget.id),
              ),
            ),
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
    final brand = context.brand;
    return Semantics(
      identifier: 'restaurant-detail-error',
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                identifier: 'restaurant-detail-error-back',
                child: GestureDetector(
                  onTap: onBack,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: brand.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: brand.border),
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 18,
                      color: brand.textPrimary,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      size: 64,
                      color: brand.textMuted,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'No pudimos cargar el restaurante',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.displayHero(
                        size: 22,
                        color: brand.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Revisa tu conexión e inténtalo de nuevo.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.editorial(
                        size: 14,
                        color: brand.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Semantics(
                      identifier: 'restaurant-detail-retry-button',
                      child: GestureDetector(
                        onTap: onRetry,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.atlantico,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Reintentar',
                            style: AppTextStyles.ui(
                              size: 15,
                              weight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
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
