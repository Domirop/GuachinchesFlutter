
import 'package:guachinches/model/Review.dart';

/// id : "08444ae3-0f82-4c51-9d67-50ef92458aac"
/// nombre : "Pepe"
/// apellidos : "Luis Cruz"
/// email : "1@gmail.com"
/// telefono : "607977602"

class User {
  String _id;
  String _nombre;
  String _apellidos;
  String _email;
  String _telefono;
  List<Review> _reviews;
  String get id => _id;
  String get nombre => _nombre;
  String get apellidos => _apellidos;
  String get email => _email;
  String get telefono => _telefono;

  User({
    String id,
    String nombre,
    String apellidos,
    String email,
    String telefono}){
    _id = id;
    _nombre = nombre;
    _apellidos = apellidos;
    _email = email;
    _telefono = telefono;
  }

  User.fromJson(dynamic json) {
    _id = json["id"];
    _nombre = json["nombre"];
    _apellidos = json["apellidos"];
    _email = json["email"];
    _telefono = json["telefono"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["id"] = _id;
    map["nombre"] = _nombre;
    map["apellidos"] = _apellidos;
    map["email"] = _email;
    map["telefono"] = _telefono;
    return map;
  }

}