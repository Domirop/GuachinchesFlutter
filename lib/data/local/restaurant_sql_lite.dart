class RestaurantSQLLite {
  late String _id;
  late String _restaurantId;

  String get restaurantId => _restaurantId;

  set restaurantId(String value) {
    _restaurantId = value;
  }

  RestaurantSQLLite.fromMap(Map<String, dynamic> mapa) {
    _id = mapa["id"] as String;
    _restaurantId = mapa["restaurantId"] as String;
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
