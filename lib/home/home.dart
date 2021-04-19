import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/data/cubit/restaurant_cubit.dart';
import 'package:guachinches/data/cubit/restaurant_state.dart';
import 'package:guachinches/data/cubit/restaurant_state.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/home/home_presenter.dart';
import 'package:guachinches/model/Category.dart';
import 'package:guachinches/model/CategoryRestaurant.dart';
import 'package:guachinches/model/restaurant.dart';
import 'package:guachinches/municipality_screen/municipality_screen.dart';
import 'package:http/http.dart';

import '../details.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> implements HomeView {
  int _current = 0;
  final List<String> imgList = [
    'assets/images/car.png',
    'assets/images/car.png',
    'assets/images/car.png',
    'assets/images/car.png'
  ];
  final List<String> iconsList = [
    'assets/images/playtime.png',
    'assets/images/parking.png',
    'assets/images/schedule.png',
    'assets/images/pig.png',
    'assets/images/cow.png',
    'assets/images/fish.png'
  ];

  String selectedCategories = "";

  List<Restaurant> restaurants = [];
  List<Category> categories = [];
  String municipalityId = "";
  String municipalityName = "Todos";
  HomePresenter presenter;
  RemoteRepository remoteRepository;
  @override
  void initState() {
    final restaurantCubit = context.read<RestaurantCubit>();

    remoteRepository = HttpRemoteRepository(Client());
    presenter = HomePresenter(remoteRepository,this );

    presenter.getSelectedMunicipality();
    presenter.getAllRestaurants();
    presenter.getAllCategories();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
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
                  onTap: ()=>goToSelectMunicipality(),
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
                Icon(
                  Icons.search,
                  color: Colors.black,
                  size: 40.0,
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
                  aspectRatio: 2.0,
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
                  Text(
                    'Ver todas',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.0,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 20.0,
            ),
            Row(

                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: categories
                    .map((e) => GestureDetector(
                    onTap: ()=> categorySelected(e.id),
                      child: new Container(
                            height: 72.0,
                            width: MediaQuery.of(context).size.width * 0.143,
                            decoration: BoxDecoration(
                              color: selectedCategories.contains(e.id) ? Colors.black12 :Colors.white,
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
                    ))
                    .toList()),
            SizedBox(
              height: 20.0,
            ),
            Container(
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
                  Icon(Icons.keyboard_arrow_down),
                  Text(
                    'Valoración',
                    style: TextStyle(fontSize: 12.0, color: Colors.black),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 20.0,
            ),
            Container(
              child: Column(
                children: restaurants.where((element) => element.negocioMunicipioId == municipalityId || municipalityId == "")
                    .map((e) {
                      bool condition = selectedCategories == "";
                      for(int i = 0; i< e.categoriaRestaurantes.length; i++){
                        if(e.categoriaRestaurantes[i].categorias.id == selectedCategories){
                            condition = true;
                        }
                      }
                      return condition == true?
                    new Container(margin: EdgeInsets.symmetric(horizontal:
                    10.0),
                child: GestureDetector(
                  onTap: () => gotoDetail(),
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
                                  image: AssetImage(
                                      'assets/images/Morenita.png'),
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
                                    "Oferta en carne cabra",
                                    style: TextStyle(
                                      color: Color.fromRGBO(226, 120, 120, 1),
                                      fontSize: 12.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
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
              ): Container();})
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  gotoDetail(){
    GlobalMethods().pushPage(context, Details());
  }

  @override
  setAllRestaurants(List<Restaurant> restaurants) {
    setState(() {
      this.restaurants = restaurants;
    });
  }
  @override
  setAllCategories(List<Category> categories) {
    setState(() {
      this.categories = categories;
    });
  }

  categorySelected(String categoryUuid) {
    setState(() {
      if(selectedCategories == categoryUuid){
        selectedCategories = "";
      }else{
      selectedCategories = categoryUuid;
      }
    });
  }
  goToSelectMunicipality(){
    GlobalMethods().pushAndReplacement(context, MunicipalityScreen());
  }

  @override
  setMunicipality(String municipalityName, String municipalityId) {
  setState(() {
    this.municipalityName = municipalityName;
    this.municipalityId = municipalityId;
  });
  }
}
