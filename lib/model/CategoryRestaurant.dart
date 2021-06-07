import 'Category.dart';

/// id : "ca605070-9d39-11eb-a400-cb3975f86e51"
/// categorias_restauranteId : "31db2882-293d-4d2d-98ba-4939578de349"
/// categoriaId : "76e52d7a-8c9b-4b2e-a74a-bcd74af4d4f5"
/// Categorias : {"id":"76e52d7a-8c9b-4b2e-a74a-bcd74af4d4f5","nombre":"Ternera"}

class CategoryRestaurant {
  String _id;
  String _categoriasRestauranteId;
  String _categoriaId;
  ModelCategory _categorias;

  String get id => _id;
  String get categoriasRestauranteId => _categoriasRestauranteId;
  String get categoriaId => _categoriaId;
  ModelCategory get categorias => _categorias;

  @override
  String toString() {
    return 'CategoryRestaurant{_id: $_id, _categoriasRestauranteId: $_categoriasRestauranteId, _categoriaId: $_categoriaId, _categorias: $_categorias}';
  }

  CategoryRestaurant({
    String id,
    String categoriasRestauranteId,
    String categoriaId,
    ModelCategory categorias}){
    _id = id;
    _categoriasRestauranteId = categoriasRestauranteId;
    _categoriaId = categoriaId;
    _categorias = categorias;
  }

  CategoryRestaurant.fromJson(dynamic json) {
    _id = json["id"];
    _categoriasRestauranteId = json["categorias_restauranteId"];
    _categoriaId = json["categoriaId"];
    _categorias = json["Categorias"] != null ? ModelCategory.fromJson(json["Categorias"]) : null;
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["id"] = _id;
    map["categorias_restauranteId"] = _categoriasRestauranteId;
    map["categoriaId"] = _categoriaId;
    if (_categorias != null) {
      map["Categorias"] = _categorias.toJson();
    }
    return map;
  }

}