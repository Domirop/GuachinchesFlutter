import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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
import 'package:guachinches/home/home_presenter.dart';
import 'package:guachinches/model/Category.dart';
import 'package:guachinches/model/fotos.dart';
import 'package:guachinches/model/restaurant.dart';
import 'package:guachinches/municipality_screen/municipality_screen.dart';
import 'package:http/http.dart';

import '../Categorias/categorias.dart';
import '../details/details.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> implements HomeView {
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
  String municipalityId = "Todos";
  String municipalityIdArea = "Todos";
  String municipalityNameArea = "Todos";
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
    final bannersCubit = context.read<BannersCubit>();
    remoteRepository = HttpRemoteRepository(Client());
    presenter = HomePresenter(
        remoteRepository, this, restaurantCubit, categoriesCubit, bannersCubit);
    presenter.getSelectedMunicipality();
    if (restaurantCubit.state is RestaurantInitial) {
      presenter.getAllRestaurants();
    }
    if (categoriesCubit.state is CategoriesInitial) {
      presenter.getAllCategories();
    }
    if (bannersCubit.state is BannersInitial) {
      presenter.getAllBanner();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _scrollPadding = MediaQuery.of(context).viewInsets.bottom;
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
                          municipalityId == null
                              ? municipalityNameArea == null
                                  ? ""
                                  : municipalityNameArea
                              : municipalityName,
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
            BlocBuilder<BannersCubit, BannersState>(builder: (context, state) {
              if (state is BannersLoaded) {
                return HeroSliderComponent(state.banners);
              } else {
                return Container();
              }
            }),
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
                margin: EdgeInsets.only(left: 15.0),
                child: BlocBuilder<CategoriesCubit, CategoriesState>(
                    builder: (context, state) {
                  if (state is CategoriesLoaded) {
                    return Container(
                      height: 120.0,
                      width: double.infinity,
                      child: ListView.builder(
                          shrinkWrap: true,
                          primary: false,
                          itemExtent: MediaQuery.of(context).size.width / 4,
                          itemCount: state.categories.length,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            return Wrap(
                              children: [
                                GestureDetector(
                                  onTap: () => categorySelected(
                                      state.categories[index].id),
                                  child: Container(
                                    height: 110,
                                    width: 80.0,
                                    decoration: BoxDecoration(
                                      color: selectedCategories.contains(
                                              state.categories[index].id)
                                          ? Color.fromRGBO(255, 255, 255, 0.85)
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
                                          state.categories[index].iconUrl,
                                          height: 60.0,
                                          width: 60.0,
                                        ),
                                        Container(
                                          margin: EdgeInsets.symmetric(
                                              vertical: 10.0, horizontal: 1.0),
                                          child: Text(
                                            state.categories[index].nombre !=
                                                    null
                                                ? state.categories[index].nombre
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
      this.municipalityIdArea = null;
      this.municipalityNameArea = null;
    });
  }

  @override
  setAreaMunicipality(String municipalityIdArea, String municipalityNameArea) {
    setState(() {
      this.municipalityIdArea = municipalityIdArea;
      this.municipalityNameArea = municipalityNameArea;
      this.municipalityName = null;
      this.municipalityId = null;
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
      children: restaurants.where((element) {
        print(municipalityId);
        print(municipalityIdArea);
        print(element.municipio.areaMunicipioId);
        print(element.municipio.id);
        if (municipalityId == null) {
          if (municipalityIdArea == "Todos") {
            return true;
          } else {
            if (element.municipio.areaMunicipioId == municipalityIdArea) {
              return true;
            } else {
              return false;
            }
          }
        } else {
          if (element.municipio.id == municipalityId) {
            print("5");
            return true;
          } else {
            print("6");
            return false;
          }
        }
      }).map((e) {
        bool condition = selectedCategories == "";
        for (int i = 0; i < e.categoriaRestaurantes.length; i++) {
          if (e.categoriaRestaurantes[i].categorias.id == selectedCategories) {
            condition = true;
          }
        }
        Fotos foto = e.fotos.firstWhere(
            (element) => element.type == "principal",
            orElse: () => null);
        return condition == true
            ? GestureDetector(
                onTap: () => gotoDetail(e),
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
                                      : AssetImage(
                                          "assets/images/Morenita.png"),
                                )),
                          ),
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.only(left: 20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.nombre != null ? e.nombre : "",
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
                                    e.direccion != null ? e.direccion : "",
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
                                    e.avg != null ? e.avg : "",
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
