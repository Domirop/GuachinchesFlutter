import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/model/Video.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/details/details_presenter.dart';
import 'package:http/http.dart' as http;
import 'package:maps_launcher/maps_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'widgets/categories_chips.dart';
import 'widgets/detail_ctas.dart';
import 'widgets/detail_hero.dart';
import 'widgets/editorial_section.dart';
import 'widgets/floating_buttons.dart';
import 'widgets/info_pills_row.dart';
import 'widgets/map_section.dart';
import 'widgets/ntk_box.dart';
import 'widgets/reviews_section.dart';
import 'widgets/section_navbar.dart';
import 'widgets/youtube_short_section.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final String id;

  const RestaurantDetailScreen({super.key, required this.id});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen>
    implements DetailView {
  late final DetailPresenter _presenter;
  final ScrollController _scrollCtrl = ScrollController();

  Restaurant? _restaurant;
  bool _loading = true;
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
    _presenter = DetailPresenter(HttpRemoteRepository(http.Client()), this);
    _presenter.getRestaurantById(widget.id);
    _presenter.getIsFav(widget.id);
    _scrollCtrl.addListener(_onScroll);
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

  Future<void> _call() async {
    final r = _restaurant;
    if (r == null || r.telefono.isEmpty) return;
    final uri = Uri.parse('tel:${r.telefono}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openWeb() async {
    final url = _restaurant?.website;
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Build ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.brand.base,
      body: Stack(
        children: [
          if (_loading || _restaurant == null)
            const _DetailSkeleton()
          else
            _buildScrollContent(),
          DetailFloatingButtons(
            isSaved: _isSaved,
            onBack: () => Navigator.pop(context),
            onToggleSave: _toggleSave,
            onShare: _share,
          ),
        ],
      ),
    );
  }

  Widget _buildScrollContent() {
    final r = _restaurant!;
    return CustomScrollView(
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
    );
  }

  Widget _buildBody(Restaurant r) {
    final hasShort = YoutubeShortSection.shouldRender(r);
    final hasEditorial = EditorialSection.shouldRender(r);
    final hasCategories = CategoriesChips.shouldRender(r);

    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          InfoPillsRow(restaurant: r),
          const SizedBox(height: 4),
          DetailCtas(
            onDirections: _openMaps,
            onCall: r.telefono.isNotEmpty ? _call : null,
            onWeb: (r.website != null && r.website!.isNotEmpty) ? _openWeb : null,
          ),
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
              child: ReviewsSection(restaurant: r),
            ),
          ),
        ],
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
        color: Colors.white.withOpacity(0.04),
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.atlantico),
          const SizedBox(height: 12),
          Text(
            'Cargando…',
            style: AppTextStyles.ui(
              size: 11,
              color: context.brand.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
