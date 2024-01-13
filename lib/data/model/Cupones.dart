class Cupones {
   String id;
   String date;
  late final String minDate;
   int mesasDisponibles;
   int mesasTotales;
   String fotoUrl;
   int descuento;
   String restaurantId;
   String restaurantName;
   String cuponesUsuarioId;
   String turno;

  Cupones({
    required this.id,
    required this.date,
    required this.mesasDisponibles,
    required this.mesasTotales,
    required this.fotoUrl,
    required this.descuento,
    required this.restaurantId,
    required this.restaurantName,
    required this.cuponesUsuarioId,
    required this.turno,
  }) {
    minDate = date.split("-")[2] + "/" + date.split("-")[1];
  }

  Cupones.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        date = json['date'],
        mesasDisponibles = json['mesasDisponibles'],
        mesasTotales = json['mesasTotales'],
        fotoUrl = json['fotoUrl'],
        descuento = json['descuento'],
        restaurantId = json['restaurantId'],
        cuponesUsuarioId = json['id'],
        turno = json['turno'],
        restaurantName = (json['restaurant'] != null && json['restaurant']['nombre'] != null)
            ? json['restaurant']['nombre']
            : '' {
    minDate = date.split("-")[2] + "/" + date.split("-")[1];
  }

}
