class ModelCategory {
  String id;
  String nombre;
  String iconUrl;

  ModelCategory({
    required this.id,
    required this.nombre,
    required this.iconUrl,
  });

  factory ModelCategory.fromMap(Map<String, dynamic> map) {
    return ModelCategory(
      id: map["id"] ?? "",
      nombre: map["nombre"] ?? "",
      iconUrl: map["iconUrl"] ?? "",
    );
  }

  factory ModelCategory.fromJson(Map<String, dynamic> json) {
    return ModelCategory(
      id: json["id"] ?? "",
      nombre: json["nombre"] ?? "",
      iconUrl: json["iconUrl"] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "nombre": nombre,
      "iconUrl": iconUrl,
    };
  }
}
