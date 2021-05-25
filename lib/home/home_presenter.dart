import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/restaurant_cubit.dart';
import 'package:guachinches/model/Category.dart';
import 'package:guachinches/model/Review.dart';
import 'package:guachinches/model/restaurant.dart';

class HomePresenter{
  final RemoteRepository _remoteRepository;
  final HomeView _view;
  RestaurantCubit _restaurantCubit;

  final storage = new FlutterSecureStorage();

  HomePresenter(this._remoteRepository, this._view, this._restaurantCubit);

  getAllRestaurants() async {
    await _restaurantCubit.getRestaurants();
  }

  getAllCategories() async {
    List<Category> categories = await _remoteRepository.getAllCategories();
    _view.setAllCategories(categories);
  }

  getSelectedMunicipality() async {
    String name = await storage.read(key: "municipalityName");
    String id = await storage.read(key: "municipalityId");
    if(id == null){

      name = "Todos";
      id = "";
      await storage.write(key: "municipalityName", value: name);
      await storage.write(key: "municipalityId", value: id);
    }
    _view.setMunicipality(name, id);

  }

  getRestaurantsFilter(List<Restaurant> restaurants, String value) async {
    await _restaurantCubit.getFilterRestaurants(restaurants, value);
  }
}
abstract class HomeView{
  setAllRestaurants(List<Restaurant> restaurants);
  setAllCategories(List<Category> categories);
  setMunicipality(String municipalityName, String municipalityId);
}
