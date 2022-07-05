import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/cupones/cupones_cubit.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_cubit.dart';
import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/data/model/Municipality.dart';
import 'package:guachinches/data/model/Types.dart';

class SearchPagePresenter {
  final SearchPageView _view;
  RestaurantCubit _restaurantCubit;
  CuponesCubit _cuponesCubit;
  final RemoteRepository _remoteRepository;

  final storage = new FlutterSecureStorage();

  SearchPagePresenter(this._view, this._restaurantCubit, this._cuponesCubit,
      this._remoteRepository);

  getAllRestaurants(number) async {
    await _restaurantCubit.getRestaurants(number);
    _view.changeCharginInitial();
  }

  saveCupon(String userId, String cuponId) async {
    bool aux = await _remoteRepository.saveCupon(cuponId, userId);
    await _cuponesCubit.getCuponesHistorias();
    _view.estadoCupon(aux);
    _view.generateWidgetTab3();
  }

  getAllRestaurantsPag1(number) async {
    await getAllRestaurants(number);
    _view.generateWidgetTab1();
  }

  getAllRestaurantsPag2(number) async {
    await getAllRestaurants(number);
    _view.generateWidgetTab2();
  }

  getAllCupones() async {
    await _cuponesCubit.getCuponesHistorias();
  }

  setCharging() async {
    _view.changeCharginInitial();
  }

  getAllRestaurantsFilters(bool isOpen,
      {List<String> categories,
      List<String> municipalities,
      int number,
      String text}) async {
    if (((categories == null || categories.isEmpty) &&
            (municipalities == null || municipalities.isEmpty) &&
            (text == null || text.length <= 3)) &&
        !isOpen) {
      await _restaurantCubit.getRestaurants(number);
      _view.changeTab();
    } else {
      await _restaurantCubit.getFilterRestaurants(
          categories: categories, municipalities: municipalities, text: text);
      _view.removeListeners();
    }
  }

  getAllMunicipalitiesCategoriesAndTypes() async {
    List<ModelCategory> categories = await _remoteRepository.getAllCategories();
    List<Municipality> municipality =
        await _remoteRepository.getAllMunicipalities();
    List<Types> types =
    await _remoteRepository.getAllTypes();
    _view.setMunicipalitiesCategoriesAndTypes(categories, municipality, types);
  }

  updateNumber(List<String> categories, List<String> municipalities, List<String> types, int number,
      bool isOpen) async {
    _view.updateNumber(categories, municipalities, types, number, isOpen);
  }

  updateFilter() {
    _view.updateFilter();
  }
}

abstract class SearchPageView {
  changeCharginInitial();

  setMunicipalitiesCategoriesAndTypes(
      List<ModelCategory> categories, List<Municipality> municipality, List<Types> type);

  updateNumber(List<String> categories, List<String> municipalities, List<String> types, int number,
      bool isOpen);

  updateFilter();

  generateWidgetTab1();

  generateWidgetTab2();

  removeListeners();

  changeTab();

  generateWidgetTab3();

  estadoCupon(bool correctSave);
}
