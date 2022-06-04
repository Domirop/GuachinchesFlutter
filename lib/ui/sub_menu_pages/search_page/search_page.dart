import 'dart:async';

import 'package:bottom_sheet/bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/cupones/cupones_cubit.dart';
import 'package:guachinches/data/cubit/cupones/cupones_state.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_state.dart';
import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/data/model/CuponesAgrupados.dart';
import 'package:guachinches/data/model/Municipality.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/Others/details/details.dart';
import 'package:guachinches/ui/sub_menu_pages/search_page/search_page_presenter.dart';
import 'package:http/http.dart';

class SearchPage extends StatefulWidget {
  String userId;

  SearchPage({this.userId});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin
    implements SearchPageView {
  RemoteRepository remoteRepository;
  ScrollController controller2;
  ScrollController controller1;
  SearchPagePresenter presenter;
  List<Restaurant> restaurants = [];
  List<Restaurant> restaurantsFilter = [];
  int maxRestaurants = 9999;
  bool isOpen = false;
  List<Restaurant> restaurants1 = [];
  List<CuponesAgrupados> cupones = [];
  int maxRestaurants1 = 9999;
  List<ModelCategory> categories = [];
  List<Municipality> municipalities = [];
  int numberPagination = 0;
  int numberPagination2 = 0;
  int currentIndex = 0;
  List<String> municipalitiesId = [];
  List<String> categoriesId = [];
  String textValue = "";

  Widget tab1;
  Widget tab2;
  Widget tab3;
  int numero = 0;
  bool isCharging = false;
  bool isChargingInitalRestaurants = true;
  TabController _tabController;
  var restaurantCubit;

  @override
  void initState() {
    remoteRepository = HttpRemoteRepository(Client());
    restaurantCubit = context.read<RestaurantCubit>();
    final cuponesCubit = context.read<CuponesCubit>();
    presenter = SearchPagePresenter(
        this, restaurantCubit, cuponesCubit, remoteRepository);
    if (restaurantCubit.state is RestaurantInitial ||
        restaurantCubit.state is RestaurantFilter) {
      presenter.getAllRestaurants(numberPagination);
      generateWidgetsTab1();
      generateWidgetsTab2();
    } else if (restaurantCubit.state is RestaurantLoaded) {
      generateWidgetsTab1();
      generateWidgetsTab2();
      presenter.setCharging();
    }
    if (cuponesCubit.state is CuponesInitial) {
      presenter.getAllRestaurants(numberPagination);
      generateWidgetsTab3();
    } else if (cuponesCubit.state is CuponesLoaded) {
      generateWidgetsTab3();
      presenter.setCharging();
    }
    presenter.getAllMunicipalitiesAndCategories();
    controller2 = new ScrollController();
    controller1 = new ScrollController();
    _tabController = TabController(length: 3, vsync: this);
    controller2.addListener(_scrollListener2);
    controller1.addListener(_scrollListener1);
    _tabController.addListener(tabListenerFunction);
  }

  tabListenerFunction() {
    if (restaurantCubit.state is RestaurantFilter &&
        (_tabController.index == 2 || _tabController.index == 0)) {
      numberPagination = 0;
      numberPagination2 = 0;
      presenter.getAllRestaurants(0);
      generateWidgetsTab1();
      generateWidgetsTab2();
      controller2.addListener(_scrollListener2);
      if (mounted) {
        setState(() {
          numero = 0;
          categoriesId = [];
          municipalitiesId = [];
        });
      }
    }
  }

  inputSearchFunction() {
    _tabController.index = 1;
  }

  @override
  void dispose() {
    super.dispose();
    controller2.dispose();
    controller1.dispose();
    _tabController.dispose();
  }

  generateWidgetsTab1() {
    Widget aux = BlocBuilder<RestaurantCubit, RestaurantState>(
        builder: (context, state) {
      if (state is RestaurantLoaded) {
        List auxList = restaurants1;
        auxList.addAll(state.restaurantResponse.restaurants);
        restaurants1 = auxList;
        maxRestaurants1 = state.restaurantResponse.count;
        return Wrap(
            children: auxList
                .map((e) => GestureDetector(
                      onTap: () =>
                          GlobalMethods().pushPage(context, Details(e.id)),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.33,
                        height: 139,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            repeat: ImageRepeat.noRepeat,
                            alignment: Alignment.center,
                            fit: BoxFit.fill,
                            image: e.mainFoto != null
                                ? NetworkImage(e.mainFoto)
                                : AssetImage("assets/images/notImage.png"),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            e.nombre,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          ),
                        ),
                      ),
                    ))
                .toList());
      }
      return Container();
    });
    setState(() {
      tab1 = aux;
    });
  }

  setListeners1Function() {
    numberPagination += 15;
    Timer(Duration(milliseconds: 500), () {
      presenter.getAllRestaurantsPag1(numberPagination);
    });
    if ((numberPagination + 15) < maxRestaurants1) {
      Timer(Duration(milliseconds: 2000), () {
        controller1.addListener(_scrollListener1);
      });
    }
  }

  _scrollListener1() {
    if (controller1.position.pixels >= controller1.position.maxScrollExtent &&
        !isCharging &&
        !isChargingInitalRestaurants) {
      controller1.removeListener(_scrollListener1);
      if (mounted) {
        setState(() {
          isCharging = true;
          Timer(Duration(milliseconds: 1000), setListeners1Function);
        });
      }
    }
  }

  setListeners2Function() {
    numberPagination2 += 15;
    Timer(Duration(milliseconds: 500), () {
      presenter.getAllRestaurantsPag2(numberPagination2);
    });
    if ((numberPagination2 + 15) < maxRestaurants) {
      Timer(Duration(milliseconds: 2000), () {
        controller2.addListener(_scrollListener2);
      });
    }
  }

  _scrollListener2() {
    if (controller2.position.pixels >= controller2.position.maxScrollExtent &&
        !isCharging &&
        !isChargingInitalRestaurants) {
      controller2.removeListener(_scrollListener2);
      if (mounted) {
        setState(() {
          isCharging = true;
          Timer(Duration(milliseconds: 1000), setListeners2Function);
        });
      }
    }
  }

  generateWidgetsTab2() {
    Widget aux = BlocBuilder<RestaurantCubit, RestaurantState>(
        builder: (context, state) {
      if (state is RestaurantLoaded) {
        List auxList = restaurants;
        auxList.addAll(state.restaurantResponse.restaurants);
        restaurants = auxList;
        maxRestaurants = state.restaurantResponse.count;
        return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: auxList
                .map((e) => GestureDetector(
                      onTap: () =>
                          GlobalMethods().pushPage(context, Details(e.id)),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10.0),
                        width: MediaQuery.of(context).size.width * 0.95,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  height: 110,
                                  margin: EdgeInsets.only(right: 10),
                                  width:
                                      MediaQuery.of(context).size.width * 0.30,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.0),
                                    image: DecorationImage(
                                      repeat: ImageRepeat.noRepeat,
                                      alignment: Alignment.center,
                                      fit: BoxFit.fill,
                                      image: e.mainFoto != null
                                          ? NetworkImage(e.mainFoto)
                                          : AssetImage(
                                              "assets/images/notImage.png"),
                                    ),
                                  ),
                                ),
                                Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.60,
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Flexible(
                                            child: Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.3,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    e.nombre,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    e.direccion,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    e.open
                                                        ? 'Abierto'
                                                        : 'Cerrado',
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: e.open
                                                          ? Color.fromRGBO(
                                                              149, 220, 0, 1)
                                                          : Color.fromRGBO(
                                                              226, 120, 120, 1),
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          e.avgRating != null
                                              ? Container(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 10.0,
                                                      vertical: 2.0),
                                                  decoration: BoxDecoration(
                                                    color: Color.fromRGBO(
                                                        149, 194, 55, 1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6.0),
                                                  ),
                                                  child: Text(
                                                    e.avgRating.toString(),
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18.0,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                )
                                              : Container(),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              width: 10,
                            )
                          ],
                        ),
                      ),
                    ))
                .toList());
      } else if (state is RestaurantFilter) {
        List auxList = state.filtersRestaurants;
        if (isOpen) {
          auxList = auxList.where((element) => element.open).toList();
        }
        restaurantsFilter = auxList;
        return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: auxList
                .map((e) => GestureDetector(
                      onTap: () =>
                          GlobalMethods().pushPage(context, Details(e.id)),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10.0),
                        width: MediaQuery.of(context).size.width * 0.95,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  height: 110,
                                  margin: EdgeInsets.only(right: 10),
                                  width:
                                      MediaQuery.of(context).size.width * 0.30,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.0),
                                    image: DecorationImage(
                                      repeat: ImageRepeat.noRepeat,
                                      alignment: Alignment.center,
                                      fit: BoxFit.fill,
                                      image: e.mainFoto != null
                                          ? NetworkImage(e.mainFoto)
                                          : AssetImage(
                                              "assets/images/notImage.png"),
                                    ),
                                  ),
                                ),
                                Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.60,
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Flexible(
                                            child: Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.3,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    e.nombre,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    e.direccion,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    e.open
                                                        ? 'Abierto'
                                                        : 'Cerrado',
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: e.open
                                                          ? Color.fromRGBO(
                                                              149, 220, 0, 1)
                                                          : Color.fromRGBO(
                                                              226, 120, 120, 1),
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          e.avgRating != null
                                              ? Container(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 10.0,
                                                      vertical: 2.0),
                                                  decoration: BoxDecoration(
                                                    color: Color.fromRGBO(
                                                        149, 194, 55, 1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6.0),
                                                  ),
                                                  child: Text(
                                                    e.avgRating.toString(),
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18.0,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                )
                                              : Container(),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              width: 10,
                            )
                          ],
                        ),
                      ),
                    ))
                .toList());
      }
      return Container();
    });
    setState(() {
      tab2 = aux;
    });
  }

  generateWidgetsTab3() {
    Widget aux =
        BlocBuilder<CuponesCubit, CuponesState>(builder: (context, state) {
      if (state is CuponesLoaded) {
        List aux = state.cuponesAgrupados;
        cupones = aux;
        return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: aux
                .map((e) => Container(
                      padding: EdgeInsets.symmetric(vertical: 10.0),
                      width: MediaQuery.of(context).size.width * 0.95,
                      child: Column(
                        children: widgetsTab3(e),
                      ),
                    ))
                .toList());
      }
      return Container();
    });
    setState(() {
      tab3 = aux;
    });
  }

  widgetsTab3(CuponesAgrupados element) {
    List<Widget> widgets = [];
    widgets.add(Text(
      element.nombre,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18.0,
      ),
    ));
    widgets.add(SizedBox(
      height: 10.0,
    ));
    element.cupones.forEach((cupon) {
      widgets.add(Container(
        padding: EdgeInsets.symmetric(vertical: 10.0),
        width: MediaQuery.of(context).size.width * 0.95,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  height: 110,
                  margin: EdgeInsets.only(right: 10),
                  width: MediaQuery.of(context).size.width * 0.30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    image: DecorationImage(
                      repeat: ImageRepeat.noRepeat,
                      alignment: Alignment.center,
                      fit: BoxFit.fill,
                      image: cupon.fotoUrl != null
                          ? NetworkImage(cupon.fotoUrl)
                          : AssetImage("assets/images/notImage.png"),
                    ),
                  ),
                ),
                Flexible(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.60,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          element.nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          cupon.date,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Obtén un descuento del " +
                              cupon.descuento.toString() +
                              "%",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color.fromRGBO(149, 220, 0, 1),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        widget.userId != null
                            ? GestureDetector(
                                onTap: () => presenter.saveCupon(
                                    widget.userId, cupon.id),
                                child: Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.58,
                                  height: 30,
                                  alignment: Alignment.center,
                                  margin: EdgeInsets.symmetric(
                                      horizontal: 10.0, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8.0),
                                    border: Border.all(
                                        width: 2,
                                        color: Color.fromRGBO(0, 133, 196, 1)),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "Guardar cupón",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color.fromRGBO(0, 133, 196, 1),
                                          fontSize: 12.0),
                                    ),
                                  ),
                                ),
                              )
                            : Container(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              width: 10,
            )
          ],
        ),
      ));
    });
    widgets.add(SizedBox(
      height: 5.0,
    ));
    widgets.add(Divider(
      color: Colors.black,
      endIndent: 2.0,
      indent: 2.0,
      height: 2.0,
    ));
    widgets.add(SizedBox(
      height: 5.0,
    ));
    return widgets;
  }

  _openBottomSheetWithInfo(BuildContext context) {
    showFlexibleBottomSheet<void>(
      bottomSheetColor: Colors.transparent,
      isExpand: true,
      initHeight: 0.7,
      maxHeight: 0.88,
      context: context,
      barrierColor: Colors.transparent,
      keyboardBarrierColor: Colors.transparent,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topRight: Radius.circular(20.0), topLeft: Radius.circular(20.0)),
      ),
      builder: (context, controllerModal, offset) {
        return BottomSheet(
            municipalities,
            categories,
            controllerModal,
            this,
            presenter,
            remoteRepository,
            municipalitiesId,
            categoriesId,
            isOpen);
      },
    );
  }

  generateAppBar(context) {
    return AppBar(
      actions: [
        Container(
          height: 40,
          padding: EdgeInsets.only(right: 10.0),
          child: GestureDetector(
            onTap: () {
              inputSearchFunction();
              _openBottomSheetWithInfo(context);
            },
            child: Container(
              width: 100,
              height: 30,
              alignment: Alignment.center,
              margin: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
              decoration: BoxDecoration(
                color: Color.fromRGBO(0, 133, 196, 1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Center(
                child: Text(
                  "Filtros - " + numero.toString(),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 12.0),
                ),
              ),
            ),
          ),
        ),
      ],
      titleSpacing: 1,
      leadingWidth: 0,
      title: Container(
          height: 60,
          padding: EdgeInsets.all(10.0),
          child: TextField(
            onTap: inputSearchFunction,
            onChanged: (text) {
              if (mounted) {
                setState(() {
                  this.textValue = text;
                });
              }
              if (text.length > 3)
                presenter.getAllRestaurantsFilters(isOpen,
                    categories: categoriesId,
                    municipalities: municipalitiesId,
                    text: text,
                    number: numero);
            },
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintStyle: TextStyle(color: Color.fromRGBO(0, 133, 196, 1)),
              filled: true,
              contentPadding: EdgeInsets.only(bottom: 3.0),
              fillColor: Color.fromRGBO(237, 230, 215, 0.42),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12.0)),
                borderSide: BorderSide(color: Colors.transparent, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10.0)),
                borderSide: BorderSide(color: Colors.transparent, width: 2),
              ),
            ),
          )),
      bottom: TabBar(
        controller: _tabController,
        labelColor: Colors.black,
        labelStyle: TextStyle(
            color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
        tabs: [
          Tab(text: "Destacado"),
          Tab(text: "Restaurantes"),
          Tab(text: "Cupones"),
        ],
      ),
      backgroundColor: Colors.white,
      elevation: 5.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: generateAppBar(context),
      body: isChargingInitalRestaurants
          ? Container(
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.center,
              child: CircularProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            )
          : Container(
              height: MediaQuery.of(context).size.height,
              child: TabBarView(
                controller: _tabController,
                children: [
                  SingleChildScrollView(
                    controller: controller1,
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      child: Column(
                        children: [
                          tab1,
                          SizedBox(
                            height: 10.0,
                          ),
                          isCharging == true
                              ? Center(
                                  child: CircularProgressIndicator(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.black),
                                  ),
                                )
                              : Container(),
                        ],
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    controller: controller2,
                    child: Column(
                      children: [
                        tab2,
                        SizedBox(
                          height: 10.0,
                        ),
                        isCharging == true
                            ? Center(
                                child: CircularProgressIndicator(
                                  backgroundColor: Colors.transparent,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black),
                                ),
                              )
                            : Container(),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        tab3,
                        SizedBox(
                          height: 10.0,
                        ),
                        isCharging == true
                            ? Center(
                                child: CircularProgressIndicator(
                                  backgroundColor: Colors.transparent,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black),
                                ),
                              )
                            : Container(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  changeCharginInitial() {
    if (mounted) {
      setState(() {
        isCharging = false;
        isChargingInitalRestaurants = false;
      });
    }
  }

  @override
  setMunicipalitiesAndCategories(
      List<ModelCategory> categories, List<Municipality> municipality) {
    if (mounted) {
      setState(() {
        this.categories = categories;
        this.municipalities = municipality;
      });
    }
  }

  @override
  updateNumber(List<String> categories, List<String> municipalities, int number,
      bool isOpen) {
    if (mounted) {
      setState(() {
        this.numero = number;
        this.categoriesId = categories;
        this.municipalitiesId = municipalities;
        this.isOpen = isOpen;
      });
    }
  }

  @override
  generateWidgetTab1() {
    generateWidgetsTab1();
  }

  @override
  generateWidgetTab2() {
    generateWidgetsTab2();
  }

  @override
  generateWidgetTab3() {
    generateWidgetsTab3();
  }

  @override
  estadoCupon(bool correctSave) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              content: Icon(
                correctSave ? Icons.check_circle_outlined : Icons.error_outline,
                size: 50,
                color: correctSave
                    ? Color.fromRGBO(149, 220, 0, 1)
                    : Color.fromRGBO(226, 120, 120, 1),
              ),
              alignment: Alignment.center,
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                SimpleDialogOption(
                  onPressed: () => GlobalMethods().popPage(context),
                  child: (Container(
                    width: double.infinity,
                    height: 30,
                    alignment: Alignment.center,
                    margin:
                        EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(0, 133, 196, 1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Center(
                      child: Text(
                        "Aceptar",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 12.0),
                      ),
                    ),
                  )),
                )
              ],
            ),
        barrierDismissible: false);
  }

  @override
  updateFilter() {
    String aux = textValue.length > 3 ? textValue : "";
    presenter.getAllRestaurantsFilters(isOpen,
        categories: categoriesId,
        number: numero,
        text: aux,
        municipalities: municipalitiesId);
  }

  @override
  removeListeners() {
    controller2.removeListener(_scrollListener2);
  }

  @override
  changeTab() {
    if (mounted) {
      setState(() {
        this._tabController.index = 0;
      });
    }
  }
}

class BottomSheet extends StatefulWidget {
  List<ModelCategory> categories;
  List<Municipality> municipalities;
  final ScrollController controller;
  SearchPageView searPage;
  List<String> municipalitiesId = [];
  List<String> categoriesId = [];
  bool isOpen = false;
  RemoteRepository remoteRepository;
  SearchPagePresenter presenter;

  BottomSheet(
      this.municipalities,
      this.categories,
      this.controller,
      this.searPage,
      this.presenter,
      this.remoteRepository,
      this.municipalitiesId,
      this.categoriesId,
      this.isOpen);

  @override
  State<BottomSheet> createState() =>
      _BottomSheetState(municipalitiesId, categoriesId, isOpen);
}

class _BottomSheetState extends State<BottomSheet> {
  List<String> municipalitiesId = [];
  List<String> municipalitiesIdParent = [];
  List<String> categoriesId = [];
  bool isOpen = false;

  _BottomSheetState(this.municipalitiesId, this.categoriesId, this.isOpen);

  @override
  void initState() {}

  @override
  void dispose() {
    super.dispose();
    widget.presenter.updateFilter();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: ListView(
        controller: widget.controller,
        shrinkWrap: true,
        children: createWidgetList(),
      ),
    );
  }

  createWidgetList() {
    List<Widget> widgets = [];
    widgets.add(GestureDetector(
      onTap: () => updateIsOpen(),
      child: Container(
        width: MediaQuery.of(context).size.width / 3,
        height: 40,
        padding: EdgeInsets.symmetric(horizontal: 6.0),
        alignment: Alignment.center,
        margin: EdgeInsets.symmetric(horizontal: 5.0, vertical: 10),
        decoration: BoxDecoration(
            color: isOpen ? Color.fromRGBO(0, 133, 196, 1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
                color: isOpen ? Colors.black : Color.fromRGBO(0, 133, 196, 1),
                width: 2)),
        child: Text(
          "Abierto",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isOpen ? Colors.white : Colors.black,
            fontSize: 14,
          ),
        ),
      ),
    ));
    widgets.add(SizedBox(
      height: 10,
    ));
    widgets.add(Container(
      child: Column(
        children: [
          Text(
            "Categorias",
            style: TextStyle(
                color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Container(
            child: Wrap(
              children: widget.categories
                  .map(
                    (element) => GestureDetector(
                      onTap: () => updateCategoriesId(element.id),
                      child: Container(
                        margin: EdgeInsets.symmetric(
                            horizontal: 5.0, vertical: 10.0),
                        height: 120,
                        width: 110.0,
                        decoration: BoxDecoration(
                          color: categoriesId.contains(element.id)
                              ? Color.fromRGBO(0, 133, 196, 1)
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
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.network(
                              element.iconUrl,
                              height: 60.0,
                              width: 60.0,
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(
                                  vertical: 10.0, horizontal: 1.0),
                              child: Text(
                                element.nombre != null ? element.nombre : "",
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
                  )
                  .toList(),
            ),
          ),
          SizedBox(
            height: 10.0,
          ),
          SizedBox(
            height: 10.0,
          ),
        ],
      ),
    ));
    widgets.add(Container(
      child: Column(
        children: [
          Divider(
            height: 2,
            color: Colors.black,
            endIndent: 2,
            indent: 2,
          ),
          SizedBox(
            height: 10.0,
          ),
          Text(
            "Localización",
            style: TextStyle(
                color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Container(
            child: Column(
              children: widget.municipalities
                  .map((e) => Container(
                        child: Column(
                          children: [
                            SizedBox(
                              height: 10.0,
                            ),
                            GestureDetector(
                              onTap: () => updateMunicipaliesId(e.id, true),
                              child: Container(
                                width: MediaQuery.of(context).size.width / 2.5,
                                height: 40,
                                alignment: Alignment.center,
                                margin: EdgeInsets.symmetric(
                                    horizontal: 10.0, vertical: 10),
                                decoration: BoxDecoration(
                                    color: municipalitiesIdParent.contains(e.id)
                                        ? Color.fromRGBO(0, 133, 196, 1)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8.0),
                                    border: Border.all(
                                        color: municipalitiesIdParent
                                                .contains(e.id)
                                            ? Colors.black
                                            : Color.fromRGBO(0, 133, 196, 1),
                                        width: 2)),
                                child: Text(
                                  e.nombre,
                                  style: TextStyle(
                                    color: municipalitiesIdParent.contains(e.id)
                                        ? Colors.white
                                        : Colors.black,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            Wrap(
                              children: e.municipalities
                                  .map(
                                    (seconElement) => GestureDetector(
                                      onTap: () => updateMunicipaliesId(
                                          seconElement.id, false),
                                      child: Container(
                                        width:
                                            MediaQuery.of(context).size.width /
                                                3,
                                        height: 40,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 6.0),
                                        alignment: Alignment.center,
                                        margin: EdgeInsets.symmetric(
                                            horizontal: 5.0, vertical: 10),
                                        decoration: BoxDecoration(
                                            color: municipalitiesId
                                                    .contains(seconElement.id)
                                                ? Color.fromRGBO(0, 133, 196, 1)
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            border: Border.all(
                                                color:
                                                    municipalitiesId.contains(
                                                            seconElement.id)
                                                        ? Colors.black
                                                        : Color.fromRGBO(
                                                            0, 133, 196, 1),
                                                width: 2)),
                                        child: Text(
                                          seconElement.nombre,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: municipalitiesId
                                                    .contains(seconElement.id)
                                                ? Colors.white
                                                : Colors.black,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            )
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    ));
    return widgets;
  }

  updateMunicipaliesId(String id, bool isParent) {
    List<String> aux = municipalitiesId;
    if (isParent) {
      int index =
          widget.municipalities.indexWhere((element) => element.id == id);
      if (municipalitiesIdParent.contains(id)) {
        widget.municipalities[index].municipalities.forEach((element) {
          aux.remove(element.id);
        });
        municipalitiesIdParent.remove(id);
      } else {
        widget.municipalities[index].municipalities.forEach((element) {
          if (!aux.contains(element.id)) aux.add(element.id);
        });
        municipalitiesIdParent.add(id);
      }
    } else {
      if (aux.contains(id))
        aux.remove(id);
      else
        aux.add(id);
    }
    if (mounted) {
      setState(() {
        municipalitiesId = aux;
      });
    }
    widget.presenter.updateNumber(categoriesId, municipalitiesId,
        (categoriesId.length + municipalitiesId.length), isOpen);
  }

  updateCategoriesId(String id) {
    List<String> aux = categoriesId;
    if (aux.contains(id))
      aux.remove(id);
    else
      aux.add(id);
    if (mounted) {
      setState(() {
        categoriesId = aux;
      });
    }
    widget.presenter.updateNumber(categoriesId, municipalitiesId,
        (categoriesId.length + municipalitiesId.length), isOpen);
  }

  updateIsOpen() {
    if (mounted) {
      setState(() {
        this.isOpen = !this.isOpen;
      });
    }
    widget.presenter.updateNumber(categoriesId, municipalitiesId,
        (categoriesId.length + municipalitiesId.length), isOpen);
  }
}
