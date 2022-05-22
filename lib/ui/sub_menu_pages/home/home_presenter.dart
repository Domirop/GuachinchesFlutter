import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/cubit/banners_cubit.dart';
import 'package:guachinches/data/cubit/restaurant_cubit.dart';
import 'package:guachinches/data/model/restaurant.dart';

class HomePresenter{
  final HomeView _view;
  RestaurantCubit _restaurantCubit;
  BannersCubit _bannersCubit;

  final storage = new FlutterSecureStorage();

  HomePresenter(this._view, this._restaurantCubit, this._bannersCubit);

  getTopRestaurants() async {
    await _restaurantCubit.getTopRestaurants();
    changeCharginInitial();
  }


  getAllBanner() async {
    await _bannersCubit.getBanners();
  }

  changeCharginInitial() {
    _view.changeCharginInitial();
  }

  changeScreen(widget){
    _view.changeScreen(widget);
  }
}
abstract class HomeView{
  setTopRestaurants(List<Restaurant> restaurants);
  changeCharginInitial();
  changeScreen(widget);
}
