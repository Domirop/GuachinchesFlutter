import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/data/cubit/categories_cubit.dart';
import 'package:guachinches/data/cubit/categories_state.dart';
import 'package:guachinches/data/cubit/restaurant_cubit.dart';
import 'package:guachinches/data/cubit/restaurant_state.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/home/home_presenter.dart';
import 'package:guachinches/model/Category.dart';
import 'package:guachinches/model/restaurant.dart';
import 'package:guachinches/municipality_screen/municipality_screen.dart';
import 'package:http/http.dart';

import '../Categorias/categorias.dart';
import '../details.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home>
    implements HomeView {
  int _current = 0;
  final List<String> imgList = [
    'assets/images/car.png',
    'assets/images/carne.png',
    'assets/images/fondoDetails.png',
    'assets/images/mojoPicon.png'
  ];
  double _scrollPadding;
  bool isDescendent = false;
  String selectedCategories = "";
  List<Restaurant> restaurants = [];
  List<ModelCategory> categories = [];
  String municipalityId = "";
  String municipalityName = "Todos";
  GlobalKey inputFocus = GlobalKey();
  HomePresenter presenter;
  RemoteRepository remoteRepository;
  Icon iconRow = Icon(Icons.keyboard_arrow_down);
  bool isSearching = false;
  TextEditingController textFieldBuscar = new TextEditingController();

  @override
  void initState() {
    final restaurantCubit = context.read<RestaurantCubit>();
    final categoriesCubit = context.read<CategoriesCubit>();
    remoteRepository = HttpRemoteRepository(Client());
    presenter =
        HomePresenter(remoteRepository, this, restaurantCubit, categoriesCubit);
    presenter.getSelectedMunicipality();
    if (restaurantCubit.state is RestaurantInitial) {
      presenter.getAllRestaurants();
    }
    if (categoriesCubit.state is CategoriesInitial) {
      presenter.getAllCategories();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _scrollPadding = MediaQuery.of(context).viewInsets.bottom;
    final List<Widget> imageSliders = imgList
        .map((item) => Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                image: DecorationImage(
                  repeat: ImageRepeat.noRepeat,
                  alignment: Alignment.center,
                  fit: BoxFit.cover,
                  image: AssetImage(item),
                ),
              ),
            ))
        .toList();
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 40.0,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Image(
                  image: AssetImage('assets/images/logo.png'),
                  height: 40.0,
                  width: 40.0,
                ),
                GestureDetector(
                  onTap: () => goToSelectMunicipality(),
                  child: Container(
                    height: 60,
                    color: Colors.transparent,
                    child: Row(
                      children: [
                        Text(
                          municipalityName,
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.black,
                          size: 20.0,
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: createSearch,
                  child: Icon(
                    Icons.search,
                    color: Colors.black,
                    size: 40.0,
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 20.0,
            ),
            CarouselSlider(
              items: imageSliders,
              options: CarouselOptions(
                  autoPlay: true,
                  viewportFraction: 0.9,
                  enlargeCenterPage: true,
                  aspectRatio: 12 / 6,
                  onPageChanged: (index, reason) {
                    setState(() {
                      _current = index;
                    });
                  }),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: imgList.map((url) {
                int index = imgList.indexOf(url);
                return Container(
                  width: 8.0,
                  height: 8.0,
                  margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _current == index
                        ? Colors.black
                        : Color.fromRGBO(196, 196, 196, 1),
                  ),
                );
              }).toList(),
            ),
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
              child: BlocBuilder<CategoriesCubit, CategoriesState>(
                  builder: (context, state) {
                if (state is CategoriesLoaded) {
                  return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: state.categories
                          .map(
                            (e) => GestureDetector(
                              onTap: () => categorySelected(e.id),
                              child: new Container(
                                height: 72.0,
                                width:
                                    MediaQuery.of(context).size.width * 0.143,
                                decoration: BoxDecoration(
                                  color: selectedCategories.contains(e.id)
                                      ? Colors.black12
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(10.0),
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 1,
                                  ),
                                ),
                                child: Stack(
                                  overflow: Overflow.visible,
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    Positioned(
                                      top: -15.0,
                                      child: Image(
                                        image: NetworkImage(e.iconUrl),
                                        height: 40.0,
                                        width: 40.0,
                                      ),
                                    ),
                                    Text(
                                      e.nombre,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 12.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList());
                }
                return Container();
              }),
            ),
            SizedBox(
              height: 20.0,
            ),
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
                    iconRow == null ? Icon(Icons.keyboard_arrow_down) : iconRow,
                    Text(
                      'Valoración',
                      style: TextStyle(fontSize: 12.0, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 20.0,
            ),
            isSearching
                ? Padding(
                    padding: EdgeInsets.only(bottom: _scrollPadding / 2),
                    child: Column(
                      children: [
                        TextFormField(
                          key: inputFocus,
                          scrollPadding: EdgeInsets.only(
                              bottom:
                                  MediaQuery.of(context).size.height - 200.0),
                          autofocus: true,
                          keyboardType: TextInputType.text,
                          controller: textFieldBuscar,
                          decoration: InputDecoration(
                            hintText: "Buscar",
                            hintStyle: TextStyle(
                              color: Colors.black,
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                            border: InputBorder.none,
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.black,
                            ),
                          ),
                          onChanged: searchGuachinche,
                        ),
                        Divider(
                          color: Colors.black,
                          endIndent: 30,
                          indent: 30,
                        ),
                        SizedBox(
                          height: 10.0,
                        ),
                      ],
                    ),
                  )
                : Container(),
            Container(
              child: BlocBuilder<RestaurantCubit, RestaurantState>(
                  builder: (context, state) {
                if (state is RestaurantLoaded) {
                  restaurants = state.restaurants;
                  return componentStateBuilder(state.restaurants);
                }
                if (state is RestaurantFilter) {
                  return componentStateBuilder(state.filtersRestaurants);
                }
                return Container();
              }),
            ),
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
    setState(() {
      this.restaurants = restaurants;
    });
  }

  @override
  setAllCategories(List<ModelCategory> categories) {
    setState(() {
      this.categories = categories;
    });
  }

  categorySelected(String categoryUuid) {
    setState(() {
      if (selectedCategories == categoryUuid) {
        selectedCategories = "";
      } else {
        selectedCategories = categoryUuid;
      }
    });
  }

  goToSelectMunicipality() {
    GlobalMethods().pushAndReplacement(context, MunicipalityScreen());
  }

  @override
  setMunicipality(String municipalityName, String municipalityId) {
    setState(() {
      this.municipalityName = municipalityName;
      this.municipalityId = municipalityId;
    });
  }

  reorderList() {
    List<Restaurant> aux = restaurants;
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
    setState(() {
      restaurants = aux;
      isDescendent = !isDescendent;
      iconRow = iconAux;
    });
  }

  searchGuachinche(e) {
    presenter.getRestaurantsFilter(restaurants, e);
  }

  createSearch() {
    setState(() {
      isSearching = !isSearching;
      textFieldBuscar.text = "";
    });
  }

  Widget componentStateBuilder(List<Restaurant> restaurants) {
    return Column(
      children: restaurants
          .where((element) =>
              element.negocioMunicipioId == municipalityId ||
              municipalityId == "")
          .map((e) {
        bool condition = selectedCategories == "";
        for (int i = 0; i < e.categoriaRestaurantes.length; i++) {
          if (e.categoriaRestaurantes[i].categorias.id == selectedCategories) {
            condition = true;
          }
        }
        return condition == true
            ? Container(
                margin: EdgeInsets.symmetric(horizontal: 10.0),
                child: GestureDetector(
                  onTap: () => gotoDetail(e),
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
                                  image:
                                      AssetImage('assets/images/Morenita.png'),
                                )),
                          ),
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.only(left: 20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.nombre,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "Carne fiesta",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 12.0,
                                    ),
                                  ),
                                  Text(
                                    e.direccion,
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12.0,
                                    ),
                                  ),
                                  Text(
                                    e.destacado != null ? e.destacado : "",
                                    style: TextStyle(
                                      color: Color.fromRGBO(226, 120, 120, 1),
                                      fontSize: 12.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          e.avg == "NaN"
                              ? Container()
                              : Container(
                                  width: 48.0,
                                  height: 24.0,
                                  decoration: BoxDecoration(
                                    color: Color.fromRGBO(149, 194, 55, 1),
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                  child: Text(
                                    e.avg,
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
              )
            : Container();
      }).toList(),
    );
  }
}
