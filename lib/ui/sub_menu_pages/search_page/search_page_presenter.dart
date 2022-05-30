import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_cubit.dart';
import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/data/model/Municipality.dart';

class SearchPagePresenter{
  final SearchPageView _view;
  RestaurantCubit _restaurantCubit;
  final RemoteRepository _remoteRepository;

  final storage = new FlutterSecureStorage();

  SearchPagePresenter(this._view, this._restaurantCubit, this._remoteRepository);

  getAllRestaurants(number) async {
    await _restaurantCubit.getRestaurants(number);
    _view.changeCharginInitial();
  }

  setCharging() async {
    _view.changeCharginInitial();
  }

  getAllRestaurantsFilters(String categoria, String municipio, String nombre, bool abierto) async {
    // await _restaurantCubit.getFilterRestaurants();
  }

  getAllMunicipalitiesAndCategories() async {
    List<ModelCategory> categories = await _remoteRepository.getAllCategories();
    List<Municipality> municipality = await _remoteRepository.getAllMunicipalities();
    _view.setMunicipalitiesAndCategories(categories, municipality);
  }

  updateNumber(int number){
    _view.updateNumber(number);
  }
}
abstract class SearchPageView{
  changeCharginInitial();
  setMunicipalitiesAndCategories(List<ModelCategory> categories, List<Municipality> municipality);
  updateNumber(int number);
}
