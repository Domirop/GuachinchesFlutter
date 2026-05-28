import 'dart:convert';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/config/app_colors.dart';
import 'package:guachinches/config/app_text_styles.dart';
import 'package:guachinches/config/brand_colors.dart';
import 'package:guachinches/data/cubit/new_home/visits_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_state.dart';
import 'package:guachinches/data/cubit/search/dish_search_cubit.dart';
import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/data/model/Municipality.dart';
import 'package:guachinches/data/model/Types.dart';
import 'package:guachinches/data/model/Visit.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/services/app_storage.dart';
import 'package:guachinches/ui/pages/advance_search/widgets/search_filter_sheet.dart';
import 'package:guachinches/ui/pages/advance_search/widgets/search_result_card.dart';
import 'package:guachinches/ui/pages/restaurant_detail/restaurant_detail_screen.dart';
import 'package:guachinches/utils/debouncer.dart';
import 'package:guachinches/utils/dish_search_index.dart';

class AdvancedSearch extends StatefulWidget {
  final List<ModelCategory> categories;
  final List<Municipality> municipalities;
  final List<Types> types;
  final String islandId;
  final List<ModelCategory> preSelectedCategories;
  final List<Types> preSelectedTypes;
  final bool preSelectedOpenOnly;

  const AdvancedSearch({
    super.key,
    required this.categories,
    required this.municipalities,
    required this.types,
    required this.islandId,
    this.preSelectedCategories = const [],
    this.preSelectedTypes = const [],
    this.preSelectedOpenOnly = false,
  });

  @override
  State<AdvancedSearch> createState() => _AdvancedSearchState();
}

class _AdvancedSearchState extends State<AdvancedSearch> {
  static const _kRecentSearchesKey = 'search_recents';
  static const _kMaxRecents = 5;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final Debouncer _searchDebouncer = Debouncer();
  late RestaurantCubit _restaurantsCubit;

  SearchFilterValues _filters = const SearchFilterValues();
  List<String> _recents = const [];
  bool _hasSearched = false;

  // Dish search state — computed in _runSearch(), never via BlocListener.
  Set<String> _dishMatchIds = const {};
  Map<String, String> _dishFirstMatchName = const {};
  // Fallback de foto cuando el match viene por plato y `Restaurant.mainFoto`
  // está vacío. Es el thumbnail del vídeo de la visita.
  Map<String, String> _dishFirstVisitThumbnail = const {};
  List<Visit> _allVisits = const [];
  bool _hasDishIndex = false;

  bool get _hasQuery => _searchController.text.trim().isNotEmpty;

  bool get _isActive => _hasQuery || _filters.count > 0;

  @override
  void initState() {
    super.initState();
    _restaurantsCubit = context.read<RestaurantCubit>();
    _filters = SearchFilterValues(
      categoryIds:
          widget.preSelectedCategories.map((c) => c.id).toList(growable: false),
      typeIds: widget.preSelectedTypes.map((t) => t.id).toList(growable: false),
      municipalityIds: const [],
      openOnly: widget.preSelectedOpenOnly,
    );
    _loadRecents();
    if (_filters.count > 0) {
      _runSearch();
    }
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadRecents() async {
    try {
      final raw = await AppStorage.instance.read(key: _kRecentSearchesKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = json.decode(raw);
      if (decoded is List) {
        if (!mounted) return;
        setState(() => _recents = decoded.whereType<String>().toList());
      }
    } catch (_) {}
  }

  Future<void> _saveRecents() async {
    try {
      await AppStorage.instance
          .write(key: _kRecentSearchesKey, value: json.encode(_recents));
    } catch (_) {}
  }

  void _addRecent(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    final next = [q, ..._recents.where((r) => r.toLowerCase() != q.toLowerCase())];
    final capped = next.take(_kMaxRecents).toList();
    setState(() => _recents = capped);
    _saveRecents();
  }

  Future<void> _clearRecents() async {
    setState(() => _recents = const []);
    await AppStorage.instance.delete(key: _kRecentSearchesKey);
  }

  void _runSearch() {
    final query = _searchController.text;

    final dishState = context.read<DishSearchCubit>().state;
    final visitsState = context.read<VisitsCubit>().state;
    Set<String> newDishMatchIds = const {};
    Map<String, String> newDishFirstMatchName = const {};
    Map<String, String> newDishFirstVisitThumbnail = const {};
    List<Visit> newAllVisits = const [];
    final newHasDishIndex =
        dishState is DishSearchReady && dishState.index.isNotEmpty;

    // Diagnóstico — si el index está vacío o el cubit no ha cargado las
    // visitas, búsqueda por plato no funcionará. Esto lo elevamos a log para
    // poder verlo en consola sin tocar el render.
    final dishStateName = dishState.runtimeType.toString();
    final visitsStateName = visitsState.runtimeType.toString();
    final indexSize =
        dishState is DishSearchReady ? dishState.index.length : 0;
    AppLogger.info(
      'advanced-search',
      'query="$query" len=${query.length} '
          'dish_state=$dishStateName index_tokens=$indexSize '
          'visits_state=$visitsStateName',
    );

    if (dishState is DishSearchReady && query.trim().length >= 3) {
      newDishMatchIds = matchRestaurantIds(dishState.index, query);
      if (newDishMatchIds.isNotEmpty) {
        newAllVisits =
            visitsState is VisitsLoaded ? visitsState.visits : const [];
        newDishFirstMatchName = buildDishFirstMatchNames(
          newAllVisits,
          newDishMatchIds,
          query,
        );
        newDishFirstVisitThumbnail = buildDishFirstVisitThumbnails(
          newAllVisits,
          newDishMatchIds,
        );
      }
      AppLogger.info(
        'advanced-search',
        'dish_match_ids=${newDishMatchIds.length} '
            'first_match_names=${newDishFirstMatchName.length}',
      );
    }

    setState(() {
      _hasSearched = true;
      _dishMatchIds = newDishMatchIds;
      _dishFirstMatchName = newDishFirstMatchName;
      _dishFirstVisitThumbnail = newDishFirstVisitThumbnail;
      _allVisits = newAllVisits;
      _hasDishIndex = newHasDishIndex;
    });

    _restaurantsCubit.getFilterRestaurantsAdvance(
      categories: _filters.categoryIds,
      municipalities: _filters.municipalityIds,
      text: query,
      types: _filters.typeIds,
      islandId: widget.islandId,
      isOpen: _filters.openOnly,
    );

    if (query.length >= 3 && Firebase.apps.isNotEmpty) {
      final prevServerState = _restaurantsCubit.state;
      final prevServerIds = prevServerState is RestaurantFilterAdvanced
          ? prevServerState.restaurantFilterAdvanced.map((r) => r.id).toSet()
          : const <String>{};
      FirebaseAnalytics.instance.logEvent(
        name: 'search_dish_match',
        parameters: {
          'query_len': query.length,
          'server_count': prevServerIds.length,
          'dish_count': newDishMatchIds.length,
          'dish_only_count': newDishMatchIds.difference(prevServerIds).length,
        },
      );
    }
  }

  void _onQueryChanged(String _) {
    setState(() {});
    _searchDebouncer(() => _runSearch());
  }

  void _onSubmitted(String value) {
    _searchDebouncer.cancel();
    _addRecent(value);
    _runSearch();
  }

  Future<void> _openFilterSheet() async {
    final result = await SearchFilterSheet.show(
      context: context,
      initial: _filters,
      categories: widget.categories,
      types: widget.types,
      municipalities: widget.municipalities,
    );
    if (result != null) {
      setState(() => _filters = result);
      _runSearch();
    }
  }

  void _applyTypePreset(Types type) {
    setState(() {
      final ids = List<String>.from(_filters.typeIds);
      if (!ids.contains(type.id)) ids.add(type.id);
      _filters = _filters.copyWith(typeIds: ids);
    });
    _runSearch();
  }

  /// Header dinámico: si entras con una categoría/tipo prefiltrado desde
  /// home, lo muestra como título; si no, "Buscar".
  String _headerTitle() {
    if (widget.preSelectedCategories.length == 1) {
      return widget.preSelectedCategories.first.nombre.toUpperCase();
    }
    if (widget.preSelectedCategories.length > 1) {
      return '${widget.preSelectedCategories.length} CATEGORÍAS';
    }
    if (widget.preSelectedTypes.length == 1) {
      return widget.preSelectedTypes.first.nombre.toUpperCase();
    }
    if (widget.preSelectedTypes.length > 1) {
      return '${widget.preSelectedTypes.length} TIPOS';
    }
    return 'BUSCAR';
  }

  void _useRecent(String query) {
    _searchController.text = query;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );
    _addRecent(query);
    _runSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.brand.base,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              title: _headerTitle(),
              onBack: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
            _SearchRow(
              controller: _searchController,
              focusNode: _searchFocus,
              filterCount: _filters.count,
              onChanged: _onQueryChanged,
              onSubmitted: _onSubmitted,
              onClear: () {
                setState(() => _searchController.clear());
                _runSearch();
              },
              onFilter: _openFilterSheet,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isActive || _hasSearched
                  ? _ResultsView(
                      onResultTap: (r) {
                        _addRecent(_searchController.text);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                RestaurantDetailScreen(id: r.id),
                          ),
                        );
                      },
                      dishMatchIds: _dishMatchIds,
                      dishFirstMatchName: _dishFirstMatchName,
                      dishFirstVisitThumbnail: _dishFirstVisitThumbnail,
                      allVisits: _allVisits,
                      hasDishIndex: _hasDishIndex,
                    )
                  : _BrowseView(
                      recents: _recents,
                      types: widget.types,
                      onUseRecent: _useRecent,
                      onClearRecents: _clearRecents,
                      onPickType: _applyTypePreset,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  const _Header({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: context.brand.textPrimary,
            ),
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.displayHero(size: 26),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchRow extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final int filterCount;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final VoidCallback onFilter;

  const _SearchRow({
    required this.controller,
    required this.focusNode,
    required this.filterCount,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: context.brand.surface,
                border: Border.all(color: context.brand.borderStrong),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: AppColors.atlanticoClaro,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Semantics(
                      identifier: 'advanced-search-input',
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        onChanged: onChanged,
                        onSubmitted: onSubmitted,
                        textInputAction: TextInputAction.search,
                        style: AppTextStyles.ui(
                          size: 14,
                          color: context.brand.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Nombre, zona, plato…',
                          hintStyle: AppTextStyles.ui(
                            size: 14,
                            color: context.brand.textMuted,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                  if (controller.text.isNotEmpty)
                    GestureDetector(
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
                          child: Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: context.brand.textPrimary,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 12),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Semantics(
            identifier: 'advanced-search-filter-button',
            child: _FilterButton(count: filterCount, onTap: onFilter),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _FilterButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = count > 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: active
              ? AppColors.atlantico.withOpacity(0.18)
              : context.brand.surface,
          border: Border.all(
            color: active
                ? AppColors.atlantico.withOpacity(0.55)
                : context.brand.borderStrong,
            width: active ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 16,
              color: active
                  ? AppColors.atlanticoClaro
                  : context.brand.textPrimary,
            ),
            const SizedBox(width: 6),
            Text(
              'Filtrar',
              style: AppTextStyles.ui(
                size: 14,
                weight: FontWeight.w500,
                color: active
                    ? AppColors.atlanticoClaro
                    : context.brand.textPrimary,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.atlantico,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '$count',
                  style: AppTextStyles.ui(
                    size: 11,
                    weight: FontWeight.w700,
                    color: Colors.white,
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

class _ResultsView extends StatelessWidget {
  final ValueChanged<Restaurant> onResultTap;
  final Set<String> dishMatchIds;
  final Map<String, String> dishFirstMatchName;
  final Map<String, String> dishFirstVisitThumbnail;
  final List<Visit> allVisits;
  final bool hasDishIndex;

  const _ResultsView({
    required this.onResultTap,
    required this.dishMatchIds,
    required this.dishFirstMatchName,
    required this.dishFirstVisitThumbnail,
    required this.allVisits,
    required this.hasDishIndex,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RestaurantCubit, RestaurantState>(
      builder: (context, state) {
        if (state is RestaurantLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: AppColors.atlanticoClaro,
              strokeWidth: 2,
            ),
          );
        }
        if (state is! RestaurantFilterAdvanced) {
          return const SizedBox.shrink();
        }

        final serverList = state.restaurantFilterAdvanced;
        final serverIds = serverList.map((r) => r.id).toSet();

        // Build dish-only list (not already in server results), sorted by name.
        final dishOnlyRestaurants = <Restaurant>[];
        final seen = <String>{};
        for (final visit in allVisits) {
          final rid = visit.restaurantId;
          if (!dishMatchIds.contains(rid)) continue;
          if (serverIds.contains(rid)) continue;
          if (seen.contains(rid)) continue;
          if (visit.restaurant == null) continue;
          seen.add(rid);
          dishOnlyRestaurants.add(visit.restaurant!);
        }
        dishOnlyRestaurants.sort((a, b) => a.nombre.compareTo(b.nombre));

        final allItems = [...serverList, ...dishOnlyRestaurants];

        if (allItems.isEmpty) {
          return _EmptyResults(hasDishHint: hasDishIndex);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Semantics(
                identifier: 'advanced-search-result-count',
                child: Text(
                  '${allItems.length} resultado${allItems.length == 1 ? '' : 's'}',
                  style: AppTextStyles.muted(size: 12),
                ),
              ),
            ),
            Expanded(
              child: Semantics(
                identifier: 'advanced-search-results-list',
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: allItems.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    thickness: 1,
                    color: context.brand.border,
                  ),
                  itemBuilder: (_, i) {
                    final r = allItems[i];
                    final dishName = dishFirstMatchName[r.id];
                    // Si el restaurante no trae mainFoto (típico de los
                    // matches por plato — vienen de visita embebida sin
                    // fotos) usamos el thumbnail del vídeo como fallback.
                    final photoOverride = r.mainFoto.isEmpty
                        ? dishFirstVisitThumbnail[r.id]
                        : null;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SearchResultCard(
                          restaurant: r,
                          photoUrlOverride: photoOverride,
                          onTap: () => onResultTap(r),
                        ),
                        if (dishName != null)
                          Semantics(
                            identifier: 'advanced-search-dish-chip-${r.id}',
                            child: _DishChip(dishName: dishName),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyResults extends StatelessWidget {
  final bool hasDishHint;

  const _EmptyResults({this.hasDishHint = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: context.brand.textMuted,
          ),
          const SizedBox(height: 14),
          Text(
            'Sin resultados',
            style: AppTextStyles.displaySection(size: 14),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Prueba con otra búsqueda o ajusta los filtros.',
              textAlign: TextAlign.center,
              style: AppTextStyles.muted(size: 12),
            ),
          ),
          if (hasDishHint) ...[
            const SizedBox(height: 12),
            Semantics(
              identifier: 'advanced-search-empty-dish-hint',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Prueba: carne de cabra, papas arrugadas, gofio…',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.muted(size: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DishChip extends StatelessWidget {
  final String dishName;

  const _DishChip({required this.dishName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.atlantico.withValues(alpha: 0.12),
          border: Border.all(color: AppColors.atlantico.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          '🍽 «$dishName»',
          style: AppTextStyles.chipLabel(
            size: 11,
            color: AppColors.atlanticoClaro,
          ),
        ),
      ),
    );
  }
}

class _BrowseView extends StatelessWidget {
  final List<String> recents;
  final List<Types> types;
  final ValueChanged<String> onUseRecent;
  final VoidCallback onClearRecents;
  final ValueChanged<Types> onPickType;

  const _BrowseView({
    required this.recents,
    required this.types,
    required this.onUseRecent,
    required this.onClearRecents,
    required this.onPickType,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recents.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'BÚSQUEDAS RECIENTES',
                    style: AppTextStyles.eyebrow(
                      size: 11,
                      color: AppColors.atlanticoClaro,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onClearRecents,
                  child: Text(
                    'Borrar',
                    style: AppTextStyles.ui(
                      size: 12,
                      weight: FontWeight.w500,
                      color: context.brand.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final r in recents)
              _RecentRow(text: r, onTap: () => onUseRecent(r)),
            const SizedBox(height: 18),
          ],
          if (types.isNotEmpty) ...[
            Text(
              'EXPLORAR POR TIPO',
              style: AppTextStyles.eyebrow(
                size: 11,
                color: AppColors.atlanticoClaro,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.7,
              ),
              itemCount: types.length,
              itemBuilder: (_, i) => _TypeTile(
                type: types[i],
                onTap: () => onPickType(types[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _RecentRow({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.history_rounded,
              size: 16,
              color: context.brand.textMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.ui(
                  size: 14,
                  color: context.brand.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.north_west_rounded,
              size: 14,
              color: context.brand.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeTile extends StatelessWidget {
  final Types type;
  final VoidCallback onTap;

  const _TypeTile({required this.type, required this.onTap});

  static const _palette = <List<Color>>[
    [AppColors.tierra, Color(0xFF3D1500)],
    [AppColors.atlantico, AppColors.profundo],
    [AppColors.sol, Color(0xFF7A5800)],
    [AppColors.mojo, Color(0xFF8B2E0E)],
    [AppColors.laurisilva, Color(0xFF064B36)],
    [AppColors.arena, Color(0xFF6B4F22)],
  ];

  List<Color> get _gradient {
    if (type.id.isEmpty) return _palette.first;
    final hash = type.id.codeUnits.fold<int>(0, (acc, c) => acc + c);
    return _palette[hash % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _gradient,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(14),
        alignment: Alignment.bottomLeft,
        child: Text(
          type.nombre.toUpperCase(),
          style: AppTextStyles.displaySection(
            size: 14,
            color: Colors.white,
          ).copyWith(
            shadows: const [
              Shadow(blurRadius: 8, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }
}
