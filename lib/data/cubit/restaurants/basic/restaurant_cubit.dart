import 'package:bloc/bloc.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/restaurants/basic/restaurant_state.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/data/model/restaurant_response.dart';

class RestaurantCubit extends Cubit<RestaurantState> {
  final RemoteRepository _remoteRepository;
  Restaurant restaurant;

  RestaurantCubit(this._remoteRepository) : super(RestaurantInitial());

  Future<void> getRestaurants(int number) async {
    RestaurantResponse restaurantResponse = await _remoteRepository.getAllRestaurants(number);
    emit(RestaurantLoaded(restaurantResponse));
  }

  Future<void> getFilterRestaurants({List<String> categories, List<String> municipalities, List<String> types, String text}) async {
    List<Restaurant> restaurants = await _remoteRepository.getFilterRestaurants(categories.join(";"), municipalities.join(";"), types.join(";"), text);
    emit(RestaurantFilter(restaurants));
  }
}
