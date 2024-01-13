class UserInfo {
  late String _id;
  late String _nombre;
  late String _apellidos;
  late String _email;
  late String _telefono;
  late List<Valoraciones> _valoraciones;

  String get id => _id;
  String get nombre => _nombre;
  String get apellidos => _apellidos;
  String get email => _email;
  String get telefono => _telefono;
  List<Valoraciones> get valoraciones => _valoraciones;

  UserInfo({
    String? id,
    String? nombre,
    String? apellidos,
    String? email,
    String? telefono,
    List<Valoraciones>? valoraciones,
  }) {
    _id = id ?? "";
    _nombre = nombre ?? "";
    _apellidos = apellidos ?? "";
    _email = email ?? "";
    _telefono = telefono ?? "";
    _valoraciones = valoraciones ?? [];
  }

  UserInfo.fromJson(dynamic json) {
    _id = json["id"] ?? "";
    _nombre = json["nombre"] ?? "";
    _apellidos = json["apellidos"] ?? "";
    _email = json["email"] ?? "";
    _telefono = json["telefono"] ?? "";
    if (json["valoraciones"] != null) {
      _valoraciones = [];
      json["valoraciones"].forEach((v) {
        _valoraciones.add(Valoraciones.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["id"] = _id;
    map["nombre"] = _nombre;
    map["apellidos"] = _apellidos;
    map["email"] = _email;
    map["telefono"] = _telefono;
    if (_valoraciones.isNotEmpty) {
      map["valoraciones"] = _valoraciones.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class Valoraciones {
  late String _id;
  late String _review;
  late String _rating;
  late String _title;
  late String _valoracionesNegocioId;
  late String _valoracionesUsuarioId;
  late Restaurantes? _restaurantes;

  String get id => _id;
  String get review => _review;
  String get title => _title;
  String get rating => _rating;
  String get valoracionesNegocioId => _valoracionesNegocioId;
  String get valoracionesUsuarioId => _valoracionesUsuarioId;
  Restaurantes? get restaurantes => _restaurantes;

  Valoraciones({
    String? id,
    String? review,
    String? title,
    String? rating,
    String? valoracionesNegocioId,
    String? valoracionesUsuarioId,
    Restaurantes? restaurantes,
  }) {
    _id = id ?? "";
    _review = review ?? "";
    _title = title ?? "";
    _rating = rating ?? "";
    _valoracionesNegocioId = valoracionesNegocioId ?? "";
    _valoracionesUsuarioId = valoracionesUsuarioId ?? "";
    _restaurantes = restaurantes;
  }

  Valoraciones.fromJson(dynamic json) {
    _id = json["id"] ?? "";
    _review = json["review"] ?? "";
    _title = json["title"] ?? "";
    _rating = json["rating"] ?? "";
    _valoracionesNegocioId = json["ValoracionesNegocioId"] ?? "";
    _valoracionesUsuarioId = json["ValoracionesUsuarioId"] ?? "";
    if (json["Restaurantes"] != null) {
      _restaurantes = Restaurantes.fromJson(json["Restaurantes"]);
    }
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["id"] = _id;
    map["review"] = _review;
    map["title"] = _title;
    map["rating"] = _rating;
    map["ValoracionesNegocioId"] = _valoracionesNegocioId;
    map["ValoracionesUsuarioId"] = _valoracionesUsuarioId;
    if (_restaurantes != null) {
      map["Restaurantes"] = _restaurantes!.toJson();
    }
    return map;
  }
}

class Restaurantes {
  late String _id;
  late String _destacado;
  late String _nombre;
  late String _direccion;
  late String _telefono;
  late String _createdAt;
  late String _updatedAt;
  late String _negocioMunicipioId;

  String get id => _id;
  String get destacado => _destacado;
  String get nombre => _nombre;
  String get direccion => _direccion;
  String get telefono => _telefono;
  String get createdAt => _createdAt;
  String get updatedAt => _updatedAt;
  String get negocioMunicipioId => _negocioMunicipioId;

  Restaurantes({
    String? id,
    String? destacado,
    String? nombre,
    String? direccion,
    String? telefono,
    String? createdAt,
    String? updatedAt,
    String? negocioMunicipioId,
  }) {
    _id = id ?? "";
    _destacado = destacado ?? "";
    _nombre = nombre ?? "";
    _direccion = direccion ?? "";
    _telefono = telefono ?? "";
    _createdAt = createdAt ?? "";
    _updatedAt = updatedAt ?? "";
    _negocioMunicipioId = negocioMunicipioId ?? "";
  }

  Restaurantes.fromJson(dynamic json) {
    _id = json["id"] ?? "";
    _destacado = json["destacado"] ?? "";
    _nombre = json["nombre"] ?? "";
    _direccion = json["direccion"] ?? "";
    _telefono = json["telefono"] ?? "";
    _createdAt = json["createdAt"] ?? "";
    _updatedAt = json["updatedAt"] ?? "";
    _negocioMunicipioId = json["NegocioMunicipioId"] ?? "";
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["id"] = _id;
    map["destacado"] = _destacado;
    map["nombre"] = _nombre;
    map["direccion"] = _direccion;
    map["telefono"] = _telefono;
    map["createdAt"] = _createdAt;
    map["updatedAt"] = _updatedAt;
    map["NegocioMunicipioId"] = _negocioMunicipioId;
    return map;
  }
}
