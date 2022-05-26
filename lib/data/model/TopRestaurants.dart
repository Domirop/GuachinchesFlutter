import 'package:guachinches/data/model/CategoryRestaurant.dart';
import 'package:guachinches/data/model/Review.dart';

import 'Menu.dart';
import 'fotos.dart';
import 'municipio_restaurant.dart';

class TopRestaurants {
  String _id;
  String _nombre;
  String _horarios;
  String _direccion;
  String _counter;
  String _imagen;

  String get id => _id;
  String get nombre => _nombre;
  String get horarios => _horarios;
  String get direccion => _direccion;
  String get counter => _counter;
  String get imagen => _imagen;

  TopRestaurants({String id, String nombre, String horarios, String direccion, String counter, String imagen}){
    _id = id;
    _nombre = nombre;
    _horarios = horarios;
    _direccion = direccion;
    _counter = counter;
    _imagen = imagen;
  }

  TopRestaurants.fromJson(dynamic json) {
    _id = json["id"];
    _nombre = json["nombre"];
    _horarios = json["horarios"];
    _direccion = json["direccion"];
    _counter = json["counter"];
    _imagen = json["max"];
  }
}











