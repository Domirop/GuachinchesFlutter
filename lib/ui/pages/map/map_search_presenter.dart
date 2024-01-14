import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_cubit.dart';
import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/data/model/Municipality.dart';
import 'package:guachinches/data/model/Types.dart';

class MapSearchPresenter{
  final MapSearchView _view;
  final RemoteRepository repository;
  RestaurantCubit _restaurantCubit;

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
}

abstract class MapSearchView{
  setMunicipalities(List<Municipality> municipalities);
  setCategories(List<ModelCategory> categories);
  setTypes(List<Types> types);

}