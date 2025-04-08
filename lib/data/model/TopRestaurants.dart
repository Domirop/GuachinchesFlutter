import 'package:guachinches/globalMethods.dart';

class TopRestaurants {
  late String _id;
  late String _nombre;
  late String _horarios;
  late String _direccion;
  late String _counter;
  late String _imagen;
  late String _cerrado;
  late String _municipio;
  late double _avg;
  late bool _open;

  String get id => _id;
  String get nombre => _nombre;
  String get horarios => _horarios;
  String get direccion => _direccion;
  String get counter => _counter;
  String get imagen => _imagen;
  String get cerrado => _cerrado;
  String get municipio => _municipio;
  double get avg => _avg;
  bool get open => _open;

  TopRestaurants({
    String? id,
    String? nombre,
    String? horarios,
    String? direccion,
    String? counter,
    String? imagen,
    String? cerrado,
    bool? open,
    String? municipio,
    double? avg,
  }) {
    _id = id ?? "";
    _nombre = nombre?.capitalize() ?? "";
    _horarios = horarios ?? "";
    _direccion = direccion ?? "";
    _counter = counter ?? "";
    _imagen = imagen ?? "";
    _cerrado = cerrado ?? "";
    _open = open ?? false;
    _municipio = municipio??municipio?.capitalize() ?? "";
    _avg = avg ?? 0.0;
  }

  TopRestaurants.fromJson(dynamic json) {
    _id = json["id"] ?? "";
    _nombre = (json["nombre"] as String?)?.capitalize() ?? "";
    _horarios = json["horarios"] ?? "";
    _direccion = json["direccion"] ?? "";
    _counter = json["counter"] ?? "";
    _imagen = json["max"] ?? "";
    _avg = double.parse(json["avg"] ?? "0.0");
    _municipio = (json['municipio'] as String?)?.capitalize() ?? "";
print(_nombre);
    bool auxOpen = true;
    bool alwaysOpen = false;
    String auxValue = json["google_horarios"] ?? "";
    print("HORARIO ${nombre.toUpperCase()} -> líneas detectadas: ${auxValue.split('\n').length}");
    print("Texto bruto:\n$auxValue");
    if (auxValue.toLowerCase() == "cerrado" || auxValue.toLowerCase() == "sin horario") {
      auxOpen = false;
    } else {
      try {
        String auxValue2 = auxValue
            .split("\n")[DateTime
            .now()
            .toUtc()
            .weekday - 1]
            .split(": ")[1];
        if (auxValue2.toLowerCase() == "cerrado") auxOpen = false;
        if (auxValue2.toLowerCase() == "abierto 24 horas") {
          auxOpen = true;
          auxOpen = alwaysOpen = true;
        }
      }catch(e){
        print("ERROR HORARIO");
        print(nombre);
      }
    }
    if (auxOpen && !alwaysOpen) {
      try{
      List<String> aux = auxValue
          .split("\n")[DateTime.now().toUtc().weekday - 1]
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
          dateTimeFirst.microsecond,
        );
        DateTime dateTimeSecond = DateTime.now();
        dateTimeSecond = DateTime(
          dateTimeSecond.year,
          dateTimeSecond.month,
          dateTimeSecond.day,
          int.parse(auxHours[1].split(":")[0]),
          int.parse(auxHours[1].split(":")[1]),
          dateTimeSecond.second,
          dateTimeSecond.millisecond,
          dateTimeSecond.microsecond,
        );
        if (actualDate.isBefore(dateTimeFirst) || actualDate.isAfter(dateTimeSecond)) auxOpen = false;
        else {
          auxOpen = true;
          break;
        }
      }
      }on Exception catch (e) {
        print("ERROR restaurante: "+nombre +" "+ e.toString());
    }
    }
    _open = auxOpen;
  }
}
