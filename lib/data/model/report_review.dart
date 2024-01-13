class ReportReview {
  String _id = "";
  String _valoracionesId= "";
  String _userId = "";
  late Usuario? _usuario ;

  ReportReview({
    String? id,
    String? valoracionesId,
    String? userId,
    Usuario? usuario,
  }) {
    _id = id ?? "";
    _valoracionesId = valoracionesId ?? "";
    _userId = userId ?? "";
    _usuario = usuario;
  }

  ReportReview.fromJson(dynamic json) {
    _id = json['Id'] ?? "";
    _valoracionesId = json['valoraciones_id'] ?? "";
    _userId = json['user_id'] ?? "";
    _usuario = json['usuario'] != null ? Usuario.fromJson(json['usuario']) : null;
  }

  String get id => _id;
  String get valoracionesId => _valoracionesId;
  String get userId => _userId;
  Usuario? get usuario => _usuario;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['Id'] = _id;
    map['valoraciones_id'] = _valoracionesId;
    map['user_id'] = _userId;
    if (_usuario != null) {
      map['usuario'] = _usuario!.toJson();
    }
    return map;
  }
}

class Usuario {
  String _id = "";
  String _nombre = "";
  String _apellidos = "";
  String _email = "";
  String _telefono ="";

  Usuario({
    String? id,
    String? nombre,
    String? apellidos,
    String? email,
    String? telefono,
  }) {
    _id = id ?? "";
    _nombre = nombre ?? "";
    _apellidos = apellidos ?? "";
    _email = email ?? "";
    _telefono = telefono ?? "";
  }

  Usuario.fromJson(dynamic json) {
    _id = json['id'] ?? "";
    _nombre = json['nombre'] ?? "";
    _apellidos = json['apellidos'] ?? "";
    _email = json['email'] ?? "";
    _telefono = json['telefono'] ?? "";
  }

  String get id => _id;
  String get nombre => _nombre;
  String get apellidos => _apellidos;
  String get email => _email;
  String get telefono => _telefono;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['nombre'] = _nombre;
    map['apellidos'] = _apellidos;
    map['email'] = _email;
    map['telefono'] = _telefono;
    return map;
  }
}
