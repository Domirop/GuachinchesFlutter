class MunicipioRestaurant {
  String _id;
  String _nombre;
  String _areaMunicipioId;

  MunicipioRestaurant({
    String id,
    String nombre,
    String areaMunicipioId}){
    _id = id;
    _nombre = nombre;
    _areaMunicipioId = areaMunicipioId;
  }

  MunicipioRestaurant.fromJson(dynamic json) {
    _id = json["Id"];
    _nombre = json["Nombre"];
    _areaMunicipioId = json["area_municipiosId"];
  }


  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["id"] = _id;
    map["nombre"] = _nombre;
    map["area_municipiosId"] = _areaMunicipioId;
    return map;
  }


  String get id => _id;

  set id(String value) {
    _id = value;
  }

  String get nombre => _nombre;

  String get areaMunicipioId => _areaMunicipioId;

  set areaMunicipioId(String value) {
    _areaMunicipioId = value;
  }

  set nombre(String value) {
    _nombre = value;
  }


}