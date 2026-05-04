class Island {
  String id;
  String photo;
  String name;
  String? key;
  String? slug;
  int position;
  String? logoUrl;
  String? backgroundUrl;

  Island(
    this.id,
    this.photo,
    this.name, {
    this.key,
    this.slug,
    this.position = 0,
    this.logoUrl,
    this.backgroundUrl,
  });

  factory Island.fromJson(Map<String, dynamic> json) {
    final logo = json['logoUrl'] as String?;
    return Island(
      (json['id'] ?? json['Id'] ?? '') as String,
      logo ?? '',
      (json['name'] ?? '') as String,
      key: json['key'] as String?,
      slug: json['slug'] as String?,
      position: (json['position'] as num?)?.toInt() ?? 0,
      logoUrl: logo,
      backgroundUrl: json['backgroundUrl'] as String?,
    );
  }
}
