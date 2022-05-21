/// id : "76e52d7a-8c9b-4b2e-a74a-bcd74af4d4f5"
/// nombre : "Ternera"

class ModelCategory {
  String _id;
  String _nombre;
  String _iconUrl;

  String get id => _id;
  String get nombre => _nombre;
  String get iconUrl => _iconUrl;
  ModelCategory({
    String id,
    String nombre,
  String iconUrl}){
    _id = id;
    _nombre = nombre;
    _iconUrl = iconUrl;
  }

  ModelCategory.fromJson(dynamic json) {
    _id = json["id"];
    _nombre = json["nombre"];
    _iconUrl = json["iconUrl"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["id"] = _id;
    map["nombre"] = _nombre;
    map["iconUrl"] = _iconUrl;
    return map;
  }

}