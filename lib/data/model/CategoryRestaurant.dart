import 'package:guachinches/data/model/Category.dart';

class CategoryRestaurant {
  final String id;
  final String categoriasRestauranteId;
  final String categoriaId;
  final ModelCategory categorias;

  CategoryRestaurant({
    required this.id,
    required this.categoriasRestauranteId,
    required this.categoriaId,
    required this.categorias,
  });

  factory CategoryRestaurant.fromJson(Map<String, dynamic> json) {
    return CategoryRestaurant(
      id: json["id"],
      categoriasRestauranteId: json["categorias_restauranteId"],
      categoriaId: json["categoriaId"],
      categorias:ModelCategory.fromJson(json["categorias"])
    );
  }
}
