
import 'package:flutter/foundation.dart';
import 'package:guachinches/data/model/restaurant_response.dart';

@immutable
abstract class RestaurantState {
  const RestaurantState();

}

class RestaurantInitial extends RestaurantState {
  const RestaurantInitial();
}

class RestaurantFilter extends RestaurantState {
  final RestaurantResponse filtersRestaurants;
  const RestaurantFilter(this.filtersRestaurants);

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is RestaurantLoaded && o.restaurantResponse == filtersRestaurants;
  }

  @override
  int get hashCode => filtersRestaurants.hashCode;
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
