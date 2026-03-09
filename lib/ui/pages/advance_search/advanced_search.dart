import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:guachinches/data/cubit/filter/filter_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_state.dart';
import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/data/model/Municipality.dart';
import 'package:guachinches/data/model/SimpleMunicipality.dart';
import 'package:guachinches/data/model/Types.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/components/cards/restaurantListCard.dart';
import 'package:guachinches/ui/pages/advance_search/advanced_search_presenter.dart';
import '../../../globalMethods.dart';

class AdvancedSearch extends StatefulWidget {
  final List<ModelCategory> categories;
  final List<Municipality> municipalities;
  final List<Types> types;
  final String islandId;
  final List<ModelCategory> preSelectedCategories;

  AdvancedSearch({
    required this.categories,
    required this.municipalities,
    required this.types,
    required this.islandId,
    this.preSelectedCategories = const [],
  });

  @override
  State<AdvancedSearch> createState() => _AdvancedSearchState();
}

class _AdvancedSearchState extends State<AdvancedSearch>
    implements AdvancedSearchView {
  final TextEditingController _searchController = TextEditingController();
  List<Restaurant> _restaurants = [];
  List<Restaurant> _filteredRestaurants = [];

  List<String> _selectedCategoryIds = [];
  List<String> _selectedTypeIds = [];
  List<String> selectedMunicipalities = [];
  bool _filterOpenOnly = false;
  late RestaurantCubit restaurantsCubit;
  late FilterCubit filterCubit;
  List<SimpleMunicipality> municipalitiesFilter = [];

  int get _activeFilterCount =>
      _selectedCategoryIds.length +
      _selectedTypeIds.length +
      selectedMunicipalities.length +
      (_filterOpenOnly ? 1 : 0);

  bool get _hasActiveFilters => _activeFilterCount > 0;

  void _toggleCategorySelection(String categoryId) {
    setState(() {
      if (_selectedCategoryIds.contains(categoryId)) {
        _selectedCategoryIds.remove(categoryId);
      } else {
        _selectedCategoryIds.add(categoryId);
      }
    });
  }

  void _toggleTypeSelection(String typeId) {
    setState(() {
      if (_selectedTypeIds.contains(typeId)) {
        _selectedTypeIds.remove(typeId);
      } else {
        _selectedTypeIds.add(typeId);
      }
    });
  }

  void _toggleMunicipalitySelection(String municipalityId) {
    setState(() {
      if (selectedMunicipalities.contains(municipalityId)) {
        selectedMunicipalities.remove(municipalityId);
      } else {
        selectedMunicipalities.add(municipalityId);
      }
    });
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategoryIds.clear();
      _selectedTypeIds.clear();
      selectedMunicipalities.clear();
      _filterOpenOnly = false;
      _searchController.clear();
    });
    restaurantsCubit.getFilterRestaurantsAdvance(
      categories: [],
      municipalities: [],
      text: '',
      types: [],
      islandId: widget.islandId,
      isOpen: false,
    );
  }

  @override
  void initState() {
    super.initState();
    restaurantsCubit = context.read<RestaurantCubit>();
    filterCubit = context.read<FilterCubit>();
    if (widget.preSelectedCategories.isNotEmpty) {
      _selectedCategoryIds.add(widget.preSelectedCategories[0].id);
      restaurantsCubit.getFilterRestaurantsAdvance(
        categories: _selectedCategoryIds,
        municipalities: selectedMunicipalities,
        text: _searchController.text,
        types: _selectedTypeIds,
        islandId: widget.islandId,
        isOpen: _filterOpenOnly,
      );
    }
  }

  void _applyFilters() {
    restaurantsCubit.getFilterRestaurantsAdvance(
      categories: _selectedCategoryIds,
      municipalities: selectedMunicipalities,
      text: _searchController.text,
      types: _selectedTypeIds,
      islandId: widget.islandId,
      isOpen: _filterOpenOnly,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalMethods.bgColor,
      appBar: _buildAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(),
          if (_hasActiveFilters) _buildActiveFilterChips(),
          Expanded(
            child: BlocBuilder<RestaurantCubit, RestaurantState>(
              builder: (context, state) {
                if (state is RestaurantLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: GlobalMethods.blueColor,
                      strokeWidth: 2,
                    ),
                  );
                } else if (state is RestaurantFilterAdvanced) {
                  if (state.restaurantFilterAdvanced.isEmpty) {
                    return _buildEmptyState();
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Text(
                            '${state.restaurantFilterAdvanced.length} resultado${state.restaurantFilterAdvanced.length != 1 ? 's' : ''}',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                              fontFamily: 'SF Pro Display',
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: state.restaurantFilterAdvanced.length,
                            itemBuilder: (context, index) {
                              return RestaurantListCard(
                                state.restaurantFilterAdvanced[index],
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }
                } else {
                  return _buildInitialState();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: GlobalMethods.bgColor,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Buscar',
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'SF Pro Display',
          fontWeight: FontWeight.w600,
          fontSize: 17,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () => showCategoryFilterModal(context),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _hasActiveFilters
                        ? GlobalMethods.blueColor
                        : GlobalMethods.bgColorFilter,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                if (_activeFilterCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Center(
                        child: Text(
                          '$_activeFilterCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: GlobalMethods.bgColorFilter,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Icon(Icons.search_rounded, color: Colors.grey.shade600, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (query) {
                  setState(() {});
                  restaurantsCubit.getFilterRestaurantsAdvance(
                    categories: _selectedCategoryIds,
                    municipalities: selectedMunicipalities,
                    text: query,
                    types: _selectedTypeIds,
                    islandId: widget.islandId,
                    isOpen: _filterOpenOnly,
                  );
                },
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontFamily: 'SF Pro Display',
                ),
                decoration: InputDecoration(
                  hintText: 'Restaurantes, guachinches...',
                  hintStyle:
                      TextStyle(color: Colors.grey.shade600, fontSize: 15),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _searchController.text.isNotEmpty
                  ? GestureDetector(
                      key: const ValueKey('clear'),
                      onTap: () {
                        setState(() => _searchController.clear());
                        restaurantsCubit.getFilterRestaurantsAdvance(
                          categories: _selectedCategoryIds,
                          municipalities: selectedMunicipalities,
                          text: '',
                          types: _selectedTypeIds,
                          islandId: widget.islandId,
                          isOpen: _filterOpenOnly,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: Icon(Icons.cancel_rounded,
                            color: Colors.grey.shade600, size: 18),
                      ),
                    )
                  : const SizedBox(key: ValueKey('empty'), width: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          // Limpiar todo
          GestureDetector(
            onTap: _clearAllFilters,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(
                    color: Colors.red.shade700.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.close, size: 14, color: Colors.red.shade400),
                  const SizedBox(width: 4),
                  Text(
                    'Limpiar',
                    style: TextStyle(
                      color: Colors.red.shade400,
                      fontSize: 13,
                      fontFamily: 'SF Pro Display',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Abierto ahora
          if (_filterOpenOnly)
            _buildActiveChip('Abierto ahora', () {
              setState(() => _filterOpenOnly = false);
              _applyFilters();
            }),
          // Categorías seleccionadas
          ..._selectedCategoryIds.map((id) {
            final cat = widget.categories.firstWhere((c) => c.id == id);
            return _buildActiveChip(cat.nombre, () {
              _toggleCategorySelection(id);
              _applyFilters();
            });
          }),
          // Tipos seleccionados
          ..._selectedTypeIds.map((id) {
            final type = widget.types.firstWhere((t) => t.id == id);
            return _buildActiveChip(type.nombre, () {
              _toggleTypeSelection(id);
              _applyFilters();
            });
          }),
          // Municipios seleccionados
          ...selectedMunicipalities.map((id) {
            final muni = widget.municipalities
                .expand((g) => g.municipalities)
                .firstWhere((m) => m.id == id);
            return _buildActiveChip(muni.nombre, () {
              _toggleMunicipalitySelection(id);
              _applyFilters();
            });
          }),
        ],
      ),
    );
  }

  Widget _buildActiveChip(String label, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
        decoration: BoxDecoration(
          color: GlobalMethods.blueColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: GlobalMethods.blueColor.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: GlobalMethods.blueColor,
                fontSize: 13,
                fontFamily: 'SF Pro Display',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onRemove,
              child: Icon(Icons.close,
                  size: 14, color: GlobalMethods.blueColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.restaurant_menu_rounded,
              size: 72,
              color: Colors.grey.shade800,
            ),
            const SizedBox(height: 20),
            const Text(
              'Encuentra tu sitio',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontFamily: 'SF Pro Display',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Escribe un nombre o usa los filtros para encontrar el restaurante perfecto',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
                fontFamily: 'SF Pro Display',
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => showCategoryFilterModal(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: GlobalMethods.blueColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.tune_rounded,
                        color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Abrir filtros',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'SF Pro Display',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 72,
              color: Colors.grey.shade800,
            ),
            const SizedBox(height: 20),
            const Text(
              'Sin resultados',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontFamily: 'SF Pro Display',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Prueba con otros filtros o busca por un nombre diferente',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
                fontFamily: 'SF Pro Display',
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (_hasActiveFilters) ...[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _clearAllFilters,
                child: Text(
                  'Limpiar filtros',
                  style: TextStyle(
                    color: GlobalMethods.blueColor,
                    fontFamily: 'SF Pro Display',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void setRestaurants(List<Restaurant> restaurants) {
    setState(() {
      _restaurants = restaurants;
      _filteredRestaurants = restaurants;
    });
  }

  // ─── Filter Modal ───────────────────────────────────────────────────────────

  void showCategoryFilterModal(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.92,
                color: GlobalMethods.bgColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 4),
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade700,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              modalSetState(() {
                                _selectedCategoryIds.clear();
                                _selectedTypeIds.clear();
                                selectedMunicipalities.clear();
                                _filterOpenOnly = false;
                              });
                              setState(() {});
                            },
                            child: Text(
                              'Limpiar todo',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 15,
                                fontFamily: 'SF Pro Display',
                              ),
                            ),
                          ),
                          const Text(
                            'Filtros',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'SF Pro Display',
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              _applyFilters();
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Aplicar',
                              style: TextStyle(
                                color: GlobalMethods.blueColor,
                                fontSize: 15,
                                fontFamily: 'SF Pro Display',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                        color: Colors.grey.shade800,
                        height: 1,
                        thickness: 1),
                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Estado ────────────────────────────────────
                            _buildSectionHeader('Estado'),
                            const SizedBox(height: 12),
                            _buildFilterChip(
                              label: 'Abierto ahora',
                              isSelected: _filterOpenOnly,
                              icon: Icons.access_time_rounded,
                              onTap: () {
                                modalSetState(() {
                                  setState(() {
                                    _filterOpenOnly = !_filterOpenOnly;
                                  });
                                });
                              },
                            ),
                            const SizedBox(height: 24),
                            Divider(
                                color: Colors.grey.shade800,
                                height: 1,
                                thickness: 1),
                            const SizedBox(height: 24),

                            // ── Zona ──────────────────────────────────────
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _buildSectionHeader('Zona'),
                                if (selectedMunicipalities.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      modalSetState(() {
                                        selectedMunicipalities.clear();
                                      });
                                      setState(() {});
                                    },
                                    child: Text(
                                      'Quitar todas',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 13,
                                        fontFamily: 'SF Pro Display',
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ...selectedMunicipalities.map((id) {
                                  final muni = widget.municipalities
                                      .expand((g) => g.municipalities)
                                      .firstWhere((m) => m.id == id);
                                  return GestureDetector(
                                    onTap: () {
                                      modalSetState(() {
                                        _toggleMunicipalitySelection(id);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.fromLTRB(
                                          10, 8, 10, 8),
                                      decoration: BoxDecoration(
                                        color: GlobalMethods.blueColor,
                                        borderRadius:
                                            BorderRadius.circular(22),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                              Icons.location_on_rounded,
                                              size: 14,
                                              color: Colors.white),
                                          const SizedBox(width: 4),
                                          Text(
                                            muni.nombre,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontFamily: 'SF Pro Display',
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(Icons.close,
                                              size: 14, color: Colors.white),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                                GestureDetector(
                                  onTap: () => showMunicipalityFilterModal(
                                      context, modalSetState),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius:
                                          BorderRadius.circular(22),
                                      border: Border.all(
                                          color: Colors.grey.shade700),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.add_rounded,
                                            size: 16,
                                            color: Colors.grey.shade400),
                                        const SizedBox(width: 4),
                                        Text(
                                          selectedMunicipalities.isEmpty
                                              ? 'Seleccionar zona'
                                              : 'Añadir más',
                                          style: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontSize: 14,
                                            fontFamily: 'SF Pro Display',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Divider(
                                color: Colors.grey.shade800,
                                height: 1,
                                thickness: 1),
                            const SizedBox(height: 24),

                            // ── Categorías ────────────────────────────────
                            _buildSectionHeader('Categorías'),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: widget.categories.map((category) {
                                final isSelected = _selectedCategoryIds
                                    .contains(category.id);
                                return GestureDetector(
                                  onTap: () {
                                    modalSetState(() {
                                      _toggleCategorySelection(category.id);
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.fromLTRB(
                                        10, 8, 12, 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? GlobalMethods.blueColor
                                          : GlobalMethods.bgColorFilter,
                                      borderRadius:
                                          BorderRadius.circular(22),
                                      border: Border.all(
                                        color: isSelected
                                            ? GlobalMethods.blueColor
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor: Colors.white,
                                          child: SvgPicture.network(
                                            category.iconUrl,
                                            width: 14,
                                            height: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          category.nombre,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.grey.shade400,
                                            fontSize: 14,
                                            fontFamily: 'SF Pro Display',
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        if (isSelected) ...[
                                          const SizedBox(width: 6),
                                          const Icon(
                                              Icons.check_circle_rounded,
                                              size: 15,
                                              color: Colors.white),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),
                            Divider(
                                color: Colors.grey.shade800,
                                height: 1,
                                thickness: 1),
                            const SizedBox(height: 24),

                            // ── Tipos ─────────────────────────────────────
                            _buildSectionHeader('Tipo de establecimiento'),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: widget.types.map((type) {
                                final isSelected =
                                    _selectedTypeIds.contains(type.id);
                                return GestureDetector(
                                  onTap: () {
                                    modalSetState(() {
                                      _toggleTypeSelection(type.id);
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 9),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? GlobalMethods.blueColor
                                          : GlobalMethods.bgColorFilter,
                                      borderRadius:
                                          BorderRadius.circular(22),
                                      border: Border.all(
                                        color: isSelected
                                            ? GlobalMethods.blueColor
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          type.nombre,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.grey.shade400,
                                            fontSize: 14,
                                            fontFamily: 'SF Pro Display',
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        if (isSelected) ...[
                                          const SizedBox(width: 6),
                                          const Icon(
                                              Icons.check_circle_rounded,
                                              size: 15,
                                              color: Colors.white),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),

                    // Bottom button
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      decoration: BoxDecoration(
                        color: GlobalMethods.bgColor,
                        border: Border(
                            top: BorderSide(
                                color: Colors.grey.shade800, width: 1)),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            _applyFilters();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GlobalMethods.blueColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            _activeFilterCount > 0
                                ? 'Ver resultados · $_activeFilterCount filtro${_activeFilterCount != 1 ? 's' : ''}'
                                : 'Ver resultados',
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'SF Pro Display',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontFamily: 'SF Pro Display',
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? GlobalMethods.blueColor
              : GlobalMethods.bgColorFilter,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color:
                isSelected ? GlobalMethods.blueColor : Colors.grey.shade700,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 16,
                  color:
                      isSelected ? Colors.white : Colors.grey.shade400),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected ? Colors.white : Colors.grey.shade400,
                fontSize: 14,
                fontFamily: 'SF Pro Display',
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Municipality Modal ─────────────────────────────────────────────────────

  void showMunicipalityFilterModal(
      BuildContext context, StateSetter outerSetState) {
    final TextEditingController muniController = TextEditingController();
    municipalitiesFilter = [];

    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.9,
                color: GlobalMethods.bgColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Padding(
                        padding:
                            const EdgeInsets.only(top: 12, bottom: 4),
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade700,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              'Cancelar',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 15,
                                fontFamily: 'SF Pro Display',
                              ),
                            ),
                          ),
                          const Text(
                            'Seleccionar zona',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'SF Pro Display',
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              'Listo',
                              style: TextStyle(
                                color: GlobalMethods.blueColor,
                                fontSize: 15,
                                fontFamily: 'SF Pro Display',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Search
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: GlobalMethods.bgColorFilter,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            Icon(Icons.search_rounded,
                                color: Colors.grey.shade600, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: muniController,
                                onChanged: (text) {
                                  final filtered = <SimpleMunicipality>[];
                                  for (final group
                                      in widget.municipalities) {
                                    for (final m in group.municipalities) {
                                      if (m.nombre
                                          .toLowerCase()
                                          .contains(text.toLowerCase())) {
                                        filtered.add(m);
                                      }
                                    }
                                  }
                                  modalSetState(() {
                                    municipalitiesFilter = filtered;
                                  });
                                },
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontFamily: 'SF Pro Display',
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Busca por zona o municipio...',
                                  hintStyle: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 15),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(
                        color: Colors.grey.shade800,
                        height: 1,
                        thickness: 1),
                    Expanded(
                      child: ListView.builder(
                        itemCount: muniController.text.isNotEmpty
                            ? municipalitiesFilter.length
                            : widget.municipalities.length,
                        itemBuilder: (context, index) {
                          if (muniController.text.isNotEmpty) {
                            final m = municipalitiesFilter[index];
                            final isChecked =
                                selectedMunicipalities.contains(m.id);
                            return _buildMunicipalityTile(
                                m, isChecked, outerSetState, modalSetState);
                          } else {
                            final group = widget.municipalities[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      20, 16, 20, 6),
                                  child: Text(
                                    group.nombre.toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 11,
                                      fontFamily: 'SF Pro Display',
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                ...group.municipalities.map((m) {
                                  final isChecked = selectedMunicipalities
                                      .contains(m.id);
                                  return _buildMunicipalityTile(m,
                                      isChecked, outerSetState, modalSetState);
                                }),
                                Divider(
                                    color: Colors.grey.shade800,
                                    height: 1,
                                    thickness: 1),
                              ],
                            );
                          }
                        },
                      ),
                    ),
                    // Bottom button
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      decoration: BoxDecoration(
                        color: GlobalMethods.bgColor,
                        border: Border(
                            top: BorderSide(
                                color: Colors.grey.shade800, width: 1)),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GlobalMethods.blueColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            selectedMunicipalities.isEmpty
                                ? 'Confirmar'
                                : 'Confirmar (${selectedMunicipalities.length})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'SF Pro Display',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMunicipalityTile(
    SimpleMunicipality municipality,
    bool isChecked,
    StateSetter outerSetState,
    StateSetter modalSetState,
  ) {
    return InkWell(
      onTap: () {
        outerSetState(() {
          modalSetState(() {
            _toggleMunicipalitySelection(municipality.id);
          });
        });
      },
      splashColor: GlobalMethods.blueColor.withOpacity(0.08),
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                municipality.nombre,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'SF Pro Display',
                  fontSize: 15,
                  fontWeight:
                      isChecked ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isChecked
                    ? GlobalMethods.blueColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isChecked
                      ? GlobalMethods.blueColor
                      : Colors.grey.shade600,
                  width: 2,
                ),
              ),
              child: isChecked
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
