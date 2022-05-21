
import 'package:flutter/foundation.dart';
import 'package:guachinches/data/model/restaurant.dart';

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

    return o is RestaurantLoaded && o.restaurants == filtersRestaurants;
  }

  @override
  int get hashCode => filtersRestaurants.hashCode;
}

class RestaurantLoaded extends RestaurantState {
  final List<Restaurant> restaurants;
  const RestaurantLoaded(this.restaurants);

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is RestaurantLoaded && o.restaurants == restaurants;
  }

  @override
  int get hashCode => restaurants.hashCode;
}
