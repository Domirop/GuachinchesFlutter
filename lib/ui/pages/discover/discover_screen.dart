import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/core/analytics/analytics.dart';
import 'package:guachinches/core/analytics/analytics_events.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/cubit/new_home/new_home_filters_cubit.dart';
import 'package:guachinches/data/cubit/new_home/new_home_filters_state.dart';
import 'package:guachinches/data/cubit/new_home/visits_cubit.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/ui/pages/discover/visit_sentiment.dart';
import 'package:guachinches/ui/pages/discover/widgets/sort_sheet.dart';
import 'package:guachinches/ui/pages/discover/widgets/visit_filter_sheet.dart';
import 'package:guachinches/ui/pages/discover/widgets/visit_list_tile.dart';
import 'package:guachinches/ui/pages/visit/visit_screen.dart';
import 'package:guachinches/utils/island_key_utils.dart';

/// Catálogo de visitas (Jonay, Joana…). Permite buscar texto libre,
/// filtrar por creador / sentimiento / zona, y ordenar por fecha,
/// rating o alfabético. Sustituye al antiguo tab Videos.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;
  String _searchText = '';

  VisitFilterValues _filters = const VisitFilterValues();
  VisitSort _sort = VisitSort.newest;
  String? _islandFilterDisabledForKey;

  @override
  void initState() {
    super.initState();
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
    _searchDebounce?.cancel();
    super.dispose();
  }

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

  Future<void> _openFilters(List<Visit> all) async {
    final zones = _uniqueZones(all);
    final result = await VisitFilterSheet.show(
      context: context,
      initial: _filters,
      zones: zones,
    );
    if (result != null) setState(() => _filters = result);
  }

  Future<void> _openSort() async {
    final picked = await VisitSortSheet.show(
      context: context,
      current: _sort,
    );
    if (picked != null && picked != _sort) {
      setState(() => _sort = picked);
    }
  }

  void _toggleCreator(String c) {
    final next = Set<String>.from(_filters.creators);
    next.contains(c) ? next.remove(c) : next.add(c);
    setState(() => _filters = _filters.copyWith(creators: next));
  }

  void _clearAllFilters() =>
      setState(() => _filters = const VisitFilterValues());

  // ── Filtering / sorting ────────────────────────────────────────────────

  List<Visit> _applyIslandFilter(List<Visit> source, String islandName) {
    if (islandName.isEmpty) return source;
    final needle = islandName.toLowerCase().trim();
    return source.where((v) {
      final rIsland = (v.restaurant?.island ?? '').toLowerCase().trim();
      if (rIsland.isEmpty) return true;
      return rIsland == needle ||
          rIsland.contains(needle) ||
          needle.contains(rIsland);
    }).toList();
  }

  /// Normaliza para búsqueda tolerante: minúsculas + sin tildes/diéresis
  /// (canario: "José" ≈ "jose", "Añaza" ≈ "anaza"). Así el match no depende
  /// de que el usuario escriba los acentos.
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

  List<String> _uniqueZones(List<Visit> visits) {
    final set = <String>{};
    for (final v in visits) {
      final z = (v.zone?.isNotEmpty == true ? v.zone : v.restaurant?.municipio)
          ?.trim();
      if (z != null && z.isNotEmpty) set.add(z);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<Visit> _applyFilters(List<Visit> source) {
    // Tokens normalizados: cada palabra debe aparecer (AND), en cualquier
    // orden y sin depender de tildes. "carne tegueste" encuentra una visita
    // con plato "carne" en zona "Tegueste".
    final queryTokens = _normalize(_searchText)
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    final filtered = source.where((v) {
      // Creator
      if (_filters.creators.isNotEmpty) {
        final c = v.creator ?? '';
        if (!_filters.creators.contains(c)) return false;
      }
      // Sentiment
      if (_filters.sentiments.isNotEmpty) {
        final s = v.overallSentiment ?? '';
        if (!_filters.sentiments.contains(s)) return false;
      }
      // Zone
      if (_filters.zones.isNotEmpty) {
        final z = v.zone?.isNotEmpty == true ? v.zone! : v.restaurant?.municipio ?? '';
        if (!_filters.zones.contains(z)) return false;
      }
      // Has video
      if (_filters.onlyWithVideo) {
        final hasVideo = (v.videoUrl?.isNotEmpty == true) ||
            (v.youtubeVideoId?.isNotEmpty == true);
        if (!hasVideo) return false;
      }
      // Free-text search (tokens AND, normalizado)
      if (queryTokens.isNotEmpty) {
        final haystack = _normalize([
          v.creator,
          v.name,
          v.restaurant?.nombre,
          v.zone,
          v.restaurant?.municipio,
          v.summary,
          v.extraText,
          ...v.highlights,
          ...v.dishes.map((d) => d.name),
          ...v.quotes.map((qt) => qt.text),
        ].where((e) => e != null && e.toString().isNotEmpty).join(' '));
        if (!queryTokens.every(haystack.contains)) return false;
      }
      return true;
    }).toList();
    return _applySort(filtered);
  }

  List<Visit> _applySort(List<Visit> list) {
    int cmpDates(String? a, String? b, {bool desc = true}) {
      final da = DateTime.tryParse(a ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = DateTime.tryParse(b ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return desc ? db.compareTo(da) : da.compareTo(db);
    }

    String _name(Visit v) => (v.name?.isNotEmpty == true
            ? v.name!
            : v.restaurant?.nombre ?? '')
        .toLowerCase();

    switch (_sort) {
      case VisitSort.newest:
        list.sort((a, b) => cmpDates(a.sortDate, b.sortDate, desc: true));
        break;
      case VisitSort.oldest:
        list.sort((a, b) => cmpDates(a.sortDate, b.sortDate, desc: false));
        break;
      case VisitSort.ratingDesc:
        list.sort((a, b) =>
            (b.ratingImplicit ?? 0).compareTo(a.ratingImplicit ?? 0));
        break;
      case VisitSort.alphaAsc:
        list.sort((a, b) => _name(a).compareTo(_name(b)));
        break;
      case VisitSort.byCreator:
        list.sort((a, b) {
          final ca = (a.creator ?? '').toLowerCase();
          final cb = (b.creator ?? '').toLowerCase();
          final byCreator = ca.compareTo(cb);
          if (byCreator != 0) return byCreator;
          return cmpDates(a.sortDate, b.sortDate, desc: true);
        });
        break;
    }
    return list;
  }

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NewHomeFiltersCubit, NewHomeFiltersState>(
      builder: (context, filtersState) {
        final islandKey = filtersState.islandKey;
        final islandLabel = filtersState.islandLabel;
        return Scaffold(
          backgroundColor: context.brand.base,
          body: SafeArea(
            child: BlocBuilder<VisitsCubit, VisitsState>(
              builder: (context, state) {
                final allVisits = state is VisitsLoaded ? state.visits : <Visit>[];
                final isLoading = state is VisitsLoading;
                final isFailure = state is VisitsFailure;

                final islandFilteredVisits = _islandFilterDisabledForKey == islandKey
                    ? allVisits
                    : _applyIslandFilter(allVisits, islandNameFromKey(islandKey));

                final isIslandEmpty = _islandFilterDisabledForKey != islandKey &&
                    !isLoading &&
                    allVisits.isNotEmpty &&
                    islandFilteredVisits.isEmpty;

                final filtered = _applyFilters(islandFilteredVisits);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barra superior anclada: título + acciones + buscador.
                    // Vive fuera del scroll (la lista va en el Expanded), así
                    // que queda fija arriba; el hairline inferior la separa.
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
                          Semantics(
                            identifier: 'discover-active-island-label',
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                              child: Text(
                                islandLabel.toUpperCase(),
                                style: AppTextStyles.eyebrow(
                                  size: 10,
                                  color: AppColors.atlanticoClaro,
                                ),
                              ),
                            ),
                          ),
                          _DiscoverHeader(
                            total: filtered.length,
                            isLoading: isLoading && allVisits.isEmpty,
                            sortLabel: _sort.label,
                            filterCount: _filters.count,
                            onSort: _openSort,
                            onFilter: () => _openFilters(allVisits),
                          ),
                          const SizedBox(height: 12),
                          Semantics(
                            identifier: 'discover-search-field',
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
                    if (_filters.count > 0)
                      _ActiveFiltersBar(
                        filters: _filters,
                        onRemoveCreator: _toggleCreator,
                        onRemoveSentiment: (s) {
                          final next = Set<String>.from(_filters.sentiments)..remove(s);
                          setState(
                              () => _filters = _filters.copyWith(sentiments: next));
                        },
                        onRemoveZone: (z) {
                          final next = Set<String>.from(_filters.zones)..remove(z);
                          setState(
                              () => _filters = _filters.copyWith(zones: next));
                        },
                        onToggleVideo: () => setState(() => _filters =
                            _filters.copyWith(onlyWithVideo: false)),
                        onClearAll: _clearAllFilters,
                      ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: isIslandEmpty
                          ? _IslandEmptyState(
                              islandLabel: islandLabel,
                              onShowAll: () =>
                                  setState(() => _islandFilterDisabledForKey = islandKey),
                            )
                          : _buildBody(
                              state: state,
                              isLoading: isLoading,
                              isFailure: isFailure,
                              filtered: filtered,
                              hasFilters:
                                  _filters.count > 0 || _searchText.isNotEmpty,
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody({
    required VisitsState state,
    required bool isLoading,
    required bool isFailure,
    required List<Visit> filtered,
    required bool hasFilters,
  }) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.atlanticoClaro,
        ),
      );
    }
    if (isFailure) {
      return _ErrorState(
        onRetry: () => context.read<VisitsCubit>().loadVisits(),
      );
    }
    if (filtered.isEmpty) {
      return _EmptyState(
        hasFilters: hasFilters,
        onClear: () {
          _clearAllFilters();
          _clearSearch();
        },
      );
    }
    return RefreshIndicator(
      color: AppColors.atlanticoClaro,
      onRefresh: () async => context.read<VisitsCubit>().loadVisits(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => Semantics(
          identifier: 'discover-visit-card-${filtered[i].id}',
          button: true,
          child: VisitListTile(
            visit: filtered[i],
            onTap: () {
              Analytics.I.logEvent(AnalyticsEvents.visitOpened, {
                'visit_id': filtered[i].id,
                'source': 'visitas_tab',
              });
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VisitDetailPage(visitId: filtered[i].id),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────
class _DiscoverHeader extends StatelessWidget {
  final int total;
  final bool isLoading;
  final String sortLabel;
  final int filterCount;
  final VoidCallback onSort;
  final VoidCallback onFilter;

  const _DiscoverHeader({
    required this.total,
    required this.isLoading,
    required this.sortLabel,
    required this.filterCount,
    required this.onSort,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'VISITAS',
                  style: AppTextStyles.displayHero(size: 28),
                ),
                const SizedBox(height: 2),
                Text(
                  isLoading
                      ? 'Cargando…'
                      : '$total visita${total == 1 ? '' : 's'} · $sortLabel',
                  style: AppTextStyles.muted(size: 12),
                ),
              ],
            ),
          ),
          Semantics(
            identifier: 'discover-sort-button',
            label: 'Ordenar visitas',
            button: true,
            child: _IconBubble(icon: Icons.swap_vert_rounded, onTap: onSort),
          ),
          const SizedBox(width: 8),
          Semantics(
            identifier: 'discover-filter-button',
            label: 'Filtrar visitas',
            button: true,
            child: _IconBubble(
              icon: Icons.tune_rounded,
              onTap: onFilter,
              badge: filterCount > 0 ? '$filterCount' : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? badge;

  const _IconBubble({
    required this.icon,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.brand.surface,
              shape: BoxShape.circle,
              border: Border.all(color: context.brand.border),
            ),
            child: Icon(icon, size: 20, color: context.brand.textPrimary),
          ),
        ),
        if (badge != null)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.atlantico,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.brand.base, width: 2),
              ),
              child: Text(
                badge!,
                style: AppTextStyles.ui(
                  size: 10,
                  weight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Search row ────────────────────────────────────────────────────────────
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
                  hintText: 'Restaurante, autor, plato…',
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

// ── Active filters bar ────────────────────────────────────────────────────
class _ActiveFiltersBar extends StatelessWidget {
  final VisitFilterValues filters;
  final ValueChanged<String> onRemoveCreator;
  final ValueChanged<String> onRemoveSentiment;
  final ValueChanged<String> onRemoveZone;
  final VoidCallback onToggleVideo;
  final VoidCallback onClearAll;

  const _ActiveFiltersBar({
    required this.filters,
    required this.onRemoveCreator,
    required this.onRemoveSentiment,
    required this.onRemoveZone,
    required this.onToggleVideo,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    for (final c in filters.creators) {
      chips.add(_RemovableChip(label: c, onRemove: () => onRemoveCreator(c)));
    }
    for (final s in filters.sentiments) {
      chips.add(_RemovableChip(
        label: kSentimentLabels[s] ?? s,
        onRemove: () => onRemoveSentiment(s),
      ));
    }
    for (final z in filters.zones) {
      chips.add(_RemovableChip(label: z, onRemove: () => onRemoveZone(z)));
    }
    if (filters.onlyWithVideo) {
      chips.add(_RemovableChip(label: 'Con vídeo', onRemove: onToggleVideo));
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: chips.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            if (i == chips.length) {
              return GestureDetector(
                onTap: onClearAll,
                child: Container(
                  height: 36,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Limpiar',
                    style: AppTextStyles.ui(
                      size: 12,
                      weight: FontWeight.w700,
                      color: AppColors.atlanticoClaro,
                    ),
                  ),
                ),
              );
            }
            return chips[i];
          },
        ),
      ),
    );
  }
}

class _RemovableChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _RemovableChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRemove,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.atlantico.withOpacity(0.14),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.atlantico.withOpacity(0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.ui(
                size: 12,
                weight: FontWeight.w600,
                color: AppColors.atlanticoClaro,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.close_rounded,
                size: 14, color: AppColors.atlanticoClaro),
          ],
        ),
      ),
    );
  }
}

// ── States ────────────────────────────────────────────────────────────────

class _IslandEmptyState extends StatelessWidget {
  final String islandLabel;
  final VoidCallback onShowAll;

  const _IslandEmptyState({
    required this.islandLabel,
    required this.onShowAll,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.explore_off_rounded,
                size: 56, color: context.brand.textMuted),
            const SizedBox(height: 16),
            Text(
              'Sin visitas en $islandLabel',
              textAlign: TextAlign.center,
              style: AppTextStyles.displaySection(size: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'Todavía no hay visitas publicadas en esta isla.',
              textAlign: TextAlign.center,
              style: AppTextStyles.muted(size: 12),
            ),
            const SizedBox(height: 18),
            Semantics(
              identifier: 'discover-show-all-islands-button',
              child: GestureDetector(
                onTap: onShowAll,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.atlantico,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'Ver todas las visitas',
                    style: AppTextStyles.ui(
                      size: 13,
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
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onClear;

  const _EmptyState({required this.hasFilters, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.movie_filter_outlined,
                size: 56, color: context.brand.textMuted),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'Sin resultados' : 'Aún no hay visitas',
              style: AppTextStyles.displaySection(size: 16),
            ),
            const SizedBox(height: 6),
            Text(
              hasFilters
                  ? 'Prueba a ajustar los filtros o la búsqueda.'
                  : 'En cuanto Jonay y Joana publiquen nuevas visitas las verás aquí.',
              textAlign: TextAlign.center,
              style: AppTextStyles.muted(size: 12),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 18),
              GestureDetector(
                onTap: onClear,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.atlantico,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'Quitar filtros',
                    style: AppTextStyles.ui(
                      size: 13,
                      weight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 48, color: context.brand.textMuted),
            const SizedBox(height: 14),
            Text(
              'No hemos podido cargar las visitas.',
              textAlign: TextAlign.center,
              style: AppTextStyles.ui(
                size: 13,
                color: context.brand.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.atlantico,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'Reintentar',
                  style: AppTextStyles.ui(
                    size: 13,
                    weight: FontWeight.w700,
                    color: Colors.white,
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
