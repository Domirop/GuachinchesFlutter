import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/cubit/new_home/curated_lists_cubit.dart';
import 'package:guachinches/data/cubit/new_home/new_home_filters_cubit.dart';
import 'package:guachinches/data/model/curated_list.dart';

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

  @override
  void initState() {
    super.initState();
    // Cargar todas las listas (sin filtro de isla) al entrar.
    final cubit = context.read<CuratedListsCubit>();
    cubit.loadForIsland(null);
    // Pre-seleccionar la isla activa del usuario para filtrar localmente.
    _islandIdFilter = context.read<NewHomeFiltersCubit>().state.islandId;
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
    final list = r.toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.brand.base,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<CuratedListsCubit, CuratedListsState>(
          builder: (_, state) {
            final isLoading = state is CuratedListsLoading ||
                state is CuratedListsInitial;
            final all = state is CuratedListsLoaded ? state.lists : const <CuratedList>[];
            final filtered = _applyFilters(all);
            final featured = filtered.isNotEmpty ? filtered.first : null;
            final rest = filtered.length > 1 ? filtered.sublist(1) : const <CuratedList>[];

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _Header()),
                SliverToBoxAdapter(
                  child: _IslandFilterRow(
                    selectedId: _islandIdFilter,
                    onSelect: (id) => setState(() => _islandIdFilter = id),
                  ),
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
                          onTap: () {},
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
                          onTap: () {},
                        ),
                        childCount: rest.length,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Header (eyebrow + título grande + acciones)
// ─────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    'LISTAS',
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
          _RoundIconButton(icon: Icons.tune_rounded, onTap: () {}),
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

// ─────────────────────────────────────────────────────────────────────
// Filtros: islas (chips) y autor (chips)
// ─────────────────────────────────────────────────────────────────────

class _IslandOption {
  final String key;
  final String? id;
  const _IslandOption(this.key, this.id);
}

const List<_IslandOption> _kIslands = [
  _IslandOption('TF', '76ac0bec-4bc1-41a5-bc60-e528e0c12f4d'),
  _IslandOption('GC', null),
  _IslandOption('LZ', null),
  _IslandOption('FV', null),
  _IslandOption('LP', null),
  _IslandOption('LG', null),
  _IslandOption('EH', null),
];

class _IslandFilterRow extends StatelessWidget {
  final String? selectedId;
  final ValueChanged<String?> onSelect;

  const _IslandFilterRow({required this.selectedId, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _kIslands.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final opt = _kIslands[i];
          final active = opt.id != null && opt.id == selectedId;
          return GestureDetector(
            onTap: opt.id == null ? null : () => onSelect(opt.id),
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
              child: Opacity(
                opacity: opt.id == null ? 0.45 : 1.0,
                child: Text(
                  opt.key,
                  style: AppTextStyles.chipLabel(
                    size: 12,
                    color: active ? Colors.white : context.brand.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
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
            // Hero (asset o emoji)
            if (list.heroAsset != null)
              Positioned.fill(
                child: Image.asset(list.heroAsset!, fit: BoxFit.cover),
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
                child: Image.asset(list.heroAsset!, fit: BoxFit.cover),
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
          'No hay listas en esta isla',
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
