import 'package:guachinches/data/model/CategoryRestaurant.dart';
import 'package:guachinches/data/model/Review.dart';

import 'Menu.dart';
import 'fotos.dart';
import 'municipio_restaurant.dart';

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
  bool _enable;
  String _horarios;
  String _googleUrl;
  String _direccion;
  String _telefono;
  String _destacado;
  String avg = "n/d";
  String _createdAt;
  String _updatedAt;
  List<Fotos> _fotos = [];
  String _negocioMunicipioId;
  MunicipioRestaurant _municipio;
  List<Menu> _menus = [];
  List<CategoryRestaurant> _categoriaRestaurantes = [];
  List<Review> _valoraciones = [];
  bool _open;
  String _googleHorarios;
  double _avgRating;
  String _mainFoto;


  set id(String value) {
    _id = value;
  }

  String get id => _id;

  String get mainFoto => _mainFoto;

  String get horarios => _horarios;

  String get googleUrl => _googleUrl;

  bool get enable => _enable;

  String get nombre => _nombre;

  String get direccion => _direccion;

  String get telefono => _telefono;

  String get destacado => _destacado;

  String get createdAt => _createdAt;

  String get updatedAt => _updatedAt;

  double get avgRating => _avgRating;

  bool get open => _open;

  String get googleHorarios => _googleHorarios;

  String get negocioMunicipioId => _negocioMunicipioId;

  List<Fotos> get fotos => _fotos;

  MunicipioRestaurant get municipio => _municipio;

  List<Menu> get menus => _menus;

  List<CategoryRestaurant> get categoriaRestaurantes => _categoriaRestaurantes;

  List<Review> get valoraciones => _valoraciones;

  @override
  String toString() {
    return 'Restaurant{_id: $_id, _nombre: $_nombre, _enable: $_enable, _googleUrl: $_googleUrl, _direccion: $_direccion, _telefono: $_telefono, _destacado: $_destacado, avg: $avg, _createdAt: $_createdAt, _updatedAt: $_updatedAt, _fotos: $_fotos, _negocioMunicipioId: $_negocioMunicipioId, _municipio: $_municipio, _menus: $_menus, _categoriaRestaurantes: $_categoriaRestaurantes, _valoraciones: $_valoraciones}';
  }

  Restaurant(
      {String id,
      String horarios,
      String nombre,
      String googleUrl,
      bool enable,
      String direccion,
      String telefono,
      String destacado,
      List<Fotos> fotos,
      String createdAt,
      String updatedAt,
      String negocioMunicipioId,
      MunicipioRestaurant municipio,
      List<Menu> menus,
      List<CategoryRestaurant> categoriaRestaurantes,
      List<Review> valoraciones,
      String googleHorarios,
      bool open,
      double avgRating, String mainFoto}) {
    _id = id;
    _enable = enable;
    _horarios = horarios;
    _googleUrl = googleUrl;
    _nombre = nombre;
    _direccion = direccion;
    _telefono = telefono;
    _destacado = destacado;
    _fotos = fotos;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
    _negocioMunicipioId = negocioMunicipioId;
    _municipio = municipio;
    _menus = menus;
    _categoriaRestaurantes = categoriaRestaurantes;
    _valoraciones = valoraciones;
    _open = open;
    _googleHorarios = googleHorarios;
    _avgRating = avgRating;
    _mainFoto = mainFoto;
  }

  Restaurant.fromJson(dynamic json) {
    _id = json["id"];
    _horarios = json["horarios"];
    _enable = json["enable"];
    _googleUrl = json["googleUrl"];
    _nombre = json["nombre"];
    _direccion = json["direccion"];
    _telefono = json["telefono"];
    _destacado = json["destacado"];
    _mainFoto = json["fotos.photoUrl"];
    if (json["avgRating"] != null)
      _avgRating =
          double.parse(double.parse(json["avgRating"]).toStringAsFixed(2));
    _createdAt = json["createdAt"];
    _updatedAt = json["updatedAt"];
    _negocioMunicipioId = json["NegocioMunicipioId"];
    _municipio = json["municipio"] != null
        ? MunicipioRestaurant.fromJson(json["municipio"])
        : null;
    if (json["menus"] != null) {
      _menus = [];
      json["menus"].forEach((v) {
        _menus.add(Menu.fromJson(v));
      });
    }
    if (json["categoriaRestaurantes"] != null) {
      _categoriaRestaurantes = [];
      json["categoriaRestaurantes"].forEach((v) {
        _categoriaRestaurantes.add(CategoryRestaurant.fromJson(v));
      });
    }
    if (json["fotos"] != null) {
      _fotos = [];
      json["fotos"].forEach((v) {
        _fotos.add(Fotos.fromJson(v));
      });
    }
    if (json["valoraciones"] != null) {
      _valoraciones = [];
      json["valoraciones"].forEach((v) {
        _valoraciones.add(Review.fromJson(v));
      });
    }

    bool auxOpen = true;
    String auxValue = json["google_horarios"];
    if (auxValue.toLowerCase() == "cerrado" ||
        auxValue.toLowerCase() == "sin horario") {
      auxOpen = false;
    } else {
      String auxValue2 = json["google_horarios"]
          .split("\n")[DateTime.now().toUtc().weekday]
          .split(": ")[1];
      if (auxValue2.toLowerCase() == "cerrado") auxOpen = false;
    }
    if (auxOpen) {
      List<String> aux = json["google_horarios"]
          .split("\n")[DateTime.now().toUtc().weekday]
          .split(": ")[1]
          .split(", ");
      DateTime actualDate = DateTime.now();
      for (var i = 0; i < aux.length; i++) {
        List<String> auxHours = aux[i].split("–");
        DateTime dateTimeFirst = DateTime.now();
        dateTimeFirst = DateTime(
            dateTimeFirst.year,
            dateTimeFirst.month,
            dateTimeFirst.day,
            int.parse(auxHours[0].split(":")[0]),
            int.parse(auxHours[0].split(":")[1]),
            dateTimeFirst.second,
            dateTimeFirst.millisecond,
            dateTimeFirst.microsecond);
        DateTime dateTimeSecond = DateTime.now();
        dateTimeSecond = DateTime(
            dateTimeSecond.year,
            dateTimeSecond.month,
            dateTimeSecond.day,
            int.parse(auxHours[1].split(":")[0]),
            int.parse(auxHours[1].split(":")[1]),
            dateTimeSecond.second,
            dateTimeSecond.millisecond,
            dateTimeSecond.microsecond);
        if (actualDate.isBefore(dateTimeFirst) ||
            actualDate.isAfter(dateTimeSecond)) auxOpen = false;
      }
    }
    _open = auxOpen;
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["id"] = _id;
    map["horarios"] = _horarios;
    map["googleUrl"] = _googleUrl;
    map["enable"] = _enable;
    map["nombre"] = _nombre;
    map["direccion"] = _direccion;
    map["telefono"] = _telefono;
    map["destacado"] = _destacado;
    map["fotos"] = _fotos;
    map["createdAt"] = _createdAt;
    map["updatedAt"] = _updatedAt;
    map["NegocioMunicipioId"] = _negocioMunicipioId;
    if (_municipio != null) {
      map["municipio"] = _municipio.toJson();
    }
    if (_categoriaRestaurantes != null) {
      map["menus"] = _menus.map((v) => v.toJson()).toList();
    }
    if (_categoriaRestaurantes != null) {
      map["categoriaRestaurantes"] =
          _categoriaRestaurantes.map((v) => v.toJson()).toList();
    }
    if (_valoraciones != null) {
      map["Valoraciones"] = _valoraciones.map((v) => v.toJson()).toList();
    }
    return map;
  }
}
