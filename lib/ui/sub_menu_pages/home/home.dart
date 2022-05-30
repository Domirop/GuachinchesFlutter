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
import 'package:guachinches/data/model/CuponesAgrupados.dart';
import 'package:guachinches/data/model/TopRestaurants.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/components/app_Bars/appbar_basic.dart';
import 'package:guachinches/ui/components/heroSliderComponent.dart';
import 'package:guachinches/ui/components/history_full_page.dart';
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
  RemoteRepository remoteRepository;
  Widget restaurantsWidgets;
  String userId;
  List<CuponesAgrupados> cuponesAgrupados = [];

  @override
  void initState() {
    super.initState();
    final topRestaurantCubit = context.read<TopRestaurantCubit>();
    final cuponesCubit = context.read<CuponesCubit>();
    final bannersCubit = context.read<BannersCubit>();
    remoteRepository = HttpRemoteRepository(Client());
    presenter =
        HomePresenter(this, topRestaurantCubit, bannersCubit, cuponesCubit);
    presenter.getUserInfo();
    if (bannersCubit.state is BannersInitial) {
      presenter.getAllBanner();
    }
    if (cuponesCubit.state is CuponesInitial) {
      presenter.getCupones();
    }
    if (topRestaurantCubit.state is TopRestaurantInitial) {
      presenter.getTopRestaurants();
      createListWidgetForRestaurants();
    }
    appBarBasic = AppBarBasic(widget);
  }

  @override
  Widget build(BuildContext context) {
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
            Text("Cupones descuento"),
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
                onTap: () =>
                    GlobalMethods().pushPage(
                        context, HistoryFullPage(cuponesAgrupados[index], guardarCupon, userId)),
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
                          image: NetworkImage(cuponesAgrupados[index].foto),
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
                        Container(
                          height: 280,
                          margin: EdgeInsets.only(right: 20),
                          width: MediaQuery
                              .of(context)
                              .size
                              .width * 0.7,
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
                                    image: NetworkImage(
                                        widget.restaurants[index].imagen),
                                  ),
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.only(top: 10),
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                      "widget.restaurants[index].horarios",
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color.fromRGBO(
                                              226, 120, 120, 1)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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

  guardarCupon(String cuponId, String userId){
    presenter.saveCupon(cuponId, userId);
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
}
