class ModelCategory {
  String id;
  String nombre;
  String iconUrl;
  String foto;

  ModelCategory({
    required this.id,
    required this.nombre,
    required this.iconUrl,
    required this.foto
  });

  factory ModelCategory.fromMap(Map<String, dynamic> map) {
    return ModelCategory(
      id: map["id"] ?? "",
      nombre: map["nombre"] ?? "",
      iconUrl: map["iconUrl"] ?? "",
      foto: map["foto"] ?? ""
    );
  }

  factory ModelCategory.fromJson(Map<String, dynamic> json) {
    return ModelCategory(
      id: json["id"] ?? "",
      nombre: json["nombre"] ?? "",
      iconUrl: json["iconUrl"] ?? "",
      foto: json["foto"] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "nombre": nombre,
      "iconUrl": iconUrl,
      "foto":foto,
    };
  }
}
