class Fotos {
  String _id;
  String _type;
  String _photoUrl;
  String _createdAt;
  String _updatedAt;
  String _fotoRestauranteId;

  Fotos(
      {String id,
      String type,
      String photoUrl,
      String createdAt,
      String updatedAt,
      String fotoRestauranteId}) {
    _id = id;
    _type = type;
    _photoUrl = photoUrl;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
    _fotoRestauranteId = fotoRestauranteId;
  }

  Fotos.fromJson(dynamic json) {
    _id = json["id"];
    _type = json["type"];
    _photoUrl = json["photoUrl"];
    _createdAt = json["createdAt"];
    _updatedAt = json["updatedAt"];
    _fotoRestauranteId = json["foto_restauranteId"];
  }

  @override
  String toString() {
    return 'Fotos{_id: $_id, _type: $_type, _photoUrl: $_photoUrl, _createdAt: $_createdAt, _updatedAt: $_updatedAt, _fotoRestauranteId: $_fotoRestauranteId}';
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["id"] = _id;
    map["type"] = _type;
    map["photoUrl"] = _photoUrl;
    map["createdAt"] = _createdAt;
    map["updatedAt"] = _updatedAt;
    map["foto_restauranteId"] = _fotoRestauranteId;
    return map;
  }

  String get id => _id;

  set fotoRestauranteId(String value) {
    _fotoRestauranteId = value;
  }

  set updatedAt(String value) {
    _updatedAt = value;
  }

  set createdAt(String value) {
    _createdAt = value;
  }

  set photoUrl(String value) {
    _photoUrl = value;
  }

  set type(String value) {
    _type = value;
  }

  set id(String value) {
    _id = value;
  }

  String get type => _type;

  String get fotoRestauranteId => _fotoRestauranteId;

  String get updatedAt => _updatedAt;

  String get createdAt => _createdAt;

  String get photoUrl => _photoUrl;
}
