
import 'package:flutter/foundation.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/data/model/restaurant_response.dart';

@immutable
abstract class RestaurantState {
  const RestaurantState();

}

class RestaurantInitial extends RestaurantState {
  const RestaurantInitial();
}

class RestaurantFilter extends RestaurantState {
  final List<Restaurant> filtersRestaurants;
  const RestaurantFilter(this.filtersRestaurants);

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is RestaurantFilter && o.filtersRestaurants == filtersRestaurants;
  }

  @override
  int get hashCode => filtersRestaurants.hashCode;
}
class RestaurantLoading extends RestaurantState {}

class RestaurantFilterAdvanced extends RestaurantState {
  final List<Restaurant> restaurantFilterAdvanced;
  const RestaurantFilterAdvanced(this.restaurantFilterAdvanced);

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is RestaurantFilterAdvanced && o.restaurantFilterAdvanced == restaurantFilterAdvanced;
  }

  @override
  int get hashCode => restaurantFilterAdvanced.hashCode;
}
class RestaurantLoaded extends RestaurantState {
  final RestaurantResponse restaurantResponse;
  const RestaurantLoaded(this.restaurantResponse);

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is RestaurantLoaded && o.restaurantResponse == restaurantResponse;
  }

  @override
  int get hashCode => restaurantResponse.hashCode;
}
class AllRestaurantLoaded extends RestaurantState {
  final RestaurantResponse restaurantResponse;
  const AllRestaurantLoaded(this.restaurantResponse);

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is AllRestaurantLoaded && o.restaurantResponse == restaurantResponse;
  }

  @override
  int get hashCode => restaurantResponse.hashCode;
}
