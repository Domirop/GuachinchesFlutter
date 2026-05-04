import 'package:guachinches/data/model/restaurant.dart';

class VisitDish {
  final String name;
  final bool isTop;

  const VisitDish({required this.name, this.isTop = false});

  factory VisitDish.fromJson(dynamic json) {
    if (json is String) return VisitDish(name: json);
    final map = json as Map<String, dynamic>;
    return VisitDish(
      name: map['name']?.toString() ?? map['dish']?.toString() ?? '',
      isTop: map['isTop'] == true || map['is_top'] == true || map['top'] == true,
    );
  }
}

class Visit {
  late String id;
  String? videoUrl;
  String? creator;
  String? extraText;
  late String restaurantId;
  String? createdAt;
  String? updatedAt;
  String? myTicket;
  String? thumbnail;
  Restaurant? restaurant;

  // Campos Gemini extraídos del video
  String? summary;
  String? overallSentiment; // "muy_positivo" | "positivo" | "neutro" | "negativo"
  String? instagram;
  int? durationSeconds;
  List<VisitDish> dishes;
  List<String> highlights;
  List<String> lowlights;
  List<String> services;

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
    this.summary,
    this.overallSentiment,
    this.instagram,
    this.durationSeconds,
    List<VisitDish>? dishes,
    List<String>? highlights,
    List<String>? lowlights,
    List<String>? services,
  })  : dishes = dishes ?? [],
        highlights = highlights ?? [],
        lowlights = lowlights ?? [],
        services = services ?? [];

  factory Visit.fromJson(Map<String, dynamic> json) {
    List<VisitDish> parseDishes(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return raw.map((d) => VisitDish.fromJson(d)).toList();
      return [];
    }

    List<String> parseStrings(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return [];
    }

    return Visit(
      id: json['id'],
      videoUrl: json['videoUrl'] ?? json['video_url'],
      creator: json['creator'],
      extraText: json['extraText'] ?? json['extra_text'],
      restaurantId: json['restaurantId'] ?? json['restaurant_id'] ?? '',
      createdAt: json['createdAt'] ?? json['created_at'],
      updatedAt: json['updatedAt'] ?? json['updated_at'],
      myTicket: json['myTicket'] ?? json['my_ticket'],
      thumbnail: json['thumbnail'],
      restaurant: json['restaurant'] != null
          ? Restaurant.fromJson(json['restaurant'])
          : null,
      summary: json['summary'],
      overallSentiment: json['overallSentiment'] ?? json['overall_sentiment'],
      instagram: json['instagram'],
      durationSeconds: json['durationSeconds'] ?? json['duration_seconds'],
      dishes: parseDishes(json['dishes']),
      highlights: parseStrings(json['highlights']),
      lowlights: parseStrings(json['lowlights']),
      services: parseStrings(json['services']),
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
      'myTicket': myTicket,
      'thumbnail': thumbnail,
    };
  }
}
