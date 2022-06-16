import 'SimpleMunicipality.dart';

/// Id : "1111a92f-45c8-4760-a5cb-9c7dc9555193"
/// Nombre : "La Victoria de Acentejo"

class Municipality {
  String _id;
  String _nombre;
  bool _limitSearch = true;
  List<SimpleMunicipality> _municipalities = [];

  bool get limitSearch => _limitSearch;

  set limitSearch(bool value) {
    _limitSearch = value;
  }

  String get id => _id;
  String get nombre => _nombre;
  List<SimpleMunicipality> get municipalities => _municipalities;

  Municipality({
    String id,
    String nombre, List<SimpleMunicipality> municipalities}){
    _id = id;
    _nombre = nombre;
    _municipalities = municipalities;
  }


  set id(String value) {
    _id = value;
  }

  Municipality.fromJson(dynamic json) {
    _id = json["Id"];
    _nombre = json["Nombre"];
    if (json["Municipios"] != null) {
      json["Municipios"].forEach((v) {
        _municipalities.add(SimpleMunicipality.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["Id"] = _id;
    map["Nombre"] = _nombre;
    return map;
  }

  set nombre(String value) {
    _nombre = value;
  }

  set municipalities(List<SimpleMunicipality> municipalities) {
    _municipalities = municipalities;
  }
}
