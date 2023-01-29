import 'package:guachinches/globalMethods.dart';

class TopRestaurants {
  String _id;
  String _nombre;
  String _horarios;
  String _direccion;
  String _counter;
  String _imagen;
  String _cerrado;
  String _municipio;
  double _avg;
  bool _open;

  String get id => _id;
  String get nombre => _nombre;
  String get horarios => _horarios;
  String get direccion => _direccion;
  String get counter => _counter;
  String get imagen => _imagen;
  String get cerrado => _cerrado;
  bool get open => _open;
  String get municipio => _municipio;
  double get avg => _avg;
  TopRestaurants({String id, String nombre, String horarios, String direccion, String counter, String imagen, String cerrado, bool open, String municipio, double avg}){
    _id = id;
    _nombre = nombre;
    _horarios = horarios;
    _direccion = direccion;
    _counter = counter;
    _imagen = imagen;
    _cerrado = cerrado;
    _open = open;
    _municipio = municipio;
    _avg = avg;
  }

  TopRestaurants.fromJson(dynamic json) {
    _id = json["id"];
    _nombre = json["nombre"].toString().capitalize();
    _horarios = json["horarios"];
    _direccion = json["direccion"];
    _counter = json["counter"];
    _imagen = json["max"];
    _avg = double.parse(json["avg"]);
    _municipio = json['municipio'].toString().capitalize();
    bool auxOpen = true;
    bool alwaysOpen = false;
    String auxValue = json["google_horarios"];
    if (auxValue.toLowerCase() == "cerrado" ||
        auxValue.toLowerCase() == "sin horario") {
      auxOpen = false;
    } else {
      String auxValue2 = json["google_horarios"]
          .split("\n")[DateTime.now().toUtc().weekday-1]
          .split(": ")[1];
      if (auxValue2.toLowerCase() == "cerrado") auxOpen = false;
      if (auxValue2.toLowerCase() == "abierto 24 horas"){
        auxOpen = true;
        auxOpen = alwaysOpen = true;
      }
    }
    if (auxOpen && !alwaysOpen) {
      List<String> aux = json["google_horarios"]
          .split("\n")[DateTime.now().toUtc().weekday-1]
          .split(": ")[1]
          .split(", ");
      DateTime actualDate = DateTime.now();
      for (var i = 0; i < aux.length; i++) {
        List<String> auxHours = aux[i].split("–");
        DateTime dateTimeFirst = DateTime.now();
        dateTimeFirst = DateTime(
            dateTimeFirst.year,
            dateTimeFirst.month,
            dateTimeFirst.day,
            int.parse(auxHours[0].split(":")[0]),
            int.parse(auxHours[0].split(":")[1]),
            dateTimeFirst.second,
            dateTimeFirst.millisecond,
            dateTimeFirst.microsecond);
        DateTime dateTimeSecond = DateTime.now();
        dateTimeSecond = DateTime(
            dateTimeSecond.year,
            dateTimeSecond.month,
            dateTimeSecond.day,
            int.parse(auxHours[1].split(":")[0]),
            int.parse(auxHours[1].split(":")[1]),
            dateTimeSecond.second,
            dateTimeSecond.millisecond,
            dateTimeSecond.microsecond);
        if (actualDate.isBefore(dateTimeFirst) ||
            actualDate.isAfter(dateTimeSecond)) auxOpen = false;
        else {
          auxOpen = true;
          break;
        }
      }
    }
    _open = auxOpen;
  }
}











