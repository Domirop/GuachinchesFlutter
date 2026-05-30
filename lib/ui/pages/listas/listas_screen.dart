import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

enum _AuthorFilter { todas, guardadas, jonay, joana }

class _ListasScreenState extends State<ListasScreen> {
  _AuthorFilter _author = _AuthorFilter.todas;
  String? _islandIdFilter;
  ListasFilterValues _sheetFilters = const ListasFilterValues();

  @override
  void initState() {
    super.initState();
    // Cargar todas las listas (sin filtro de isla) al entrar.
    final cubit = context.read<CuratedListsCubit>();
    cubit.loadForIsland(null);
    // Pre-seleccionar la isla activa del usuario para filtrar localmente.
    _islandIdFilter = context.read<NewHomeFiltersCubit>().state.islandId;
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
    switch (_author) {
      case _AuthorFilter.jonay:
        r = r.where((l) => l.eyebrow.toUpperCase().contains('JONAY'));
        break;
      case _AuthorFilter.joana:
        r = r.where((l) => l.eyebrow.toUpperCase().contains('JOANA'));
        break;
      case _AuthorFilter.guardadas:
        // Sin estado de guardadas todavía: vacío.
        r = const [];
        break;
      case _AuthorFilter.todas:
        break;
    }
    // Sheet filters (combined / AND)
    if (_sheetFilters.authors.isNotEmpty) {
      r = r.where((l) {
        final up = l.eyebrow.toUpperCase();
        return _sheetFilters.authors.any((a) => up.contains(a));
      });
    }
    if (_sheetFilters.featuredOnly) {
      r = r.where((l) => l.position == 1);
    }
    if (_sheetFilters.minCount > 0) {
      r = r.where((l) => l.count >= _sheetFilters.minCount);
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
            final featured = filtered.isNotEmpty ? filtered.first : null;
            final rest = filtered.length > 1 ? filtered.sublist(1) : const <CuratedList>[];

            return Semantics(
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
                  child: _Header(
                    onFilterTap: _openFilterSheet,
                    activeFilterCount: _sheetFilters.count,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _IslandFilterRow(selectedId: _islandIdFilter),
                ),
                SliverToBoxAdapter(
                  child: _AuthorFilterRow(
                    selected: _author,
                    onSelect: (a) => setState(() => _author = a),
                  ),
                ),
                if (isLoading && all.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(author: _author),
                  )
                else ...[
                  if (featured != null)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      sliver: SliverToBoxAdapter(
                        child: _FeaturedListCard(
                          list: featured,
                          onTap: () => _openList(featured),
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
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
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.72,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _GridListCard(
                          list: rest[i],
                          onTap: () => _openList(rest[i]),
                        ),
                        childCount: rest.length,
                      ),
                    ),
                  ),
                ],
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
          _RoundIconButton(icon: Icons.view_agenda_outlined, onTap: () {}),
          const SizedBox(width: 8),
          _FilterIconButton(
            onTap: onFilterTap,
            activeCount: activeFilterCount,
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.brand.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.brand.border),
        ),
        child: Icon(icon, size: 18, color: context.brand.textPrimary),
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

class _AuthorFilterRow extends StatelessWidget {
  final _AuthorFilter selected;
  final ValueChanged<_AuthorFilter> onSelect;

  const _AuthorFilterRow({required this.selected, required this.onSelect});

  static const _items = [
    (_AuthorFilter.todas, 'Todas'),
    (_AuthorFilter.guardadas, 'Guardadas'),
    (_AuthorFilter.jonay, 'Jonay'),
    (_AuthorFilter.joana, 'Joana'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final (value, label) = _items[i];
            final active = selected == value;
            return GestureDetector(
              onTap: () => onSelect(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? AppColors.atlantico : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  border: active
                      ? null
                      : Border.all(color: context.brand.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (value == _AuthorFilter.guardadas) ...[
                      Icon(
                        Icons.bookmark_outline_rounded,
                        size: 14,
                        color: active
                            ? Colors.white
                            : context.brand.textSecondary,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      label,
                      style: AppTextStyles.ui(
                        size: 13,
                        weight: FontWeight.w600,
                        color: active
                            ? Colors.white
                            : context.brand.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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

  const _FeaturedListCard({required this.list, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
            // Tinte oscuro para legibilidad
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.10),
                    Colors.black.withOpacity(0.55),
                  ],
                ),
              ),
            ),
            // Hero (URL remota / asset local / emoji)
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
            // Badges arriba
            Positioned(
              left: 16,
              top: 16,
              right: 16,
              child: Row(
                children: [
                  _Badge(
                    label: 'DESTACADA',
                    background: AppColors.mojo,
                    foreground: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  if (list.eyebrow.isNotEmpty)
                    _Badge(
                      label: list.eyebrow.toUpperCase(),
                      background: Colors.black.withOpacity(0.45),
                      foreground: AppColors.crema.withOpacity(0.9),
                    ),
                  const Spacer(),
                  // Numeral grande del puesto
                  if (list.count > 0)
                    Text(
                      '${list.count}',
                      style: AppTextStyles.displayHero(
                        size: 64,
                        color: Colors.white.withOpacity(0.95),
                      ),
                    ),
                ],
              ),
            ),
            // Pie editorial
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (list.position > 0)
                    Text(
                      'Nº ${list.position} · ${list.count} sitios',
                      style: AppTextStyles.eyebrow(
                        size: 10,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  const SizedBox(height: 6),
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
    );
  }
}

class _GridListCard extends StatelessWidget {
  final CuratedList list;
  final VoidCallback onTap;

  const _GridListCard({required this.list, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: list.accent,
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Degradado oscuro para legibilidad del título inferior
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.05),
                    Colors.black.withOpacity(0.55),
                  ],
                ),
              ),
            ),
            if (list.heroAsset != null)
              Positioned.fill(
                child: CuratedHeroImage(source: list.heroAsset!),
              )
            else if (list.heroEmoji != null)
              Positioned(
                right: -10,
                bottom: -16,
                child: Text(
                  list.heroEmoji!,
                  style: const TextStyle(fontSize: 110),
                ),
              ),
            // Badge autor + bookmark
            Positioned(
              left: 10,
              top: 10,
              right: 10,
              child: Row(
                children: [
                  if (list.eyebrow.isNotEmpty)
                    _Badge(
                      label: list.eyebrow.toUpperCase(),
                      background: Colors.black.withOpacity(0.45),
                      foreground: AppColors.crema.withOpacity(0.9),
                    ),
                  const Spacer(),
                  Icon(
                    Icons.bookmark_outline_rounded,
                    size: 18,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ],
              ),
            ),
            // Contador grande lateral derecho
            if (list.count > 0)
              Positioned(
                right: 10,
                top: 36,
                child: Text(
                  '${list.count}',
                  style: AppTextStyles.displayHero(
                    size: 44,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ),
            // Pie con nº y título
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (list.position > 0)
                    Text(
                      'Nº ${list.position}',
                      style: AppTextStyles.eyebrow(
                        size: 9,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    list.title.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.displayHero(
                      size: 14,
                      color: Colors.white,
                    ),
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
        style: AppTextStyles.eyebrow(size: 9, color: foreground),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final _AuthorFilter author;

  const _EmptyState({required this.author});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final (title, subtitle) = switch (author) {
      _AuthorFilter.guardadas => (
          'Aún no has guardado listas',
          'Toca el icono de marcador en cualquier lista para guardarla.',
        ),
      _AuthorFilter.jonay => (
          'Sin listas de Jonay todavía',
          'Prueba con otra isla o cambia de filtro.',
        ),
      _AuthorFilter.joana => (
          'Sin listas de Joana todavía',
          'Prueba con otra isla o cambia de filtro.',
        ),
      _AuthorFilter.todas => (
          l10n.listsEmpty,
          'Prueba a seleccionar otra isla.',
        ),
    };

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
