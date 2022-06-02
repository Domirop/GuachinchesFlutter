import 'User.dart';

/// id : "707d096c-43cf-425f-b7e7-55fc830c3b6b"
/// review : "Muy Buena carne fresca de maxima calidad"
/// rating : "4.5"
/// ValoracionesNegocioId : "31db2882-293d-4d2d-98ba-4939578de349"
/// ValoracionesUsuarioId : "08444ae3-0f82-4c51-9d67-50ef92458aac"
/// usuario : {"id":"08444ae3-0f82-4c51-9d67-50ef92458aac","nombre":"Pepe","apellidos":"Luis Cruz","email":"1@gmail.com","telefono":"607977602"}

class Review {
  String _id;
  String _review;
  String _rating;
  String _title;
  String _valoracionesNegocioId;
  String _valoracionesUsuarioId;
  User _usuario;

  String get id => _id;
  String get review => _review;
  String get title => _title;
  String get rating => _rating;
  String get valoracionesNegocioId => _valoracionesNegocioId;
  String get valoracionesUsuarioId => _valoracionesUsuarioId;
  User get usuario => _usuario;

  Review({
    String id,
    String review,
    String rating,
    String title,
    String valoracionesNegocioId,
    String valoracionesUsuarioId,
    User usuario}){
    _id = id;
    _review = review;
    _title = title;
    _rating = rating;
    _valoracionesNegocioId = valoracionesNegocioId;
    _valoracionesUsuarioId = valoracionesUsuarioId;
    _usuario = usuario;
  }

  Review.fromJson(dynamic json) {
    _id = json["id"];
    _title = json["title"];
    _review = json["review"];
    _rating = json["rating"];
    _valoracionesNegocioId = json["ValoracionesNegocioId"];
    _valoracionesUsuarioId = json["ValoracionesUsuarioId"];
    _usuario = json["usuarios"] != null ? User.fromJson(json["usuarios"]) : null;
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["id"] = _id;
    map["title"] = _title;
    map["review"] = _review;
    map["rating"] = _rating;
    map["ValoracionesNegocioId"] = _valoracionesNegocioId;
    map["ValoracionesUsuarioId"] = _valoracionesUsuarioId;
    if (_usuario != null) {
      map["usuario"] = _usuario.toJson();
    }
    return map;
  }

  @override
  String toString() {
    return 'Review{_id: $_id, _review: $_review, _rating: $_rating, _valoracionesNegocioId: $_valoracionesNegocioId, _valoracionesUsuarioId: $_valoracionesUsuarioId, _usuario: $_usuario}';
  }
}