import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/core/analytics/analytics.dart';
import 'package:guachinches/core/analytics/analytics_events.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/data/cubit/location/location_cubit.dart';
import 'package:guachinches/data/cubit/location/location_state.dart';
import 'package:guachinches/data/cubit/new_home/islands_cubit.dart';
import 'package:guachinches/data/cubit/new_home/new_home_filters_cubit.dart';
import 'package:guachinches/data/cubit/new_home/new_home_filters_state.dart';
import 'package:guachinches/data/cubit/new_home/visits_cubit.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/ui/pages/discover/discover_logic.dart';
import 'package:guachinches/ui/pages/discover/widgets/gm_pull_down_menu.dart'
    show gmAnchorRect;
import 'package:guachinches/ui/pages/discover/widgets/sort_sheet.dart';
import 'package:guachinches/ui/pages/discover/widgets/visit_filter_sheet.dart';
import 'package:guachinches/ui/pages/new_home/widgets/gm_place_card.dart'
    show GmPhoto;
import 'package:guachinches/ui/pages/restaurant_detail/ficha_logic.dart'
    show
        fichaDateFromIso,
        fichaLoved,
        fichaReelSize,
        fichaReelThumbs,
        fichaShortDateFromIso,
        fichaVisitDuration;
import 'package:guachinches/ui/pages/restaurant_detail/widgets/ficha_visit_reels.dart'
    show FichaLovedSeal, FichaReelCover, FichaStoryAvatar;
import 'package:guachinches/ui/pages/visit/visit_screen.dart';
import 'package:guachinches/ui/theme/gm_icons.dart';
import 'package:guachinches/ui/theme/gm_motion.dart';
import 'package:guachinches/ui/theme/gm_tokens.dart';
import 'package:guachinches/ui/theme/gm_widgets.dart';
import 'package:guachinches/utils/island_key_utils.dart';

/// Pestaña Visitas (tablero TabVisitas): los vídeos de Jonay y Joana de la
/// isla elegida en la app. Cabecera con su avatar, buscador + Filtros, chips
/// de isla con recuento, «Lo último» (portadas tipo Reels), «Lo que más
/// piden» y «Todas las visitas» agrupadas por mes. Se monta como pestaña y
/// también se empuja desde «Últimas visitas» del Inicio.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final ScrollController _scroll = ScrollController();
  final ScrollController _chipsCtrl = ScrollController();
  final Map<String, GlobalKey> _chipKeys = {};
  Timer? _searchDebounce;
  String _searchText = '';
  bool _scrolled = false;
  String? _revealedChips;

  /// Últimas visitas cargadas: al refrescar (el cubit emite «cargando») se
  /// siguen viendo en vez de volver al esqueleto.
  List<Visit>? _lastVisits;

  VisitFilterValues _filters = const VisitFilterValues();
  VisitSort _sort = VisitSort.newest;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _bootstrap();
  }

  void _bootstrap() {
    final cubit = context.read<VisitsCubit>();
    if (cubit.state is VisitsInitial || cubit.state is VisitsFailure) {
      cubit.loadVisits();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _scroll.dispose();
    _chipsCtrl.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    final s = _scroll.hasClients && _scroll.offset > 4;
    if (s != _scrolled) setState(() => _scrolled = s);
  }

  // ── Acciones ─────────────────────────────────────────────────────────────

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      final trimmed = value.trim();
      setState(() => _searchText = trimmed);
      if (trimmed.length >= 2) {
        Analytics.I.logEvent(AnalyticsEvents.searchPerformed, {
          'query': trimmed,
          'tab': 'visitas',
        });
      }
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchCtrl.clear();
    setState(() => _searchText = '');
  }

  /// Tarjeta de «Lo que más piden»: escribe el plato en el buscador.
  void _searchFor(String word) {
    _searchDebounce?.cancel();
    HapticFeedback.selectionClick();
    _searchCtrl.value = TextEditingValue(
      text: word,
      selection: TextSelection.collapsed(offset: word.length),
    );
    setState(() => _searchText = word);
    Analytics.I.logEvent(AnalyticsEvents.searchPerformed, {
      'query': word,
      'tab': 'visitas',
      'source': 'dish_tile',
    });
    if (_scroll.hasClients) {
      _scroll.animateTo(0,
          duration: Duration(milliseconds: GmMotion.reduced(context) ? 0 : 380),
          curve: GmMotion.settle);
    }
  }

  Future<void> _openFilters(List<Visit> islandVisits) async {
    // Base de los recuentos: la isla con la búsqueda ya aplicada.
    final base = [
      for (final v in islandVisits)
        if (discoverMatches(v, _searchText, const VisitFilterValues())) v
    ];
    final result = await VisitFilterSheet.show(
      context: context,
      initial: _filters,
      visits: base,
    );
    if (result != null) setState(() => _filters = result);
  }

  /// Ubicación para «Más cerca de ti» (`null` sin permiso o sin fix).
  DiscoverOrigin? _origin() {
    try {
      final st = context.read<LocationCubit>().state;
      if (st is LocationLoaded) {
        return (lat: st.latitude, lon: st.longitude);
      }
    } on ProviderNotFoundException catch (e) {
      AppLogger.warn('discover', 'sin LocationCubit: $e');
    }
    return null;
  }

  Future<void> _openSort(BuildContext anchorContext) async {
    final picked = await showVisitSortMenu(
      context,
      anchor: gmAnchorRect(anchorContext),
      current: _sort,
      hasLocation: _origin() != null,
    );
    if (picked != null && picked != _sort) setState(() => _sort = picked);
  }

  void _clearFilters() => setState(() => _filters = const VisitFilterValues());

  void _selectIsland(DiscoverIsland island, String currentKey) {
    if (island.key.toUpperCase() == currentKey.toUpperCase()) return;
    HapticFeedback.selectionClick();
    context.read<NewHomeFiltersCubit>().selectIsland(
          id: island.id,
          key: island.key,
          label: island.label,
        );
  }

  void _openVisit(Visit v) {
    Analytics.I.logEvent(AnalyticsEvents.visitOpened, {
      'visit_id': v.id,
      'source': 'visitas_tab',
    });
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VisitDetailPage(visitId: v.id, initialVisit: v),
      ),
    );
  }

  /// Desplaza la fila de chips para que se vea la isla elegida (solo en
  /// horizontal: no mueve la página).
  void _revealSelectedChip(String signature, String key) {
    if (_revealedChips == signature) return;
    _revealedChips = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_chipsCtrl.hasClients) return;
      final ro = _chipKeys[key]?.currentContext?.findRenderObject();
      if (ro == null || !ro.attached) return;
      final viewport = RenderAbstractViewport.maybeOf(ro);
      if (viewport == null) return;
      final pos = _chipsCtrl.position;
      final target = viewport
          .getOffsetToReveal(ro, 0.5)
          .offset
          .clamp(pos.minScrollExtent, pos.maxScrollExtent);
      if ((target - pos.pixels).abs() < 1) return;
      if (GmMotion.reduced(context)) {
        _chipsCtrl.jumpTo(target);
      } else {
        _chipsCtrl.animateTo(target,
            duration: const Duration(milliseconds: 320),
            curve: GmMotion.settle);
      }
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return BlocBuilder<NewHomeFiltersCubit, NewHomeFiltersState>(
      builder: (context, fs) => BlocBuilder<IslandsCubit, IslandsState>(
        builder: (context, islandsState) =>
            BlocBuilder<VisitsCubit, VisitsState>(
          builder: (context, vs) {
            if (vs is VisitsLoaded) _lastVisits = vs.visits;
            if (vs is VisitsFailure) _lastVisits = null;
            return Scaffold(
              backgroundColor: gm.canvas,
              body: Stack(
                children: [
                  _buildScroll(context, fs, islandsState, vs),
                  GmTopScrim(visible: _scrolled),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildScroll(
    BuildContext context,
    NewHomeFiltersState fs,
    IslandsState islandsState,
    VisitsState vs,
  ) {
    final gm = GmColors.of(context);
    final media = MediaQuery.of(context);
    final islandKey = fs.islandKey.toUpperCase();
    final islandLabel = fs.islandLabel;

    // Islas del backend (para los chips y para traducir islandId → key).
    final islands = <DiscoverIsland>[
      if (islandsState is IslandsLoaded)
        for (final i in islandsState.islands)
          DiscoverIsland(
            id: i.id,
            key: (i.key != null && i.key!.isNotEmpty
                    ? i.key!
                    : islandKeyFromName(i.name))
                .toUpperCase(),
            label: i.name,
          ),
    ];
    if (!islands.any((i) => i.key == islandKey)) {
      islands.add(
          DiscoverIsland(id: fs.islandId, key: islandKey, label: islandLabel));
    }
    final idToKey = <String, String>{
      for (final i in islands) i.id: i.key,
      if (fs.islandId.isNotEmpty) fs.islandId: islandKey,
    };
    DiscoverIsland? islandByKey(String? k) {
      for (final i in islands) {
        if (i.key == k) return i;
      }
      return null;
    }

    final visits = _lastVisits;
    final loaded = visits != null;
    final failed = vs is VisitsFailure;
    final all = visits ?? const <Visit>[];
    final islandVisits = discoverVisitsOfIsland(all, islandKey, idToKey);
    final counts =
        loaded ? discoverIslandCounts(all, idToKey) : const <String, int>{};
    final chips = discoverIslandChips(islands, counts, islandKey);
    _revealSelectedChip(
        '$islandKey|${chips.map((c) => c.island.key).join(',')}', islandKey);

    final filtering = discoverIsFiltering(_searchText, _filters);
    final results = discoverApply(islandVisits,
        query: _searchText,
        filters: _filters,
        sort: _sort,
        origin: _sort == VisitSort.nearest ? _origin() : null);

    final canPop = Navigator.of(context).canPop();
    final latest = discoverLatest(islandVisits);

    final slivers = <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: media.padding.top + (canPop ? 4 : 10)),
          child: GmRise(
            trigger: GmTrigger.mount,
            child: _Header(
              canPop: canPop,
              avatarThumbs:
                  latest.isEmpty ? const [] : fichaReelThumbs(latest.first),
              subtitle: loaded
                  ? discoverSubtitle(islandVisits, islandLabel)
                  : 'Vídeos de $islandLabel',
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: GmRise(
          index: 1,
          trigger: GmTrigger.mount,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _SearchRow(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              onChanged: _onSearchChanged,
              onClear: _clearSearch,
              filterCount: _filters.count,
              onFilters: () => _openFilters(islandVisits),
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: GmRise(
          index: 2,
          trigger: GmTrigger.mount,
          child: Padding(
            padding: const EdgeInsets.only(top: 7),
            child: _IslandChips(
              controller: _chipsCtrl,
              chips: chips,
              showCounts: loaded,
              keyFor: (k) => _chipKeys.putIfAbsent(k, GlobalKey.new),
              onSelect: (i) => _selectIsland(i, islandKey),
            ),
          ),
        ),
      ),
    ];

    if (failed) {
      slivers.add(SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 27, 16, 0),
          child: _StateCard(
            identifier: 'discover-error',
            leading: const GmSadVolcano(width: 96),
            title: 'No pudimos cargar las visitas',
            text: 'Revisa tu conexión e inténtalo de nuevo.',
            primary: GmCapsuleButton(
              label: 'Reintentar',
              identifier: 'discover-retry-button',
              onTap: () => context.read<VisitsCubit>().loadVisits(),
            ),
          ),
        ),
      ));
    } else if (!loaded) {
      slivers.add(const SliverToBoxAdapter(child: _Skeleton()));
    } else if (islandVisits.isEmpty) {
      final top = islandByKey(discoverTopIsland(counts, islandKey));
      slivers.add(SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 19, 16, 0),
          child: _StateCard(
            identifier: 'discover-island-empty',
            leading: _IconDisc(icon: GmIcons.video),
            title: 'Todavía no hay visitas en $islandLabel',
            text: top == null
                ? 'En cuanto Jonay y Joana publiquen vídeos, los verás aquí.'
                : 'Jonay y Joana aún no han publicado vídeos de esta isla.',
            primary: top == null
                ? null
                : GmCapsuleButton(
                    label: 'Ver las de ${top.label}',
                    identifier: 'discover-island-empty-switch-button',
                    onTap: () => _selectIsland(top, islandKey),
                  ),
          ),
        ),
      ));
    } else if (filtering && results.isEmpty) {
      final suggestion = discoverEmptySuggestion(
        all,
        currentKey: islandKey,
        query: _searchText,
        filters: _filters,
        islandIdToKey: idToKey,
      );
      final other = islandByKey(suggestion?.islandKey);
      slivers.add(SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 19, 16, 0),
          child: _StateCard(
            identifier: 'discover-empty',
            leading: _IconDisc(icon: GmIcons.search),
            title: discoverEmptyTitle(_searchText, islandLabel),
            text: suggestion == null || other == null
                ? (_filters.count > 0
                    ? 'Prueba con menos filtros u otra palabra.'
                    : 'Prueba con otro sitio, zona o plato.')
                : discoverSuggestionText(
                    _searchText, other.label, suggestion.count),
            primary: other == null
                ? null
                : GmCapsuleButton(
                    label: 'Ver las de ${other.label}',
                    identifier: 'discover-empty-switch-island-button',
                    onTap: () => _selectIsland(other, islandKey),
                  ),
            secondary: _filters.count > 0
                ? GmSoftCapsuleButton(
                    label: 'Quitar filtros',
                    identifier: 'discover-clear-filters-button',
                    onTap: _clearFilters,
                  )
                : other == null && _searchText.isNotEmpty
                    ? GmSoftCapsuleButton(
                        label: 'Borrar búsqueda',
                        identifier: 'discover-clear-search-button',
                        onTap: _clearSearch,
                      )
                    : null,
          ),
        ),
      ));
    } else {
      if (!filtering) {
        slivers.add(SliverToBoxAdapter(
          child: _LatestSection(
            visits: latest,
            eyebrow: discoverLatestEyebrow(islandVisits),
            onOpen: _openVisit,
          ),
        ));
        final dishCounts = discoverDishCounts(islandVisits);
        if (dishCounts.values.any((n) => n > 0)) {
          slivers.add(SliverToBoxAdapter(
            child: _DishSection(counts: dishCounts, onTap: _searchFor),
          ));
        }
      }
      slivers.add(SliverToBoxAdapter(
        child: GmRise(
          index: 5,
          child: Padding(
            padding: EdgeInsets.only(top: filtering ? 24 : GmSpace.section),
            child: _AllHeader(
              eyebrow: filtering
                  ? discoverResultsEyebrow(results.length)
                  : discoverListEyebrow(_sort),
              sortLabel: _sort.pillLabel,
              onSort: _openSort,
            ),
          ),
        ),
      ));
      final groups = discoverGroups(results, _sort);
      for (var g = 0; g < groups.length; g++) {
        slivers.addAll(_groupSlivers(context, groups[g], first: g == 0));
      }
    }

    slivers.add(SliverToBoxAdapter(
      child: SizedBox(height: 120 + media.padding.bottom),
    ));

    return RefreshIndicator(
      color: gm.accent,
      backgroundColor: gm.card,
      edgeOffset: media.padding.top,
      onRefresh: () => context.read<VisitsCubit>().loadVisits(),
      child: CustomScrollView(
        controller: _scroll,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: slivers,
      ),
    );
  }

  /// Título del mes + tarjeta agrupada (lista perezosa).
  List<Widget> _groupSlivers(BuildContext context, DiscoverGroup group,
      {required bool first}) {
    final gm = GmColors.of(context);
    final n = group.visits.length;
    return [
      SliverToBoxAdapter(
        child: group.caption == null
            ? const SizedBox(height: 10)
            : Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Semantics(
                  header: true,
                  child: Text(group.caption!,
                      style: GmText.eyebrow(color: gm.label2)),
                ),
              ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
        sliver: DecoratedSliver(
          decoration: BoxDecoration(
            color: gm.card,
            borderRadius: BorderRadius.circular(GmRadius.card),
            boxShadow: gm.shadow1,
          ),
          sliver: SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            sliver: SliverList.separated(
              itemCount: n,
              separatorBuilder: (_, __) => Padding(
                padding: const EdgeInsets.only(left: 80),
                child: Container(height: 1, color: gm.sep),
              ),
              itemBuilder: (_, i) {
                final row = _VisitRow(
                  visit: group.visits[i],
                  onTap: () => _openVisit(group.visits[i]),
                );
                return first ? GmRise(index: 6, child: row) : row;
              },
            ),
          ),
        ),
      ),
    ];
  }
}

// ── Cabecera ────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final bool canPop;
  final List<String> avatarThumbs;
  final String subtitle;

  const _Header({
    required this.canPop,
    required this.avatarThumbs,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: GmSpace.titleInset),
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
                identifier: 'discover-back-button',
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              FichaStoryAvatar(thumbs: avatarThumbs, size: 24, photo: 17),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Jonay y Joana',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GmText.eyebrow(color: gm.label2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Semantics(
            header: true,
            child: Text('Visitas', style: GmText.largeTitle(color: gm.label)),
          ),
          const SizedBox(height: 2),
          Semantics(
            identifier: 'discover-active-island-label',
            child: Text(subtitle, style: GmText.body(color: gm.label2)),
          ),
        ],
      ),
    );
  }
}

// ── Buscador + Filtros ──────────────────────────────────────────────────────

class _SearchRow extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final int filterCount;
  final VoidCallback onFilters;

  const _SearchRow({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    required this.filterCount,
    required this.onFilters,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Row(
      children: [
        Expanded(
          child: Semantics(
            identifier: 'discover-search-field',
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
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
                      focusNode: focusNode,
                      onChanged: onChanged,
                      onSubmitted: (_) => focusNode.unfocus(),
                      textInputAction: TextInputAction.search,
                      cursorColor: gm.accent,
                      style: GmText.body17(color: gm.label),
                      decoration: InputDecoration(
                        hintText: 'Sitio, zona o plato',
                        hintStyle: GmText.body17(color: gm.label2),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (_, v, __) {
                      if (v.text.isEmpty) return const SizedBox(width: 12);
                      return Semantics(
                        identifier: 'discover-search-clear',
                        button: true,
                        label: 'Borrar búsqueda',
                        excludeSemantics: true,
                        child: GmPressable(
                          onTap: onClear,
                          pressedScale: 0.9,
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
                                child: GmIcon(GmIcons.xSmall,
                                    size: 12, color: gm.label2),
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
          ),
        ),
        const SizedBox(width: 8),
        Semantics(
          identifier: 'discover-filter-button',
          button: true,
          label: filterCount > 0 ? 'Filtros, $filterCount activos' : 'Filtros',
          excludeSemantics: true,
          child: GmPressable(
            onTap: onFilters,
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: gm.card,
                borderRadius: BorderRadius.circular(GmRadius.pill),
                boxShadow: gm.shadow1,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GmIcon(GmIcons.filters, size: 16, color: gm.label),
                  const SizedBox(width: 6),
                  Text('Filtros',
                      style: GmText.sub(color: gm.label, w: FontWeight.w600)),
                  if (filterCount > 0) ...[
                    const SizedBox(width: 6),
                    _CountBadge(count: filterCount),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          gradient: GmColors.accentFill,
          borderRadius: BorderRadius.circular(GmRadius.pill),
        ),
        alignment: Alignment.center,
        child: Text(
          '$count',
          style: const TextStyle(
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
}

// ── Chips de isla ───────────────────────────────────────────────────────────

class _IslandChips extends StatelessWidget {
  final ScrollController controller;
  final List<DiscoverIslandChip> chips;
  final bool showCounts;
  final GlobalKey Function(String key) keyFor;
  final ValueChanged<DiscoverIsland> onSelect;

  const _IslandChips({
    required this.controller,
    required this.chips,
    required this.showCounts,
    required this.keyFor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return SingleChildScrollView(
      controller: controller,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
      child: Row(
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _chip(gm, chips[i]),
          ],
        ],
      ),
    );
  }

  Widget _chip(GmColors gm, DiscoverIslandChip c) {
    final sel = c.selected;
    final ink = sel ? gm.accent : gm.label;
    final key = c.island.key;
    return Semantics(
      key: keyFor(key),
      identifier: 'discover-island-chip-${key.toLowerCase()}',
      button: true,
      selected: sel,
      label: showCounts
          ? '${c.island.label}, ${discoverVisitCount(c.count)}'
          : c.island.label,
      excludeSemantics: true,
      child: GmPressable(
        onTap: () => onSelect(c.island),
        child: SizedBox(
          height: 44,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: GmMotion.ease,
              constraints: const BoxConstraints(minHeight: 34),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: sel ? gm.accentSoft : gm.fill,
                borderRadius: BorderRadius.circular(GmRadius.pill),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(c.island.label,
                      style: GmText.sub(color: ink, w: FontWeight.w600)),
                  if (showCounts) ...[
                    const SizedBox(width: 5),
                    Text('${c.count}',
                        style: GmText.sub(
                            color: sel ? gm.accent : gm.label2,
                            w: FontWeight.w500)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Cabeceras de sección ────────────────────────────────────────────────────

class _SectionHead extends StatelessWidget {
  final String? eyebrow;
  final String title;
  const _SectionHead({this.eyebrow, required this.title});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (eyebrow != null) GmEyebrow(text: eyebrow),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 34),
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: 1,
            child: Semantics(
              header: true,
              child: Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GmText.title2(color: gm.label)),
            ),
          ),
        ),
      ],
    );
  }
}

// ── «Lo último» ─────────────────────────────────────────────────────────────

class _LatestSection extends StatelessWidget {
  final List<Visit> visits;
  final String? eyebrow;
  final ValueChanged<Visit> onOpen;

  const _LatestSection({
    required this.visits,
    required this.eyebrow,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (visits.isEmpty) return const SizedBox.shrink();
    final lead = fichaReelSize(0);
    // Portada + hueco del anillo (5 por lado).
    final rowH = lead.height + 10;
    return Semantics(
      identifier: 'discover-latest',
      container: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GmRise(
              index: 2,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: GmSpace.titleInset),
                child: _SectionHead(eyebrow: eyebrow, title: 'Lo último'),
              ),
            ),
            const SizedBox(height: 10),
            GmRise(
              index: 3,
              child: SizedBox(
                height: rowH,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  padding:
                      const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
                  itemCount: visits.length,
                  // 12 entre portadas: la de 132 lleva 5 de hueco de anillo.
                  separatorBuilder: (_, __) => const SizedBox(width: 7),
                  itemBuilder: (_, i) {
                    final v = visits[i];
                    final name = discoverVisitName(v);
                    final date = fichaDateFromIso(v.sortDate);
                    return Align(
                      alignment: Alignment.topLeft,
                      child: FichaReelCover(
                        visit: v,
                        index: i,
                        selected: i == 0,
                        selectable: false,
                        title: name.isEmpty ? null : name,
                        subtitle: discoverShortMunicipio(v),
                        semanticsIdentifier: 'discover-latest-cover-$i',
                        semanticsLabel: [
                          'Ver la visita',
                          if (name.isNotEmpty) 'a $name',
                          if (date != null) 'del $date',
                        ].join(' '),
                        onTap: () => onOpen(v),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── «Lo que más piden» ──────────────────────────────────────────────────────

class _DishSection extends StatelessWidget {
  final Map<DiscoverDish, int> counts;
  final ValueChanged<String> onTap;

  const _DishSection({required this.counts, required this.onTap});

  /// Platos pastel del tablero (los mismos que la banda de especialidades
  /// del Inicio; también de noche, con el glifo oscuro encima).
  static const _plates = {
    DiscoverDish.cabra: Color(0xFFF6DCD8),
    DiscoverDish.cochino: Color(0xFFE9DCC2),
    DiscoverDish.vieja: Color(0xFFE1E8D2),
    DiscoverDish.barraquito: Color(0xFFF3E6D6),
  };

  static const _glyphs = {
    DiscoverDish.cabra: GmGlyphKind.cabra,
    DiscoverDish.cochino: GmGlyphKind.cochino,
    DiscoverDish.vieja: GmGlyphKind.vieja,
    DiscoverDish.barraquito: GmGlyphKind.barraquito,
  };

  @override
  Widget build(BuildContext context) {
    final kinds = [
      for (final k in DiscoverDish.values)
        if ((counts[k] ?? 0) > 0) k
    ];
    final rows = <Widget>[];
    for (var i = 0; i < kinds.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 10));
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: GmRise(index: 4 + i, child: _tile(context, kinds[i])),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: i + 1 < kinds.length
                  ? GmRise(index: 5 + i, child: _tile(context, kinds[i + 1]))
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ));
    }
    return Semantics(
      identifier: 'discover-dishes',
      container: true,
      child: Padding(
        padding: const EdgeInsets.only(top: GmSpace.section),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GmRise(
              index: 4,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: GmSpace.titleInset),
                child: _SectionHead(
                  eyebrow: 'Sale en los platos de sus vídeos',
                  title: 'Lo que más piden',
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: GmSpace.gutter),
              child: Column(children: rows),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, DiscoverDish kind) {
    final gm = GmColors.of(context);
    final n = counts[kind] ?? 0;
    return Semantics(
      identifier: 'discover-dish-tile-${kind.name}',
      button: true,
      label: '${kind.label}, ${discoverVisitCount(n)}. Buscar',
      excludeSemantics: true,
      child: GmPressable(
        onTap: () => onTap(kind.query),
        child: GmCard(
          radius: 20,
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _plates[kind],
                    borderRadius: BorderRadius.circular(GmRadius.listIcon),
                  ),
                  alignment: Alignment.center,
                  child: GmGlyph(_glyphs[kind]!,
                      size: kind == DiscoverDish.cabra ? 26 : 28),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        kind.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GmText.body(color: gm.label, w: FontWeight.w600)
                            .copyWith(height: 19 / 15, letterSpacing: -0.2),
                      ),
                      Text(
                        discoverVisitCount(n),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            GmText.chip(color: gm.label2, w: FontWeight.w400),
                      ),
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

// ── «Todas las visitas» ─────────────────────────────────────────────────────

class _AllHeader extends StatelessWidget {
  final String eyebrow;
  final String sortLabel;
  final ValueChanged<BuildContext> onSort;

  const _AllHeader({
    required this.eyebrow,
    required this.sortLabel,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(GmSpace.titleInset, 0, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _SectionHead(eyebrow: eyebrow, title: 'Todas las visitas'),
          ),
          const SizedBox(width: 10),
          Builder(
            builder: (anchorCtx) => Semantics(
              identifier: 'discover-sort-button',
              button: true,
              label: 'Ordenar: $sortLabel',
              excludeSemantics: true,
              child: GmPressable(
                onTap: () => onSort(anchorCtx),
                child: SizedBox(
                  height: 44,
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: gm.card,
                        borderRadius: BorderRadius.circular(GmRadius.pill),
                        boxShadow: gm.shadow1,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GmIcon(GmIcons.sort, size: 14, color: gm.label),
                          const SizedBox(width: 6),
                          Text(sortLabel,
                              style: GmText.sub(
                                  color: gm.label, w: FontWeight.w600)),
                          const SizedBox(width: 6),
                          GmIcon(GmIcons.chevronDown,
                              size: 14, color: gm.label),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de la lista agrupada: miniatura 60 × 84 con duración, nombre, «Tipo ·
/// Municipio», platos, fecha y «Les encantó».
class _VisitRow extends StatelessWidget {
  final Visit visit;
  final VoidCallback onTap;

  const _VisitRow({required this.visit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    final v = visit;
    final name = discoverVisitName(v);
    final type = discoverTypeLabel(v);
    final muni = discoverShortMunicipio(v);
    final dishes = discoverDishLine(v);
    final shortDate = fichaShortDateFromIso(v.sortDate);
    final longDate = fichaDateFromIso(v.sortDate);
    final loved = fichaLoved(v);
    final duration = fichaVisitDuration(v);
    final thumbs = fichaReelThumbs(v);
    final meta = gm.label2;

    return Semantics(
      identifier: 'discover-visit-card-${v.id}',
      button: true,
      label: [
        name,
        if (type != null) type,
        if (muni != null) muni,
        if (longDate != null) longDate,
        if (loved) 'Les encantó',
      ].join(', '),
      excludeSemantics: true,
      child: GmPressable(
        onTap: onTap,
        pressedScale: 0.98,
        child: Container(
          constraints: const BoxConstraints(minHeight: 100),
          padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 60,
                  height: 84,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      GmPhoto(
                        thumbs.firstOrNull,
                        decodeWidth: 180,
                        fallbacks: thumbs.skip(1).toList(),
                      ),
                      if (duration != null)
                        Positioned(
                          left: 4,
                          bottom: 4,
                          child: MediaQuery.withClampedTextScaling(
                            maxScaleFactor: 1.2,
                            child: Container(
                              height: 18,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                color: const Color(0x8C14100C),
                                borderRadius:
                                    BorderRadius.circular(GmRadius.pill),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                duration,
                                style: const TextStyle(
                                  fontSize: 10,
                                  height: 12 / 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GmText.guideTitle(color: gm.label)
                          .copyWith(letterSpacing: -0.3),
                    ),
                    if (type != null || muni != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text.rich(
                          TextSpan(children: [
                            if (type != null)
                              TextSpan(
                                text: type,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: gm.label),
                              ),
                            if (type != null && muni != null)
                              const TextSpan(text: ' · '),
                            if (muni != null) TextSpan(text: muni),
                          ]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GmText.meta(color: meta),
                        ),
                      ),
                    if (dishes != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          dishes,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GmText.meta(color: meta),
                        ),
                      ),
                    if (shortDate != null || loved)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            if (shortDate != null)
                              Text(shortDate, style: GmText.meta(color: meta)),
                            if (shortDate != null && loved)
                              const SizedBox(width: 8),
                            if (loved)
                              const Flexible(
                                child:
                                    FichaLovedSeal(compact: true, height: 20),
                              ),
                          ],
                        ),
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
    );
  }
}

// ── Estados ─────────────────────────────────────────────────────────────────

/// Círculo de relleno 84 con un icono (vacíos).
class _IconDisc extends StatelessWidget {
  final String icon;
  const _IconDisc({required this.icon});

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return ExcludeSemantics(
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(color: gm.fill, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: GmIcon(icon, size: 40, color: gm.label2),
      ),
    );
  }
}

/// Tarjeta de estado (error / vacío): ilustración, título, texto y botones.
class _StateCard extends StatelessWidget {
  final String identifier;
  final Widget leading;
  final String title;
  final String text;
  final Widget? primary;
  final Widget? secondary;

  const _StateCard({
    required this.identifier,
    required this.leading,
    required this.title,
    required this.text,
    this.primary,
    this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final gm = GmColors.of(context);
    return GmRise(
      index: 3,
      trigger: GmTrigger.mount,
      child: Semantics(
        identifier: identifier,
        container: true,
        child: GmCard(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                leading,
                const SizedBox(height: 10),
                Text(title,
                    textAlign: TextAlign.center,
                    style: GmText.poster(color: gm.label)),
                const SizedBox(height: 6),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style:
                      GmText.body(color: gm.label2).copyWith(height: 21 / 15),
                ),
                if (primary != null || secondary != null) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (primary != null) primary!,
                      if (secondary != null) secondary!,
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Esqueleto con la forma real (tablero TabVisitas · cargando): bloques
/// planos, sin barrido.
class _Skeleton extends StatelessWidget {
  const _Skeleton();

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
    Widget row(double nameFactor) => Container(
          constraints: const BoxConstraints(minHeight: 100),
          padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
          child: Row(
            children: [
              sk(60, 84, 12),
              const SizedBox(width: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (_, c) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      sk(c.maxWidth * nameFactor, 15),
                      const SizedBox(height: 8),
                      sk(c.maxWidth * 0.52, 12),
                      const SizedBox(height: 8),
                      sk(c.maxWidth * 0.70, 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
    Widget small() => Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Align(alignment: Alignment.topLeft, child: sk(132, 234, 20)),
        );
    return Semantics(
      identifier: 'discover-skeleton',
      label: 'Cargando visitas',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cargando visitas…',
                      style: GmText.eyebrow(color: gm.label2)),
                  const SizedBox(height: 8),
                  sk(120, 24),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 294,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  sk(170, 294, 23),
                  const SizedBox(width: 12),
                  small(),
                  const SizedBox(width: 12),
                  small(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sk(150, 12),
                  const SizedBox(height: 10),
                  sk(190, 24),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (var r = 0; r < 2; r++) ...[
                    if (r > 0) const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: sk(null, 64, 20)),
                        const SizedBox(width: 10),
                        Expanded(child: sk(null, 64, 20)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GmCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [row(0.74), row(0.60), row(0.82), row(0.66)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
