import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/model/weather_zone_bundle.dart';

void main() {
  const _tenerife = {
    'islandId': 'tenerife',
    'generatedAt': '2026-05-23T12:00:00Z',
    'zones': [
      {
        'id': 'zone-norte',
        'key': 'norte',
        'label': 'Norte',
        'weather': {
          'tempC': 18.5,
          'condition': 'cloudy',
          'emoji': '☁️',
          'updatedAt': '2026-05-23T11:55:00Z',
          'source': 'aemet',
          'sourceId': 'aemet-001',
        },
      },
      {
        'id': 'zone-sur',
        'key': 'sur',
        'label': 'Sur',
        'weather': {
          'tempC': 24.0,
          'condition': 'sunny',
          'emoji': '☀️',
          'updatedAt': '2026-05-23T11:55:00Z',
          'source': 'aemet',
          'sourceId': null,
        },
      },
      {
        'id': 'zone-metro',
        'key': 'metro',
        'label': 'Área metropolitana',
        'weather': {
          'tempC': null,
          'condition': 'unknown',
          'emoji': '—',
          'updatedAt': '2026-05-23T11:55:00Z',
          'source': 'manual',
          'sourceId': null,
        },
      },
    ],
  };

  group('WeatherZoneBundle.fromJson', () {
    test('parses islandId and generatedAt', () {
      final bundle = WeatherZoneBundle.fromJson(_tenerife);
      expect(bundle.islandId, 'tenerife');
      expect(bundle.generatedAt, '2026-05-23T12:00:00Z');
    });

    test('parses 3 zones from Tenerife JSON', () {
      final bundle = WeatherZoneBundle.fromJson(_tenerife);
      expect(bundle.zones.length, 3);
    });

    test('parses zone fields (id, key, label)', () {
      final zone = WeatherZoneBundle.fromJson(_tenerife).zones.first;
      expect(zone.id, 'zone-norte');
      expect(zone.key, 'norte');
      expect(zone.label, 'Norte');
    });

    test('parses weather fields (tempC, condition, emoji)', () {
      final weather = WeatherZoneBundle.fromJson(_tenerife).zones.first.weather;
      expect(weather.tempC, 18.5);
      expect(weather.condition, 'cloudy');
      expect(weather.emoji, '☁️');
    });

    test('tolerates tempC null without throwing', () {
      final bundle = WeatherZoneBundle.fromJson(_tenerife);
      final metroWeather = bundle.zones[2].weather;
      expect(metroWeather.tempC, isNull);
      expect(metroWeather.condition, 'unknown');
    });

    test('tolerates sourceId null without throwing', () {
      final bundle = WeatherZoneBundle.fromJson(_tenerife);
      expect(bundle.zones[1].weather.sourceId, isNull);
      expect(bundle.zones[2].weather.sourceId, isNull);
    });

    test('byZoneId map can be built from bundle.zones', () {
      final bundle = WeatherZoneBundle.fromJson(_tenerife);
      final byZoneId = {
        for (final e in bundle.zones) e.id: e.weather,
      };
      expect(byZoneId['zone-norte']!.tempC, 18.5);
      expect(byZoneId['zone-sur']!.tempC, 24.0);
      expect(byZoneId['zone-metro']!.tempC, isNull);
    });
  });
}
