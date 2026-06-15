import 'package:guachinches/data/model/restaurant.dart';

class VisitDish {
  final String name;
  final String? description;
  final num? price;
  final String? sentiment; // "loved" | "liked" | "neutral" | "disliked" …
  final bool isTop;

  /// Foto del plato extraída automáticamente del vídeo (backend migrations
  /// 031 DishPhotoService + 032 picker platocéntrico). JPEG vertical 9:16
  /// servido por CDN público de Scaleway. Puede llegar como `string`, `null`,
  /// o estar **ausente** del JSON: los tres casos = "sin foto".
  final String? photoUrl;

  const VisitDish({
    required this.name,
    this.description,
    this.price,
    this.sentiment,
    this.isTop = false,
    this.photoUrl,
  });

  factory VisitDish.fromJson(dynamic json) {
    if (json is String) return VisitDish(name: json);
    final map = json as Map<String, dynamic>;
    final sentiment = map['sentiment']?.toString().toLowerCase();
    final isTop = map['isTop'] == true ||
        map['is_top'] == true ||
        map['top'] == true ||
        sentiment == 'loved';
    // Tolera camelCase/snake_case, null, ausente y string vacío.
    final photoRaw = (map['photoUrl'] ?? map['photo_url'])?.toString();
    return VisitDish(
      name: map['name']?.toString() ?? map['dish']?.toString() ?? '',
      description: map['description']?.toString(),
      price: map['price'] is num ? map['price'] as num : num.tryParse('${map['price']}'),
      sentiment: sentiment,
      isTop: isTop,
      photoUrl: (photoRaw != null && photoRaw.isNotEmpty) ? photoRaw : null,
    );
  }
}

class VisitQuote {
  final String text;
  final String? sentiment;
  final String? timestamp;

  const VisitQuote({required this.text, this.sentiment, this.timestamp});

  factory VisitQuote.fromJson(dynamic json) {
    if (json is String) return VisitQuote(text: json);
    final map = json as Map<String, dynamic>;
    final text = (map['text'] ??
            map['quote'] ??
            map['content'] ??
            map['phrase'] ??
            '')
        .toString();
    return VisitQuote(
      text: text,
      sentiment: map['sentiment']?.toString(),
      timestamp: (map['timestamp'] ?? map['time'])?.toString(),
    );
  }
}

class Visit {
  late String id;
  String? videoUrl;
  String? youtubeVideoId;

  /// URL del mp4 self-host en S3 (backend migration 033). Si no es null, se
  /// reproduce in-app vertical (TikTok) en vez del embed de YouTube.
  String? videoFileUrl;

  /// Códec de vídeo del mp4 self-host (`youtubeVideo.videoFile.videoCodec`,
  /// backend migration 035). iOS (AVPlayer) NO decodifica AV1/VP9 → frame
  /// negro; solo H.264/HEVC son seguros. Lo usamos para gatear la reproducción
  /// in-app: si el códec no es compatible (o no lo conocemos), caemos a YouTube.
  String? videoCodec;
  String? creator;
  String? extraText;
  late String restaurantId;
  String? createdAt;
  String? updatedAt;
  String? publishedAt;

  /// Fecha de publicación del vídeo en YouTube (`youtubeVideo.publishedAt`).
  /// Es la fecha real del vídeo — distinta de [publishedAt], que es cuándo se
  /// publicó la visita en la app. Se usa para ordenar las visitas.
  String? videoPublishedAt;
  String? myTicket;
  String? thumbnail;
  Restaurant? restaurant;

  // Campos extraídos del video / IA
  String? summary;
  String? overallSentiment; // muy_positivo | positivo | neutro | negativo
  String? instagram;
  int? durationSeconds;
  List<VisitDish> dishes;
  List<String> highlights;
  List<String> lowlights;
  List<String> services;
  List<VisitQuote> quotes;

  // Campos visit-level del nuevo endpoint
  String? name;
  String? address;
  String? zone;
  String? phone;
  String? website;
  String? googleMapsUrl;
  String? openingHours;
  String? priceRange; // p.ej. "$$"
  double? priceApprox; // €
  double? ratingImplicit;

  Visit({
    required this.id,
    this.videoUrl,
    this.youtubeVideoId,
    this.videoFileUrl,
    this.videoCodec,
    this.creator,
    this.extraText,
    required this.restaurantId,
    this.createdAt,
    this.updatedAt,
    this.publishedAt,
    this.videoPublishedAt,
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
    List<VisitQuote>? quotes,
    this.name,
    this.address,
    this.zone,
    this.phone,
    this.website,
    this.googleMapsUrl,
    this.openingHours,
    this.priceRange,
    this.priceApprox,
    this.ratingImplicit,
  })  : dishes = dishes ?? [],
        highlights = highlights ?? [],
        lowlights = lowlights ?? [],
        services = services ?? [],
        quotes = quotes ?? [];

  factory Visit.fromJson(Map<String, dynamic> json) {
    List<VisitDish> parseDishes(dynamic raw) {
      if (raw is List) return raw.map((d) => VisitDish.fromJson(d)).toList();
      return [];
    }

    List<VisitQuote> parseQuotes(dynamic raw) {
      if (raw is List) return raw.map((q) => VisitQuote.fromJson(q)).toList();
      return [];
    }

    List<String> parseStrings(dynamic raw) {
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return [];
    }

    double? parseDouble(dynamic raw) {
      if (raw == null) return null;
      if (raw is num) return raw.toDouble();
      return double.tryParse(raw.toString());
    }

    // youtubeVideo nested (nuevo endpoint).
    // Importante: el "videoId" real de YouTube vive en youtubeVideo.videoId.
    // El campo top-level "youtubeVideoId" es el UUID interno (no sirve para reproducir).
    final yt = json['youtubeVideo'] is Map<String, dynamic>
        ? json['youtubeVideo'] as Map<String, dynamic>
        : null;
    final ytVideoId = (yt?['videoId'] ?? json['videoId'])?.toString();

    // mp4 self-host (backend migration 033): youtubeVideo.videoFile.s3Url, solo
    // si status == 'stored'. Tolera snake_case y un top-level videoFileUrl.
    // Ausente/null/no-stored → null → fallback a YouTube embed.
    String? parseVideoFileUrl() {
      final vf = yt?['videoFile'] ?? yt?['video_file'];
      if (vf is Map) {
        final status = vf['status']?.toString();
        if (status == null || status == 'stored') {
          final u = (vf['s3Url'] ?? vf['s3_url'])?.toString();
          if (u != null && u.isNotEmpty) return u;
        }
      }
      final flat =
          (json['videoFileUrl'] ?? json['video_file_url'])?.toString();
      return (flat != null && flat.isNotEmpty) ? flat : null;
    }

    // Códec del mp4 self-host (backend migration 035). Tolera camelCase/snake.
    String? parseVideoCodec() {
      final vf = yt?['videoFile'] ?? yt?['video_file'];
      if (vf is Map) {
        final c = (vf['videoCodec'] ?? vf['video_codec'] ?? vf['codec'])
            ?.toString();
        if (c != null && c.isNotEmpty) return c.toLowerCase();
      }
      final flat = (json['videoCodec'] ?? json['video_codec'])?.toString();
      return (flat != null && flat.isNotEmpty) ? flat.toLowerCase() : null;
    }

    final videoUrl = json['videoUrl'] ??
        json['video_url'] ??
        (ytVideoId != null && ytVideoId.isNotEmpty
            ? 'https://www.youtube.com/watch?v=$ytVideoId'
            : null);
    final thumbnail = json['thumbnail'] ?? yt?['thumbnailUrl'];
    final durationSeconds = json['durationSeconds'] ??
        json['duration_seconds'] ??
        yt?['durationSeconds'];

    return Visit(
      id: json['id']?.toString() ?? '',
      videoUrl: videoUrl?.toString(),
      youtubeVideoId: ytVideoId,
      videoFileUrl: parseVideoFileUrl(),
      videoCodec: parseVideoCodec(),
      creator: json['creator']?.toString(),
      extraText: (json['extraText'] ?? json['extra_text'])?.toString(),
      restaurantId:
          (json['restaurantId'] ?? json['restaurant_id'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? json['created_at'])?.toString(),
      updatedAt: (json['updatedAt'] ?? json['updated_at'])?.toString(),
      publishedAt: (json['publishedAt'] ?? json['published_at'])?.toString(),
      videoPublishedAt: (yt?['publishedAt'] ??
              json['videoPublishedAt'] ??
              json['video_published_at'])
          ?.toString(),
      myTicket: (json['myTicket'] ?? json['my_ticket'])?.toString(),
      thumbnail: thumbnail?.toString(),
      restaurant: json['restaurant'] is Map<String, dynamic>
          ? Restaurant.fromJson(json['restaurant'])
          : null,
      summary: json['summary']?.toString(),
      overallSentiment: _normalizeSentiment(
          (json['overallSentiment'] ?? json['overall_sentiment'])?.toString()),
      instagram: json['instagram']?.toString(),
      durationSeconds: durationSeconds is int
          ? durationSeconds
          : int.tryParse('${durationSeconds ?? ''}'),
      dishes: parseDishes(json['dishes']),
      highlights: parseStrings(json['highlights']),
      lowlights: parseStrings(json['lowlights']),
      services: parseStrings(json['services']),
      quotes: parseQuotes(json['quotes']),
      name: json['name']?.toString(),
      address: json['address']?.toString(),
      zone: json['zone']?.toString(),
      phone: json['phone']?.toString(),
      website: json['website']?.toString(),
      googleMapsUrl:
          (json['googleMapsUrl'] ?? json['google_maps_url'])?.toString(),
      openingHours:
          (json['openingHours'] ?? json['opening_hours'])?.toString(),
      priceRange: (json['priceRange'] ?? json['price_range'])?.toString(),
      priceApprox: parseDouble(json['priceApprox'] ?? json['price_approx']),
      ratingImplicit:
          parseDouble(json['ratingImplicit'] ?? json['rating_implicit']),
    );
  }

  /// Normaliza "very_positive" → "muy_positivo" para que los widgets existentes
  /// (que esperan los labels antiguos) sigan funcionando.
  static String? _normalizeSentiment(String? raw) {
    if (raw == null) return null;
    final s = raw.toLowerCase();
    switch (s) {
      case 'very_positive':
      case 'very positive':
        return 'muy_positivo';
      case 'positive':
        return 'positivo';
      case 'neutral':
        return 'neutro';
      case 'negative':
        return 'negativo';
      case 'very_negative':
      case 'very negative':
        return 'negativo';
      default:
        return s;
    }
  }

  /// Fecha canónica para ordenar visitas: la del vídeo de YouTube si existe,
  /// si no la de publicación en la app, y como último recurso la de creación.
  String? get sortDate => videoPublishedAt ?? publishedAt ?? createdAt;

  /// Códecs que iOS (AVPlayer) y Android pueden decodificar de forma fiable.
  /// AV1 / VP9 quedan FUERA a propósito: la mayoría de iPhones (y el simulador)
  /// no los decodifican → reproducen audio pero pintan el frame negro.
  static const _iosSafeCodecs = {
    'h264', 'avc', 'avc1', 'hevc', 'h265', 'hvc1',
  };

  /// ¿Podemos reproducir el mp4 self-host in-app sin riesgo de frame negro?
  /// Solo si hay URL y el backend ha confirmado un códec compatible (migration
  /// 035). Si el códec es desconocido o no-compatible (p.ej. los mp4 AV1 que
  /// guarda hoy el backend), devolvemos false → el caller cae a YouTube embed.
  bool get selfHostVideoPlayable {
    final u = videoFileUrl;
    if (u == null || u.trim().isEmpty) return false;
    final c = videoCodec;
    if (c == null) return false; // desconocido → conservador, no arriesgar negro
    return _iosSafeCodecs.contains(c);
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
