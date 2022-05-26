import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/cubit/banners_cubit.dart';
import 'package:guachinches/data/cubit/top_restaurants_cubit.dart';
import 'package:guachinches/data/model/TopRestaurants.dart';

class HomePresenter{
  final HomeView _view;
  TopRestaurantCubit _topRestaurantCubit;
  BannersCubit _bannersCubit;

  final storage = new FlutterSecureStorage();

  HomePresenter(this._view, this._topRestaurantCubit, this._bannersCubit);

  getTopRestaurants() async {
    await _topRestaurantCubit.getTopRestaurants();
    _view.changeCharginInitial();
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
  changeScreen(widget);
}
