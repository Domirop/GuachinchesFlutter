import 'package:guachinches/core/logging/app_logger.dart';

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
      //
      // El descarte se REGISTRA a propósito. Cuando era un catch mudo, un fallo
      // de parseo (horarios null) se comía los 11 restaurantes de Lanzarote y
      // la isla parecía vacía "por falta de datos". Un salto silencioso
      // convierte un bug en una laguna invisible.
      var skipped = 0;
      for (final v in json["rows"]) {
        try {
          _restaurants.add(Restaurant.fromJson(v));
        } catch (e, st) {
          skipped++;
          AppLogger.error('restaurant-response', e, st);
        }
      }
      if (skipped > 0) {
        AppLogger.info('restaurant-response',
            'descartados $skipped de ${json["rows"].length} restaurantes por error de parseo');
      }
    }
  }

  set restaurants(List<Restaurant> restaurants) {
    _restaurants = restaurants;
  }
}
