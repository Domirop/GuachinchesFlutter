/// id : "08444ae3-0f82-4c51-9d67-50ef92458aac"
/// nombre : "Pepe"
/// apellidos : "Luis Cruz"
/// email : "1@gmail.com"
/// telefono : "607977602"
/// valoraciones : [{"id":"707d096c-43cf-425f-b7e7-55fc830c3b6b","review":"Muy Buena carne fresca de maxima calidad","rating":"4.5","ValoracionesNegocioId":"31db2882-293d-4d2d-98ba-4939578de349","ValoracionesUsuarioId":"08444ae3-0f82-4c51-9d67-50ef92458aac","Restaurantes":{"id":"31db2882-293d-4d2d-98ba-4939578de349","destacado":"","nombre":"El parralito","direccion":"Calle San Cristobal, 66, 38379 La Matanza de Acentejo","telefono":"922581552","createdAt":"2021-04-17T11:29:00.910Z","updatedAt":"2021-04-17T11:29:00.910Z","NegocioMunicipioId":"1111a92f-45c8-4760-a5cb-9c7dc9555193"}}]

class UserInfo {
  String _id;
  String _nombre;
  String _apellidos;
  String _email;
  String _telefono;
  List<Valoraciones> _valoraciones;

  String get id => _id;
  String get nombre => _nombre;
  String get apellidos => _apellidos;
  String get email => _email;
  String get telefono => _telefono;
  List<Valoraciones> get valoraciones => _valoraciones;

  UserInfo({
      String id, 
      String nombre, 
      String apellidos, 
      String email, 
      String telefono, 
      List<Valoraciones> valoraciones}){
    _id = id;
    _nombre = nombre;
    _apellidos = apellidos;
    _email = email;
    _telefono = telefono;
    _valoraciones = valoraciones;
}

  @override
  String toString() {
    return 'UserInfo{_id: $_id, _nombre: $_nombre, _apellidos: $_apellidos, _email: $_email, _telefono: $_telefono, _valoraciones: $_valoraciones}';
  }

  UserInfo.fromJson(dynamic json) {
    _id = json["id"];
    _nombre = json["nombre"];
    _apellidos = json["apellidos"];
    _email = json["email"];
    _telefono = json["telefono"];
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
    if (_valoraciones != null) {
      map["valoraciones"] = _valoraciones.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

/// id : "707d096c-43cf-425f-b7e7-55fc830c3b6b"
/// review : "Muy Buena carne fresca de maxima calidad"
/// rating : "4.5"
/// ValoracionesNegocioId : "31db2882-293d-4d2d-98ba-4939578de349"
/// ValoracionesUsuarioId : "08444ae3-0f82-4c51-9d67-50ef92458aac"
/// Restaurantes : {"id":"31db2882-293d-4d2d-98ba-4939578de349","destacado":"","nombre":"El parralito","direccion":"Calle San Cristobal, 66, 38379 La Matanza de Acentejo","telefono":"922581552","createdAt":"2021-04-17T11:29:00.910Z","updatedAt":"2021-04-17T11:29:00.910Z","NegocioMunicipioId":"1111a92f-45c8-4760-a5cb-9c7dc9555193"}

class Valoraciones {
  String _id;
  String _review;
  String _rating;
  String _title;
  String _valoracionesNegocioId;
  String _valoracionesUsuarioId;
  Restaurantes _restaurantes;

  String get id => _id;
  String get review => _review;
  String get title => _title;
  String get rating => _rating;
  String get valoracionesNegocioId => _valoracionesNegocioId;
  String get valoracionesUsuarioId => _valoracionesUsuarioId;
  Restaurantes get restaurantes => _restaurantes;

  Valoraciones({
      String id, 
      String review,
      String title,
      String rating,
      String valoracionesNegocioId, 
      String valoracionesUsuarioId, 
      Restaurantes restaurantes}){
    _id = id;
    _review = review;
    _title = title;
    _rating = rating;
    _valoracionesNegocioId = valoracionesNegocioId;
    _valoracionesUsuarioId = valoracionesUsuarioId;
    _restaurantes = restaurantes;
}

  Valoraciones.fromJson(dynamic json) {
    _id = json["id"];
    _review = json["review"];
    _title = json["title"];
    _rating = json["rating"];
    _valoracionesNegocioId = json["ValoracionesNegocioId"];
    _valoracionesUsuarioId = json["ValoracionesUsuarioId"];
    _restaurantes = json["Restaurantes"] != null ? Restaurantes.fromJson(json["Restaurantes"]) : null;
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
      map["Restaurantes"] = _restaurantes.toJson();
    }
    return map;
  }

  @override
  String toString() {
    return 'Valoraciones{_id: $_id, _review: $_review, _rating: $_rating, _title: $_title, _valoracionesNegocioId: $_valoracionesNegocioId, _valoracionesUsuarioId: $_valoracionesUsuarioId, _restaurantes: $_restaurantes}';
  }
}


class Restaurantes {
  String _id;
  String _destacado;
  String _nombre;
  String _direccion;
  String _telefono;
  String _createdAt;
  String _updatedAt;
  String _negocioMunicipioId;

  @override
  String toString() {
    return 'Restaurantes{_id: $_id, _destacado: $_destacado, _nombre: $_nombre, _direccion: $_direccion, _telefono: $_telefono, _createdAt: $_createdAt, _updatedAt: $_updatedAt, _negocioMunicipioId: $_negocioMunicipioId}';
  }

  String get id => _id;
  String get destacado => _destacado;
  String get nombre => _nombre;
  String get direccion => _direccion;
  String get telefono => _telefono;
  String get createdAt => _createdAt;
  String get updatedAt => _updatedAt;
  String get negocioMunicipioId => _negocioMunicipioId;

  Restaurantes({
      String id, 
      String destacado, 
      String nombre, 
      String direccion, 
      String telefono, 
      String createdAt, 
      String updatedAt, 
      String negocioMunicipioId}){
    _id = id;
    _destacado = destacado;
    _nombre = nombre;
    _direccion = direccion;
    _telefono = telefono;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
    _negocioMunicipioId = negocioMunicipioId;
}

  Restaurantes.fromJson(dynamic json) {
    _id = json["id"];
    _destacado = json["destacado"];
    _nombre = json["nombre"];
    _direccion = json["direccion"];
    _telefono = json["telefono"];
    _createdAt = json["createdAt"];
    _updatedAt = json["updatedAt"];
    _negocioMunicipioId = json["NegocioMunicipioId"];
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