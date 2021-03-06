import 'package:flutter/material.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/data/cubit/banners/banners_cubit.dart';
import 'package:guachinches/data/cubit/banners/banners_state.dart';
import 'package:guachinches/data/cubit/cupones/cupones_cubit.dart';
import 'package:guachinches/data/cubit/cupones/cupones_state.dart';
import 'package:guachinches/data/cubit/restaurants/top/top_restaurant_state.dart';
import 'package:guachinches/data/cubit/restaurants/top/top_restaurants_cubit.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/data/cubit/user/user_state.dart';
import 'package:guachinches/data/model/CuponesAgrupados.dart';
import 'package:guachinches/data/model/TopRestaurants.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:flutter_svg/svg.dart';
import 'package:guachinches/ui/Others/details/details.dart';
import 'package:guachinches/ui/components/app_Bars/appbar_basic.dart';
import 'package:guachinches/ui/components/heroSliderComponent.dart';
import 'package:guachinches/ui/components/history_full_page/history_full_page.dart';
import 'package:guachinches/ui/sub_menu_pages/home/home_presenter.dart';
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

  HomePresenter presenter;
  List<Widget> screens;
  RemoteRepository remoteRepository;
  bool isCorrectSaveCupon;
  Widget restaurantsWidgets;
  String userId;
  List<String> assets = [
    "assets/images/firstTop.png",
    "assets/images/secondTop.png",
    "assets/images/thirdTop.png",
    "assets/images/otherTop.png",
    "assets/images/otherTop.png"
  ];
  List<CuponesAgrupados> cuponesAgrupados = [];

  @override
  void initState() {
    super.initState();
    final topRestaurantCubit = context.read<TopRestaurantCubit>();
    final cuponesCubit = context.read<CuponesCubit>();
    final bannersCubit = context.read<BannersCubit>();
    final userCubit = context.read<UserCubit>();
    remoteRepository = HttpRemoteRepository(Client());
    presenter = HomePresenter(this, topRestaurantCubit, bannersCubit,
        cuponesCubit, userCubit, remoteRepository);
    presenter.getUserInfo();
    if (bannersCubit.state is BannersInitial) {
      presenter.getAllBanner();
    }
    if (userCubit.state is UserInitial) {
      presenter.getScreens();
    } else if (userCubit.state is UserLoaded) {
      presenter.getScreens();
    }
    if (cuponesCubit.state is CuponesInitial) {
      presenter.getCupones();
    }
    if (topRestaurantCubit.state is TopRestaurantInitial) {
      presenter.getTopRestaurants();
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
        padding: EdgeInsets.only(left: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 20.0,
            ),
            Image.asset(
              'assets/images/tuscupones.png',
              width: 200.0,
              height: 50.0,
            ),
            SizedBox(
              height: 10.0,
            ),
            Container(
              height: 100,
              child: BlocBuilder<CuponesCubit, CuponesState>(
                  builder: (context, state) {
                if (state is CuponesLoaded) {
                  cuponesAgrupados = state.cuponesAgrupados;
                  return historyPreviewWidget();
                } else {
                  return Container();
                }
              }),
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
            Text("Nuestro top 5"),
            SizedBox(
              height: 20.0,
            ),
            Container(
              child: restaurantsWidgets,
            ),
            SizedBox(
              height: 20.0,
            ),
          ],
        ),
      ),
    );
  }

  historyPreviewWidget() {
    Widget preview = ListView.builder(
        shrinkWrap: true,
        primary: false,
        itemCount: cuponesAgrupados.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return Wrap(
            children: [
              GestureDetector(
                onTap: () => GlobalMethods().pushPage(
                    context, HistoryFullPage(cuponesAgrupados[index], userId)),
                child: Column(
                  children: [
                    Container(
                      height: 75,
                      width: 90,
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: 2,
                          color: Color.fromRGBO(0, 133, 196, 1),
                        ),
                        image: DecorationImage(
                          repeat: ImageRepeat.noRepeat,
                          alignment: Alignment.center,
                          fit: BoxFit.fill,
                          image: cuponesAgrupados[index].foto != null
                              ? NetworkImage(cuponesAgrupados[index].foto)
                              : AssetImage("assets/images/notImage.png"),
                        ),
                      ),
                    ),
                    Text(
                      cuponesAgrupados[index].nombreAbrev,
                      style: TextStyle(color: Colors.black, fontSize: 12),
                    )
                  ],
                ),
              )
            ],
          );
        });
    return preview;
  }

  createListWidgetForRestaurants() {
    Widget aux = BlocBuilder<TopRestaurantCubit, TopRestaurantState>(
        builder: (context, state) {
      if (state is TopRestaurantLoaded) {
        widget.restaurants = state.restaurants;
        return Container(
          height: 320,
          width: double.infinity,
          child: ListView.builder(
              shrinkWrap: true,
              primary: false,
              itemCount: widget.restaurants.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return Wrap(
                  children: [
                    GestureDetector(
                      onTap: () => GlobalMethods().pushPage(
                          context, Details(widget.restaurants[index].id)),
                      child: Container(
                        height: 280,
                        margin: EdgeInsets.only(right: 20),
                        width: MediaQuery.of(context).size.width * 0.7,
                        decoration: BoxDecoration(
                          color: Color(0xfff6f6f6),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black45,
                              offset: Offset(0.0, 2.0),
                              blurRadius: 10.0,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 160,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20)),
                                image: DecorationImage(
                                  repeat: ImageRepeat.noRepeat,
                                  alignment: Alignment.center,
                                  fit: BoxFit.fill,
                                  image:
                                      widget.restaurants[index].imagen != null
                                          ? NetworkImage(
                                              widget.restaurants[index].imagen)
                                          : AssetImage(
                                              "assets/images/notImage.png"),
                                ),
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(top: 10),
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.restaurants[index].nombre,
                                          softWrap: true,
                                          maxLines: 2,
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          widget.restaurants[index].open
                                              ? "Abierto"
                                              : "Cerrado",
                                          style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  widget.restaurants[index].open
                                                      ? Color.fromRGBO(
                                                          149, 220, 0, 1)
                                                      : Color.fromRGBO(
                                                          226, 120, 120, 1)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                      margin: EdgeInsets.only(left: 6),
                                      child: Image(
                                          image: AssetImage(assets[index]),
                                          height: 60)),
                                ],
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
      }
      return Container();
    });
    if (mounted) {
      setState(() {
        restaurantsWidgets = aux;
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
}
