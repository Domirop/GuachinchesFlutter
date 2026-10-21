import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/config/app_theme.dart';
import 'package:guachinches/data/local/local_repository.dart';
import 'package:guachinches/data/local/restaurant_sql_lite.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/ui/pages/map/map_logic.dart';
import 'package:guachinches/utils/open_state.dart';

/// Utilidades de los tests de la pestaña Mapa (no es un test).

/// Miércoles 14 oct 2026, 13:30 (como los tableros).
final kWed1330 = DateTime(2026, 10, 14, 13, 30);

/// Usuario de muestra (La Matanza de Acentejo).
const kUserLat = 28.4528;
const kUserLon = -16.4478;

/// Periodo de Google del miércoles (día 3) de [open] a [close] («HHMM»).
Map<String, dynamic> wedHours(String open, String close) => {
      'periods': [
        {
          'open': {'day': 3, 'time': open},
          'close': {'day': 3, 'time': close},
        }
      ]
    };

Restaurant place(
  String id, {
  String name = 'Casa Ángela',
  double lat = kUserLat,
  double lon = kUserLon,
  String type = 'vacio',
  String municipio = 'La Victoria',
  Map<String, dynamic>? hours,
  double rating = 0,
  String phone = '',
}) {
  final r = Restaurant(
    id: id,
    nombre: name,
    lat: lat,
    lon: lon,
    type: type,
    municipio: municipio,
    avgRating: rating,
  );
  r.horariosJson = hours;
  r.telefono = phone;
  return r;
}

MapSite site(
  String id, {
  String name = 'Casa Ángela',
  String type = 'vacio',
  String municipio = 'La Victoria',
  OpenState open = const OpenState(OpenKind.open,
      minutesToClose: 510, closesAtMinute: 22 * 60),
  double? meters = 3400,
  double lat = kUserLat,
  double lon = kUserLon,
}) =>
    MapSite(
      restaurant: place(id,
          name: name, type: type, municipio: municipio, lat: lat, lon: lon),
      kind: mapKindOf(place(id, type: type)),
      open: open,
      meters: meters,
    );

/// Envuelve en MaterialApp con el tema del rediseño.
Widget wrapMap(Widget child, {bool dark = false}) => MaterialApp(
      theme: dark ? appDarkTheme : appLightTheme,
      home: Scaffold(body: child),
    );

Finder byIdentifier(String id) => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.identifier == id,
    );

/// Guardados en memoria.
class MemFavs implements LocalRepository {
  final Set<String> ids;
  MemFavs([Set<String>? ids]) : ids = ids ?? {};

  @override
  Future<List<RestaurantSQLLite>> getRestaurants() async => [
        for (final id in ids)
          RestaurantSQLLite.fromMap({'id': 1, 'restaurantId': id}),
      ];
  @override
  Future<bool> insertRestaurant(String id) async => ids.add(id);
  @override
  Future<bool> removeRestaurant(String id) async => ids.remove(id);
  @override
  Future<bool> isFavorite(String id) async => ids.contains(id);
  @override
  Future<RestaurantSQLLite?> getRestaurant(String id) async => null;
}
