import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/core/analytics/analytics.dart';
import 'package:guachinches/core/analytics/analytics_events.dart';
import 'package:guachinches/l10n/app_localizations.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/core/remote_config/dcc_remote_config.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/cubit/new_home/curated_lists_cubit.dart';
import 'package:guachinches/data/cubit/new_home/islands_cubit.dart';
import 'package:guachinches/data/cubit/new_home/new_home_filters_cubit.dart';
import 'package:guachinches/data/cubit/new_home/new_home_filters_state.dart';
import 'package:guachinches/data/model/Island.dart';
import 'package:guachinches/data/model/curated_list.dart';
import 'package:guachinches/ui/components/curated_hero_image.dart';
import 'package:guachinches/ui/pages/curated_list_detail/curated_list_detail_screen.dart';
import 'package:guachinches/ui/pages/listas/widgets/listas_filter_sheet.dart';
import 'package:guachinches/utils/island_key_utils.dart';
import 'package:http/http.dart' as http;

/// Pantalla "Listas": catálogo de recopilatorios editoriales.
/// Reusa los tokens de diseño (light/dark) y el modelo de [CuratedList].
class ListasScreen extends StatefulWidget {
  const ListasScreen({super.key});

  @override
  State<ListasScreen> createState() => _ListasScreenState();
}

class _ListasScreenState extends State<ListasScreen> {
  String? _islandIdFilter;
  ListasFilterValues _sheetFilters = const ListasFilterValues();

  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    // Cargar todas las listas (sin filtro de isla) al entrar.
    final cubit = context.read<CuratedListsCubit>();
    cubit.loadForIsland(null);
    // Pre-seleccionar la isla activa del usuario para filtrar localmente.
    _islandIdFilter = context.read<NewHomeFiltersCubit>().state.islandId;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      setState(() => _searchText = value.trim());
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchCtrl.clear();
    setState(() => _searchText = '');
  }

  /// Normaliza para búsqueda tolerante: minúsculas + sin tildes/diéresis.
  static String _normalize(String s) {
    const from = 'áàäâãéèëêíìïîóòöôõúùüûñçºª';
    const to = 'aaaaaeeeeiiiiooooouuuunc  ';
    final buf = StringBuffer();
    for (final rune in s.toLowerCase().runes) {
      final ch = String.fromCharCode(rune);
      final idx = from.indexOf(ch);
      buf.write(idx >= 0 ? to[idx] : ch);
    }
    return buf.toString();
  }

  Future<void> _openFilterSheet() async {
    final result = await ListasFilterSheet.show(
      context: context,
      initial: _sheetFilters,
    );
    if (result != null && mounted) {
      setState(() => _sheetFilters = result);
    }
  }

  Future<void> _onRefresh() async {
    final repo = HttpRemoteRepository(http.Client());
    await repo.invalidateCache('categories');
    final cubit = context.read<CuratedListsCubit>();
    await cubit.refresh(null);
  }

  void _openList(CuratedList list) {
    Analytics.I.logEvent(AnalyticsEvents.listOpened, {
      'list_id': list.id,
      'list_title': list.title,
    });
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CuratedListDetailScreen(list: list),
      ),
    );
  }

  List<CuratedList> _applyFilters(List<CuratedList> all) {
    Iterable<CuratedList> r = all.where((l) => l.enabled);
    if (_islandIdFilter != null) {
      r = r.where((l) => l.islandId == null || l.islandId == _islandIdFilter);
    }
    if (_sheetFilters.featuredOnly) {
      r = r.where((l) => l.position == 1);
    }
    if (_sheetFilters.minCount > 0) {
      r = r.where((l) => l.count >= _sheetFilters.minCount);
    }
    // Búsqueda por nombre: tokens normalizados (AND), insensible a tildes.
    // "jonay terrazas" encuentra una lista de Jonay con "terrazas" en el título.
    final queryTokens = _normalize(_searchText)
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (queryTokens.isNotEmpty) {
      r = r.where((l) {
        final haystack = _normalize(
            '${l.title} ${l.subtitle} ${l.eyebrow} ${l.location}');
        return queryTokens.every(haystack.contains);
      });
    }
    final list = r.toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NewHomeFiltersCubit, NewHomeFiltersState>(
      listener: (context, state) {
        if (state.islandId != _islandIdFilter) {
          setState(() => _islandIdFilter = state.islandId);
        }
      },
      child: Scaffold(
      backgroundColor: context.brand.base,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<CuratedListsCubit, CuratedListsState>(
          builder: (_, state) {
            if (!DccRemoteConfig.instance.showCuratedLists) {
              return const SizedBox.shrink();
            }
            final isLoading = state is CuratedListsLoading ||
                state is CuratedListsInitial;
            final all = state is CuratedListsLoaded ? state.lists : const <CuratedList>[];
            final filtered = _applyFilters(all);
            final hasQuery = _searchText.isNotEmpty;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Barra superior anclada: cabecera + buscador (no scrollea).
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.brand.base,
                    border: Border(
                      bottom: BorderSide(color: context.brand.border),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(
                        onFilterTap: _openFilterSheet,
                        activeFilterCount: _sheetFilters.count,
                      ),
                      const SizedBox(height: 4),
                      Semantics(
                        identifier: 'listas-search-field',
                        child: _SearchRow(
                          controller: _searchCtrl,
                          onChanged: _onSearchChanged,
                          onClear: _clearSearch,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                Expanded(
                  child: Semantics(
                    identifier: 'listas-refresh-indicator',
                    child: RefreshIndicator(
                      onRefresh: _onRefresh,
                      color: Theme.of(context).colorScheme.primary,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        slivers: [
                          SliverToBoxAdapter(
                            child: _IslandFilterRow(selectedId: _islandIdFilter),
                          ),
                          if (isLoading && all.isEmpty)
                            const SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (filtered.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: _EmptyState(hasQuery: hasQuery),
                            )
                          else ...[
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                              sliver: SliverToBoxAdapter(
                                child: Text(
                                  '${filtered.length} listas',
                                  style: AppTextStyles.eyebrow(
                                    size: 11,
                                    color: context.brand.textMuted,
                                  ),
                                ),
                              ),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (_, i) => Padding(
                                    padding: EdgeInsets.only(
                                      bottom: i == filtered.length - 1 ? 0 : 14,
                                    ),
                                    child: _FeaturedListCard(
                                      list: filtered[i],
                                      showFeaturedBadge: i == 0,
                                      onTap: () => _openList(filtered[i]),
                                    ),
                                  ),
                                  childCount: filtered.length,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Header (eyebrow + título grande + acciones)
// ─────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onFilterTap;
  final int activeFilterCount;

  const _Header({
    required this.onFilterTap,
    required this.activeFilterCount,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Padding(
      padding: EdgeInsets.fromLTRB(canPop ? 8 : 20, 8, 12, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canPop)
            IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: context.brand.textPrimary,
              ),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'JONAY & JOANA',
                    style: AppTextStyles.eyebrow(
                      size: 10,
                      color: context.brand.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppL10n.of(context).listsScreenTitle.toUpperCase(),
                    style: AppTextStyles.displayHero(
                      size: 36,
                      color: context.brand.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _FilterIconButton(
            onTap: onFilterTap,
            activeCount: activeFilterCount,
          ),
        ],
      ),
    );
  }
}

class _FilterIconButton extends StatelessWidget {
  final VoidCallback onTap;
  final int activeCount;

  const _FilterIconButton({required this.onTap, required this.activeCount});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.brand.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.brand.border),
            ),
            child: Icon(
              Icons.tune_rounded,
              size: 18,
              color: context.brand.textPrimary,
            ),
          ),
          if (activeCount > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.mojo,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '$activeCount',
                  style: AppTextStyles.ui(
                    size: 11,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Filtros: islas (chips) y autor (chips)
// ─────────────────────────────────────────────────────────────────────

class _IslandFilterRow extends StatelessWidget {
  final String? selectedId;

  const _IslandFilterRow({required this.selectedId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IslandsCubit, IslandsState>(
      builder: (context, state) {
        final islands = state is IslandsLoaded ? state.islands : <Island>[];
        if (islands.isEmpty) return const SizedBox(height: 44);
        return SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: islands.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final island = islands[i];
              final key = (island.key != null && island.key!.isNotEmpty)
                  ? island.key!
                  : islandKeyFromName(island.name);
              final active = island.id == selectedId;
              return Semantics(
                identifier: 'listas-island-chip-${key.toLowerCase()}',
                child: GestureDetector(
                  onTap: () {
                    context.read<NewHomeFiltersCubit>().selectIsland(
                          id: island.id,
                          key: key,
                          label: island.name,
                        );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? AppColors.atlantico : context.brand.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: active
                          ? null
                          : Border.all(color: context.brand.border),
                    ),
                    child: Text(
                      key,
                      style: AppTextStyles.chipLabel(
                        size: 12,
                        color:
                            active ? Colors.white : context.brand.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Buscador por nombre
// ─────────────────────────────────────────────────────────────────────

class _SearchRow extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchRow({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: context.brand.surface,
          border: Border.all(color: context.brand.borderStrong),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(Icons.search_rounded,
                size: 20, color: AppColors.atlanticoClaro),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                style: AppTextStyles.ui(
                  size: 14,
                  color: context.brand.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar lista, zona, autor…',
                  hintStyle: AppTextStyles.ui(
                    size: 14,
                    color: context.brand.textMuted,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, v, __) {
                if (v.text.isEmpty) return const SizedBox(width: 12);
                return GestureDetector(
                  onTap: onClear,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12, left: 4),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: context.brand.elevated,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.close_rounded,
                          size: 14, color: context.brand.textPrimary),
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
// Cards: featured (full-width) + grid (2 columnas)
// ─────────────────────────────────────────────────────────────────────

class _FeaturedListCard extends StatelessWidget {
  final CuratedList list;
  final VoidCallback onTap;
  final bool showFeaturedBadge;

  const _FeaturedListCard({
    required this.list,
    required this.onTap,
    this.showFeaturedBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'listas-card-${list.id}',
      button: true,
      child: GestureDetector(
      onTap: onTap,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: list.accent,
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Hero de fondo (URL remota / asset local / emoji).
            if (list.heroAsset != null)
              Positioned.fill(
                child: CuratedHeroImage(source: list.heroAsset!),
              )
            else if (list.heroEmoji != null)
              Positioned(
                right: -8,
                bottom: -22,
                child: Text(
                  list.heroEmoji!,
                  style: const TextStyle(fontSize: 180),
                ),
              ),
            // Vignette superior — contraste del numeral "N SITIOS".
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 90,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.28),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Degradado inferior — el típico para legibilidad de tags + texto.
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 150,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.5, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.32),
                      Colors.black.withOpacity(0.80),
                    ],
                  ),
                ),
              ),
            ),
            // Numeral grande (recuento de sitios) — arriba a la derecha.
            if (list.count > 0)
              Positioned(
                top: 14,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${list.count}',
                      style: AppTextStyles.displayHero(
                        size: 64,
                        color: Colors.white.withOpacity(0.95),
                      ),
                    ),
                    Text(
                      'SITIOS',
                      style: AppTextStyles.eyebrow(
                        size: 9,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            // Tags arriba a la izquierda, sobre la foto (deja hueco al numeral).
            if (showFeaturedBadge || list.eyebrow.isNotEmpty)
              Positioned(
                top: 16,
                left: 16,
                right: 80,
                child: Row(
                  children: [
                    if (showFeaturedBadge) ...[
                      _Badge(
                        label: 'DESTACADA',
                        background: AppColors.mojo,
                        foreground: Colors.white,
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (list.eyebrow.isNotEmpty)
                      Flexible(
                        child: _Badge(
                          label: list.eyebrow.toUpperCase(),
                          background: Colors.black.withOpacity(0.45),
                          foreground: AppColors.crema.withOpacity(0.9),
                        ),
                      ),
                  ],
                ),
              ),
            // Pie: título + subtítulo.
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    list.title.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.displayHero(
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                  if (list.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      list.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.editorial(
                        size: 12,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _Badge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: AppTextStyles.eyebrow(size: 9, color: foreground),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasQuery;

  const _EmptyState({required this.hasQuery});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final (title, subtitle) = hasQuery
        ? (
            'Sin resultados',
            'Prueba con otro nombre, zona o autor.',
          )
        : (
            l10n.listsEmpty,
            'Prueba a seleccionar otra isla.',
          );

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_stories_outlined,
            size: 56,
            color: context.brand.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.displayHero(
              size: 18,
              color: context.brand.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.ui(
              size: 13,
              color: context.brand.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
