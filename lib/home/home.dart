import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:guachinches/Filter/filter_content.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/data/cubit/banners_cubit.dart';
import 'package:guachinches/data/cubit/banners_state.dart';
import 'package:guachinches/data/cubit/categories_cubit.dart';
import 'package:guachinches/data/cubit/categories_state.dart';
import 'package:guachinches/data/cubit/restaurant_cubit.dart';
import 'package:guachinches/data/cubit/restaurant_state.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/heroSliderComponent.dart';
import 'package:guachinches/home/app_Bars/appbar_basic.dart';
import 'package:guachinches/home/app_Bars/appbar_search.dart';
import 'package:guachinches/home/home_presenter.dart';
import 'package:guachinches/model/Category.dart';
import 'package:guachinches/model/fotos.dart';
import 'package:guachinches/model/restaurant.dart';
import 'package:guachinches/municipality_screen/municipality_screen.dart';
import 'package:http/http.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../Categorias/categorias.dart';
import '../details/details.dart';

class Home extends StatefulWidget {
  List<Restaurant> restaurants = [];
  bool isChargingInitalRestaurants = true;

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> implements HomeView {
  AppBarSearch appBarSearch;
  AppBarBasic appBarBasic;

  bool isDescendent = false;
  String selectedCategories = "Todas";

  List<ModelCategory> categories = [];

  //Para El filtro catregorias
  String _municipalityId = "";
  String _municipalityIdArea = "";
  String _useMunicipality = "Todos";

  bool doRequest = false;
  bool isCharging = false;

  HomePresenter presenter;
  RemoteRepository remoteRepository;

  //Icon que cambia con el reordenado por valoracion
  Icon iconRow = Icon(Icons.keyboard_arrow_down);

  int index = 0;
  ScrollController _controller;
  List<Widget> widgetsRestaurants = [];
  List<String> test = ["Lunes", "Martes", "Miercoles", "Jueves"];

  bool _isSearchingByName = false;

  @override
  void initState() {
    super.initState();
    final restaurantCubit = context.read<RestaurantCubit>();
    final categoriesCubit = context.read<CategoriesCubit>();
    final bannersCubit = context.read<BannersCubit>();
    remoteRepository = HttpRemoteRepository(Client());
    presenter =
        HomePresenter(this, restaurantCubit, categoriesCubit, bannersCubit);
    presenter.getSelectedMunicipality();
    if (categoriesCubit.state is CategoriesInitial) {
      presenter.getAllCategories();
      if (mounted) {
        setState(() {
          changeCharginInitial();
        });
      }
    }
    if (bannersCubit.state is BannersInitial) {
      presenter.getAllBanner();
    }
    if (restaurantCubit.state is RestaurantInitial) {
      presenter.getAllRestaurants();
    }
    presenter.getSelectedMunicipality();
    presenter.getSelectedCategory();
    _controller = ScrollController();
    _controller.addListener(_scrollListener);
    appBarBasic = AppBarBasic(presenter, widget);
    presenter.setLocationData();
    createListWidgetForRestaurants();
    appBarSearch = AppBarSearch(presenter, widget);
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  setListeners() {
    if (mounted) {
      setState(() {
        isCharging = false;
      });
    }
    Timer(Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          index++;
        });
      }
      createListWidgetForRestaurants();
    });
    Timer(Duration(milliseconds: 2000), () {
      _controller.addListener(_scrollListener);
    });
  }

  _scrollListener() {
    if (_controller.position.pixels >= _controller.position.maxScrollExtent &&
        !isCharging &&
        widget.isChargingInitalRestaurants) {
      _controller.removeListener(_scrollListener);
      if (mounted) {
        setState(() {
          isCharging = true;
          Timer(Duration(milliseconds: 1000), setListeners);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSearchingByName
          ? appBarSearch.createWidget(context)
          : appBarBasic.createWidget(context),
      body: SingleChildScrollView(
        controller: _controller,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 20.0,
            ),
            BlocBuilder<BannersCubit, BannersState>(builder: (context, state) {
              if (state is BannersLoaded) {
                return HeroSliderComponent(state.banners);
              } else {
                return Container();
              }
            }),
            SizedBox(
              height: 20.0,
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Categorias',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        {GlobalMethods().pushPage(context, Categorias())},
                    child: Text(
                      'Ver todas',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 20.0,
            ),
            Container(
                margin: EdgeInsets.only(left: 15.0),
                child: BlocBuilder<CategoriesCubit, CategoriesState>(
                    builder: (context, state) {
                  if (state is CategoriesLoaded) {
                    List<ModelCategory> aux = [];
                    if (selectedCategories != "Todas") {
                      ModelCategory auxCategory = state.categories.firstWhere(
                          (element) => element.id == selectedCategories,
                          orElse: null);
                      if (auxCategory != null) {
                        aux.add(auxCategory);
                      }
                      aux.addAll(state.categories
                          .where((element) => element != auxCategory));
                    } else {
                      aux = state.categories;
                    }
                    return Container(
                      height: 120.0,
                      width: double.infinity,
                      child: ListView.builder(
                          shrinkWrap: true,
                          primary: false,
                          itemExtent: MediaQuery.of(context).size.width / 4,
                          itemCount: aux.length,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            return Wrap(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    widgetsRestaurants = [];
                                    presenter
                                        .setSelectedCategory(aux[index].id);
                                  },
                                  child: Container(
                                    height: 110,
                                    width: 80.0,
                                    decoration: BoxDecoration(
                                      color: selectedCategories
                                              .contains(aux[index].id)
                                          ? Color.fromRGBO(254, 192, 75, 1)
                                          : Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.black54,
                                            blurRadius: 2.0,
                                            spreadRadius: 1.0,
                                            offset: Offset(2.0, 3.0))
                                      ],
                                      borderRadius: BorderRadius.circular(17.0),
                                    ),
                                    child: Column(
                                      children: [
                                        SvgPicture.network(
                                          aux[index].iconUrl,
                                          height: 60.0,
                                          width: 60.0,
                                        ),
                                        Container(
                                          margin: EdgeInsets.symmetric(
                                              vertical: 10.0, horizontal: 1.0),
                                          child: Text(
                                            aux[index].nombre != null
                                                ? aux[index].nombre
                                                : "",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 12.0,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 30.0,
                                ),
                              ],
                            );
                          }),
                    );
                  } else {
                    return Container();
                  }
                })),
            SizedBox(
              height: 20.0,
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: reorderList,
                  child: Container(
                    margin: EdgeInsets.only(left: 10.0),
                    width: 100.0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                        color: Colors.black,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        iconRow == null
                            ? Icon(Icons.keyboard_arrow_down)
                            : iconRow,
                        Text(
                          'Valoración',
                          style: TextStyle(fontSize: 12.0, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => showMaterialModalBottomSheet(
                    backgroundColor: Colors.transparent,
                    context: context,
                    builder: (context) => FilterContent(),
                  ),
                  child: Container(
                    margin: EdgeInsets.only(left: 10.0),
                    width: 100.0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                        color: Colors.black,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          "assets/images/filter_icon.svg",
                          height: 24,
                        ),
                        Text(
                          'Filtros',
                          style: TextStyle(fontSize: 12.0, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 20.0,
            ),
            !widget.isChargingInitalRestaurants
                ? Center(
                    child: CircularProgressIndicator(
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : Column(
                    children: widgetsRestaurants.map((e) => e).toList(),
                  ),
            isCharging
                ? Center(
                  child: CircularProgressIndicator(
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                )
                : Container(),
          ],
        ),
      ),
    );
  }

  gotoDetail(Restaurant restaurant) {
    GlobalMethods().pushPage(context, Details(restaurant));
  }

  @override
  setAllRestaurants(List<Restaurant> restaurants) {
    if (mounted) {
      setState(() {
        index = 0;
        this.widget.restaurants = restaurants;
      });
    }
  }

  @override
  setAllCategories(List<ModelCategory> categories) {
    if (mounted) {
      setState(() {
        index = 0;
        this.categories = categories;
      });
    }
  }

  @override
  categorySelected(String id) {
    if (mounted) {
      setState(() {
        index = 0;
        selectedCategories = id;
      });
    }
    createListWidgetForRestaurants();
  }

  goToSelectMunicipality() {
    GlobalMethods().pushPage(context, MunicipalityScreen());
  }

  reorderList() {
    List<Restaurant> aux = widget.restaurants;
    Icon iconAux = iconRow;
    aux.sort((a, b) {
      double firstValue = a.avg == "NaN" ? 0.0 : double.parse(a.avg);
      double secondValue = b.avg == "NaN" ? 0.0 : double.parse(b.avg);
      if (isDescendent) {
        iconAux = Icon(Icons.keyboard_arrow_down);
        if (firstValue > secondValue)
          return -1;
        else if (firstValue < secondValue)
          return 1;
        else
          return 0;
      } else {
        iconAux = Icon(Icons.keyboard_arrow_up);
        if (firstValue > secondValue)
          return 1;
        else if (firstValue < secondValue)
          return -1;
        else
          return 0;
      }
    });
    if (mounted) {
      setState(() {
        widget.restaurants = aux;
        isDescendent = !isDescendent;
        iconRow = iconAux;
        widgetsRestaurants = [];
      });
    }
    createListWidgetForRestaurants();
  }

  List<Restaurant> filterList(List<Restaurant> restaurants) {
    List<Restaurant> aux = [];
    restaurants.forEach((element) {
      if (this._useMunicipality == "Todos") {
        aux.add(element);
      } else if (this._useMunicipality == "true") {
        if (element.municipio.id == this._municipalityId) {
          aux.add(element);
        }
      } else {
        if (element.municipio.areaMunicipioId == this._municipalityIdArea) {
          aux.add(element);
        }
      }
    });
    return aux;
  }

  List<Restaurant> filterListCategory(List<Restaurant> restaurants) {
    List<Restaurant> aux = [];
    restaurants.forEach((element) {
      if (selectedCategories == "Todas") {
        aux.add(element);
      } else {
        element.categoriaRestaurantes.forEach((cat) {
          if (cat.categorias.id == selectedCategories) {
            aux.add(element);
          }
        });
      }
    });
    return aux;
  }

  createListWidgetForRestaurants() {
    Widget aux = Container(
      child: BlocBuilder<RestaurantCubit, RestaurantState>(
          builder: (context, state) {
        if (state is RestaurantLoaded) {
          widget.restaurants = state.restaurants;
          return Column(
            children: componentStateBuilder(widget.restaurants, index)
                .map((e) => e)
                .toList(),
          );
        }
        if (state is RestaurantFilter) {
          return Column(
            children: componentStateBuilder(state.filtersRestaurants, index)
                .map((e) => e)
                .toList(),
          );
        }
        return Container();
      }),
    );
    if (mounted) {
      setState(() {
        widgetsRestaurants.add(aux);
      });
    }
  }

  List<Widget> componentStateBuilder(
      List<Restaurant> restaurants, int indexList) {
    restaurants = filterList(restaurants);
    restaurants = filterListCategory(restaurants);
    return getWidgetList(restaurants, indexList);
  }

  List<Widget> getWidgetList(restaurants, indexList) {
    List<Widget> widgets = [];
    for (int i = (indexList * 10); i < (indexList * 10 + 10); i++) {
      if (i < restaurants.length) {
        Fotos foto = restaurants[i].fotos.firstWhere(
            (element) => element.type == "principal",
            orElse: () => null);
        String categorias = "";
        for (int x = 0; x < restaurants[i].categoriaRestaurantes.length; x++) {
          categorias += x != restaurants[i].categoriaRestaurantes.length - 1
              ? " " +
                  restaurants[i].categoriaRestaurantes[x].categorias.nombre +
                  ","
              : " " + restaurants[i].categoriaRestaurantes[x].categorias.nombre;
        }
        Widget aux = GestureDetector(
          onTap: () => gotoDetail(restaurants[i]),
          child: Container(
            color: Colors.transparent,
            margin: EdgeInsets.symmetric(horizontal: 10.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80.0,
                      height: 80.0,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.0),
                          image: DecorationImage(
                            image: foto != null
                                ? NetworkImage(
                                    foto.photoUrl,
                                  )
                                : AssetImage("assets/images/notImage.png"),
                          )),
                    ),
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.only(left: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              restaurants[i].nombre != null
                                  ? restaurants[i].nombre
                                  : "",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            categorias != ""
                                ? Text(
                                    categorias,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 12.0,
                                    ),
                                  )
                                : Container(),
                            Text(
                              restaurants[i].direccion != null
                                  ? restaurants[i].direccion
                                  : "",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12.0,
                              ),
                            ),
                            Text(
                              restaurants[i].destacado != null
                                  ? restaurants[i].destacado
                                  : "",
                              style: TextStyle(
                                color: Color.fromRGBO(226, 120, 120, 1),
                                fontSize: 12.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    restaurants[i].avg == "NaN"
                        ? Container()
                        : Container(
                            width: 48.0,
                            height: 24.0,
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(149, 194, 55, 1),
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                            child: Text(
                              restaurants[i].avg != null
                                  ? restaurants[i].avg
                                  : "",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18.0,
                              ),
                            ),
                          ),
                  ],
                ),
                SizedBox(
                  height: 20.0,
                ),
              ],
            ),
          ),
        );
        widgets.add(aux);
      }
    }
    return widgets;
  }

  @override
  changeStateAppBar(value) {
    if (mounted) {
      setState(() {
        this._isSearchingByName = value;
      });
    }
  }

  @override
  setLocationData(data) {
    _useMunicipality = data["useMunicipality"];
    _municipalityIdArea = data["municipalityIdArea"];
    _municipalityId = data["municipalityId"];
    widgetsRestaurants.clear();
    createListWidgetForRestaurants();
  }

  @override
  callCreateNewRestaurantsList() {
    if (mounted) {
      setState(() {
        index = 0;
        widgetsRestaurants.clear();
        createListWidgetForRestaurants();
      });
    }
  }

  @override
  changeCharginInitial() {
    if (mounted) {
      setState(() {
        this.widget.isChargingInitalRestaurants = !this.widget.isChargingInitalRestaurants;
      });
    }
  }

  @override
  changeScreen(widget) {
    GlobalMethods().pushAndReplacement(context, widget);
  }
}
