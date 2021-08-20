import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/cubit/banners_cubit.dart';
import 'package:guachinches/data/cubit/categories_cubit.dart';
import 'package:guachinches/data/cubit/restaurant_cubit.dart';
import 'package:guachinches/model/Category.dart';
import 'package:guachinches/model/restaurant.dart';

class HomePresenter{
  final HomeView _view;
  RestaurantCubit _restaurantCubit;
  CategoriesCubit _categoriesCubit;
  BannersCubit _bannersCubit;

  final storage = new FlutterSecureStorage();

  HomePresenter(this._view, this._restaurantCubit, this._categoriesCubit, this._bannersCubit);

  getAllRestaurants() async {
    await _restaurantCubit.getRestaurants();
    changeCharginInitial();
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
      return {"useMunicipality": "Todos",
        "municipalityIdArea": "",
        "municipalityNameArea": "",
        "municipalityName": "",
        "municipalityId": ""};
    }else if (useMunicipality == "true"){
      String name = await storage.read(key: "municipalityName");
      String id = await storage.read(key: "municipalityId");
      return {"municipalityName": name,
        "municipalityId": id,
        "useMunicipality": "true",
        "municipalityIdArea": "",
        "municipalityNameArea": ""};
    }else{
      String areaId = await storage.read(key: "municipalityIdArea");
      String areaName = await storage.read(key: "municipalityNameArea");
      return {"municipalityIdArea": areaId,
        "municipalityNameArea": areaName,
        "useMunicipality": "false",
        "municipalityName": "",
        "municipalityId": ""};
    }
  }

  getRestaurantsFilter(List<Restaurant> restaurants, String value) async {
    await _restaurantCubit.getFilterRestaurants(restaurants, value);
  }

  changeStateAppBar(value){
    _view.changeStateAppBar(value);
  }

  setLocationData() async {
    var data = await getSelectedMunicipality();
    _view.setLocationData(data);
  }

  callCreateNewRestaurantsList() async {
    _view.callCreateNewRestaurantsList();
  }

  changeCharginInitial() {
    _view.changeCharginInitial();
  }

  changeScreen(widget){
    _view.changeScreen(widget);
  }
}
abstract class HomeView{
  setAllRestaurants(List<Restaurant> restaurants);
  setAllCategories(List<ModelCategory> categories);
  categorySelected(String id);
  changeStateAppBar(value);
  setLocationData(data);
  callCreateNewRestaurantsList();
  changeCharginInitial();
  changeScreen(widget);
}
