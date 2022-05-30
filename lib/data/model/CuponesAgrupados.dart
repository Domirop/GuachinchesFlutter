import 'package:guachinches/data/model/Cupones.dart';

class CuponesAgrupados {
  String _id;
  bool _enable;
  String _nombre;
  String _nombreAbrev;
  String _foto;
  List<Cupones> cupones = [];

  CuponesAgrupados (
      {String id,
        bool enable,
        String nombre,
        String nombreAbrev,
        String foto}) {
    _id = id;
    _enable = enable;
    _nombre = nombre;
    _nombreAbrev = nombreAbrev;
    _foto = foto;
  }

  CuponesAgrupados.fromJson(dynamic json) {
    _id = json["id"];
    _enable = json["enable"];
    _nombre = json["nombre"];
    _nombreAbrev = _nombre.toLowerCase();
    if(_nombreAbrev.contains("guachinche"))_nombreAbrev = _nombreAbrev.replaceAll("guachinche", "");
    if(_nombreAbrev.length > 10)_nombreAbrev = _nombreAbrev.substring(0,10) + "...";
    var aux = json["fotos"];
    if(aux != null && aux.length > 0) _foto = aux[0]["photoUrl"];
    if(json["cupones"] != null && json["cupones"].length > 0){
      json["cupones"].forEach((element) {
        Cupones cupon = Cupones.fromJson(element);
        cupones.add(cupon);
      });
    }
  }

  String get id => _id;

  set descuento(String value) {
    _foto = value;
  }

  set nombre(String value) {
    _nombre = value;
  }

  set nombreAbrev(String value) {
    _nombreAbrev = value;
  }

  set date(bool value) {
    _enable = value;
  }

  set id(String value) {
    _id = value;
  }

  bool get enable => _enable;

  String get foto => _foto;

  String get nombre => _nombre;

  String get nombreAbrev => _nombreAbrev;

}
