import 'package:flutter/material.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/data/cubit/banners/banners_cubit.dart';
import 'package:guachinches/data/cubit/banners/banners_state.dart';
import 'package:guachinches/data/cubit/cupones/cupones_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_state.dart';
import 'package:guachinches/data/cubit/restaurants/top/top_restaurant_state.dart';
import 'package:guachinches/data/cubit/restaurants/top/top_restaurants_cubit.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/data/cubit/user/user_state.dart';
import 'package:guachinches/data/model/CuponesAgrupados.dart';
import 'package:guachinches/data/model/TopRestaurants.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/components/app_Bars/appbar_basic.dart';
import 'package:guachinches/ui/components/cards/topRestaurantCard.dart';
import 'package:guachinches/ui/components/cards/restaurantOpenCard.dart';
import 'package:guachinches/ui/components/cupones/cupones_list.dart';
import 'package:guachinches/ui/components/heroSliderComponent.dart';
import 'package:guachinches/ui/pages/home/home_presenter.dart';
import 'package:guachinches/ui/pages/restaurantsShowMore/restaurantsShowMore.dart';
import 'package:guachinches/ui/pages/restaurantsShowMore/restaurantsShowMoreGuachinches.dart';
import 'package:http/http.dart';

class Home extends StatefulWidget {
  List<TopRestaurants> restaurants = [];
  bool isChargingInitalRestaurants = true;

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> implements HomeView {
  AppBarBasic appBarBasic;

  bool doRequest = false;
  bool isCharging = false;
  int menuRestaurantSelected = 0;
  List<String> menuOptions = ['Top mejores','Abiertos'];

  HomePresenter presenter;
  List<Widget> screens;
  RemoteRepository remoteRepository;
  bool isCorrectSaveCupon;
  Widget restaurantsWidgets;
  Widget openRestaurantsWidgets;
  Widget menuRestaurants;
  String userId;
  List<String> assets = [
    "assets/images/firstTop.png",
    "assets/images/secondTop.png",
    "assets/images/thirdTop.png",
    "assets/images/otherTop.png",
    "assets/images/otherTop.png"
  ];
  List<CuponesAgrupados> cuponesAgrupados = [];
  bool userIdSearched = false;
  @override
  void initState() {

    super.initState();
    final topRestaurantCubit = context.read<TopRestaurantCubit>();
    final cuponesCubit = context.read<CuponesCubit>();
    final bannersCubit = context.read<BannersCubit>();
    final userCubit = context.read<UserCubit>();
    final restaurantsCubit = context.read<RestaurantCubit>();
    remoteRepository = HttpRemoteRepository(Client());
    presenter = HomePresenter(this, topRestaurantCubit, bannersCubit,
        cuponesCubit, userCubit, remoteRepository,restaurantsCubit);
    presenter.getUserInfo();
    presenter.getCupones();
    if (bannersCubit.state is BannersInitial) {
      presenter.getAllBanner();
    }
    if (restaurantsCubit.state is RestaurantInitial|| restaurantsCubit.state is RestaurantLoaded){
      presenter.getAllRestaurants();
      createOpenListWidget();
    }
    if (userCubit.state is UserInitial) {
      presenter.getScreens();
    } else if (userCubit.state is UserLoaded) {
      presenter.getScreens();
    }
    if (topRestaurantCubit.state is TopRestaurantInitial) {
      presenter.getTopRestaurants();
      menuRestaurants = createMenuForRestaurants();
      createListWidgetForRestaurants();
    } else if (topRestaurantCubit.state is TopRestaurantLoaded) {
      createListWidgetForRestaurants();
    }
  }

  @override
  Widget build(BuildContext context) {

    appBarBasic = AppBarBasic(widget, screens);
    return Scaffold(
      appBar: appBarBasic.createWidget(context),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(left: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 20.0,
            ),
            cuponesAgrupados.length<0?Padding(
              padding: const EdgeInsets.only(left:8.0),
              child: Text('Cupones descuento',style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  foreground: Paint()..shader = linearGradient
              ),),
            ):Container(),
            SizedBox(
              height: 20.0,
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
            SizedBox(
              height: 20.0,
            ),
            Container(
              child:cuponesAgrupados.length>0&&userIdSearched? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left:8.0),
                    child: Text('Cupones',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        foreground: Paint()..shader = linearGradient
                    ),),
                  ),
                  CuponesList(cuponesAgrupados,userId)
                ],
              ):Container(),
            ),
            Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left:8.0),
                    child: Text('DESTACADOS',style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        foreground: Paint()..shader = linearGradient

                    ),),
                  ),

                  createMenuForRestaurants()
                ],
              ),
            ),
            SizedBox(
              height: 10.0,
            ),
            Container(
              child: menuRestaurantSelected==0?restaurantsWidgets:openRestaurantsWidgets,
            ),
            Padding(
              padding: const EdgeInsets.only(left:8.0),
              child: Text('NOVEDADES',style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  foreground: Paint()..shader = linearGradient

              ),),
            ),
            SizedBox(
              height: 10.0,
            ),
            Container(
              child: Stack(children:[ Image(image: AssetImage('assets/images/bg-norte-test.png')),
                Positioned.fill(
                  child: Container(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Guachinches Tenerife norte',
                          style:TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 32
                        ),),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              primary: Colors.white,
                            ),onPressed: ()=>{
                              GlobalMethods().pushPage(context, RestaurantShowMoreGuachinches('GuachinchesNorteTF'))
                        }, child: Text(
                          'Descubrir',
                          style: TextStyle(
                              color: Colors.black
                          ),
                        ))
                      ],
                    ),
                  ),
                )
              ]),
            ),
            SizedBox(
              height: 10.0,
            ),
          ],
        ),
      ),
    );
  }

    createMenuForRestaurants(){
    return Padding(
      padding: const EdgeInsets.only(top:24.0),
      child: Container(
        height: 48,
        width: double.infinity,
        child: Center(
          child: ListView.builder(
              shrinkWrap: true,
              primary: false,
              scrollDirection: Axis.horizontal,
              itemCount: menuOptions.length,
              itemBuilder: (context, index){
          return  Wrap(
              children: [
                GestureDetector(
                  onTap: ()=>{
                    menuHandle(index),
                  },
                  child: Container(
                    margin: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                        border: Border.all(color:Colors.blue,width: 1),
                        color: menuRestaurantSelected==index?Colors.blue:Colors.white
                    ),
                    height: 32,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                            menuOptions[index],
                            style:TextStyle(
                              color: menuRestaurantSelected==index?Colors.white:Colors.blue
                            )
                        ),
                      ),
                    ),
                  ),
                )
              ],
            );
          }),
        ),
      ),
    );
    }

  createListWidgetForRestaurants() {

    Widget aux = BlocBuilder<TopRestaurantCubit, TopRestaurantState>(
        builder: (context, state) {
      if (state is TopRestaurantLoaded) {
        widget.restaurants = state.restaurants;
        return Container(
          height: 220,
          width: double.infinity,
          child: ListView.builder(
              shrinkWrap: true,
              primary: false,
              itemCount: 6,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                print(index);
                if (index==5){
                  return Wrap(
                    alignment: WrapAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => GlobalMethods().pushPage(context, RestaurantShowMore('top')),
                        child: Container(
                            height: 145,
                            margin: EdgeInsets.fromLTRB(10,16,0,0),
                            width: MediaQuery.of(context).size.width * 0.8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                              color: Colors.blue,
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: Colors.white,
                                  offset: Offset(0.0, 1.0),
                                  blurRadius: 0.8,
                                ),
                              ],
                            ),
                            child: Center(child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Ver más',
                                  style: TextStyle(color: Colors.white,fontSize: 20,fontWeight: FontWeight.w600)),
                                Icon(Icons.arrow_forward_ios,color: Colors.white,)
                              ],
                            ))
                        ),
                      ),
                      SizedBox(
                        width: 30.0,
                      ),
                    ],
                  );
                }
                return TopRestaurantCard(widget.restaurants[index]);
              }),
        );
      }
      return Container();
    });
    if (mounted) {
      setState(() {
        restaurantsWidgets = aux;
      });
    }
  }

  createOpenListWidget(){
    Widget aux = BlocBuilder<RestaurantCubit,RestaurantState>(
        builder: (context,state){
      if (state is AllRestaurantLoaded){
        List<Restaurant> restaurants = [];
         state.restaurantResponse.restaurants.forEach((element)=>
        {
          if(element.open){
          restaurants.add(element),
        }
         });
     return Container(
       height: 220,
       width: double.infinity,
       child: ListView.builder(
           shrinkWrap: true,
           primary: false,
           itemCount: restaurants.length>0?restaurants.length<6?restaurants.length+1:6:1,
           scrollDirection: Axis.horizontal,
           itemBuilder: (context, index) {
             if (index==5 || (restaurants.length<6 && index == restaurants.length)){
               return Wrap(
                 alignment: WrapAlignment.end,
                 children: [
                   GestureDetector(
                     onTap: () => GlobalMethods().pushPage(context, RestaurantShowMoreGuachinches('open')),
                     child: Container(
                         height: 145,
                         margin: EdgeInsets.fromLTRB(10,16,0,0),
                         width: MediaQuery.of(context).size.width * 0.8,
                         decoration: BoxDecoration(
                           borderRadius: BorderRadius.all(Radius.circular(10)),
                           color: Colors.blue,
                           boxShadow: <BoxShadow>[
                             BoxShadow(
                               color: Colors.white,
                               offset: Offset(0.0, 1.0),
                               blurRadius: 0.8,
                             ),
                           ],
                         ),
                         child: Center(child: Row(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: [
                             Text(
                                 'Ver más',
                                 style: TextStyle(color: Colors.white,fontSize: 20,fontWeight: FontWeight.w600)),
                             Icon(Icons.arrow_forward_ios,color: Colors.white,)
                           ],
                         ))
                     ),
                   ),
                   SizedBox(
                     width: 30.0,
                   ),
                 ],
               );
             }
             return restaurants.length>0?RestaurantOpenCard(restaurants[index]):Container(
                 width: MediaQuery.of(context).size.width ,
                 child: Center(child: Text('Vaya! Parece que no hay restaurantes abiertos')));
           }),
     );
      }
      return null;
    });
    if (mounted) {
      setState(() {
        openRestaurantsWidgets = aux;
      });
    }
  }
  @override
  setTopRestaurants(List<TopRestaurants> restaurants) {
    if (mounted) {
      setState(() {
        this.widget.restaurants = restaurants;
      });
    }
  }
  menuHandle(int index){
    setState(() {
      this.menuRestaurantSelected = index;
    });
  }
  @override
  changeCharginInitial() {
    if (mounted) {
      setState(() {
        this.widget.isChargingInitalRestaurants =
            !this.widget.isChargingInitalRestaurants;
      });
    }
  }

  @override
  changeScreen(widget) {
    GlobalMethods().pushAndReplacement(context, widget);
  }

  @override
  setUserId(String id) {
    if (mounted) {
      setState(() {
        userId = id;
        userIdSearched = true;
      });
    }
  }

  @override
  setScreens(List<Widget> screens) {
    if (mounted) {
      setState(() {
        this.screens = screens;
      });
    }
  }

  @override
  setCupones(List<CuponesAgrupados> cuponesAgrupadosParam) {
    setState(() {
      cuponesAgrupados = cuponesAgrupadosParam;
    });
  }


}
final Shader linearGradient = LinearGradient(
colors: <Color>[Color(0xff0189C4), Color(0xff01BCC4)],
).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0));