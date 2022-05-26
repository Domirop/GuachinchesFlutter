import 'package:flutter/material.dart';
import 'package:guachinches/data/HttpRemoteRepository.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/data/cubit/banners_cubit.dart';
import 'package:guachinches/data/cubit/banners_state.dart';
import 'package:guachinches/data/cubit/top_restaurant_state.dart';
import 'package:guachinches/data/cubit/top_restaurants_cubit.dart';
import 'package:guachinches/data/model/TopRestaurants.dart';
import 'package:guachinches/globalMethods.dart';
import 'package:guachinches/ui/components/app_Bars/appbar_basic.dart';
import 'package:guachinches/ui/components/heroSliderComponent.dart';
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

  @override
  void initState() {
    super.initState();
    final topRestaurantCubit = context.read<TopRestaurantCubit>();
    final bannersCubit = context.read<BannersCubit>();
    remoteRepository = HttpRemoteRepository(Client());
    presenter = HomePresenter(this, topRestaurantCubit, bannersCubit);
    if (bannersCubit.state is BannersInitial) {
      presenter.getAllBanner();
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
            Container(),
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
            Text("Nuestro top 3"),
            SizedBox(
              height: 20.0,
            ),
            Container(
              height: 320,
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

  createListWidgetForRestaurants() {
    Widget aux = BlocBuilder<TopRestaurantCubit, TopRestaurantState>(
          builder: (context, state) {
        if (state is TopRestaurantLoaded) {
          widget.restaurants = state.restaurants;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: generateWidgetsRestaurant().map((e) => e).toList(),
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

  List<Widget> generateWidgetsRestaurant() {
    List<Widget> widgets = [];
    widget.restaurants.forEach((element) {
      Widget container = Container(
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
                  image: NetworkImage(element.imagen),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 10),
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    child: Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            element.nombre,
                            softWrap: true,
                            maxLines: 2,
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            element.horarios,
                            style: TextStyle(
                                fontSize: 12,
                                color: Color.fromRGBO(226, 120, 120, 1)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
      widgets.add(container);
    });
    return widgets;
  }

  @override
  setTopRestaurants(List<TopRestaurants> restaurants) {
    if (mounted) {
      setState(() {
        this.widget.restaurants = restaurants;
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
