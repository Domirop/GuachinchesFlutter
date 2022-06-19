import 'package:guachinches/data/model/Cupones.dart';
import 'package:guachinches/data/model/restaurant.dart';

class CuponesAgrupados {
  String _id;
  bool _enable;
  String _nombre;
  String _nombreAbrev;
  String _direccion;
  String _foto;
  double _avgRating;
  List<Cupones> cupones = [];
  bool _open;

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
    _direccion = json["direccion"];
    _nombreAbrev = _nombre.toLowerCase();
    if(_nombreAbrev.contains("guachinche"))_nombreAbrev = _nombreAbrev.replaceAll("guachinche", "");
    if(_nombreAbrev.length > 10)_nombreAbrev = _nombreAbrev.substring(0,10) + "...";
    if (json["avgRating"] != null)
      _avgRating =
          double.parse(double.parse(json["avgRating"]).toStringAsFixed(2));
    var aux = json["fotos"];
    if(aux != null && aux.length > 0) _foto = aux[0]["photoUrl"];
    if(json["cupones"] != null && json["cupones"].length > 0){
      json["cupones"].forEach((element) {
        Cupones cupon = Cupones.fromJson(element);
        cupones.add(cupon);
      });
    }
    _open = Restaurant.generateOpen(json["google_horarios"]);
  }

  String get id => _id;

  String get direccion => _direccion;

  bool get open => _open;

  double get avgRating => _avgRating;

  bool get enable => _enable;

  String get foto => _foto;

  String get nombre => _nombre;

  String get nombreAbrev => _nombreAbrev;

}
