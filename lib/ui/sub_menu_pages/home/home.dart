import 'package:flutter/material.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/data/cubit/banners_cubit.dart';
import 'package:guachinches/data/cubit/banners_state.dart';
import 'package:guachinches/data/cubit/restaurant_cubit.dart';
import 'package:guachinches/data/cubit/restaurant_state.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/Others/details/details.dart';
import 'package:guachinches/ui/components/app_Bars/appbar_basic.dart';
import 'package:guachinches/ui/components/heroSliderComponent.dart';
import 'package:guachinches/ui/sub_menu_pages/home/home_presenter.dart';
import 'package:http/http.dart';

class Home extends StatefulWidget {
  List<Restaurant> restaurants = [];
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

  @override
  void initState() {
    super.initState();
    final restaurantCubit = context.read<RestaurantCubit>();
    final bannersCubit = context.read<BannersCubit>();
    remoteRepository = HttpRemoteRepository(Client());
    presenter = HomePresenter(this, restaurantCubit, bannersCubit);
    if (bannersCubit.state is BannersInitial) {
      presenter.getAllBanner();
    }
    if (restaurantCubit.state is RestaurantInitial) {
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
        primary: false,
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 20.0,
            ),
            Text("Cupones descuento"),
            Container(),
            SizedBox(
              height: 20.0,
            ),
            // BlocBuilder<BannersCubit, BannersState>(builder: (context, state) {
            //   if (state is BannersLoaded) {
            //     return HeroSliderComponent(state.banners);
            //   } else {
            //     return Container();
            //   }
            // }),
            SizedBox(
              height: 20.0,
            ),
            Text("Nuestro top 3"),
            SizedBox(
              height: 20.0,
            ),
            Container(
              height: 270,
              width: MediaQuery.of(context).size.width,
              child: restaurantsWidgets,
            ),
          ],
        ),
      ),
    );
  }

  createListWidgetForRestaurants() {
    Widget aux = Container(
      child: BlocBuilder<RestaurantCubit, RestaurantState>(
          builder: (context, state) {
        if (state is RestaurantLoaded) {
          widget.restaurants = state.restaurants;
          return Container(
            width: MediaQuery.of(context).size.width,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: generateWidgetsRestaurant().map((e) => e).toList(),
            ),
          );
        }
        return Container();
      }),
    );
    if (mounted) {
      setState(() {
        restaurantsWidgets = aux;
      });
    }
  }

  List<Widget> generateWidgetsRestaurant() {
    List<Widget> widgets = [];
    widget.restaurants = [Restaurant(), Restaurant(), Restaurant()];
    widget.restaurants.forEach((element) {
      widgets.add(Container(
        height: 400,
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
                  image: NetworkImage(
                      "https://i.pinimg.com/550x/a6/51/1e/a6511e138352d38726e03b69d18bccdf.jpg"),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 10),
              padding: EdgeInsets.only(left: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Bodegón Mojo Picón",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Carnes de cerdo y ternera.",
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          "Hoy cerrado",
                          style: TextStyle(
                              fontSize: 12, color: Color.fromRGBO(226, 120, 120, 1)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ));
    });
    return widgets;
  }

  gotoDetail(Restaurant restaurant) {
    GlobalMethods().pushPage(context, Details(restaurant));
  }

  @override
  setTopRestaurants(List<Restaurant> restaurants) {
    if (mounted) {
      setState(() {
        this.widget.restaurants = restaurants;
        this.widget.restaurants = [Restaurant(), Restaurant(), Restaurant()];
        generateWidgetsRestaurant();
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
}
