/// id : "ea140019-f397-45b5-879f-0006ab3b4149"
/// plato : "Carne fiesta con papas"
/// precio : "5.5"
/// fotoUrl : "www.google.com/prueba"
/// descuento : 0
/// menu_restauranteId : "31db2882-293d-4d2d-98ba-4939578de349"

class Menu {
  String _id;
  String _plato;
  String _precio;
  String _fotoUrl;
  int _descuento;
  String _menuRestauranteId;

  String get id => _id;
  String get plato => _plato;
  String get precio => _precio;
  String get fotoUrl => _fotoUrl;
  int get descuento => _descuento;
  String get menuRestauranteId => _menuRestauranteId;

  Menu({
    String id,
    String plato,
    String precio,
    String fotoUrl,
    int descuento,
    String menuRestauranteId}){
    _id = id;
    _plato = plato;
    _precio = precio;
    _fotoUrl = fotoUrl;
    _descuento = descuento;
    _menuRestauranteId = menuRestauranteId;
  }

  Menu.fromJson(dynamic json) {
    _id = json["id"];
    _plato = json["plato"];
    _precio = json["precio"];
    _fotoUrl = json["fotoUrl"];
    _descuento = json["descuento"];
    _menuRestauranteId = json["menu_restauranteId"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["id"] = _id;
    map["plato"] = _plato;
    map["precio"] = _precio;
    map["fotoUrl"] = _fotoUrl;
    map["descuento"] = _descuento;
    map["menu_restauranteId"] = _menuRestauranteId;
    return map;
  }

}