class Types {
  String _id;
  String _nombre;
  String _iconUrl;

  String get id => _id;
  String get nombre => _nombre;
  String get iconUrl => _iconUrl;
  Types({
    String id,
    String nombre,
  String iconUrl}){
    _id = id;
    _nombre = nombre;
    _iconUrl = iconUrl;
  }

  Types.fromJson(dynamic json) {
    _id = json["id"];
    _nombre = json["name"];
    _iconUrl = json["icon"];
  }

}