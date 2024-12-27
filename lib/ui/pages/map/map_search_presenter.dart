import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/restaurants/map/restaurant_map_cubit.dart';
import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/data/model/Municipality.dart';
import 'package:guachinches/data/model/Types.dart';

class MapSearchPresenter{
  final MapSearchView _view;
  final RemoteRepository repository;
  RestaurantMapCubit _restaurantCubit;
  final storage = new FlutterSecureStorage();

  MapSearchPresenter(this._view, this.repository, this._restaurantCubit);

  getAllMunicipalities(String islandId) async {
    List<Municipality> municipalities = await repository.getAllMunicipalitiesFiltered(islandId);
    _view.setMunicipalities(municipalities);
  }
  getAllCategories() async {
    List<ModelCategory> categories = await repository.getAllCategories();
    _view.setCategories(categories);
  }
  getAllTypes() async {
    List<Types> types = await repository.getAllTypes();
    _view.setTypes(types);
  }
  getAllRestaurants(String islandId) async{
    _restaurantCubit.getAllRestaurants(0,islandId);
  }

  //get islandId from local storage
  getIsland() async {
    String islandId = await storage.read(key: 'islandId') ?? '76ac0bec-4bc1-41a5-bc60-e528e0c12f4d';
    _view.setIsland(islandId);
  }
}

abstract class MapSearchView{
  setMunicipalities(List<Municipality> municipalities);
  setCategories(List<ModelCategory> categories);
  setTypes(List<Types> types);
  setIsland(String islandId);
}