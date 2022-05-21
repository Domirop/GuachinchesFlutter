class RestaurantSQLLite {
  String _id;
  String _restaurantId;

  String get restaurantId => _restaurantId;

  set restaurantId(String value) {
    _restaurantId = value;
  }

  RestaurantSQLLite.fromMap(dynamic mapa) {
    _id = mapa["id"];
    _restaurantId = mapa["restaurantId"];
  }


  @override
  String toString() {
    return 'RestaurantSQLLite{_id: $_id, _restaurantId: $_restaurantId}';
  }

  String get id => _id;

  set id(String value) {
    _id = value;
  }
}
