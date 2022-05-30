class Cupones {
  String _id;
  String _date;
  int _mesasDisponibles;
  int _mesasTotales;
  String _fotoUrl;
  int _descuento;
  String _restaurantId;

  Cupones (
      {String id,
        String date,
        int mesasDisponibles,
        int mesasTotales,
        String fotoUrl,
        int descuento, String restaurantId}) {
    _id = id;
    _date = date;
    _mesasDisponibles = mesasDisponibles;
    _mesasTotales = mesasTotales;
    _fotoUrl = fotoUrl;
    _descuento = descuento;
    _restaurantId = restaurantId;
  }

  Cupones.fromJson(dynamic json) {
    _id = json["id"];
    _date = json["date"];
    _mesasDisponibles = json["mesasDisponibles"];
    _mesasTotales = json["mesasTotales"];
    _fotoUrl = json["fotoUrl"];
    _descuento = json["_descuento"];
    _restaurantId = json["restaurantId"];
  }

  String get id => _id;

  set descuento(int value) {
    _descuento = value;
  }

  set fotoUrl(String value) {
    _fotoUrl = value;
  }

  set mesasTotales(int value) {
    _mesasTotales = value;
  }

  set mesasDisponibles(int value) {
    _mesasDisponibles = value;
  }

  set date(String value) {
    _date = value;
  }

  set id(String value) {
    _id = value;
  }

  set restaurantId(String value) {
    _restaurantId = value;
  }

  String get date => _date;

  int get descuento => _descuento;

  String get fotoUrl => _fotoUrl;

  int get mesasTotales => _mesasTotales;

  int get mesasDisponibles => _mesasDisponibles;

  String get restaurantId => _restaurantId;

}
