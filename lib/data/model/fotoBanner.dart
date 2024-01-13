class FotoBanner {
  String? _id;
  String? _restaurantId;
  String? _fotoUrl;

  FotoBanner({
    String? id,
    String? restaurantId,
    String? fotoUrl,
  }) {
    _id = id;
    _restaurantId = restaurantId;
    _fotoUrl = fotoUrl;
  }

  @override
  String toString() {
    return 'FotoBanner{_id: $_id, _restaurantId: $_restaurantId, _fotoUrl: $_fotoUrl}';
  }

  FotoBanner.fromJson(dynamic json) {
    _id = json["id"];
    _restaurantId = json["restaurantId"];
    _fotoUrl = json["fotoUrl"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["id"] = _id;
    map["restaurantId"] = _restaurantId;
    map["fotoUrl"] = _fotoUrl;
    return map;
  }

  String? get restaurantId => _restaurantId;
  String? get id => _id;
  String? get fotoUrl => _fotoUrl;
}
