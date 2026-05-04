class WeatherData {
  final double? tempC;
  final String condition; // 'sunny' | 'cloudy' | 'rain' | 'fog' | 'storm' | 'unknown'
  final String emoji;

  const WeatherData({
    required this.tempC,
    required this.condition,
    required this.emoji,
  });

  const WeatherData.unknown()
      : tempC = null,
        condition = 'unknown',
        emoji = '—';

  String get displayTemp => tempC != null ? '${tempC!.round()}°' : '—°';
  String get displayFull => tempC != null ? '${emoji} ${tempC!.round()}°' : '—';

  bool get isAvailable => tempC != null;
}
