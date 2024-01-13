import 'User.dart';

class Review {
  late String _id;
  late String _review;
  late String _rating;
  late String _title;
  late String _valoracionesNegocioId;
  late String _valoracionesUsuarioId;
  User? _usuario;

  String get id => _id;
  String get review => _review;
  String get title => _title;
  String get rating => _rating;
  String get valoracionesNegocioId => _valoracionesNegocioId;
  String get valoracionesUsuarioId => _valoracionesUsuarioId;
  User? get usuario => _usuario;

  Review({
    String? id,
    String? review,
    String? rating,
    String? title,
    String? valoracionesNegocioId,
    String? valoracionesUsuarioId,
    User? usuario,
  }) {
    _id = id ?? "";
    _title = title ?? "";
    _review = review ?? "";
    _rating = rating ?? "";
    _valoracionesNegocioId = valoracionesNegocioId ?? "";
    _valoracionesUsuarioId = valoracionesUsuarioId ?? "";
    _usuario = usuario;
  }

  Review.fromJson(dynamic json) {
    _id = json["id"];
    _title = json["title"];
    _review = json["review"];
    _rating = json["rating"];
    _valoracionesNegocioId = json["ValoracionesNegocioId"];
    _valoracionesUsuarioId = json["ValoracionesUsuarioId"];
    _usuario =  User.fromJson(json["usuarios"]);
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["id"] = _id;
    map["title"] = _title;
    map["review"] = _review;
    map["rating"] = _rating;
    map["ValoracionesNegocioId"] = _valoracionesNegocioId;
    map["ValoracionesUsuarioId"] = _valoracionesUsuarioId;
    map["usuario"] = _usuario!.toJson();
    return map;
  }

  @override
  String toString() {
    return 'Review{_id: $_id, _review: $_review, _rating: $_rating, _valoracionesNegocioId: $_valoracionesNegocioId, _valoracionesUsuarioId: $_valoracionesUsuarioId, _usuario: $_usuario}';
  }
}
