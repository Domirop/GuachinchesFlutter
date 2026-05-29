import 'package:flutter_test/flutter_test.dart';
import 'package:guachinches/data/cubit/new_home/zone_weather_cubit.dart';
import 'package:guachinches/data/model/weather_data.dart';
import 'package:guachinches/data/model/weather_zone_bundle.dart';
import 'package:guachinches/services/weather_service.dart';

class _FakeWeatherService implements WeatherService {
  final WeatherZoneBundle bundle;
  _FakeWeatherService(this.bundle);

  @override
  Future<WeatherZoneBundle> bundleForIsland(String islandId) async => bundle;

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

WeatherZoneBundle _makeBundle() {
  WeatherZoneWeather _w(double temp) => WeatherZoneWeather(
        tempC: temp,
        condition: 'sunny',
        emoji: '☀️',
        updatedAt: '2026-05-23T00:00:00Z',
        source: 'aemet',
        sourceId: null,
      );

  return WeatherZoneBundle(
    islandId: 'isl-1',
    generatedAt: '2026-05-23T00:00:00Z',
    zones: [
      WeatherZoneEntry(id: 'zone-a', key: 'norte', label: 'Norte', weather: _w(18.0)),
      WeatherZoneEntry(id: 'zone-b', key: 'sur', label: 'Sur', weather: _w(22.0)),
      WeatherZoneEntry(id: 'zone-c', key: 'este', label: 'Este', weather: _w(26.0)),
    ],
  );
}

void main() {
  group('ZoneWeatherCubit.loadForIsland', () {
    test('builds byZoneId with 3 distinct tempC values', () async {
      final cubit = ZoneWeatherCubit(_FakeWeatherService(_makeBundle()));

      await cubit.loadForIsland('isl-1');

      final byZoneId = cubit.state.byZoneId;
      expect(byZoneId.length, 3);
      expect(byZoneId['zone-a']!.tempC, 18.0);
      expect(byZoneId['zone-b']!.tempC, 22.0);
      expect(byZoneId['zone-c']!.tempC, 26.0);
    });
  });
}
