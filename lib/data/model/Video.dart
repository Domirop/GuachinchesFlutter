import 'package:guachinches/data/model/restaurant.dart';

class Video {
  late String id;
  late String nombre;
  late String urlVideo;
  late String restaurantId;
  late String thumbnail;

  Video({
    String? id,
    String? nombre,
    String? urlVideo,
    String? restaurantId,
    String? thumbnail
  }) {
    this.id = id!;
    this.nombre = nombre!;
    this.urlVideo = urlVideo!;
    this.restaurantId = restaurantId!;
    this.thumbnail = thumbnail!;
  }
  //from json
  Video.fromJson(dynamic json) {
    id = json["id"];
    nombre = json["name"];
    urlVideo = json["url_video"];
    restaurantId = json["restaurant_id"];
    thumbnail = json["thumbnail"];
  }
}