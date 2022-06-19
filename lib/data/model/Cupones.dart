class Cupones {
  String _id;
  String _date;
  String _minDate;
  int _mesasDisponibles;
  int _mesasTotales;
  String _fotoUrl;
  int _descuento;
  String _restaurantId;
  String _restaurantName;

  Cupones (
      {String id,
        String date,
        int mesasDisponibles,
        int mesasTotales,
        String fotoUrl,
        int descuento, String restaurantId, String restaurantName}) {
    _id = id;
    _date = date;
    _mesasDisponibles = mesasDisponibles;
    _mesasTotales = mesasTotales;
    _fotoUrl = fotoUrl;
    _descuento = descuento;
    _restaurantId = restaurantId;
    _restaurantName = restaurantName;
  }

  Cupones.fromJson(dynamic json) {
    _id = json["id"];
    _date = json["date"];
    if(_date != null){
      List aux = _date.split("-");
      _minDate = aux[2] + "/" + aux[1];
    }
    _mesasDisponibles = json["mesasDisponibles"];
    _mesasTotales = json["mesasTotales"];
    _fotoUrl = json["fotoUrl"];
    _descuento = json["descuento"];
    _restaurantId = json["restaurantId"];
    if(json["restaurant"] != null && json["restaurant"]["nombre"] != null)_restaurantName = json["restaurant"]["nombre"];
  }

  String get id => _id;
  String get restaurantName => _restaurantName;

  set descuento(int value) {
    _descuento = value;
  }

  set restaurantName(String value) {
    _restaurantName = value;
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

  String get minDate => _minDate;

  int get descuento => _descuento;

  String get fotoUrl => _fotoUrl;

  int get mesasTotales => _mesasTotales;

  int get mesasDisponibles => _mesasDisponibles;

  String get restaurantId => _restaurantId;

}
