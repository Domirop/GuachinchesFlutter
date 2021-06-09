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
  getSelectedCategory() async {
    String useCategory = await storage.read(key: "category");
    _view.categorySelected(useCategory);
  }

  setSelectedCategory(String id) async {
    String useCategory = await storage.read(key: "category");
    if(useCategory == id){
      await storage.write(key: "category", value: "Todas");
    }else{
      await storage.write(key: "category", value: id);
    }
    getSelectedCategory();
  }

  getSelectedMunicipality() async {
    String useMunicipality = await storage.read(key: "useMunicipality");
    if(useMunicipality == "Todos"){
      _view.setAllMunicipalities();
    }else if (useMunicipality == "true"){
      String name = await storage.read(key: "municipalityName");
      String id = await storage.read(key: "municipalityId");
      _view.setMunicipality(name, id);
    }else{
      String areaId = await storage.read(key: "municipalityIdArea");
      String areaName = await storage.read(key: "municipalityNameArea");
      _view.setAreaMunicipality(areaId, areaName);
    }
  }

  getRestaurantsFilter(List<Restaurant> restaurants, String value) async {
    await _restaurantCubit.getFilterRestaurants(restaurants, value);
  }
}
abstract class HomeView{
  setAllRestaurants(List<Restaurant> restaurants);
  setAllCategories(List<ModelCategory> categories);
  setAllMunicipalities();
  categorySelected(String id);
  setMunicipality(String municipalityName, String municipalityId);
  setAreaMunicipality(String municipalityIdArea, String municipalityNameArea);
}
