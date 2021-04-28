import 'package:guachinches/model/CategoryRestaurant.dart';
import 'package:guachinches/model/Review.dart';

import 'Menu.dart';
import 'Municipality.dart';

/// id : "31db2882-293d-4d2d-98ba-4939578de349"
/// nombre : "Guachinche El Barco"
/// direccion : " Calle Maria Nieves, 15, 38389 La Victoria de Acentejo"
/// telefono : "922581552"
/// createdAt : "2021-04-15T13:10:11.435Z"
/// updatedAt : "2021-04-15T13:10:11.435Z"
/// NegocioMunicipioId : "1111a92f-45c8-4760-a5cb-9c7dc9555193"
/// municipio : {"Id":"1111a92f-45c8-4760-a5cb-9c7dc9555193","Nombre":"La Victoria de Acentejo"}
/// menu : {"id":"ea140019-f397-45b5-879f-0006ab3b4149","plato":"Carne fiesta con papas","precio":"5.5","fotoUrl":"www.google.com/prueba","descuento":0,"menu_restauranteId":"31db2882-293d-4d2d-98ba-4939578de349"}
/// categoriaRestaurantes : [{"id":"ca605070-9d39-11eb-a400-cb3975f86e51","categorias_restauranteId":"31db2882-293d-4d2d-98ba-4939578de349","categoriaId":"76e52d7a-8c9b-4b2e-a74a-bcd74af4d4f5","Categorias":{"id":"76e52d7a-8c9b-4b2e-a74a-bcd74af4d4f5","nombre":"Ternera"}},{"id":"db0df037-796f-44d8-8d72-da04a9b86df0","categorias_restauranteId":"31db2882-293d-4d2d-98ba-4939578de349","categoriaId":"16bd1169-9b0c-43d8-985b-42699dab2527","Categorias":{"id":"16bd1169-9b0c-43d8-985b-42699dab2527","nombre":"Cerdo"}}]
/// Valoraciones : [{"id":"707d096c-43cf-425f-b7e7-55fc830c3b6b","review":"Muy Buena carne fresca de maxima calidad","rating":"4.5","ValoracionesNegocioId":"31db2882-293d-4d2d-98ba-4939578de349","ValoracionesUsuarioId":"08444ae3-0f82-4c51-9d67-50ef92458aac","usuario":{"id":"08444ae3-0f82-4c51-9d67-50ef92458aac","nombre":"Pepe","apellidos":"Luis Cruz","email":"1@gmail.com","telefono":"607977602"}}]

class Restaurant {
  String _id;
  String _nombre;
  String _direccion;
  String _telefono;
  String _destacado;
  String avg = "n/d";
  String _createdAt;
  String _updatedAt;
  String _negocioMunicipioId;
  Municipality _municipio;
  Menu _menu;
  List<CategoryRestaurant> _categoriaRestaurantes;
  List<Review> _valoraciones;

  String get id => _id;
  String get nombre => _nombre;
  String get direccion => _direccion;
  String get telefono => _telefono;
  String get destacado => _destacado;
  String get createdAt => _createdAt;
  String get updatedAt => _updatedAt;
  String get negocioMunicipioId => _negocioMunicipioId;
  Municipality get municipio => _municipio;
  Menu get menu => _menu;
  List<CategoryRestaurant> get categoriaRestaurantes => _categoriaRestaurantes;
  List<Review> get valoraciones => _valoraciones;

  Restaurant({
      String id, 
      String nombre, 
      String direccion, 
      String telefono,
      String destacado,
      String createdAt, 
      String updatedAt, 
      String negocioMunicipioId,
    Municipality municipio,
      Menu menu, 
      List<CategoryRestaurant> categoriaRestaurantes,
      List<Review> valoraciones}){
    _id = id;
    _nombre = nombre;
    _direccion = direccion;
    _telefono = telefono;
    _destacado = destacado;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
    _negocioMunicipioId = negocioMunicipioId;
    _municipio = municipio;
    _menu = menu;
    _categoriaRestaurantes = categoriaRestaurantes;
    _valoraciones = valoraciones;
}

  Restaurant.fromJson(dynamic json) {
    _id = json["id"];
    _nombre = json["nombre"];
    _direccion = json["direccion"];
    _telefono = json["telefono"];
    _destacado = json["destacado"];
    _createdAt = json["createdAt"];
    _updatedAt = json["updatedAt"];
    _negocioMunicipioId = json["NegocioMunicipioId"];
    _municipio = json["municipio"] != null ? Municipality.fromJson(json["municipio"]) : null;
    _menu = json["menu"] != null ? Menu.fromJson(json["menu"]) : null;
    if (json["categoriaRestaurantes"] != null) {
      _categoriaRestaurantes = [];
      json["categoriaRestaurantes"].forEach((v) {
        _categoriaRestaurantes.add(CategoryRestaurant.fromJson(v));
      });
    }
    if (json["Valoraciones"] != null) {
      _valoraciones = [];
      json["Valoraciones"].forEach((v) {
        _valoraciones.add(Review.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["id"] = _id;
    map["nombre"] = _nombre;
    map["direccion"] = _direccion;
    map["telefono"] = _telefono;
    map["destacado"] = _destacado;
    map["createdAt"] = _createdAt;
    map["updatedAt"] = _updatedAt;
    map["NegocioMunicipioId"] = _negocioMunicipioId;
    if (_municipio != null) {
      map["municipio"] = _municipio.toJson();
    }
    if (_menu != null) {
      map["menu"] = _menu.toJson();
    }
    if (_categoriaRestaurantes != null) {
      map["categoriaRestaurantes"] = _categoriaRestaurantes.map((v) => v.toJson()).toList();
    }
    if (_valoraciones != null) {
      map["Valoraciones"] = _valoraciones.map((v) => v.toJson()).toList();
    }
    return map;
  }

}











