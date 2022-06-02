import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/banners/banners_cubit.dart';
import 'package:guachinches/data/cubit/cupones/cupones_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/top/top_restaurants_cubit.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/data/cubit/user/user_state.dart';
import 'package:guachinches/data/model/TopRestaurants.dart';
import 'package:guachinches/ui/main/login/login.dart';
import 'package:guachinches/ui/sub_menu_pages/home/home.dart';
import 'package:guachinches/ui/sub_menu_pages/profile/profile.dart';
import 'package:guachinches/ui/sub_menu_pages/search_page/search_page.dart';
import 'package:guachinches/ui/sub_menu_pages/valoraciones/valoraciones.dart';

class HomePresenter{
  final HomeView _view;
  TopRestaurantCubit _topRestaurantCubit;
  CuponesCubit _cuponesCubit;
  UserCubit _userCubit;
  final RemoteRepository repository;
  BannersCubit _bannersCubit;

  final storage = new FlutterSecureStorage();

  HomePresenter(this._view, this._topRestaurantCubit, this._bannersCubit, this._cuponesCubit, this._userCubit, this.repository);

  getTopRestaurants() async {
    await _topRestaurantCubit.getTopRestaurants();
    _view.changeCharginInitial();
  }

  getScreens() async {
    final storage = new FlutterSecureStorage();
    List<Widget> screens = [
      Home(),
      SearchPage(),
      Login("Para ver tus valoraciones debes iniciar sesión."),
      Login("Para ver tu perfíl debes iniciar sesión.")
    ];
    try {
      String userId = await storage.read(key: "userId");

      if (userId != null) {
        if (_userCubit.state is UserInitial) {
          var response = await _userCubit.getUserInfo(userId);
          if (response == true) {
            screens = [Home(), SearchPage(userId: userId), Valoraciones(), Profile()];
          } else {
            await storage.delete(key: "userId");
          }
        }else if(_userCubit.state is UserLoaded){
          screens = [Home(), SearchPage(userId: userId), Valoraciones(), Profile()];
        }
      } else {
        screens = [
          Home(),
          SearchPage(),
          Login("Para ver tus valoraciones debes iniciar sesión."),
          Login("Para ver tu perfíl debes iniciar sesión.")
        ];
      }
    } catch (e) {
    }
    _view.setScreens(screens);
  }

  getCupones() async {
    await _cuponesCubit.getCuponesHistorias();
  }

  getUserInfo() async {
    String userId = await storage.read(key: "userId");
    _view.setUserId(userId);
  }

  getAllBanner() async {
    await _bannersCubit.getBanners();
  }

  changeScreen(widget){
    _view.changeScreen(widget);
  }
}
abstract class HomeView{
  setTopRestaurants(List<TopRestaurants> restaurants);
  changeCharginInitial();
  setUserId(String id);
  setScreens(List<Widget> screens);
  changeScreen(widget);
}
