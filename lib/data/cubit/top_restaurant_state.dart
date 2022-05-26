
import 'package:flutter/foundation.dart';
import 'package:guachinches/data/model/TopRestaurants.dart';
import 'package:guachinches/data/model/restaurant.dart';

@immutable
abstract class TopRestaurantState {
  const TopRestaurantState();

}

class TopRestaurantInitial extends TopRestaurantState {
  const TopRestaurantInitial();
}

class TopRestaurantLoaded extends TopRestaurantState {
  final List<TopRestaurants> restaurants;
  const TopRestaurantLoaded(this.restaurants);

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is TopRestaurantLoaded && o.restaurants == restaurants;
  }

  @override
  int get hashCode => restaurants.hashCode;
}
