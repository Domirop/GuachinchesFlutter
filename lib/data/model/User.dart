import 'package:guachinches/data/model/Review.dart';

class User {
  late String _id;
  late String _nombre;
  late String _apellidos;
  late String _email;
  late String _telefono;

  List<Review>? _reviews;

  String get id => _id;
  String get nombre => _nombre;
  String get apellidos => _apellidos;
  String get email => _email;
  String get telefono => _telefono;

  User({
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

  User.fromJson(dynamic json) {
    _id = json["id"] ?? "";
    _nombre = json["nombre"] ?? "";
    _apellidos = json["apellidos"] ?? "";
    _email = json["email"] ?? "";
    _telefono = json["telefono"] ?? "";
    if (json["reviews"] != null) {
      _reviews = [];
      json["reviews"].forEach((v) {
        _reviews?.add(Review.fromJson(v));
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
    if (_reviews != null) {
      map["reviews"] = _reviews!.map((v) => v.toJson()).toList();
    }
    return map;
  }

  @override
  String toString() {
    return 'User{_id: $_id, _nombre: $_nombre, _apellidos: $_apellidos, _email: $_email, _telefono: $_telefono, _reviews: $_reviews}';
  }
}
