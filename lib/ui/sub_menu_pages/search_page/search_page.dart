import 'dart:async';

import 'package:bottom_sheet/bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_state.dart';
import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/data/model/Municipality.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/Others/details/details.dart';
import 'package:guachinches/ui/sub_menu_pages/search_page/search_page_presenter.dart';
import 'package:http/http.dart';

class SearchPage extends StatefulWidget {
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
  List<Restaurant> restaurants1 = [];
  List<ModelCategory> categories = [];
  List<Municipality> municipalities = [];
  int numberPagination = 0;
  int numberPagination2 = 0;
  int currentIndex = 0;

  Widget tab1;
  Widget tab2;
  int numero = 0;
  bool isCharging = false;
  bool isChargingInitalRestaurants = true;
  TabController _tabController;

  @override
  void initState() {
    remoteRepository = HttpRemoteRepository(Client());
    final restaurantCubit = context.read<RestaurantCubit>();
    presenter = SearchPagePresenter(this, restaurantCubit, remoteRepository);
    if (restaurantCubit.state is RestaurantInitial) {
      presenter.getAllRestaurants(numberPagination);
      generateWidgetsTab1();
      generateWidgetsTab2();
    } else if (restaurantCubit.state is RestaurantLoaded) {
      generateWidgetsTab1();
      generateWidgetsTab2();
      presenter.setCharging();
    }
    presenter.getAllMunicipalitiesAndCategories();
    controller2 = new ScrollController();
    controller1 = new ScrollController();
    _tabController = TabController(length: 3, vsync: this);
    controller2.addListener(_scrollListener2);
    controller1.addListener(_scrollListener1);
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
        List aux = restaurants1;
        aux.addAll(state.restaurantResponse.restaurants);
        restaurants1 = aux;
        return Wrap(
            children: aux
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
                            image: NetworkImage(
                                "https://louvre.s3.fr-par.scw.cloud/guachinches/184954223_928922927895837_779066988885510655_n.jpeg"),
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
    Timer(Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          numberPagination += 15;
        });
      }
      presenter.getAllRestaurants(numberPagination);
      generateWidgetsTab1();
    });
    Timer(Duration(milliseconds: 2000), () {
      controller1.addListener(_scrollListener1);
    });
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
    Timer(Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          numberPagination2 += 15;
        });
      }
      presenter.getAllRestaurants(numberPagination2);
      generateWidgetsTab2();
    });
    Timer(Duration(milliseconds: 2000), () {
      controller2.addListener(_scrollListener2);
    });
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
        List aux = restaurants;
        aux.addAll(state.restaurantResponse.restaurants);
        restaurants = aux;
        return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: aux
                .map((e) => GestureDetector(
                      onTap: () =>
                          GlobalMethods().pushPage(context, Details(e.id)),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.98,
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
                                    image: DecorationImage(
                                      repeat: ImageRepeat.noRepeat,
                                      alignment: Alignment.center,
                                      fit: BoxFit.fill,
                                      image: NetworkImage(
                                          "https://louvre.s3.fr-par.scw.cloud/guachinches/184954223_928922927895837_779066988885510655_n.jpeg"),
                                    ),
                                  ),
                                ),
                                Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.60,
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.3,
                                              child: Column(
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
                                                    e.destacado,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Container(),
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

  _openBottomSheetWithInfo(BuildContext context) {
    showFlexibleBottomSheet<void>(
      bottomSheetColor: Colors.transparent,
      isExpand: true,
      initHeight: 0.8,
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
        return BottomSheet(municipalities, categories, controllerModal, this,
            presenter, remoteRepository);
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
            onTap: () => _openBottomSheetWithInfo(context),
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
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintStyle: TextStyle(color: Color.fromRGBO(0, 133, 196, 1)),
              filled: true,
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
                  Icon(Icons.directions_bike),
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
  updateNumber(int number) {
    if (mounted) {
      setState(() {
        this.numero = number;
      });
    }
  }
}

class BottomSheet extends StatefulWidget {
  List<ModelCategory> categories;
  List<Municipality> municipalities;
  final ScrollController controller;
  SearchPageView searPage;
  RemoteRepository remoteRepository;
  SearchPagePresenter presenter;

  BottomSheet(this.municipalities, this.categories, this.controller,
      this.searPage, this.presenter, this.remoteRepository);

  @override
  State<BottomSheet> createState() => _BottomSheetState();
}

class _BottomSheetState extends State<BottomSheet> {
  List<String> municipalitiesId = [];
  List<String> municipalitiesIdParent = [];
  List<String> categoriesId = [];

  @override
  void initState() {}

  @override
  void dispose() {
    super.dispose();
    // presenter.getAllRestaurantsFilters(categoriesId.join(","), municipalitiesId.join(","),"",true);
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
      widget.presenter
          .updateNumber(municipalitiesId.length + categoriesId.length);
    }
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
    widget.presenter
        .updateNumber(municipalitiesId.length + categoriesId.length);
  }
}
