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
    this.preSelectedCategories =
        const [], // Valor predeterminado como lista vacía
  });

  @override
  State<AdvancedSearch> createState() => _AdvancedSearchState();
}

class _AdvancedSearchState extends State<AdvancedSearch>
    implements AdvancedSearchView {
  final TextEditingController _searchController = TextEditingController();
  List<Restaurant> _restaurants = [];
  List<Restaurant> _filteredRestaurants = [];

  // Lists to store selected IDs
  List<String> _selectedCategoryIds = [];
  List<String> _selectedTypeIds = [];
  List<String> selectedMunicipalities = [];
  late RestaurantCubit restaurantsCubit;
  late FilterCubit filterCubit;
  List<SimpleMunicipality> municipalitiesFilter = [];

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

  @override
  void initState() {
    super.initState();
    restaurantsCubit = context.read<RestaurantCubit>();
    filterCubit = context.read<FilterCubit>();
    if(widget.preSelectedCategories.length>0){
      _selectedCategoryIds.add(widget.preSelectedCategories[0].id);
      restaurantsCubit.getFilterRestaurantsAdvance(
        categories: _selectedCategoryIds,
        municipalities: selectedMunicipalities,
        text: _searchController.text,
        types: _selectedTypeIds,
        islandId: widget.islandId,
      );
    }
  }

  void _filterRestaurants(String query) {
    restaurantsCubit.getFilterRestaurantsAdvance(
      categories: _selectedCategoryIds,
      municipalities: selectedMunicipalities,
      text: query,
      types: _selectedTypeIds,
      islandId: widget.islandId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leadingWidth: 32,
        title: Container(
          height: 36,
          width: MediaQuery.of(context).size.width * 0.9,
          decoration: BoxDecoration(
            color: GlobalMethods.bgColorFilter,
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10.0,
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 16.0),
              const Icon(Icons.search, color: Colors.grey),
              const SizedBox(width: 8.0),
              Expanded(
                child: TextField(
                  controller: _searchController,

                  onChanged: _filterRestaurants,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                    fontFamily: 'SF Pro Display',
                  ),
                  decoration: const InputDecoration(
                    hintText: "Busca donde comer",
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              GestureDetector(
                onTap: () {
                  showCategoryFilterModal(context);
                },
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10.0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'assets/images/line.3.horizontal.decrease.circle.svg',
                          width: 16,
                          height: 16,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "Filtrar",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16.0,
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSelectedChips(),
            BlocBuilder<RestaurantCubit, RestaurantState>(
              builder: (context, state) {
                if (state is RestaurantLoading) {
                  // Mostrar un spinner mientras carga
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                } else if (state is RestaurantFilterAdvanced) {
                  if (state.restaurantFilterAdvanced.isEmpty) {
                    // Mostrar mensaje cuando no haya resultados
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          "Introduce filtros para buscar restaurantes",
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.grey,
                            fontFamily: 'SF Pro Display',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  } else {
                    // Mostrar la lista de restaurantes
                    return Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 8),
                      child: ListView.builder(
                        shrinkWrap: true,
                        primary: false,
                        itemCount: state.restaurantFilterAdvanced.length,
                        itemBuilder: (context, index) {
                          return RestaurantListCard(
                            state.restaurantFilterAdvanced[index],
                          );
                        },
                      ),
                    );
                  }
                } else {
                  // Estado inicial o vacío
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        "Introduce filtros para buscar restaurantes",
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.grey,
                          fontFamily: 'SF Pro Display',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
              },
            ),
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
  void _toggleMunicipalitySelection(String municipalityId) {
    setState(() {
      if (selectedMunicipalities.contains(municipalityId)) {
        selectedMunicipalities.remove(municipalityId);
      } else {
        selectedMunicipalities.add(municipalityId);
      }
    });
  }

  void showCategoryFilterModal(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.9,
                color: GlobalMethods.bgColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        color: GlobalMethods.bgColor,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(12.0)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  "Cancelar",
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 16.0,
                                    fontFamily: "SF Pro Display",
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.center,
                              child: Text(
                                "Filtros",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: "SF Pro Display",
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () {
                                  restaurantsCubit.getFilterRestaurantsAdvance(
                                    categories: _selectedCategoryIds,
                                    municipalities: selectedMunicipalities,
                                    text: _searchController.text,
                                    types: _selectedTypeIds,
                                    islandId: widget.islandId,
                                  );
                                  Navigator.pop(context);

                                },
                                child: Text(
                                  "OK",
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontFamily: "SF Pro Display",
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Estado
                              Text(
                                "Estado",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: "SF Pro Display",
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Chip(
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                      color: GlobalMethods.bgColorFilter),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                backgroundColor: GlobalMethods.bgColorFilter,
                                label: Padding(
                                  padding: const EdgeInsets.only(bottom: 3),
                                  child: Text(
                                    'Abierto',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                      fontFamily: "SF Pro Display",
                                    ),
                                  ),
                                ),
                              ),
                              // Zona
                              Text(
                                "Zona",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: "SF Pro Display",
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    ...selectedMunicipalities.map((id) {
                                      final municipality = widget.municipalities
                                          .expand(
                                              (group) => group.municipalities)
                                          .firstWhere((m) => m.id == id);

                                      return municipality != null
                                          ? GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _toggleMunicipalitySelection(
                                                      municipality.id);
                                                });
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 8.0),
                                                child: Chip(
                                                  label: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.close,
                                                        size: 16,
                                                        color: Colors.white,
                                                      ),
                                                      Text(
                                                        municipality.nombre,
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 14,
                                                          fontFamily:
                                                              "SF Pro Display",
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                    ],
                                                  ),
                                                  backgroundColor: Colors.blue,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : SizedBox();
                                    }).toList(),

                                    // Chip para añadir más municipios
                                    GestureDetector(
                                      onTap: () => {
                                        showMunicipalityFilterModal(context,setState)
                                      },
                                      child: Chip(
                                        shape: RoundedRectangleBorder(
                                          side: BorderSide(
                                              color:
                                                  GlobalMethods.bgColorFilter),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        backgroundColor:
                                            GlobalMethods.bgColorFilter,
                                        label: Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 3),
                                          child: Text(
                                            'Añadir más',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 16,
                                              fontFamily: "SF Pro Display",
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Categorías
                              Text(
                                "Categorías",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: "SF Pro Display",
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                height: 264,
                                child: GridView.builder(
                                  scrollDirection: Axis.horizontal,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 5,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 10,
                                    childAspectRatio: 0.20,
                                  ),
                                  itemCount: widget.categories.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    final category = widget.categories[index];
                                    final isSelected = _selectedCategoryIds
                                        .contains(category.id);

                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _toggleCategorySelection(category.id);
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.blue
                                              : GlobalMethods.bgColorFilter,
                                          border: Border.all(
                                              color:
                                                  GlobalMethods.bgColorFilter),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4, horizontal: 6),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: Colors.white,
                                              child: SvgPicture.network(
                                                category.iconUrl,
                                                height: 24,
                                              ),
                                            ),
                                            Flexible(
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 8.0),
                                                child: Text(
                                                  category.nombre,
                                                  style: TextStyle(
                                                    color: isSelected
                                                        ? Colors.white
                                                        : Colors.grey,
                                                    fontSize: 14,
                                                    fontFamily:
                                                        "SF Pro Display",
                                                  ),
                                                  textAlign: TextAlign.left,
                                                  overflow:
                                                      TextOverflow.visible,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              // Tipos
                              Text(
                                "Tipos",
                                style: TextStyle(
                                  fontFamily: "SF Pro Display",
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                height: 264,
                                child: GridView.builder(
                                  scrollDirection: Axis.horizontal,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 6,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 4,
                                    childAspectRatio: 0.20,
                                  ),
                                  itemCount: widget.types.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    final types = widget.types[index];
                                    final isSelected =
                                        _selectedTypeIds.contains(types.id);

                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _toggleTypeSelection(types.id);
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.blue
                                              : GlobalMethods.bgColorFilter,
                                          border: Border.all(
                                              color:
                                                  GlobalMethods.bgColorFilter),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 2, horizontal: 6),
                                        child: Center(
                                          child: Text(
                                            types.nombre,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.grey,
                                              fontSize: 14,
                                              fontFamily: "SF Pro Display",
                                            ),
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
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

  void showMunicipalityFilterModal(BuildContext context,StateSetter outSetState) {
    TextEditingController _textController = TextEditingController();

    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {

          return ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.9,
              color: GlobalMethods.bgColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(height: 8),
                  Center(
                    child: Container(
                      height: 2,
                      color: Color.fromRGBO(231, 231, 231, 1),
                      width: 64,
                    ),
                  ),
                  SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Container(
                      height: 36,
                      width: MediaQuery.of(context).size.width * 0.9,
                      decoration: BoxDecoration(
                        color: GlobalMethods.bgColorFilter,
                        borderRadius: BorderRadius.circular(20.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10.0,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16.0),
                          const Icon(Icons.search, color: Colors.grey),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: TextField(
                              onChanged: (text) {
                                List<SimpleMunicipality>
                                    auxMunicipalitiesFilter = [];
                                for (var municipalityGroup
                                    in widget.municipalities) {
                                  for (var municipality
                                      in municipalityGroup.municipalities) {
                                    if (municipality.nombre
                                        .toLowerCase()
                                        .contains(text.toLowerCase())) {
                                      auxMunicipalitiesFilter.add(municipality);
                                    }
                                  }
                                }
                                setState(() {
                                  municipalitiesFilter =
                                      auxMunicipalitiesFilter;
                                });
                              },
                              controller: _textController,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16.0,
                                fontFamily: 'SF Pro Display',
                              ),
                              decoration: const InputDecoration(
                                hintText: "Busca donde comer",
                                hintStyle: TextStyle(color: Colors.grey),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _textController.text.isNotEmpty
                          ? municipalitiesFilter.length
                          : widget.municipalities.length,
                      itemBuilder: (context, index) {
                        if (_textController.text.isNotEmpty) {
                          // Mostrar municipios filtrados
                          SimpleMunicipality municipality =
                              municipalitiesFilter[index];
                          bool isCheck =
                              selectedMunicipalities.contains(municipality.id);
                          return _buildMunicipalityItem(
                              municipality, isCheck, setState,setState);
                        } else {
                          // Mostrar grupos de municipios completos
                          var municipalityGroup = widget.municipalities[index];
                          return Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Container(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    municipalityGroup.nombre,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'SF Pro Display',
                                    ),
                                  ),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    primary: false,
                                    physics: ClampingScrollPhysics(),
                                    itemCount:
                                        municipalityGroup.municipalities.length,
                                    itemBuilder: (context, index2) {
                                      SimpleMunicipality municipality =
                                          municipalityGroup
                                              .municipalities[index2];
                                      bool isCheck = selectedMunicipalities
                                          .contains(municipality.id);
                                      return _buildMunicipalityItem(
                                          municipality, isCheck, outSetState,setState);
                                    },
                                  ),
                                  Divider(thickness: 0.1),
                                ],
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  Divider(thickness: 0.2),
                  _buildActionButtons(context),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildMunicipalityItem(
      SimpleMunicipality municipality, bool isCheck, StateSetter outSetState,StateSetter setState) {
    return GestureDetector(
      onTap: () {
        outSetState((){
          setState(() {
            _toggleMunicipalitySelection(municipality.id);
          });
        });
      },
      child: Chip(
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: isCheck ? Colors.blue : GlobalMethods.bgColorFilter,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: isCheck ? Colors.blue : GlobalMethods.bgColorFilter,
        label: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                municipality.nombre,
                key: Key(municipality.id),
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 14,
                  color: isCheck ? Colors.white : Colors.white,
                  fontWeight: isCheck ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            isCheck
                ? Icon(Icons.check, color: Color.fromRGBO(231, 231, 231, 1))
                : Container(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Center(
      child: Column(
        children: [
          SizedBox(height: 12),
          Container(
            width: MediaQuery.of(context).size.width * 0.86,
            child: ElevatedButton(
              onPressed: () =>{

                Navigator.pop(context),
              },
              style: ButtonStyle(
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                minimumSize: MaterialStateProperty.all(Size.fromHeight(48)),
                backgroundColor:
                    MaterialStateProperty.all(Color.fromRGBO(0, 133, 196, 1)),
              ),
              child: Text(
                "Ver resultados",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'SF Pro Display',
                  fontSize: 16.0,
                ),
              ),
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.86,
            child: TextButton(
              onPressed: () => {Navigator.pop(context)},
              style: ButtonStyle(
                elevation: MaterialStateProperty.all(0),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                minimumSize: MaterialStateProperty.all(Size.fromHeight(48)),
              ),
              child: Text(
                "Descartar",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SF Pro Display',
                  color: Color.fromRGBO(97, 97, 97, 1),
                  fontSize: 16.0,
                ),
              ),
            ),
          ),
          SizedBox(height: 12),
        ],
      ),
    );
  }
  // Builds the selected filter chips
  Widget _buildSelectedChips() {
    List<Widget> chips = [];

    // Add selected categories as chips
    chips.addAll(
      _selectedCategoryIds.map(
            (id) {
          final category = widget.categories.firstWhere((c) => c.id == id);
          return _buildChip(category.nombre, () {
            setState(() {
              _toggleCategorySelection(id);
            });
            restaurantsCubit.getFilterRestaurantsAdvance(
              categories: _selectedCategoryIds,
              municipalities: selectedMunicipalities,
              text: _searchController.text,
              types: _selectedTypeIds,
              islandId: widget.islandId,
            );
          });
        },
      ),
    );

    // Add selected types as chips
    chips.addAll(
      _selectedTypeIds.map(
            (id) {
          final type = widget.types.firstWhere((t) => t.id == id);
          return _buildChip(type.nombre, () {
            setState(() {
              _toggleTypeSelection(id);
              restaurantsCubit.getFilterRestaurantsAdvance(
                categories: _selectedCategoryIds,
                municipalities: selectedMunicipalities,
                text: _searchController.text,
                types: _selectedTypeIds,
                islandId: widget.islandId,
              );
            });
          });
        },
      ),
    );




    return chips.isNotEmpty
        ? Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        children: chips,
      ),
    )
        : const SizedBox.shrink();
  }

// Builds a single chip
  Widget _buildChip(String label, VoidCallback onDeleted) {
    return Chip(
      label: Text(label),
      onDeleted: onDeleted,
      backgroundColor: Colors.blue.shade100,
      deleteIcon: const Icon(Icons.close, size: 16),
    );
  }

}
