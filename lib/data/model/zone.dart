/// Representa una zona geográfica dentro de una isla.
class Zone {
  final String? id;
  final String key;
  final String label;
  final String emoji;
  final String? assetImage;
  final String? imageUrl;
  final String islandId;
  final double centerLat;
  final double centerLng;
  final int position;
  final bool enabled;

  const Zone({
    this.id,
    required this.key,
    required this.label,
    required this.emoji,
    required this.islandId,
    required this.centerLat,
    required this.centerLng,
    this.assetImage,
    this.imageUrl,
    this.position = 0,
    this.enabled = true,
  });

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      id: json['id'] as String?,
      key: (json['key'] ?? '') as String,
      label: (json['label'] ?? '') as String,
      emoji: (json['emoji'] ?? '') as String,
      islandId: (json['islandId'] ?? '') as String,
      centerLat: (json['centerLat'] as num?)?.toDouble() ?? 0,
      centerLng: (json['centerLng'] as num?)?.toDouble() ?? 0,
      imageUrl: json['imageUrl'] as String?,
      position: (json['position'] as num?)?.toInt() ?? 0,
      enabled: (json['enabled'] as bool?) ?? true,
    );
  }
}
