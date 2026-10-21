import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/core/analytics/analytics.dart';
import 'package:guachinches/core/analytics/analytics_events.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/core/remote_config/dcc_remote_config.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/new_home/curated_lists_cubit.dart';
import 'package:guachinches/data/cubit/new_home/new_home_filters_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_state.dart';
import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/data/model/Municipality.dart';
import 'package:guachinches/data/model/Types.dart';
import 'package:guachinches/data/model/curated_list.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/components/curated_hero_image.dart';
import 'package:guachinches/ui/pages/advance_search/advanced_search.dart';
import 'package:guachinches/ui/pages/advance_search/list_theme.dart';
import 'package:guachinches/ui/pages/advance_search/widgets/list_glyph.dart';
import 'package:guachinches/ui/pages/advance_search/widgets/type_grid.dart';
import 'package:guachinches/ui/pages/curated_list_detail/curated_list_detail_screen.dart';
import 'package:guachinches/ui/pages/favoritos/favoritos.dart';
import 'package:guachinches/ui/pages/listas/listas_logic.dart';
import 'package:guachinches/ui/pages/map/map_search.dart';
import 'package:guachinches/ui/pages/new_home/top_rated_ranking_screen.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show gmDisplayName;
import 'package:guachinches/ui/theme/gm_favorites.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:guachinches/utils/contextual_pool.dart';
import 'package:http/http.dart' as http;

/// Pestaña «Listas» (rediseño iOS 27 · tablero TabListas): el sitio de
/// todas las listas. De arriba abajo: cabecera con la isla, buscador de
/// guías, «Para ahora» (lista de la franja horaria, la misma que abre «Hoy»
/// en el Inicio), «Guías de Jonay y Joana», «Guardados», «Más listas»
/// (mejor valorados, abiertos ahora, cerca de ti) y «Por tipo».
///
/// Se monta como pestaña 1 y también se empuja desde la cabecera «Guías de
/// Jonay y Joana» del Inicio (entonces lleva botón de volver).
class ListasScreen extends StatefulWidget {
  /// Repositorio para tipos, categorías, municipios y el ranking. Por
  /// defecto el HTTP de siempre; los tests inyectan uno falso.
  final RemoteRepository? repository;

  /// Guardados del móvil. Por defecto [GmFavorites.instance].
  final GmFavorites? favorites;

  const ListasScreen({super.key, this.repository, this.favorites});

  @override
  State<ListasScreen> createState() => _ListasScreenState();
}

class _ListasScreenState extends State<ListasScreen> {
  /// Últimos sitios de la isla que cargó el Inicio (`AllRestaurantLoaded`).
  /// La instancia de la pestaña vive desde el arranque y lo mantiene; la que
  /// se empuja desde el Inicio lo hereda aunque el cubit ya tenga otra cosa.
  static List<Restaurant> _lastPool = const [];

  late final RemoteRepository _repo =
      widget.repository ?? HttpRemoteRepository(http.Client());
  late final GmFavorites _favorites = widget.favorites ?? GmFavorites.instance;

  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;
  String _query = '';

  /// Refresca «Para ahora» al cambiar de minuto/franja.
  Timer? _clock;
  DateTime _now = DateTime.now();

  List<Types> _types = const [];
  List<ModelCategory> _categories = const [];
  late Future<void> _browseData;
  final Map<String, Future<List<Municipality>>> _municipalities = {};

  bool _navBusy = false;
  bool _topBusy = false;

  @override
  void initState() {
    super.initState();
    final rs = context.read<RestaurantCubit>().state;
    if (rs is AllRestaurantLoaded) {
      _lastPool = rs.restaurantResponse.restaurants;
    }
    _browseData = _loadBrowseData();
    _favorites.ensureLoaded();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    // Las guías las comparte el Inicio (que las pide por isla). Solo se
    // piden aquí si nadie lo ha hecho aún.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<CuratedListsCubit>();
      if (cubit.state is CuratedListsInitial) {
        cubit.loadForIsland(context.read<NewHomeFiltersCubit>().state.islandId);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    _clock?.cancel();
    super.dispose();
  }

  // ── Datos ──────────────────────────────────────────────────────────────

  Future<void> _loadBrowseData() async {
    try {
      final types = await _repo.getAllTypes();
      if (mounted) setState(() => _types = types);
    } catch (e) {
      AppLogger.warn('listas', 'no se pudieron cargar los tipos: $e');
    }
    try {
      final cats = await _repo.getAllCategories();
      if (mounted) setState(() => _categories = cats);
    } catch (e) {
      AppLogger.warn('listas', 'no se pudieron cargar las categorías: $e');
    }
  }

  Future<List<Municipality>> _municipalitiesFor(String islandId) =>
      _municipalities.putIfAbsent(islandId, () async {
        try {
          return await _repo.getAllMunicipalitiesFiltered(islandId);
        } catch (e) {
          AppLogger.warn('listas', 'no se pudieron cargar los municipios: $e');
          _municipalities.remove(islandId);
          return const <Municipality>[];
        }
      });

  Future<void> _onRefresh() async {
    final island = context.read<NewHomeFiltersCubit>().state.islandId;
    await Future.wait([
      context.read<CuratedListsCubit>().refresh(island),
      _favorites.ensureLoaded(force: true),
    ]);
  }

  void _retryGuides() {
    final island = context.read<NewHomeFiltersCubit>().state.islandId;
    context.read<CuratedListsCubit>().loadForIsland(island);
  }

  // ── Búsqueda ───────────────────────────────────────────────────────────

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      setState(() => _query = value.trim());
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchCtrl.clear();
    setState(() => _query = '');
  }

  // ── Navegación ─────────────────────────────────────────────────────────

  void _openList(CuratedList list) {
    Analytics.I.logEvent(AnalyticsEvents.listOpened, {
      'list_id': list.id,
      'list_title': list.title,
    });
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CuratedListDetailScreen(list: list)),
    );
  }

  /// Abre la lista de resultados con los mismos datos que le pasa el Inicio.
  Future<void> _openAdvanced({
    List<Types> types = const [],
    List<ModelCategory> categories = const [],
    bool openOnly = false,
    bool fromToday = false,
  }) async {
    if (_navBusy) return;
    _navBusy = true;
    try {
      final filters = context.read<NewHomeFiltersCubit>().state;
      await _browseData;
      final munis = await _municipalitiesFor(filters.islandId);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => AdvancedSearch(
          categories: _categories,
          municipalities: munis,
          types: _types,
          islandId: filters.islandId,
          islandLabel: filters.islandLabel,
          pool: _lastPool,
          preSelectedTypes: types,
          preSelectedCategories: categories,
          preSelectedOpenOnly: openOnly,
          fromToday: fromToday,
        ),
      ));
    } finally {
      _navBusy = false;
    }
  }

  /// «Para ahora»: igual que «Hoy» del Inicio (`_openContextualSearch`):
  /// tipos y categorías de la franja, solo abiertos y tema horario.
  Future<void> _openForNow() async {
    await _browseData;
    final cfg = contextualFilterFor(DateTime.now().hour);
    await _openAdvanced(
      types: _types.where((t) => cfg.typeIds.contains(t.id)).toList(),
      categories:
          _categories.where((c) => cfg.categoryIds.contains(c.id)).toList(),
      openOnly: true,
      fromToday: true,
    );
  }

  Future<void> _openTopRated() async {
    if (_topBusy) return;
    setState(() => _topBusy = true);
    try {
      final label = context.read<NewHomeFiltersCubit>().state.islandLabel;
      // La pantalla carga el ranking completo de la isla, también «Aún con
      // pocas reseñas»; si le pasáramos la lista ya filtrada saldría vacía.
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => TopRatedRankingScreen(
          restaurants: const [],
          islandLabel: label,
        ),
      ));
    } catch (e) {
      AppLogger.warn('listas', 'no se pudo abrir el ranking: $e');
    } finally {
      if (mounted) setState(() => _topBusy = false);
    }
  }

  void _openNearby() => Navigator.of(context)
      .push(MaterialPageRoute<void>(
          builder: (_) => const MapSearch(nearby: true)));

  Future<void> _openSaved() async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const FavoritosPage()));
    await _favorites.ensureLoaded(force: true);
  }

  // ── Vista ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final filters = context.watch<NewHomeFiltersCubit>().state;
    final showGuides = DccRemoteConfig.instance.showCuratedLists;
    final searching = _query.isNotEmpty;
    final bottom = 120 + MediaQuery.paddingOf(context).bottom;

    return BlocListener<RestaurantCubit, RestaurantState>(
      listenWhen: (_, s) => s is AllRestaurantLoaded,
      listener: (_, s) {
        if (s is AllRestaurantLoaded) {
          setState(() => _lastPool = s.restaurantResponse.restaurants);
        }
      },
      child: Scaffold(
        backgroundColor: gm.canvas,
        body: SafeArea(
          bottom: false,
          child: Semantics(
            identifier: 'listas-refresh-indicator',
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: gm.accent,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: GmRise(
                      child: _Header(islandLabel: filters.islandLabel),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: GmRise(
                      index: 1,
                      child: Semantics(
                        identifier: 'listas-search-field',
                        child: _SearchCapsule(
                          controller: _searchCtrl,
                          onChanged: _onSearchChanged,
                          onClear: _clearSearch,
                        ),
                      ),
                    ),
                  ),
                  if (searching)
                    SliverToBoxAdapter(
                      child: _SearchResults(
                        query: _query,
                        islandId: filters.islandId,
                        enabled: showGuides,
                        onOpen: _openList,
                      ),
                    )
                  else ...[
                    SliverToBoxAdapter(
                      child: GmRise(
                        index: 2,
                        child: _ParaAhoraCard(now: _now, onTap: _openForNow),
                      ),
                    ),
                    if (showGuides)
                      SliverToBoxAdapter(
                        child: _GuidesSection(
                          islandId: filters.islandId,
                          onOpen: _openList,
                          onRetry: _retryGuides,
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: _SavedSection(
                        favorites: _favorites,
                        pool: _lastPool,
                        onOpen: _openSaved,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _MoreListsSection(
                        islandLabel: filters.islandLabel,
                        topBusy: _topBusy,
                        onTopRated: _openTopRated,
                        onOpenNow: () => _openAdvanced(openOnly: true),
                        onNearby: _openNearby,
                      ),
                    ),
                    if (_types.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _TypesSection(
                          types: _types,
                          pool: _lastPool,
                          onPick: (t) => _openAdvanced(types: [t]),
                        ),
                      ),
                  ],
                  SliverToBoxAdapter(child: SizedBox(height: bottom)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Cabecera y buscador
// ─────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String islandLabel;
  const _Header({required this.islandLabel});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final canPop = Navigator.of(context).canPop();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canPop) ...[
            Transform.translate(
              offset: const Offset(-4, 0),
              child: GmToolbarButton(
                icon: GmIcons.chevronLeft,
                light: true,
                semanticLabel: 'Volver',
                identifier: 'listas-back-button',
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
            const SizedBox(height: 8),
          ],
          GmEyebrow(
            leading: GmIcon(GmIcons.pin, size: 12, color: gm.accent),
            text: islandLabel,
          ),
          const SizedBox(height: 2),
          Semantics(
            header: true,
            child: Text('Listas', style: GmText.largeTitle(color: gm.label)),
          ),
          const SizedBox(height: 2),
          Text(
            'Guías de Jonay y Joana, rankings y lo que guardas.',
            style: GmText.body(color: gm.label2),
          ),
        ],
      ),
    );
  }
}

class _SearchCapsule extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchCapsule({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: gm.card,
          borderRadius: BorderRadius.circular(GmRadius.pill),
          boxShadow: gm.shadow1,
        ),
        child: Row(
          children: [
            const SizedBox(width: 15),
            GmIcon(GmIcons.search, size: 18, color: gm.label2),
            const SizedBox(width: 9),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                cursorColor: gm.accent,
                style: GmText.body17(color: gm.label),
                decoration: InputDecoration(
                  hintText: 'Lista, sitio o plato',
                  hintStyle: GmText.body17(color: gm.label2),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, v, __) {
                if (v.text.isEmpty) return const SizedBox(width: 16);
                return Semantics(
                  identifier: 'listas-search-clear',
                  label: 'Borrar búsqueda',
                  button: true,
                  child: GmPressable(
                    onTap: onClear,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: gm.fill,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child:
                              GmIcon(GmIcons.xSmall, size: 12, color: gm.label2),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Para ahora
// ─────────────────────────────────────────────────────────────────────

class _ParaAhoraCard extends StatelessWidget {
  final DateTime now;
  final VoidCallback onTap;

  const _ParaAhoraCard({required this.now, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final dark = gm.isDark;
    final k = contextThemeForHour(now.hour);
    final t = kListThemes[k]!;
    final ink = t.ink(dark);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Semantics(
        identifier: 'listas-para-ahora',
        button: true,
        child: GmPressable(
          onTap: onTap,
          pressedScale: 0.98,
          child: Container(
            constraints: const BoxConstraints(minHeight: 92),
            padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
            decoration: BoxDecoration(
              color: t.band(dark),
              borderRadius: BorderRadius.circular(GmRadius.card),
            ),
            child: Row(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: gm.card,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: gm.shadow1,
                  ),
                  alignment: Alignment.center,
                  child: ListThemeGlyph(t.glyph, size: 42, color: ink),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        listasParaAhoraEyebrow(now),
                        style: GmText.chip(color: ink, w: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.title,
                        style: GmText.poster(color: gm.label).copyWith(
                            fontSize: 19, height: 24 / 19, letterSpacing: -0.4),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        listasParaAhoraSubtitle(k, now),
                        style: GmText.sub(color: gm.label2),
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

// ─────────────────────────────────────────────────────────────────────
// Guías de Jonay y Joana
// ─────────────────────────────────────────────────────────────────────

class _GuidesSection extends StatelessWidget {
  final String islandId;
  final ValueChanged<CuratedList> onOpen;
  final VoidCallback onRetry;

  const _GuidesSection({
    required this.islandId,
    required this.onOpen,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return BlocBuilder<CuratedListsCubit, CuratedListsState>(
      builder: (_, state) {
        final Widget body;
        if (state is CuratedListsLoaded) {
          final guides = listasGuidesForIsland(state.lists, islandId);
          if (guides.isEmpty) return const SizedBox.shrink();
          body = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GmRise(
                index: 3,
                child: _FeaturedGuideCard(
                    list: guides.first, onTap: () => onOpen(guides.first)),
              ),
              for (var i = 1; i < guides.length; i++) ...[
                const SizedBox(height: GmSpace.cardGap),
                GmRise(
                  index: 3 + math.min(i, 3),
                  child: _GuideRowCard(
                      list: guides[i], onTap: () => onOpen(guides[i])),
                ),
              ],
            ],
          );
        } else if (state is CuratedListsFailure) {
          body = _GuidesError(onRetry: onRetry);
        } else {
          body = const _GuidesSkeleton();
        }
        return Semantics(
          identifier: 'listas-section-guides',
          child: Padding(
            padding: const EdgeInsets.only(top: GmSpace.section),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GmRise(
                  index: 3,
                  child: GmSectionHeader(
                    eyebrow: GmEyebrow(
                      leading: GmIcon(GmIcons.pin, size: 12, color: gm.accent),
                      text: 'Rutas elegidas a mano',
                    ),
                    title: 'Guías de Jonay y Joana',
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
                  child: body,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Foto de la guía sobre el tinte de su tema (sin foto: tinte + glifo).
class _GuidePhoto extends StatelessWidget {
  final CuratedList list;
  final ListTheme theme;
  final double glyphSize;

  const _GuidePhoto(
      {required this.list, required this.theme, required this.glyphSize});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final dark = gm.isDark;
    final hasGlyph = theme.kind != ListThemeKind.categoria;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: theme.tint(dark)),
        if (hasGlyph)
          Center(
            child: ListThemeGlyph(theme.glyph,
                size: glyphSize, color: theme.ink(dark)),
          ),
        if (list.heroAsset != null && list.heroAsset!.trim().isNotEmpty)
          CuratedHeroImage(source: list.heroAsset!),
      ],
    );
  }
}

class _FeaturedGuideCard extends StatelessWidget {
  final CuratedList list;
  final VoidCallback onTap;

  const _FeaturedGuideCard({required this.list, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final dark = gm.isDark;
    final theme = kListThemes[listasThemeForGuide(list)]!;
    final ink = theme.ink(dark);
    final chip = listasSentence(list.eyebrow);
    final eyebrow = listasFeaturedEyebrow(list);
    return Semantics(
      identifier: 'listas-card-${list.id}',
      button: true,
      child: GmPressable(
        onTap: onTap,
        pressedScale: 0.98,
        child: GmCard(
          radius: GmRadius.guide,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(GmRadius.guidePhoto),
                  child: SizedBox(
                    height: 196,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _GuidePhoto(list: list, theme: theme, glyphSize: 72),
                        if (chip.isNotEmpty)
                          Positioned(
                            left: 10,
                            top: 10,
                            right: 110,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: GmPhotoChip(label: chip),
                            ),
                          ),
                        if (list.count > 0)
                          Positioned(
                            right: 10,
                            top: 10,
                            child: GmPhotoChip(
                                label: listasCountLabel(list.count)),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (eyebrow.isNotEmpty)
                        Row(
                          children: [
                            if (theme.kind != ListThemeKind.categoria) ...[
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: theme.tint(dark),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: ListThemeGlyph(theme.glyph,
                                    size: 13, color: ink),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Flexible(
                              child: Text(
                                eyebrow,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GmText.eyebrow(color: ink),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 2),
                      Text(
                        gmDisplayName(list.title),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GmText.poster(color: gm.label),
                      ),
                      if (list.subtitle.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          list.subtitle,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GmText.body(color: gm.label2),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuideRowCard extends StatelessWidget {
  final CuratedList list;
  final VoidCallback onTap;

  const _GuideRowCard({required this.list, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final theme = kListThemes[listasThemeForGuide(list)]!;
    final eyebrow = listasRowEyebrow(list);
    return Semantics(
      identifier: 'listas-card-${list.id}',
      button: true,
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
                    width: 88,
                    height: 88,
                    child: _GuidePhoto(list: list, theme: theme, glyphSize: 40),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (eyebrow.isNotEmpty)
                        Text(
                          eyebrow,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GmText.chip(
                              color: theme.ink(gm.isDark), w: FontWeight.w700),
                        ),
                      const SizedBox(height: 1),
                      Text(
                        gmDisplayName(list.title),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GmText.guideTitle(color: gm.label),
                      ),
                      if (list.subtitle.trim().isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          list.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GmText.meta(color: gm.label2),
                        ),
                      ],
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

class _SkeletonBar extends StatelessWidget {
  final double height;
  final double widthFactor;

  const _SkeletonBar({required this.height, required this.widthFactor});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: GmColors.of(context).fill,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class _GuidesSkeleton extends StatelessWidget {
  const _GuidesSkeleton();

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    Widget row() => GmCard(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: gm.fill,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonBar(height: 11, widthFactor: 0.38),
                      SizedBox(height: 8),
                      _SkeletonBar(height: 15, widthFactor: 0.76),
                      SizedBox(height: 8),
                      _SkeletonBar(height: 12, widthFactor: 0.88),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
    return Semantics(
      identifier: 'listas-guides-loading',
      label: 'Cargando guías',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GmCard(
              radius: GmRadius.guide,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 196,
                      decoration: BoxDecoration(
                        color: gm.fill,
                        borderRadius:
                            BorderRadius.circular(GmRadius.guidePhoto),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(10, 12, 10, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SkeletonBar(height: 12, widthFactor: 0.4),
                          SizedBox(height: 8),
                          _SkeletonBar(height: 18, widthFactor: 0.78),
                          SizedBox(height: 8),
                          _SkeletonBar(height: 13, widthFactor: 0.9),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: GmSpace.cardGap),
            row(),
            const SizedBox(height: GmSpace.cardGap),
            row(),
          ],
        ),
      ),
    );
  }
}

class _GuidesError extends StatelessWidget {
  final VoidCallback onRetry;
  const _GuidesError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: 'listas-guides-error',
      liveRegion: true,
      child: GmCard(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          children: [
            Text(
              'No pudimos cargar las guías',
              textAlign: TextAlign.center,
              style: GmText.body17(color: gm.label, w: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Revisa tu conexión e inténtalo de nuevo.',
              textAlign: TextAlign.center,
              style: GmText.body(color: gm.label2),
            ),
            const SizedBox(height: 10),
            GmSoftCapsuleButton(
              label: 'Reintentar',
              fontSize: 15,
              identifier: 'listas-guides-retry',
              onTap: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

/// Resultados del buscador: solo guías (en filas) o «Sin resultados».
class _SearchResults extends StatelessWidget {
  final String query;
  final String islandId;
  final bool enabled;
  final ValueChanged<CuratedList> onOpen;

  const _SearchResults({
    required this.query,
    required this.islandId,
    required this.enabled,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CuratedListsCubit, CuratedListsState>(
      builder: (_, state) {
        final loading =
            state is CuratedListsInitial || state is CuratedListsLoading;
        final results = enabled && state is CuratedListsLoaded
            ? listasSearchGuides(
                listasGuidesForIsland(state.lists, islandId), query)
            : const <CuratedList>[];
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: enabled && loading
              ? const _GuidesSkeleton()
              : results.isEmpty
                  ? const _NoResults()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < results.length; i++) ...[
                          if (i > 0) const SizedBox(height: GmSpace.cardGap),
                          GmRise(
                            index: math.min(i, 3),
                            child: _GuideRowCard(
                                list: results[i],
                                onTap: () => onOpen(results[i])),
                          ),
                        ],
                      ],
                    ),
        );
      },
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: 'listas-search-empty',
      liveRegion: true,
      child: GmCard(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          children: [
            Text(
              'Sin resultados',
              textAlign: TextAlign.center,
              style: GmText.body17(color: gm.label, w: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Prueba con otro nombre, zona o plato.',
              textAlign: TextAlign.center,
              style: GmText.body(color: gm.label2),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Guardados
// ─────────────────────────────────────────────────────────────────────

class _SavedSection extends StatelessWidget {
  final GmFavorites favorites;
  final List<Restaurant> pool;
  final VoidCallback onOpen;

  const _SavedSection({
    required this.favorites,
    required this.pool,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: GmSpace.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GmRise(
            index: 6,
            child: GmSectionHeader(
              eyebrow: GmEyebrow(
                leading: GmIcon(GmIcons.heartFilled,
                    size: 12, color: GmColors.heart),
                text: 'En este móvil',
              ),
              title: 'Guardados',
              onTap: onOpen,
              identifier: 'listas-saved-see-all',
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
            child: GmRise(
              index: 7,
              child: ValueListenableBuilder<Set<String>>(
                valueListenable: favorites,
                builder: (_, saved, __) {
                  if (saved.isEmpty) return const _SavedEmpty();
                  final photos = listasSavedPhotos(saved, pool);
                  return Semantics(
                    identifier: 'listas-saved-card',
                    button: true,
                    child: GmPressable(
                      onTap: onOpen,
                      pressedScale: 0.98,
                      child: GmCard(
                        padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
                        child: Row(
                          children: [
                            photos.isEmpty
                                ? const _HeartTile(filled: true)
                                : _PhotoStack(urls: photos),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    listasSavedTitle(saved.length),
                                    style: GmText.guideTitle(color: gm.label),
                                  ),
                                  Text(
                                    'En lista o en el mapa',
                                    style: GmText.meta(color: gm.label2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            GmIcon(GmIcons.chevronRight,
                                size: 14, color: gm.label2),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedEmpty extends StatelessWidget {
  const _SavedEmpty();

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: 'listas-saved-empty',
      child: GmCard(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            const _HeartTile(filled: false),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Aún no has guardado nada',
                      style: GmText.guideTitle(color: gm.label)),
                  Text(
                    'Toca el corazón en cualquier sitio y lo tendrás aquí.',
                    style: GmText.meta(color: gm.label2),
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

class _HeartTile extends StatelessWidget {
  final bool filled;
  const _HeartTile({required this.filled});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: GmColors.heart.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: GmIcon(filled ? GmIcons.heartFilled : GmIcons.heart,
          size: 26, color: GmColors.heart),
    );
  }
}

/// Hasta tres fotos de guardados, solapadas y algo giradas.
class _PhotoStack extends StatelessWidget {
  final List<String> urls;
  const _PhotoStack({required this.urls});

  static const _turns = [-4.0, 2.0, 6.0];

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    const size = 52.0;
    const overlap = 16.0;
    final width = size + (urls.length - 1) * (size - overlap);
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: size + 4,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = urls.length - 1; i >= 0; i--)
              Positioned(
                left: i * (size - overlap),
                top: 2,
                child: Transform.rotate(
                  angle: _turns[i] * math.pi / 180,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: gm.fill,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: gm.card, width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CachedNetworkImage(
                      imageUrl: urls[i],
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const SizedBox.shrink(),
                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Más listas
// ─────────────────────────────────────────────────────────────────────

class _MoreListsSection extends StatelessWidget {
  final String islandLabel;
  final bool topBusy;
  final VoidCallback onTopRated;
  final VoidCallback onOpenNow;
  final VoidCallback onNearby;

  const _MoreListsSection({
    required this.islandLabel,
    required this.topBusy,
    required this.onTopRated,
    required this.onOpenNow,
    required this.onNearby,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    Widget sep() => Padding(
          padding: const EdgeInsets.only(left: 56),
          child: Container(height: 1, color: gm.sep),
        );
    return Padding(
      padding: const EdgeInsets.only(top: GmSpace.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GmRise(
            index: 7,
            child: GmSectionHeader(
              eyebrow: const GmEyebrow(text: 'Se actualizan solas'),
              title: 'Más listas',
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
            child: GmRise(
              index: 8,
              child: GmCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    _MoreRow(
                      identifier: 'listas-more-top-rated',
                      iconBg: GmColors.gold.withValues(alpha: 0.22),
                      icon: GmIcon(GmIcons.medal, size: 20, color: gm.label),
                      title: 'Mejor valorados de $islandLabel',
                      subtitle: 'Solo sitios con 10 reseñas o más',
                      busy: topBusy,
                      onTap: onTopRated,
                    ),
                    sep(),
                    _MoreRow(
                      identifier: 'listas-more-open-now',
                      iconBg: gm.okSoft,
                      icon: const GmLiveDot(),
                      title: 'Abiertos ahora',
                      subtitle: 'Según el horario de Google',
                      onTap: onOpenNow,
                    ),
                    sep(),
                    _MoreRow(
                      identifier: 'listas-more-nearby',
                      iconBg: gm.accentSoft,
                      icon: GmIcon(GmIcons.pin, size: 18, color: gm.accent),
                      title: 'Cerca de ti',
                      subtitle: 'Lo más cerca primero',
                      onTap: onNearby,
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
}

class _MoreRow extends StatelessWidget {
  final String identifier;
  final Color iconBg;
  final Widget icon;
  final String title;
  final String subtitle;
  final bool busy;
  final VoidCallback onTap;

  const _MoreRow({
    required this.identifier,
    required this.iconBg,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Semantics(
      identifier: identifier,
      button: true,
      child: GmPressable(
        onTap: onTap,
        pressedScale: 0.98,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 58),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: icon,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title,
                          style: GmText.body17(
                              color: gm.label, w: FontWeight.w500)),
                      Text(subtitle, style: GmText.meta(color: gm.label2)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (busy)
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: gm.label2),
                  )
                else
                  GmIcon(GmIcons.chevronRight, size: 14, color: gm.label2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Por tipo
// ─────────────────────────────────────────────────────────────────────

class _TypesSection extends StatelessWidget {
  final List<Types> types;
  final List<Restaurant> pool;
  final ValueChanged<Types> onPick;

  const _TypesSection({
    required this.types,
    required this.pool,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final n = typeGridEntries(types, pool).length;
    if (n == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: GmSpace.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GmRise(
            index: 8,
            child: GmSectionHeader(
              eyebrow: GmEyebrow(
                  text: n == 1 ? '1 tipo de sitio' : '$n tipos de sitio'),
              title: 'Por tipo',
            ),
          ),
          const SizedBox(height: 6),
          GmRise(
            index: 9,
            child: TypeGrid(
              types: types,
              pool: pool,
              onPick: onPick,
              identifierPrefix: 'listas-type',
            ),
          ),
        ],
      ),
    );
  }
}
