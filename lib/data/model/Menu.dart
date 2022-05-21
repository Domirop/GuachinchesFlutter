/// id : "ea140019-f397-45b5-879f-0006ab3b4149"
/// plato : "Carne fiesta con papas"
/// precio : "5.5"
/// fotoUrl : "www.google.com/prueba"
/// descuento : 0
/// menu_restauranteId : "31db2882-293d-4d2d-98ba-4939578de349"

class Menu {
  String _id;
  String _plato;
  String _descripcion;
  String _precio;
  String _fotoUrl;
  String _alergenos;
  int _descuento;
  String _menuRestauranteId;

  String get id => _id;
  String get descripcion => _descripcion;
  String get plato => _plato;
  String get alergenos => _alergenos;
  String get precio => _precio;
  String get fotoUrl => _fotoUrl;
  int get descuento => _descuento;
  String get menuRestauranteId => _menuRestauranteId;

  Menu({
    String id,
    String plato,
    String descripcion,
    String alergenos,
    String precio,
    String fotoUrl,
    int descuento,
    String menuRestauranteId}){
    _id = id;
    _plato = plato;
    _alergenos = alergenos;
    _descripcion = descripcion;
    _precio = precio;
    _fotoUrl = fotoUrl;
    _descuento = descuento;
    _menuRestauranteId = menuRestauranteId;
  }

  Menu.fromJson(dynamic json) {
    _id = json["id"];
    _plato = json["plato"];
    _alergenos = json["alergenos"];
    _descripcion = json["descripcion"];
    _precio = json["precio"];
    _fotoUrl = json["fotoUrl"];
    _descuento = json["descuento"];
    _menuRestauranteId = json["menu_restauranteId"];
  }

  @override
  String toString() {
    return 'Menu{_id: $_id, _plato: $_plato, _descripcion: $_descripcion, _precio: $_precio, _fotoUrl: $_fotoUrl, _alergenos: $_alergenos, _descuento: $_descuento, _menuRestauranteId: $_menuRestauranteId}';
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["id"] = _id;
    map["plato"] = _plato;
    map["alergenos"] = _alergenos;
    map["descripcion"] = _descripcion;
    map["precio"] = _precio;
    map["fotoUrl"] = _fotoUrl;
    map["descuento"] = _descuento;
    map["menu_restauranteId"] = _menuRestauranteId;
    return map;
  }

}