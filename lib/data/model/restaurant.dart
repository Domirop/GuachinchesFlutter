
import 'package:guachinches/data/model/Menu.dart';
import 'package:guachinches/data/model/fotos.dart';
import 'CategoryRestaurant.dart';
import 'Review.dart';

class Restaurant {
  late String id;
  late String nombre;
  late bool enable;
  late String horarios;
  late String googleUrl;
  late String direccion;
  late String telefono;
  late String destacado;
  late String avg = "n/d";
  late double lat = 0.0;
  late double lon = 0.0;
  late String createdAt;
  late String updatedAt;
  late List<Fotos> fotos = [];
  late String negocioMunicipioId;
  late String municipio = '';
  late List<Menu> menus = [];
  late List<CategoryRestaurant> categoriaRestaurantes = [];
  late List<Review> valoraciones = [];
  late bool open;
  late String googleHorarios;
  late double avgRating = 0;
  late String mainFoto;
  late String area;
  late String type;

  Restaurant(
      {String? id,
        String? horarios,
        String? nombre,
        String? googleUrl,
        bool? enable,
        String? direccion,
        String? telefono,
        String? destacado,
        List<Fotos>? fotos,
        String? createdAt,
        String? updatedAt,
        String? negocioMunicipioId,
        String? municipio,
        List<Menu>? menus,
        List<CategoryRestaurant>? categoriaRestaurantes,
        List<Review>? valoraciones,
        String? googleHorarios,
        bool? open = false,
        double? avgRating,
        String? mainFoto,
        String? area,
        double? lat,
        double? lon,
        String? type}) {
    this.id = id!;
    this.enable = enable!;
    this.horarios = horarios!;
    this.googleUrl = googleUrl!;
    this.nombre = nombre!;
    this.direccion = direccion!;
    this.telefono = telefono!;
    this.destacado = destacado!;
    this.fotos = fotos!;
    this.createdAt = createdAt!;
    this.updatedAt = updatedAt!;
    this.negocioMunicipioId = negocioMunicipioId!;
    this.municipio = municipio!;
    this.menus = menus!;
    this.categoriaRestaurantes = categoriaRestaurantes!;
    this.valoraciones = valoraciones!;
    this.open = open!;
    this.googleHorarios = googleHorarios!;
    this.avgRating = avgRating!;
    this.mainFoto = mainFoto!;
    this.area = area!;
    this.lat = lat!;
    this.lon = lon!;
    this.type = type!;
  }

  Restaurant.fromJson(dynamic json) {
    id = json["id"];
    horarios = json["horarios"];
    if(json['enable']!=null){
      enable = json["enable"];

    }
    googleUrl = json["googleUrl"];
    nombre = json["nombre"];
    direccion = json["direccion"];
    telefono = json["telefono"];
    if(json["destacado"]!=null){
      destacado = json["destacado"];
    }

    if (json["lat"] != null) {

      double resultado = double.parse(json['lat'].toString());
      print('resultado '+resultado.toString());

      lat = resultado;
    }
    if (json["lon"] != null) {
      double resultado = double.parse(json['lon'].toString());
      lon = resultado;
    }
    if (json["fotos"] is List) {
      try{
        mainFoto = json["fotos"][0]["photoUrl"];

      }catch(e) {
        mainFoto = '';
        print(e);
      }
    }else {
      if (json["fotos.photoUrl"] != null) {
        mainFoto = json["fotos.photoUrl"];
      } else {
        mainFoto = "";
      }
    }

    if (json["avgRating"] != null) {
      avgRating = double.parse(double.parse(json["avgRating"]).toStringAsFixed(2));
    }
    if (json["createdAt"] != null) {
      avg = json["createdAt"];
    }
    if(json["updatedAt"] != null){
      updatedAt = json["updatedAt"];
    }
    if (json["NegocioMunicipioId"] != null) {
      negocioMunicipioId = json["NegocioMunicipioId"];
    }
    if (json["google_horarios"] != null) {
      googleHorarios = json["google_horarios"];
    }
    if (json["municipios.Nombre"] != null){
      municipio = json["municipios.Nombre"];

    }else{
      try {
        municipio = json["municipios"]["Nombre"];
      } catch (e) {
        print(e);
      }
    }
    if (json["municipios.area_municipiosId"] != null){
      area = json["municipios.area_municipiosId"];
    }
    if (json["restaurantTypeId"] != null) {
      type = json["restaurantTypeId"];
    }else{
      type = 'vacio';
    }
    if (json["menus"] != null) {
      menus = [];
      json["menus"].forEach((v) {
        menus.add(Menu.fromJson(v));
      });
    }
    if (json["categoriasRestaurantes"] != null) {
      categoriaRestaurantes = [];
      json["categoriasRestaurantes"].forEach((v) {
        categoriaRestaurantes.add(CategoryRestaurant.fromJson(v));
      });
    }
    if (json["fotos"] != null) {
      fotos = [];
      json["fotos"].forEach((v) {
        fotos.add(Fotos.fromJson(v));
      });
    }
    if (json["valoraciones"] != null) {
      valoraciones = [];
      json["valoraciones"].forEach((v) {
        valoraciones.add(Review.fromJson(v));
      });
    }
    if (json["google_horarios"] != null) {
      String auxValue = json["google_horarios"];
      open = false;
      open = generateOpen(auxValue);
    }else{
      open = false;
    }
  }
  static generateOpen(googleHorario){
    bool auxOpen = true;
    bool alwaysOpen = false;
    if (googleHorario.toLowerCase() == "cerrado" ||
        googleHorario.toLowerCase() == "sin horario"||googleHorario == null) {
      auxOpen = false;
    } else {
      String auxValue2 = googleHorario
          .split("\n")[DateTime.now().toUtc().weekday-1]
          .split(": ")[1];
      if (auxValue2.toLowerCase() == "cerrado") auxOpen = false;
      if (auxValue2.toLowerCase() == "abierto 24 horas"){
        auxOpen = true;
        auxOpen = alwaysOpen = true;
      }
    }
    if (auxOpen && !alwaysOpen) {
      List<String> aux = googleHorario
          .split("\n")[DateTime.now().toUtc().weekday-1]
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
        else {
          auxOpen = true;
          break;
        }
      }
    }
    return auxOpen;
  }


}
