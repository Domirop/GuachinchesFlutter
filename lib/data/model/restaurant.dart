
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/data/model/Menu.dart';
import 'package:guachinches/data/model/fotos.dart';
import 'package:guachinches/data/model/short_quote.dart';
import 'CategoryRestaurant.dart';
import 'Review.dart';

class Restaurant {
  String id = '';
  String nombre = '';
  bool enable = true;
  String horarios = '';
  String googleUrl = '';
  String direccion = '';
  String telefono = '';
  String destacado = '';
  String avg = "n/d";
  double lat = 0.0;
  double lon = 0.0;
  String createdAt = '';
  String updatedAt = '';
  List<Fotos> fotos = [];
  String negocioMunicipioId = '';
  String municipio = '';
  List<Menu> menus = [];
  List<CategoryRestaurant> categoriaRestaurantes = [];
  List<Review> valoraciones = [];
  bool open = false;
  String googleHorarios = '';
  double avgRating = 0;
  Map<String, dynamic>? horariosJson;
  String? googleHorariosSyncedAt;
  String mainFoto = '';
  String area = '';
  String type = 'vacio';

  // Campos opcionales nuevos (backend puede o no devolverlos).
  int? rankNumber;
  String? season;
  String? reservationInfo;
  String? parking;
  int? minPrice;
  int? maxPrice;
  String? website;
  String? island;

  // YouTube Short
  String? shortVideoId;
  String? shortThumbnailUrl;
  String? shortDuration;
  int? shortLikes;
  int? shortComments;
  String? shortDescription;
  List<ShortQuote> shortQuotes = const [];

  // Editorial
  String? editorialQuote;
  String? editorialBody;

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
    this.id = id ?? '';
    this.enable = enable ?? true;
    this.horarios = horarios ?? '';
    this.googleUrl = googleUrl ?? '';
    this.nombre = nombre ?? '';
    this.direccion = direccion ?? '';
    this.telefono = telefono ?? '';
    this.destacado = destacado ?? '';
    this.fotos = fotos ?? [];
    this.createdAt = createdAt ?? '';
    this.updatedAt = updatedAt ?? '';
    this.negocioMunicipioId = negocioMunicipioId ?? '';
    this.municipio = municipio ?? '';
    this.menus = menus ?? [];
    this.categoriaRestaurantes = categoriaRestaurantes ?? [];
    this.valoraciones = valoraciones ?? [];
    this.open = open ?? false;
    this.googleHorarios = googleHorarios ?? '';
    this.avgRating = avgRating ?? 0;
    this.mainFoto = mainFoto ?? '';
    this.area = area ?? '';
    this.lat = lat ?? 0.0;
    this.lon = lon ?? 0.0;
    this.type = type ?? 'vacio';
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

      lat = resultado;
    }
    if (json["lon"] != null) {
      double resultado = double.parse(json['lon'].toString());
      lon = resultado;
    }
    if (json["fotos"] is List) {
      try{
        mainFoto = json["fotos"][0]["photoUrl"];

      }catch(e, st) {
        mainFoto = '';
        AppLogger.error('restaurant-model', e, st);
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
    // Dos shapes válidos: clave plana "municipios.Nombre" (endpoint legacy)
    // o nested "municipios": { "Nombre": "..." } (endpoint nuevo).
    // Cuando el Restaurant viene embebido dentro de un Visit (`getAllVisits`)
    // el payload puede no traer NINGUNO de los dos — ahí `municipio` queda
    // como '' y seguimos. Sin null-checks aquí petaba en línea 173 con
    // `null["Nombre"]` y spameaba la consola con NoSuchMethodError, aunque
    // el catch lo atrapaba.
    if (json["municipios.Nombre"] != null) {
      municipio = json["municipios.Nombre"];
    } else {
      final muniNested = json["municipios"];
      if (muniNested is Map && muniNested["Nombre"] != null) {
        municipio = muniNested["Nombre"].toString();
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
    if (json["horarios_json"] != null) {
      horariosJson = Map<String, dynamic>.from(json["horarios_json"]);
    }
    if (json["google_horarios_synced_at"] != null) {
      googleHorariosSyncedAt = json["google_horarios_synced_at"].toString();
    }

    // Campos opcionales nuevos
    rankNumber = _asInt(json["rankNumber"] ?? json["rank_number"]);
    season = json["season"]?.toString();
    reservationInfo = json["reservationInfo"]?.toString() ?? json["reservation_info"]?.toString();
    parking = json["parking"]?.toString();
    minPrice = _asInt(json["minPrice"] ?? json["min_price"]);
    maxPrice = _asInt(json["maxPrice"] ?? json["max_price"]);
    website = json["website"]?.toString();
    island = json["island"]?.toString();

    final short = json["short"];
    if (short is Map) {
      shortVideoId = short["videoId"]?.toString() ?? short["video_id"]?.toString();
      shortThumbnailUrl = short["thumbnailUrl"]?.toString() ?? short["thumbnail_url"]?.toString();
      shortDuration = short["duration"]?.toString();
      shortLikes = _asInt(short["likes"]);
      shortComments = _asInt(short["comments"]);
      shortDescription = short["description"]?.toString();
      final quotes = short["quotes"];
      if (quotes is List) {
        shortQuotes = quotes
            .whereType<Map>()
            .map((q) => ShortQuote.fromJson(Map<String, dynamic>.from(q)))
            .toList();
      }
    }

    final editorial = json["editorial"];
    if (editorial is Map) {
      editorialQuote = editorial["quote"]?.toString();
      editorialBody = editorial["body"]?.toString();
    }
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
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
