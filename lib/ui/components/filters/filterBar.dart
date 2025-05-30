import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:guachinches/data/cubit/filter/filter_cubit.dart';
import 'package:guachinches/data/cubit/filter/filter_state.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/map/restaurant_map_cubit.dart';
import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/data/model/Municipality.dart';
import 'package:guachinches/data/model/SimpleMunicipality.dart';
import 'package:guachinches/data/model/Types.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/pages/map/search_text.dart';

class FilterBar extends StatefulWidget {
  final bool showCategoryChip;
  final List<ModelCategory> categories;
  final List<Municipality> municipalities;
  final List<Types> types;
  final bool withSearchBar;
  final bool filterMap;
  final Function? zoomOut;
  final String islandId;
  FilterBar(
      {required this.showCategoryChip,
      required this.categories,
      required this.municipalities,
      required this.types,
      required this.filterMap,
      this.withSearchBar = false,
      this.zoomOut, required this.islandId});

  @override
  State<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<FilterBar> {
  Color bgColor = Color.fromRGBO(25, 27, 32, 1);

  late RestaurantCubit restaurantsCubit;
  late bool openFilter = false;
  List<String> selectedCategories = [];
  List<String> selectedMunicipalities = [];
  List<String> typesSelected = [];
  late FilterCubit filterCubit;
  String text = '';
  List<SimpleMunicipality> municipalitiesFilter = [];

  @override
  void initState() {
    restaurantsCubit = context.read<RestaurantCubit>();
    filterCubit = context.read<FilterCubit>();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        widget.withSearchBar
            ? Padding(
                padding: const EdgeInsets.only(right: 8.0, bottom: 16),
                child: GestureDetector(
                  onTap: () => GlobalMethods()
                      .pushPage(context, SearchText(zoomOut: widget.zoomOut)),
                  child: BlocBuilder<FilterCubit, FilterState>(
                      builder: (context, state) {
                    if (state is FilterCategory) {
                      text = state.text;
                    }
                    return Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18.0),
                        // Ajusta el radio según tus necesidades
                        border: Border.all(
                          // Puedes ajustar el color del borde según tus necesidades
                          width:
                              1.0, // Puedes ajustar el ancho del borde según tus necesidades
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.search,
                                    color: Color.fromRGBO(97, 97, 97, 1)),
                                Text(
                                  text.isEmpty ? 'Buscar' : text,
                                  style: TextStyle(
                                      color: Color.fromRGBO(97, 97, 97, 1)),
                                )
                              ],
                            ),
                            Icon(
                              Icons.close,
                              color: Color.fromRGBO(97, 97, 97, 1),
                            )
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              )
            : Container(),
        Container(
          height: 30,
          child:
              BlocBuilder<FilterCubit, FilterState>(builder: (context, state) {
            if (state is FilterCategory) {
              selectedMunicipalities = state.municipalitesSelected;
            } else if (state is FilterInitial) {
              selectedMunicipalities = [];
              selectedCategories = [];
              typesSelected = [];
            }

            return ListView(
              scrollDirection: Axis.horizontal,
              children: [
                widget.showCategoryChip
                    ? GestureDetector(
                        onTap: () => {showCategoryFilterModal(context)},
                        child: Chip(
                          backgroundColor: bgColor,
                          shape: RoundedRectangleBorder(
                              side: BorderSide(color: Colors.white),
                              borderRadius: BorderRadius.circular(20)),
                          label: Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Text(
                              selectedCategories.isEmpty
                                  ? 'Categoria'
                                  : 'Categorias +' +
                                      selectedCategories.length.toString(),
                              style:
                                  TextStyle(color:Colors.white,fontSize: 16),
                            ),
                          ),
                        ),
                      )
                    : Container(),
                widget.showCategoryChip
                    ? SizedBox(
                        width: 8,
                      )
                    : Container(),
                GestureDetector(
                  onTap: () => handleIsOpenFilter(),
                  child: openFilter
                      ? Chip(
                          shape: RoundedRectangleBorder(
                              side: BorderSide(color: Colors.white),
                              borderRadius: BorderRadius.circular(20)),
                          backgroundColor: Colors.white,
                          label: Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              'Abierto',
                              style: TextStyle(color: bgColor, fontSize: 16),
                            ),
                          ),
                        )
                      :  Chip(
                    shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(20)),
                    backgroundColor: bgColor,
                    label: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'Abierto',
                        style: TextStyle(color: Colors.white,fontSize: 16),
                      ),
                    ),
                  )
                ),
                SizedBox(
                  width: 8,
                ),
                GestureDetector(
                  onTap: () => {showMunicipalityFilterModal(context)},
                  child: Chip(
                    shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(20)),
                    backgroundColor: bgColor,
                    label: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        selectedMunicipalities.isEmpty
                            ? 'Municipio'
                            : 'Municipio +' +
                                selectedMunicipalities.length.toString(),
                        style: TextStyle(color: Colors.white,fontSize: 16),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 8,
                ),
                // Chip(
                //   label: Text('Valoración'),
                //   backgroundColor: Color.fromRGBO(231, 231, 231, 1),
                // ),
                // SizedBox(
                //   width: 8,
                // ),
                GestureDetector(
                  onTap: () {
                    showTypeFilterModal(context);
                  },
                  child: Chip(
                    shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(20)),
                    backgroundColor: bgColor,
                    label: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'Tipo',
                        style: TextStyle(color: Colors.white,fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  showCategoryFilterModal(context) {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (BuildContext context,
            StateSetter setState /*You can rename this!*/) {
          return ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
            child: Container(
              height: 600,
              color: GlobalMethods.bgColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(
                    height: 8,
                  ),
                  Center(
                    child: Container(
                      height: 2,
                      color: Color.fromRGBO(231, 231, 231, 1),
                      width: 64,
                    ),
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  BlocBuilder<FilterCubit, FilterState>(
                      builder: (context, state) {
                        if (state is FilterCategory) {
                          selectedCategories = state.categorySelected;
                        }
                        return Container(
                          height: 400,
                          child: GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 0.02,
                              mainAxisSpacing: 1, // Espaciado vertical entre filas
                            ),
                            itemCount: widget.categories.length,
                            // 4 filas x 2 columnas = 8 elementos
                            itemBuilder: (BuildContext context, int index) {
                              bool isCheck = selectedCategories
                                  .contains(widget.categories[index].id);
                              return GestureDetector(
                                onTap: () =>
                                {
                                  setState(() {
                                    List<String> selectedCategoriesAux =
                                        selectedCategories;
                                    if (isCheck) {
                                      selectedCategoriesAux
                                          .remove(widget.categories[index].id);
                                    } else {
                                      selectedCategories
                                          .add(widget.categories[index].id);
                                    }
                                    filterCubit.handleFilterChange(
                                        selectedCategories,
                                        selectedMunicipalities,
                                        typesSelected, '');
                                    this.selectedCategories =
                                        selectedCategoriesAux;
                                  })
                                },
                                child: Container(
                                  margin: EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      SvgPicture.network(
                                        widget.categories[index].iconUrl,
                                        width: 42.0,
                                        height: 42.0,
                                      ),
                                      SizedBox(
                                        height: 12,
                                      ),
                                      Center(
                                        child: Text(
                                          widget.categories[index].nombre,
                                          textAlign: TextAlign.center,
                                          // Alineación al centro
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: isCheck
                                                  ? Color.fromRGBO(
                                                  0, 133, 196, 1)
                                                  : Colors.white,
                                              fontWeight: isCheck
                                                  ? FontWeight.bold
                                                  : FontWeight.w500),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }),
                  Divider(
                    thickness: 0.2,
                  ),
                  Center(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 12,
                        ),
                        Container(
                          width: MediaQuery
                              .of(context)
                              .size
                              .width * 0.86,
                          child: ElevatedButton(
                            onPressed: () =>
                            {
                              restaurantsCubit.getFilterRestaurants(
                                categories: selectedCategories,
                                municipalities: selectedMunicipalities,
                                text: text,
                                types: typesSelected,
                                islandId:
                                widget.islandId,
                              ),
                              Navigator.pop(context)
                            },
                            style: ButtonStyle(
                                shape: MaterialStateProperty.all(
                                  RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(8), // <-- Radius
                                  ),
                                ),
                                minimumSize: MaterialStateProperty.all(
                                    Size.fromHeight(48)),
                                backgroundColor: MaterialStateProperty.all(
                                    Color.fromRGBO(0, 133, 196, 1))),
                            child: Text(
                              "Ver resultados",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'SF Pro Display',

                                  fontSize: 16.0),
                            ),
                          ),
                        ),
                        Container(
                          width: MediaQuery
                              .of(context)
                              .size
                              .width * 0.86,
                          child: TextButton(
                            onPressed: () => {Navigator.pop(context)},
                            style: ButtonStyle(
                              elevation: MaterialStateProperty.all(0),
                              // Establecer elevación a 0
                              shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(8), // <-- Radius
                                ),
                              ),
                              minimumSize: MaterialStateProperty.all(
                                  Size.fromHeight(48)),
                            ),
                            child: Text(
                              "Descartar",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'SF Pro Display',
                                  color: Color.fromRGBO(97, 97, 97, 1),
                                  fontSize: 16.0),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 12,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        });
      },
    );
  }

  showMunicipalityFilterModal(context) {
    TextEditingController _textController = TextEditingController();

    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (BuildContext context,
            StateSetter setState /*You can rename this!*/) {
          return ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
            child: Container(
              height: MediaQuery
                  .of(context)
                  .size
                  .height * 0.9,
              color: GlobalMethods.bgColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(
                    height: 8,
                  ),
                  Center(
                    child: Container(
                      height: 2,
                      color: Color.fromRGBO(231, 231, 231, 1),
                      width: 64,
                    ),
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: TextField(
                      onChanged: (text) {
                        List<SimpleMunicipality> auxmunicipalitiesFilter = [];
                        for (int i = 0; i < widget.municipalities.length; i++) {
                          for (int y = 0;
                          y <
                              widget
                                  .municipalities[i].municipalities.length;
                          y++) {
                            if (widget
                                .municipalities[i].municipalities[y].nombre
                                .contains(text.toUpperCase())) {
                              print(widget.municipalities[i].municipalities[y]);
                              auxmunicipalitiesFilter.add(
                                  widget.municipalities[i].municipalities[y]);
                            }
                          }
                        }
                        setState(() {
                          municipalitiesFilter = auxmunicipalitiesFilter;
                        });
                      },
                      controller: _textController,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintStyle:
                        TextStyle(color: Color.fromRGBO(0, 133, 196, 1)),
                        filled: true,
                        contentPadding: EdgeInsets.only(bottom: 3.0),
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12.0)),
                          borderSide:
                          BorderSide(color: Colors.transparent, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                          borderSide:
                          BorderSide(color: Colors.transparent, width: 2),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: (MediaQuery
                        .of(context)
                        .size
                        .height * 0.9) * 0.68,
                    child: BlocBuilder<FilterCubit, FilterState>(
                        builder: (context, state) {
                          if (state is FilterCategory) {
                            selectedMunicipalities =
                                state.municipalitesSelected;
                          }
                          return ListView.builder(
                              shrinkWrap: true,
                              itemCount: _textController.text.length > 0
                                  ? 1
                                  : widget.municipalities.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                      top: 8.0, left: 12, right: 12, bottom: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment
                                        .start,
                                    children: [
                                      Text(
                                        _textController.text.length > 0
                                            ? 'Resultados'
                                            : widget.municipalities[index]
                                            .nombre,
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
                                          itemCount: _textController.text
                                              .length > 0
                                              ? municipalitiesFilter.length
                                              : widget.municipalities[index]
                                              .municipalities.length,
                                          itemBuilder: (context, index2) {
                                            SimpleMunicipality municipality =
                                            _textController.text.length > 0
                                                ? municipalitiesFilter[index2]
                                                : widget.municipalities[index]
                                                .municipalities[index2];
                                            bool isCheck = selectedMunicipalities
                                                .contains(municipality.id);
                                            return GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  if (isCheck) {
                                                    selectedMunicipalities
                                                        .remove(municipality
                                                        .id);
                                                  } else {
                                                    selectedMunicipalities
                                                        .add(municipality.id);
                                                  }
                                                  filterCubit
                                                      .handleFilterChange(
                                                      selectedCategories,
                                                      selectedMunicipalities,
                                                      typesSelected, '');
                                                });
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 24.0),
                                                child: Row(
                                                  mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        municipality.nombre,
                                                        key: Key(
                                                            municipality.id),
                                                        style: TextStyle(
                                                            fontFamily: 'SF Pro Display',
                                                            fontSize: 14,
                                                            color:Colors.white,
                                                            fontWeight:
                                                            FontWeight.normal),
                                                      ),
                                                    ),
                                                    isCheck
                                                        ? Icon(
                                                      Icons.check,
                                                      color: Color.fromRGBO(
                                                          231, 231, 231, 1),
                                                    )
                                                        : Container()
                                                  ],
                                                ),
                                              ),
                                            );
                                          }),
                                      Divider(
                                        thickness: 0.1,
                                      ),
                                    ],
                                  ),
                                );
                              });
                        }),
                  ),
                  Divider(
                    thickness: 0.2,
                  ),
                  Center(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 12,
                        ),
                        Container(
                          width: MediaQuery
                              .of(context)
                              .size
                              .width * 0.86,
                          child: ElevatedButton(
                            onPressed: () {
                              restaurantsCubit.getFilterRestaurants(
                                categories: selectedCategories,
                                municipalities: selectedMunicipalities,
                                text: text,
                                types: typesSelected,
                                islandId:
                                widget.islandId,
                              );

                              Navigator.pop(context);
                            },
                            style: ButtonStyle(
                                shape: MaterialStateProperty.all(
                                  RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(8), // <-- Radius
                                  ),
                                ),
                                minimumSize: MaterialStateProperty.all(
                                    Size.fromHeight(48)),
                                backgroundColor: MaterialStateProperty.all(
                                    Color.fromRGBO(0, 133, 196, 1))),
                            child: Text(
                              "Ver resultados",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'SF Pro Display',

                                  fontSize: 16.0),
                            ),
                          ),
                        ),
                        Container(
                          width: MediaQuery
                              .of(context)
                              .size
                              .width * 0.86,
                          child: TextButton(
                            onPressed: () => {Navigator.pop(context)},
                            style: ButtonStyle(
                              elevation: MaterialStateProperty.all(0),
                              // Establecer elevación a 0
                              shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(8), // <-- Radius
                                ),
                              ),
                              minimumSize: MaterialStateProperty.all(
                                  Size.fromHeight(48)),
                            ),
                            child: Text(
                              "Descartar",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'SF Pro Display',
                                  color: Color.fromRGBO(97, 97, 97, 1),
                                  fontSize: 16.0),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 12,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        });
      },
    );
  }

  showTypeFilterModal(context) {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (BuildContext context,
            StateSetter setState /*You can rename this!*/) {
          return ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
            child: Container(
              height: MediaQuery
                  .of(context)
                  .size
                  .height * 0.9,
              color: GlobalMethods.bgColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(
                    height: 8,
                  ),
                  Center(
                    child: Container(
                      height: 2,
                      color: Color.fromRGBO(231, 231, 231, 1),
                      width: 64,
                    ),
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  Container(
                    height: (MediaQuery
                        .of(context)
                        .size
                        .height * 0.9) * 0.68,
                    child: BlocBuilder<FilterCubit, FilterState>(
                        builder: (context, state) {
                          if (state is FilterCategory) {
                            typesSelected =
                                state.typesSelected;
                          }
                          return ListView.builder(
                              shrinkWrap: true,
                              primary: false,
                              physics: ClampingScrollPhysics(),
                              itemCount: widget.types.length,
                              itemBuilder: (context, index) {
                                Types type = widget.types[index];
                                bool isCheck = typesSelected.contains(type.id);
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isCheck) {
                                        typesSelected.remove(type.id);
                                      } else {
                                        typesSelected.add(type.id);
                                      }
                                      filterCubit.handleFilterChange(
                                          selectedCategories,
                                          selectedMunicipalities,
                                          typesSelected, '');
                                    });
                                  },
                                  child: Padding(
                                    padding:
                                    const EdgeInsets.only(top: 24.0, left: 12),
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            type.nombre,
                                            key: Key(type.id),
                                            style: TextStyle(
                                                color:
                                                Colors.white,
                                                fontSize: 16,
                                                fontFamily: 'SF Pro Display',
                                                fontWeight: FontWeight.normal),
                                          ),
                                        ),
                                        isCheck
                                            ? Icon(
                                          Icons.check,
                                          color: Color.fromRGBO(
                                              231, 231, 231, 1),
                                        )
                                            : Container()
                                      ],
                                    ),
                                  ),
                                );
                              });
                        }),
                  ),
                  Divider(
                    thickness: 0.2,
                  ),
                  Center(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 12,
                        ),
                        Container(
                          width: MediaQuery
                              .of(context)
                              .size
                              .width * 0.86,
                          child: ElevatedButton(
                            onPressed: () {
                              restaurantsCubit.getFilterRestaurants(
                                categories: selectedCategories,
                                municipalities: selectedMunicipalities,
                                text: text,
                                types: typesSelected,
                                islandId:
                                widget.islandId,
                              );
                              Navigator.pop(context);
                            },
                            style: ButtonStyle(
                                shape: MaterialStateProperty.all(
                                  RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(8), // <-- Radius
                                  ),
                                ),
                                minimumSize: MaterialStateProperty.all(
                                    Size.fromHeight(48)),
                                backgroundColor: MaterialStateProperty.all(
                                    Color.fromRGBO(0, 133, 196, 1))),
                            child: Text(
                              "Ver resultados",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'SF Pro Display',
                                  fontSize: 16.0),
                            ),
                          ),
                        ),
                        Container(
                          width: MediaQuery
                              .of(context)
                              .size
                              .width * 0.86,
                          child: TextButton(
                            onPressed: () => {Navigator.pop(context)},
                            style: ButtonStyle(
                              elevation: MaterialStateProperty.all(0),
                              // Establecer elevación a 0
                              shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(8), // <-- Radius
                                ),
                              ),
                              minimumSize: MaterialStateProperty.all(
                                  Size.fromHeight(48)),
                            ),
                            child: Text(
                              "Descartar",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'SF Pro Display',

                                  color: Color.fromRGBO(97, 97, 97, 1),
                                  fontSize: 16.0),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 12,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        });
      },
    );
  }

  handleIsOpenFilter() {
    if (widget.filterMap) {
      restaurantsCubit.getFilterRestaurants(
        categories: selectedCategories,
        municipalities: selectedMunicipalities,
        text: text,
        types: typesSelected,
        isOpen: openFilter,
        islandId: widget.islandId,
      );
    } else {
      restaurantsCubit.getFilterRestaurants(
        categories: selectedCategories,
        municipalities: selectedMunicipalities,
        text: text,
        types: typesSelected,
        isOpen: openFilter,
        islandId: widget.islandId,
      );
    }
    setState(() {
      openFilter = !openFilter;
    });
  }
}
