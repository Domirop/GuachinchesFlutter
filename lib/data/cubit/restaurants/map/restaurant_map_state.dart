
import 'package:flutter/foundation.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/data/model/restaurant_response.dart';

@immutable
abstract class RestaurantMapState {
  const RestaurantMapState();

}

class RestaurantInitial extends RestaurantMapState {
  const RestaurantInitial();
}


class RestaurantFilterMap extends RestaurantMapState {
  final List<Restaurant> filtersRestaurants;
  const RestaurantFilterMap(this.filtersRestaurants);

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is RestaurantFilterMap && o.filtersRestaurants == filtersRestaurants;
  }

  @override
  int get hashCode => filtersRestaurants.hashCode;
}

class RestaurantMapLoaded extends RestaurantMapState {
  final RestaurantResponse restaurantResponse;
  const RestaurantMapLoaded(this.restaurantResponse);

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is RestaurantMapLoaded && o.restaurantResponse == restaurantResponse;
  }

  @override
  int get hashCode => restaurantResponse.hashCode;
}
class AllRestaurantMapLoaded extends RestaurantMapState {
  final RestaurantResponse restaurantResponse;
  const AllRestaurantMapLoaded(this.restaurantResponse);

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is AllRestaurantMapLoaded && o.restaurantResponse == restaurantResponse;
  }

  @override
  int get hashCode => restaurantResponse.hashCode;
}
