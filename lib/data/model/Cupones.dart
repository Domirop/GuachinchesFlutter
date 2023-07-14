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
  String _cuponesUsuarioId;
  String _turno;

  Cupones (
      {String id,
        String date,
        int mesasDisponibles,
        int mesasTotales,
        String fotoUrl,
        int descuento, String restaurantId, String restaurantName, String cuponesUsuarioId,String turno}) {
    _id = id;
    _date = date;
    _mesasDisponibles = mesasDisponibles;
    _mesasTotales = mesasTotales;
    _fotoUrl = fotoUrl;
    _descuento = descuento;
    _restaurantId = restaurantId;
    _cuponesUsuarioId = cuponesUsuarioId;
    _restaurantName = restaurantName;
    _turno = turno;
  }

  Cupones.fromJson(dynamic json) {
    print('Cupones');
    print(json);

    if(json['cupones']!= null){
      _id = json["cupones"]["id"];
      _date = json["cupones"]["date"];
      _mesasDisponibles = json["cupones"]["mesasDisponibles"];
      _fotoUrl = json['fotoUrl'];
      _mesasTotales = json["cupones"]["mesasTotales"];
      _fotoUrl = json["cupones"]["fotoUrl"];
      _descuento = json["cupones"]["descuento"];
      _restaurantId = json["cupones"]["restaurantId"];
      _turno = json["cupones"]["turno"];
      _cuponesUsuarioId = json["id"];
      if(json["cupones"]["restaurant"] != null && json["cupones"]["restaurant"]["nombre"] != null)_restaurantName = json["cupones"]["restaurant"]["nombre"];

    } else{
      _id = json["id"];
      _date = json["date"];
      _turno = json["turno"];
      _mesasDisponibles = json["mesasDisponibles"];
      _mesasTotales = json["mesasTotales"];
      _fotoUrl = json["fotoUrl"];
      _descuento = json["descuento"];
      _restaurantId = json["restaurantId"];
      if(json["restaurant"] != null && json["restaurant"]["nombre"] != null)_restaurantName = json["restaurant"]["nombre"];
    }
    if(_date != null){
      List aux = _date.split("-");
      _minDate = aux[2] + "/" + aux[1];
    }
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
  String get cuponesUsuarioId => _cuponesUsuarioId;

  int get mesasTotales => _mesasTotales;

  int get mesasDisponibles => _mesasDisponibles;

  String get turno => _turno;

  String get restaurantId => _restaurantId;

}
