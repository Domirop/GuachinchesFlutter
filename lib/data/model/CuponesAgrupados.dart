import 'package:guachinches/data/model/restaurant.dart';

import 'Cupones.dart';

class CuponesAgrupados {
  late String _id;
  late bool _enable;
  late String _nombre;
  late String _nombreAbrev;
  late String _direccion;
  late String _foto;
  late double _avgRating;
  late List<Cupones> cupones;
  late bool _open;

  String get nombre => _nombre;

  String get id => _id;

  set nombre(String value) {
    _nombre = value;
  }

  CuponesAgrupados({
    required String id,
    required bool enable,
    required String nombre,
    required String nombreAbrev,
    required String foto,
  }) {
    _id = id;
    _enable = enable;
    _nombre = nombre;
    _nombreAbrev = nombreAbrev;
    _foto = foto;
    cupones = <Cupones>[];
  }

  CuponesAgrupados.fromJson(dynamic json) {
    print('test03');
    _id = json["id"];
    _enable = json["enable"];
    _nombre = json["nombre"];
    _direccion = json["direccion"];
    _nombreAbrev = _nombre.toLowerCase();
    if (_nombreAbrev.contains("guachinche")) _nombreAbrev = _nombreAbrev.replaceAll("guachinche", "");
    if (_nombreAbrev.length > 10) _nombreAbrev = _nombreAbrev.substring(0, 10) + "...";
    _avgRating = json["avgRating"] != null ? double.parse(double.parse(json["avgRating"]).toStringAsFixed(2)) : 0.0;
    var aux = json["fotos"];
    _foto = aux != null && aux.length > 0 ? aux[0]["photoUrl"] : "";
    cupones = <Cupones>[];
    if (json["cupones"] != null && json["cupones"].length > 0) {
      json["cupones"].forEach((element) {
        element['fotoUrl'] = _foto;
        final cupon = Cupones.fromJson(element);
        cupon.fotoUrl = _foto;
        cupones.add(cupon);
      });
    }
    _open = Restaurant.generateOpen(json["google_horarios"]);
  }

  bool get enable => _enable;

  String get nombreAbrev => _nombreAbrev;

  String get direccion => _direccion;

  String get foto => _foto;

  double get avgRating => _avgRating;

  bool get open => _open;
}
