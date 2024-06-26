import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/restaurants/map/restaurant_map_cubit.dart';
import 'package:guachinches/data/model/restaurant.dart';

class SearchTextPresenter{
  final SearchTextView _view;
  final RemoteRepository repository;
  RestaurantMapCubit _restaurantCubit;

  SearchTextPresenter(this._view, this.repository, this._restaurantCubit);

  getAllRestaurantsFilterByText(String text) async {
    List<Restaurant> restaurants = await repository.getFilterRestaurants('','', '', text, '76ac0bec-4bc1-41a5-bc60-e528e0c12f4d');
    _view.setRestaurantsFilter(restaurants);
  }
}

abstract class SearchTextView{
  setRestaurantsFilter(List<Restaurant> restaurants);
}