import 'restaurant.dart';

class RestaurantResponse {
  int? _count;
  List<Restaurant> _restaurants = [];

  int? get count => _count;
  List<Restaurant> get restaurants => _restaurants;

  RestaurantResponse({
    int? count,
    List<Restaurant> restaurants = const [],
  }) : _count = count {
    _restaurants = restaurants;
  }

  set count(int? value) {
    _count = value;
  }

  RestaurantResponse.fromJson(dynamic json) {
    _count = json["count"];
    if (json["rows"] != null) {
      json["rows"].forEach((v) {
        _restaurants.add(Restaurant.fromJson(v));
      });
    }
  }

  set restaurants(List<Restaurant> restaurants) {
    _restaurants = restaurants;
  }
}
