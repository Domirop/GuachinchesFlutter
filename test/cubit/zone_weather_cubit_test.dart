import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/cubit/new_home/zone_weather_cubit.dart';
import 'package:guachinches/data/model/weather_data.dart';
import 'package:guachinches/data/model/weather_zone_bundle.dart';
import 'package:guachinches/services/weather_service.dart';

class _CountingWeatherService implements WeatherService {
  int bundleCallCount = 0;
  final WeatherZoneBundle bundle;

  _CountingWeatherService(this.bundle);

  @override
  Future<WeatherZoneBundle> bundleForIsland(String islandId) async {
    bundleCallCount++;
    return bundle;
  }

  @override
  Future<WeatherData> forIsland(String islandId) async =>
      const WeatherData.unknown();

  @override
  Future<WeatherData> forMunicipality(String municipalityId) async =>
      const WeatherData.unknown();

  @override
  Future<WeatherData> forZone(String zoneId) async =>
      const WeatherData.unknown();
}

WeatherZoneBundle _stubBundle() {
  WeatherZoneWeather _w(double temp) => WeatherZoneWeather(
        tempC: temp,
        condition: 'sunny',
        emoji: '☀️',
        updatedAt: '2026-05-23T00:00:00Z',
        source: 'aemet',
        sourceId: null,
      );

  return WeatherZoneBundle(
    islandId: 'island-1',
    generatedAt: '2026-05-23T00:00:00Z',
    zones: [
      WeatherZoneEntry(id: 'zone-a', key: 'norte', label: 'Norte', weather: _w(18.0)),
      WeatherZoneEntry(id: 'zone-b', key: 'sur', label: 'Sur', weather: _w(22.0)),
    ],
  );
}

void main() {
  group('ZoneWeatherCubit.loadForIsland', () {
    test('calls bundleForIsland exactly once', () async {
      final service = _CountingWeatherService(_stubBundle());
      final cubit = ZoneWeatherCubit(service);

      await cubit.loadForIsland('island-1');

      expect(service.bundleCallCount, 1);
    });

    test('maps each bundle zone to byZoneId with correct tempC', () async {
      final service = _CountingWeatherService(_stubBundle());
      final cubit = ZoneWeatherCubit(service);

      await cubit.loadForIsland('island-1');

      final byZoneId = cubit.state.byZoneId;
      expect(byZoneId.length, 2);
      expect(byZoneId['zone-a']!.tempC, 18.0);
      expect(byZoneId['zone-b']!.tempC, 22.0);
    });
  });
}
