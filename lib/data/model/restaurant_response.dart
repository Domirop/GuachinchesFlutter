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
      // Tolerante por-item: si UN restaurante trae datos malformados y su
      // `fromJson` lanza, lo saltamos en vez de tumbar la lista entera (antes,
      // un solo registro roto dejaba la home sin NINGÚN restaurante).
      for (final v in json["rows"]) {
        try {
          _restaurants.add(Restaurant.fromJson(v));
        } catch (_) {
          // Registro corrupto: lo ignoramos y seguimos con el resto.
        }
      }
    }
  }

  set restaurants(List<Restaurant> restaurants) {
    _restaurants = restaurants;
  }
}
