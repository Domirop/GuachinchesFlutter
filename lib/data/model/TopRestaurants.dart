class TopRestaurants {
  String _id;
  String _nombre;
  String _horarios;
  String _direccion;
  String _counter;
  String _imagen;
  String _cerrado;
  bool _open;

  String get id => _id;
  String get nombre => _nombre;
  String get horarios => _horarios;
  String get direccion => _direccion;
  String get counter => _counter;
  String get imagen => _imagen;
  String get cerrado => _cerrado;
  bool get open => _open;

  TopRestaurants({String id, String nombre, String horarios, String direccion, String counter, String imagen, String cerrado, bool open}){
    _id = id;
    _nombre = nombre;
    _horarios = horarios;
    _direccion = direccion;
    _counter = counter;
    _imagen = imagen;
    _cerrado = cerrado;
    _open = open;
  }

  TopRestaurants.fromJson(dynamic json) {
    _id = json["id"];
    _nombre = json["nombre"];
    _horarios = json["horarios"];
    _direccion = json["direccion"];
    _counter = json["counter"];
    _imagen = json["max"];
    bool auxOpen = true;

    String auxValue = json["google_horarios"];
    if(auxValue.toLowerCase() == "cerrado")auxOpen = false;
    String auxValue2 = json["google_horarios"].split("\n")[DateTime.now().toUtc().weekday].split(": ")[1];
    if(auxValue2.toLowerCase() == "cerrado")auxOpen = false;
    if(auxOpen){
    List<String> aux = json["google_horarios"].split("\n")[DateTime.now().toUtc().weekday].split(": ")[1].split(", ");
    DateTime actualDate = DateTime.now();
      for(var i = 0; i < aux.length; i++){
        List<String> auxHours = aux[i].split("–");
        DateTime dateTimeFirst = DateTime.now();
        dateTimeFirst = DateTime(dateTimeFirst.year, dateTimeFirst.month, dateTimeFirst.day, int.parse(auxHours[0].split(":")[0]), int.parse(auxHours[0].split(":")[1]), dateTimeFirst.second, dateTimeFirst.millisecond, dateTimeFirst.microsecond);
        DateTime dateTimeSecond = DateTime.now();
        dateTimeSecond = DateTime(dateTimeSecond.year, dateTimeSecond.month, dateTimeSecond.day, int.parse(auxHours[1].split(":")[0]), int.parse(auxHours[1].split(":")[1]), dateTimeSecond.second, dateTimeSecond.millisecond, dateTimeSecond.microsecond);
        if(actualDate.isBefore(dateTimeFirst) || actualDate.isAfter(dateTimeSecond))auxOpen = false;
      }
    }
    _open = auxOpen;
  }
}











