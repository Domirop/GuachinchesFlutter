import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/cupones/cupones_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_cubit.dart';
import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/data/model/Municipality.dart';
import 'package:guachinches/data/model/Types.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/data/model/restaurant_response.dart';

class SearchPagePresenter {
  final SearchPageView _view;
  RestaurantCubit _restaurantCubit;
  CuponesCubit _cuponesCubit;
  final RemoteRepository _remoteRepository;

  final storage = new FlutterSecureStorage();

  SearchPagePresenter(this._view, this._restaurantCubit, this._cuponesCubit,
      this._remoteRepository);

  getAllRestaurants(number,islandId) async {
    await _remoteRepository.getAllRestaurants(number,islandId);
  }

  saveCupon(String userId, String cuponId) async {
    String aux = await _remoteRepository.saveCupon(cuponId, userId);
    await _cuponesCubit.getCuponesHistorias();
    _view.estadoCupon(aux.length>0);
    _view.generateWidgetTab3();
  }

  getAllRestaurantsPag1(number) async {
    //No funciona
    String? islandId = await storage.read(key: 'islandId');
    RestaurantResponse response =  await _remoteRepository.getAllRestaurants(number,islandId!);
    List<Restaurant> restaurants = response.restaurants;
    _view.generateWidgetTab1(restaurants);
    _view.changeCharginInitial();

  }



  getAllCupones() async {
    await _cuponesCubit.getCuponesHistorias();
  }

  setCharging() async {
    _view.changeCharginInitial();
  }

  getAllRestaurantsFilters(bool isOpen,
      {List<String>? categories,
      List<String>? municipalities,
      List<String>? types,
      int? number,
        String? islandId,
      String? text}) async {

    if (((categories == null || categories.isEmpty) &&
            (municipalities == null || municipalities.isEmpty) &&
            (text == null || text.length < 3)) &&
        (types == null || types.isEmpty) &&
        !isOpen) {
      // await getAllRestaurantsPag1(0);
      await Future.delayed(Duration(milliseconds: 100));

      _view.generateWidgetTab2([]);
      if(text!.length ==0){
        _view.changeTab();

      }
    } else {
      List<Restaurant> restaurants = await _remoteRepository. getFilterRestaurants(categories!.join(";"), municipalities!.join(";"), types!.join(";"), text!,islandId!);
      _view.generateWidgetTab2(restaurants);
      _view.removeListeners();
    }
  }

  getAllMunicipalitiesCategoriesAndTypes(String islandId) async {
    List<ModelCategory> categories = await _remoteRepository.getAllCategories();
    List<Municipality> municipality =
        await _remoteRepository.getAllMunicipalitiesFiltered(islandId);
    List<Types> types = await _remoteRepository.getAllTypes();
    _view.setMunicipalitiesCategoriesAndTypes(categories, municipality, types);
  }

  updateNumber(List<String> categories, List<String> municipalities,
      List<String> types, int number, bool isOpen) async {
    _view.updateNumber(categories, municipalities, types, number, isOpen);
  }

  updateFilter() {
    _view.updateFilter();
  }
}

abstract class SearchPageView {
  changeCharginInitial();

  setMunicipalitiesCategoriesAndTypes(List<ModelCategory> categories,
      List<Municipality> municipality, List<Types> type);

  updateNumber(List<String> categories, List<String> municipalities,
      List<String> types, int number, bool isOpen);

  updateFilter();

  generateWidgetTab1(List<Restaurant> restaurants);

  generateWidgetTab2(List<Restaurant> restaurants);

  removeListeners();

  changeTab();

  generateWidgetTab3();

  estadoCupon(bool correctSave);
}
