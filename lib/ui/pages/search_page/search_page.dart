import 'dart:async';
import 'package:bottom_sheet/bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/cupones/cupones_cubit.dart';
import 'package:guachinches/data/cubit/cupones/cupones_state.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_state.dart';
import 'package:guachinches/data/defaultData/allIsland.dart';
import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/data/model/CuponesAgrupados.dart';
import 'package:guachinches/data/model/Island.dart';
import 'package:guachinches/data/model/Municipality.dart';
import 'package:guachinches/data/model/SimpleMunicipality.dart';
import 'package:guachinches/data/model/Types.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/components/cards/restaurantListCard.dart';
import 'package:guachinches/ui/pages/changeIsland/change_island.dart';
import 'package:guachinches/ui/pages/details/details.dart';
import 'package:guachinches/ui/pages/search_page/search_page_presenter.dart';
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
  List<Types> types = [];
  int numberPagination = 0;
  int numberPagination2 = 0;
  int currentIndex = 0;
  List<String> municipalitiesId = [];
  List<String> categoriesId = [];
  List<String> typesId = [];
  String textValue = "";
  final storage = new FlutterSecureStorage();
  Island island = new Island('', '', '');
  Widget tab1;
  Widget tab2;
  Widget tab3;
  int activeFilterNumber = 0;
  bool isCharging = false;
  bool isChargingInitalRestaurants = true;
  TabController _tabController;
  var restaurantCubit;


  @override
  void initState() {

    remoteRepository = HttpRemoteRepository(Client());
    restaurantCubit = context.read<RestaurantCubit>();
    final cuponesCubit = context.read<CuponesCubit>();
    generateWidgetsTab1(restaurants);
    generateWidgetsTab2(restaurants);
    generateWidgetsTab3();

    presenter = SearchPagePresenter(
        this, restaurantCubit, cuponesCubit, remoteRepository);
    getIsland();
    presenter.getAllMunicipalitiesCategoriesAndTypes('76ac0bec-4bc1-41a5-bc60-e528e0c12f4d');
    controller2 = new ScrollController();
    controller1 = new ScrollController();
    _tabController = TabController(length: 3, vsync: this);
    controller2.addListener(_scrollListener2);
    controller1.addListener(_scrollListener1);
    _tabController.addListener(tabListenerFunction);
  }

  getIsland() async {
    String value = await storage.read(key: 'islandId');

    if(value==null){
      String defaultIsland = '76ac0bec-4bc1-41a5-bc60-e528e0c12f4d';
      await storage.write(key: 'islandId', value: defaultIsland);
      value = defaultIsland;
    }
    presenter.getAllMunicipalitiesCategoriesAndTypes(AllIsland().getIslandById(value).id);
    if(island.id != value){
      numberPagination = 0;
      restaurants = [];
      presenter.getAllRestaurantsPag1(0);
    }
    setState(() {
        island = AllIsland().getIslandById(value);
    });

  }




  tabListenerFunction() {
    if (restaurantCubit.state is RestaurantFilter &&
        (_tabController.index == 2 || _tabController.index == 0)) {
      numberPagination = 0;
      numberPagination2 = 0;
      presenter.getAllRestaurants(0,island.id);
      generateWidgetsTab1(restaurants);
      generateWidgetsTab2(restaurants);
      controller2.addListener(_scrollListener2);
      if (mounted) {
        setState(() {
          activeFilterNumber = 0;
          categoriesId = [];
          municipalitiesId = [];
          typesId = [];
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

  generateWidgetsTab1(List<Restaurant> restaurantsParam) {
    restaurants.addAll(restaurantsParam);
    List<Restaurant> auxList = restaurants;
    Widget aux = Wrap(
            children:auxList.length>0? auxList
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
                      ),
                    ))
                .toList():[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container( child: Center(child: Text('Vaya! Parece que no hay restaurantes. Estamos trabajando para llegar al mayor número de sitios')),),
                  )
        ]
        );

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
    numberPagination+= 15;
    Timer(Duration(milliseconds: 500), () {
      presenter.getAllRestaurantsPag1(numberPagination);
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

  generateWidgetsTab2(List<Restaurant> restaurantsParams) async {
    List auxList = [];
    print(activeFilterNumber);
    if(activeFilterNumber>0 || textValue.length>2){
      auxList = restaurantsParams;

    }else{
      auxList = restaurants;
    }
    if (isOpen) {
      auxList = auxList.where((element) => element.open).toList();
    }
    Widget widget = Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children:auxList.length>0?auxList
              .map((e) => RestaurantListCard(e)).toList():[Text('Vaya!Parece que no hay resultados')],),
    );
    await Future.delayed(Duration(milliseconds: 500));

    setState(() {
      tab2 = widget;
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
    showStickyFlexibleBottomSheet<void>(
      bottomSheetColor: Colors.transparent,
      isExpand: true,
      initHeight: 0.7,
      maxHeight: 0.88,
      context: context,
      barrierColor: Colors.transparent,
      headerHeight: 70,
      keyboardBarrierColor: Colors.transparent,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topRight: Radius.circular(20.0), topLeft: Radius.circular(20.0)),
      ),
      headerBuilder: (BuildContext contextModal, double offset) {
        return Container(
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              GestureDetector(
                onTap: () => {
                  presenter.updateNumber([], [], [], 0, false),
                  GlobalMethods().popPage(contextModal)
                },
                child: Text(
                  "Borrar Filtros",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => GlobalMethods().popPage(contextModal),
                child: Container(
                  width: MediaQuery.of(context).size.width / 3,
                  alignment: Alignment.center,
                  margin: EdgeInsets.symmetric(vertical: 10.0),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(0, 133, 196, 1),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 7.0),
                  child: Text(
                    "Ver resultados",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 12.0),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      bodyBuilder: (BuildContext context, double offset) {
        return SliverChildListDelegate(
          <Widget>[
            BottomSheet(municipalities, categories, this, presenter,
                remoteRepository, municipalitiesId, categoriesId, types, typesId, isOpen)
          ],
        );
      },
    );
  }

  generateAppBar(context) {
    return AppBar(
      toolbarHeight: 100, // Set this height
      actions: [
      ],
      titleSpacing: 1,
      leadingWidth: 0,
      title: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
                height: 60,
                width: double.infinity,
                padding: EdgeInsets.all(10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: TextField(
                        onTap: inputSearchFunction,
                        onChanged: (text) {
                          if (mounted) {
                            setState(() {
                              this.textValue = text;
                            });
                          }
                            presenter.getAllRestaurantsFilters(isOpen,
                                categories: categoriesId,
                                municipalities: municipalitiesId,
                                types: typesId,
                                text: text,
                                number: activeFilterNumber,
                                islandId: island.id

                            );
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
                      ),
                    ),
                    Container(
                      height: 80,
                      padding: EdgeInsets.only(left: 8),
                      child: GestureDetector(
                        onTap: () {
                          inputSearchFunction();
                          _openBottomSheetWithInfo(context);
                        },
                        child: Container(
                          width: 100,
                          height: 80,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(0, 133, 196, 1),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Center(
                            child: Text(
                              "Filtros - " + activeFilterNumber.toString(),
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
                )),
            Padding(
              padding: const EdgeInsets.fromLTRB(10,0,10,0),
              child: GestureDetector(
                onTap: () =>Navigator.of(context)
                        .push(MaterialPageRoute(
                      builder: (context) => ChangeIsland(),
                    )).then((value) {
                        getIsland();
                    }),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                    color:  Color.fromRGBO(237, 230, 215, 0.42),
                  ),
                  height: 40,
                  width: double.infinity,
                  padding: EdgeInsets.all(10.0),
                  child: island.id.length>0?Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       Container(height:28,width: 28,
                           child: Image.asset('assets/images/'+island.photo)),
                      Text(island.name,style: TextStyle(color: Colors.black),),
                    ],
                  ):null),
              ),
            )
          ],
        ),
      ),
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
      elevation: 0,
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
                                      Colors.blue),
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
  setMunicipalitiesCategoriesAndTypes(
      List<ModelCategory> categories, List<Municipality> municipality, List<Types> types) {
    if (mounted) {
      setState(() {
        this.categories = categories;
        this.municipalities = municipality;
        this.types = types;
      });
    }
  }

  @override
  updateNumber(List<String> categories, List<String> municipalities, List<String> types, int number,
      bool isOpen) {
    if (mounted) {
      setState(() {
        this.activeFilterNumber = number;
        this.categoriesId = categories;
        this.municipalitiesId = municipalities;
        this.typesId = typesId;
        this.isOpen = isOpen;
      });
    }
  }

  @override
  generateWidgetTab1(List<Restaurant> restaurants) {
    generateWidgetsTab1(restaurants);
    generateWidgetsTab2(restaurants);
  }

  @override
  generateWidgetTab2(List<Restaurant> restaurants) {
    generateWidgetsTab2(restaurants);
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
        types: typesId,
        number: activeFilterNumber,
        text: aux,
        islandId:island.id,
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
  List<Types> types;
  SearchPageView searPage;
  List<String> municipalitiesId = [];
  List<String> categoriesId = [];
  List<String> typesId = [];
  bool isOpen = false;
  RemoteRepository remoteRepository;
  SearchPagePresenter presenter;

  BottomSheet(
      this.municipalities,
      this.categories,
      this.searPage,
      this.presenter,
      this.remoteRepository,
      this.municipalitiesId,
      this.categoriesId,
      this.types,
      this.typesId,
      this.isOpen);

  @override
  State<BottomSheet> createState() =>
      _BottomSheetState(municipalitiesId, categoriesId, isOpen, typesId);
}

class _BottomSheetState extends State<BottomSheet> {
  List<String> municipalitiesId = [];
  List<String> municipalitiesIdParent = [];
  List<String> typesId = [];
  List<String> categoriesId = [];
  bool isOpen = false;
  bool limitMunicipalities = true;
  bool limitType = true;
  bool limitCategories = true;

  _BottomSheetState(this.municipalitiesId, this.categoriesId, this.isOpen, this.typesId);

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
      padding: EdgeInsets.all(8.0),
      child: Column(
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
      width: MediaQuery.of(context).size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Establecimiento",
            style: TextStyle(
                color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(
            height: 10,
          ),
          Center(
            child: Container(
              child: Wrap(
                children: limitType
                    ? generateListTypes(
                    widget.types.getRange(0, 6).toList())
                    : generateListTypes(widget.types),
              ),
            ),
          ),
          limitType
              ? GestureDetector(
            onTap: () => {
              if (mounted)
                {
                  setState(() {
                    limitType = false;
                  })
                }
            },
            child: Center(
              child: Text(
                "Ver más",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                  color: Color.fromRGBO(0, 189, 195, 1),
                ),
              ),
            ),
          )
              : GestureDetector(
            onTap: () => {
              if (mounted)
                {
                  setState(() {
                    limitType = true;
                  })
                }
            },
            child: Center(
              child: Text(
                "Ver menos",
                style: TextStyle(
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 20.0,
          ),
        ],
      ),
    ));
    widgets.add(SizedBox(
      height: 10,
    ));
    widgets.add(Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Categorias",
            style: TextStyle(
                color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Container(
            child: Wrap(
              children: limitCategories
                  ? generateListCategories(
                      widget.categories.getRange(0, 6).toList())
                  : generateListCategories(widget.categories),
            ),
          ),
          limitCategories
              ? GestureDetector(
                  onTap: () => {
                    if (mounted)
                      {
                        setState(() {
                          limitCategories = false;
                        })
                      }
                  },
                  child: Center(
                    child: Text(
                      "Ver más",
                      style: TextStyle(
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                        color: Color.fromRGBO(0, 189, 195, 1),
                      ),
                    ),
                  ),
                )
              : GestureDetector(
                  onTap: () => {
                    if (mounted)
                      {
                        setState(() {
                          limitCategories = true;
                        })
                      }
                  },
                  child: Center(
                    child: Text(
                      "Ver menos",
                      style: TextStyle(
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
          SizedBox(
            height: 20.0,
          ),
        ],
      ),
    ));
    widgets.add(Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Container(
            width: MediaQuery.of(context).size.width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
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
                              children: e.limitSearch
                                  ? e.municipalities.length>6
                              ? generateListMunicipalities(
                                      e.municipalities.getRange(0, 6).toList())
                                : generateListMunicipalities(
                                e.municipalities)
                                  : generateListMunicipalities(
                                      e.municipalities),
                            ),
                            e.limitSearch
                                ? Container(
                                    width: MediaQuery.of(context).size.width,
                                    child: GestureDetector(
                                      onTap: () => {
                                        if (mounted)
                                          {
                                            setState(() {
                                              e.limitSearch = false;
                                            })
                                          }
                                      },
                                      child: Center(
                                        child: Text(
                                          "Ver más",
                                          style: TextStyle(
                                            fontSize: 16,
                                            decoration: TextDecoration.underline,
                                            color: Color.fromRGBO(0, 189, 195, 1),

                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: MediaQuery.of(context).size.width,
                                    child: GestureDetector(
                                      onTap: () => {
                                        if (mounted)
                                          {
                                            setState(() {
                                              e.limitSearch = true;
                                            })
                                          }
                                      },
                                      child: Center(
                                        child: Text(
                                          "Ver menos",
                                          style: TextStyle(
                                            fontSize: 16,
                                            decoration: TextDecoration.underline,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
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

  generateListCategories(List<ModelCategory> categories) {
    return categories
        .map(
          (element) => GestureDetector(
            onTap: () => updateCategoriesId(element.id),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
              height: 120,
              width: 110.0,
              decoration: BoxDecoration(
                color: categoriesId.contains(element.id)
                    ? Color.fromRGBO(0, 133, 196, 1)
                    : Colors.white,
                border: Border.all(color:Color.fromRGBO(0, 133, 196, 1),width: 2.0),
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
                    margin:
                        EdgeInsets.symmetric(vertical: 10.0, horizontal: 1.0),
                    child: Text(
                      element.nombre != null ? element.nombre : "",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: categoriesId.contains(element.id)
                            ?Colors.white:Colors.black,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .toList();
  }

  generateListTypes(List<Types> types) {
    return types
        .map(
          (element) => GestureDetector(
            onTap: () => updateTypesId(element.id),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
              height: 50,
              width: 120.0,
              decoration: BoxDecoration(
                  color: typesId.contains(element.id) ? Color.fromRGBO(0, 133, 196, 1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                      color: typesId.contains(element.id) ? Color.fromRGBO(0, 133, 196, 1) : Color.fromRGBO(0, 133, 196, 1),
                      width: 2)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                     Text(
                       element.nombre != null ? element.nombre : "",
                       textAlign: TextAlign.center,
                       style: TextStyle(
                         color: typesId.contains(element.id) ? Colors.white:Colors.black,
                         fontSize: 12.0,
                       ),
                     ),
                ],
              ),
            ),
          ),
        )
        .toList();
  }

  generateListMunicipalities(List<SimpleMunicipality> municipalities) {
    return municipalities
        .map(
          (seconElement) => GestureDetector(
            onTap: () => updateMunicipaliesId(seconElement.id, false),
            child: Container(
              width: MediaQuery.of(context).size.width / 3,
              height: 40,
              padding: EdgeInsets.symmetric(horizontal: 6.0),
              alignment: Alignment.center,
              margin: EdgeInsets.symmetric(horizontal: 5.0, vertical: 10),
              decoration: BoxDecoration(
                  color: municipalitiesId.contains(seconElement.id)
                      ? Color.fromRGBO(0, 133, 196, 1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                      color: municipalitiesId.contains(seconElement.id)
                          ? Color.fromRGBO(0, 133, 196, 1)
                          : Color.fromRGBO(0, 133, 196, 1),
                      width: 2)),
              child: Text(
                seconElement.nombre,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: municipalitiesId.contains(seconElement.id)
                      ? Colors.white
                      : Colors.black,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        )
        .toList();
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
    widget.presenter.updateNumber(categoriesId, municipalitiesId, typesId,
        (categoriesId.length + municipalitiesId.length + typesId.length), isOpen);
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
    widget.presenter.updateNumber(categoriesId, municipalitiesId, typesId,
        (categoriesId.length + municipalitiesId.length + typesId.length), isOpen);
  }

  updateTypesId(String id) {
    List<String> aux = typesId;
    if (aux.contains(id))
      aux.remove(id);
    else
      aux.add(id);
    if (mounted) {
      setState(() {
        typesId = aux;
      });
    }
    widget.presenter.updateNumber(categoriesId, municipalitiesId, typesId,
        (categoriesId.length + municipalitiesId.length + typesId.length), isOpen);
  }

  updateIsOpen() {
    if (mounted) {
      setState(() {
        this.isOpen = !this.isOpen;
      });
    }
    widget.presenter.updateNumber(categoriesId, municipalitiesId, typesId,
        (categoriesId.length + municipalitiesId.length + typesId.length), isOpen);
  }
}
