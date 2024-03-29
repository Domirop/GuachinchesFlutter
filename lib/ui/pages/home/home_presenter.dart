import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/Categorias/categorias.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/banners/banners_cubit.dart';
import 'package:guachinches/data/cubit/cupones/cupones_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/top/top_restaurants_cubit.dart';
import 'package:guachinches/data/cubit/user/user_cubit.dart';
import 'package:guachinches/data/cubit/user/user_state.dart';
import 'package:guachinches/data/model/CuponesAgrupados.dart';
import 'package:guachinches/data/model/Municipality.dart';
import 'package:guachinches/data/model/TopRestaurants.dart';
import 'package:guachinches/data/model/Types.dart';
import 'package:guachinches/data/model/Video.dart';
import 'package:guachinches/ui/pages/login/login.dart';
import 'package:guachinches/ui/pages/map/map_search.dart';
import 'package:guachinches/ui/pages/search_page/search_page.dart';
import '../../../data/model/Category.dart';
import '../profile/profile.dart';
import '../video/video.dart';
import 'home.dart';

class HomePresenter{
  final HomeView _view;
  TopRestaurantCubit _topRestaurantCubit;
  CuponesCubit _cuponesCubit;
  UserCubit _userCubit;
  final RemoteRepository repository;
  BannersCubit _bannersCubit;
  RestaurantCubit _restaurantCubit;


  final storage = new FlutterSecureStorage();

  HomePresenter(this._view, this._topRestaurantCubit, this._bannersCubit, this._cuponesCubit, this._userCubit, this.repository,this._restaurantCubit);

  getTopRestaurants() async {
    await _topRestaurantCubit.getTopRestaurants();
    _view.changeCharginInitial();
  }
  getAllRestaurants() async{

    await _restaurantCubit.getAllRestaurants(0);
  }



  getAllVideos() async {
    List<Video> videos = await repository.getAllVideos();
    _view.setAllVideos(videos);
  }
  getAllCategories() async {
    List<ModelCategory> categories = await repository.getAllCategories();
    _view.setCategories(categories);
  }
  getAllTypes() async {
    List<Types> types = await repository.getAllTypes();
    print('types '+types.length.toString());
    _view.setTypes(types);
  }
  getAllMunicipalities(String islandId) async {
    List<Municipality> municipalities = await repository.getAllMunicipalitiesFiltered(islandId);
    _view.setMunicipalities(municipalities);
  }
  getScreens() async {
    final storage = new FlutterSecureStorage();
    List<Widget> screens = [
      Home(),
      MapSearch(),
      Login("Para ver tus valoraciones debes iniciar sesión."),
      Login("Para ver tu perfíl debes iniciar sesión.")
    ];
    try {
      String? userId = await storage.read(key: "userId");

      if (userId != null) {
        if (_userCubit.state is UserInitial) {
          var response = await _userCubit.getUserInfo(userId);
          if (response == true) {
            screens = [Home(), SearchPage(userId: userId), VideoScreen(index: 0), Profile()];
          } else {
            await storage.delete(key: "userId");
          }
        }else if(_userCubit.state is UserLoaded){
          screens = [Home(), SearchPage(userId: userId), VideoScreen(index:0), Profile()];
        }
      } else {
        screens = [
          Home(),
          MapSearch(),
          Login("Para ver tus valoraciones debes iniciar sesión."),
          Login("Para ver tu perfíl debes iniciar sesión.")
        ];
      }
    } catch (e) {
    }
    _view.setScreens(screens);
  }

  getCupones() async {
    List<CuponesAgrupados> cupones= await repository.getCuponesHistorias();
    _view.setCupones(cupones);
  }

  getUserInfo() async {
    String? userId = await storage.read(key: "userId");
    if (userId != null){
      _view.setUserId(userId!);

    }
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
  setAllVideos(List<Video> videos);
  setCategories(List<ModelCategory> categories);
  setTypes(List<Types> types);
  setMunicipalities(List<Municipality> municipalities);
  setCupones(List<CuponesAgrupados>cuponesAgrupadosParam);
}
