class WeatherZoneWeather {
  final double? tempC;
  final String condition;
  final String emoji;
  final String updatedAt;
  final String source;
  final String? sourceId;

  const WeatherZoneWeather({
    required this.tempC,
    required this.condition,
    required this.emoji,
    required this.updatedAt,
    required this.source,
    this.sourceId,
  });

  factory WeatherZoneWeather.fromJson(Map<String, dynamic> json) {
    final tempRaw = json['tempC'];
    return WeatherZoneWeather(
      tempC: tempRaw is num ? tempRaw.toDouble() : null,
      condition: (json['condition'] ?? 'unknown') as String,
      emoji: (json['emoji'] ?? '—') as String,
      updatedAt: (json['updatedAt'] ?? '') as String,
      source: (json['source'] ?? '') as String,
      sourceId: json['sourceId'] as String?,
    );
  }
}

class WeatherZoneEntry {
  final String id;
  final String key;
  final String label;
  final WeatherZoneWeather weather;

  const WeatherZoneEntry({
    required this.id,
    required this.key,
    required this.label,
    required this.weather,
  });

  factory WeatherZoneEntry.fromJson(Map<String, dynamic> json) {
    return WeatherZoneEntry(
      id: (json['id'] ?? '') as String,
      key: (json['key'] ?? '') as String,
      label: (json['label'] ?? '') as String,
      weather: WeatherZoneWeather.fromJson(
        json['weather'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class WeatherZoneBundle {
  final String islandId;
  final String generatedAt;
  final List<WeatherZoneEntry> zones;

  const WeatherZoneBundle({
    required this.islandId,
    required this.generatedAt,
    required this.zones,
  });

  factory WeatherZoneBundle.fromJson(Map<String, dynamic> json) {
    final rawZones = json['zones'] as List<dynamic>? ?? [];
    return WeatherZoneBundle(
      islandId: (json['islandId'] ?? '') as String,
      generatedAt: (json['generatedAt'] ?? '') as String,
      zones: rawZones
          .whereType<Map<String, dynamic>>()
          .map(WeatherZoneEntry.fromJson)
          .toList(),
    );
  }
}
