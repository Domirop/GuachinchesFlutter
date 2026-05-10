import 'dart:convert';

import 'package:http/http.dart' as http;

/// Condición meteorológica simplificada que usa la UI para decidir
/// qué overlays renderizar (nubes/lluvia/etc.).
enum WeatherCondition {
  unknown,
  clear,         // soleado / despejado
  mostlyClear,   // mayormente despejado
  partlyCloudy,  // parcialmente nuboso
  cloudy,        // nublado / cubierto
  fog,
  drizzle,
  rain,
  heavyRain,
  thunderstorm,
  snow,
}

extension WeatherConditionVisuals on WeatherCondition {
  bool get hasClouds => switch (this) {
        WeatherCondition.mostlyClear ||
        WeatherCondition.partlyCloudy ||
        WeatherCondition.cloudy ||
        WeatherCondition.fog ||
        WeatherCondition.drizzle ||
        WeatherCondition.rain ||
        WeatherCondition.heavyRain ||
        WeatherCondition.thunderstorm ||
        WeatherCondition.snow =>
          true,
        _ => false,
      };

  /// Densidad relativa de nubes (0..1).
  double get cloudIntensity => switch (this) {
        WeatherCondition.mostlyClear => 0.15,
        WeatherCondition.partlyCloudy => 0.25,
        WeatherCondition.cloudy => 0.40,
        WeatherCondition.fog => 0.50,
        WeatherCondition.drizzle => 0.32,
        WeatherCondition.rain => 0.40,
        WeatherCondition.heavyRain => 0.50,
        WeatherCondition.thunderstorm => 0.55,
        WeatherCondition.snow => 0.38,
        _ => 0.0,
      };

  bool get hasRain => switch (this) {
        WeatherCondition.drizzle ||
        WeatherCondition.rain ||
        WeatherCondition.heavyRain ||
        WeatherCondition.thunderstorm =>
          true,
        _ => false,
      };

  /// Cantidad de gotas en pantalla (densidad).
  int get rainDensity => switch (this) {
        WeatherCondition.drizzle => 30,
        WeatherCondition.rain => 80,
        WeatherCondition.heavyRain => 140,
        WeatherCondition.thunderstorm => 180,
        _ => 0,
      };

  double get rainTilt => switch (this) {
        WeatherCondition.thunderstorm => 0.30,
        WeatherCondition.heavyRain => 0.24,
        _ => 0.16,
      };
}

/// Wrapper sobre Open-Meteo (gratis, sin API key) que devuelve la condición
/// meteorológica actual para una coordenada. Cachea la última respuesta
/// durante 15 minutos para evitar llamadas repetidas en hot reloads.
class WeatherService {
  WeatherService._();
  static final WeatherService instance = WeatherService._();

  final Map<String, _CacheEntry> _cache = {};
  static const Duration _ttl = Duration(minutes: 15);

  Future<WeatherCondition> currentCondition({
    required double lat,
    required double lon,
  }) async {
    final key = '${lat.toStringAsFixed(2)},${lon.toStringAsFixed(2)}';
    final cached = _cache[key];
    if (cached != null && DateTime.now().difference(cached.at) < _ttl) {
      return cached.condition;
    }

    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat&longitude=$lon&current=weather_code'
      '&timezone=auto',
    );
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return WeatherCondition.unknown;
      final body = json.decode(res.body) as Map<String, dynamic>;
      final code = (body['current'] as Map<String, dynamic>?)?['weather_code'];
      if (code is! num) return WeatherCondition.unknown;
      final condition = _mapCode(code.toInt());
      _cache[key] = _CacheEntry(condition, DateTime.now());
      return condition;
    } catch (_) {
      return WeatherCondition.unknown;
    }
  }

  /// WMO weather codes → simplified enum.
  /// Ref: https://open-meteo.com/en/docs (sección "weather_code").
  static WeatherCondition _mapCode(int code) {
    switch (code) {
      case 0:
        return WeatherCondition.clear;
      case 1:
        return WeatherCondition.mostlyClear;
      case 2:
        return WeatherCondition.partlyCloudy;
      case 3:
        return WeatherCondition.cloudy;
      case 45:
      case 48:
        return WeatherCondition.fog;
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return WeatherCondition.drizzle;
      case 61:
      case 63:
      case 80:
      case 81:
        return WeatherCondition.rain;
      case 65:
      case 66:
      case 67:
      case 82:
        return WeatherCondition.heavyRain;
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return WeatherCondition.snow;
      case 95:
      case 96:
      case 99:
        return WeatherCondition.thunderstorm;
      default:
        return WeatherCondition.unknown;
    }
  }
}

class _CacheEntry {
  final WeatherCondition condition;
  final DateTime at;
  const _CacheEntry(this.condition, this.at);
}
