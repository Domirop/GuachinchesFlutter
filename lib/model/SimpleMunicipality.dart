class SimpleMunicipality{
  String _id;
  String _nombre;
  String _areaMunicipioId;

  String get id => _id;
  String get nombre => _nombre;
  String get areaMunicipioId => _areaMunicipioId;

  SimpleMunicipality({
  String id,
  String nombre, String areaMunicipioId}){
  _id = id;
  _nombre = nombre;
  _areaMunicipioId = areaMunicipioId;
  }

  SimpleMunicipality.fromJson(dynamic json) {
    _id = json["Id"];
    _nombre = json["Nombre"];
    _areaMunicipioId = json["area_municipiosId"];
  }

  set nombre(String value) {
    _nombre = value;
  }

  set id(String value) {
    _id = value;
  }

  set areaMunicipioId(String value) {
    _areaMunicipioId = value;
  }
}