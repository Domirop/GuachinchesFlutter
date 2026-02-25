import 'Restaurant.dart';

class Visit {
  late String id;
  String? videoUrl;
  String? creator;
  String? extraText;
  late String restaurantId;
  String? createdAt;
  String? updatedAt;
  String? myTicket;   // <-- nuevo
  String? thumbnail;  // <-- nuevo
  Restaurant? restaurant;

  Visit({
    required this.id,
    this.videoUrl,
    this.creator,
    this.extraText,
    required this.restaurantId,
    this.createdAt,
    this.updatedAt,
    this.myTicket,
    this.thumbnail,
    this.restaurant,
  });

  factory Visit.fromJson(Map<String, dynamic> json) {
    return Visit(
      id: json['id'],
      videoUrl: json['videoUrl'] ?? json['video_url'],
      creator: json['creator'],
      extraText: json['extraText'] ?? json['extra_text'],
      restaurantId: json['restaurantId'] ?? json['restaurant_id'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      myTicket: json['myTicket'] ?? json['my_ticket'],   // <-- nuevo
      thumbnail: json['thumbnail'],                      // <-- nuevo (mismo nombre en API)
      restaurant: json['restaurant'] != null
          ? Restaurant.fromJson(json['restaurant'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'videoUrl': videoUrl,
      'creator': creator,
      'extraText': extraText,
      'restaurantId': restaurantId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'myTicket': myTicket,   // si tu API espera snake_case al enviar, usa 'my_ticket'
      'thumbnail': thumbnail,
      'restaurant': restaurant, // normalmente no se envía objeto completo
    };
  }
}
