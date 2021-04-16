/// Id : "1111a92f-45c8-4760-a5cb-9c7dc9555193"
/// Nombre : "La Victoria de Acentejo"

class Municipality {
  String _id;
  String _nombre;

  String get id => _id;
  String get nombre => _nombre;

  Municipality({
    String id,
    String nombre}){
    _id = id;
    _nombre = nombre;
  }

  Municipality.fromJson(dynamic json) {
    _id = json["Id"];
    _nombre = json["Nombre"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["Id"] = _id;
    map["Nombre"] = _nombre;
    return map;
  }

}