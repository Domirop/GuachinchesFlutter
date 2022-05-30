import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/banners/banners_cubit.dart';
import 'package:guachinches/data/cubit/cupones/cupones_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/top/top_restaurants_cubit.dart';
import 'package:guachinches/data/model/TopRestaurants.dart';

class HomePresenter{
  final HomeView _view;
  TopRestaurantCubit _topRestaurantCubit;
  CuponesCubit _cuponesCubit;
  final RemoteRepository repository;
  BannersCubit _bannersCubit;

  final storage = new FlutterSecureStorage();

  HomePresenter(this._view, this._topRestaurantCubit, this._bannersCubit, this._cuponesCubit, this.repository);

  getTopRestaurants() async {
    await _topRestaurantCubit.getTopRestaurants();
    _view.changeCharginInitial();
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
  changeScreen(widget);
}
