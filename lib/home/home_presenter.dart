import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/banners_cubit.dart';
import 'package:guachinches/data/cubit/categories_cubit.dart';
import 'package:guachinches/data/cubit/restaurant_cubit.dart';
import 'package:guachinches/model/Category.dart';
import 'package:guachinches/model/restaurant.dart';

class HomePresenter{
  final RemoteRepository _remoteRepository;
  final HomeView _view;
  RestaurantCubit _restaurantCubit;
  CategoriesCubit _categoriesCubit;
  BannersCubit _bannersCubit;

  final storage = new FlutterSecureStorage();

  HomePresenter(this._remoteRepository, this._view, this._restaurantCubit, this._categoriesCubit, this._bannersCubit);

  getAllRestaurants() async {
    await _restaurantCubit.getRestaurants();
  }

  getAllCategories() async {
    await _categoriesCubit.getCategories();
  }

  getAllBanner() async {
    await _bannersCubit.getBanners();
  }

  getSelectedMunicipality() async {
    String name = await storage.read(key: "municipalityName");
    String id = await storage.read(key: "municipalityId");
    String areaId = await storage.read(key: "municipalityIdArea");
    String areaName = await storage.read(key: "municipalityNameArea");
    if(name == null && id == null && areaName == null && areaId == null){
      await storage.write(key: "municipalityIdArea", value: "Todos");
      await storage.write(key: "municipalityNameArea", value: "Todos");
    }
    if(id == null){
      _view.setAreaMunicipality(areaId, areaName);
    }else {
      _view.setMunicipality(name, id);
    }
  }

  getRestaurantsFilter(List<Restaurant> restaurants, String value) async {
    await _restaurantCubit.getFilterRestaurants(restaurants, value);
  }
}
abstract class HomeView{
  setAllRestaurants(List<Restaurant> restaurants);
  setAllCategories(List<ModelCategory> categories);
  setMunicipality(String municipalityName, String municipalityId);
  setAreaMunicipality(String municipalityIdArea, String municipalityNameArea);
}
