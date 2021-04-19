
import 'package:flutter/foundation.dart';
import 'package:guachinches/model/restaurant.dart';

@immutable
abstract class RestaurantState {
  const RestaurantState();

}

class RestaurantInitial extends RestaurantState {
  const RestaurantInitial();
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
