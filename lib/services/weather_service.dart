import 'package:guachinches/data/model/weather_data.dart';

/// Contrato del servicio de clima.
abstract class WeatherService {
  Future<WeatherData> forMunicipality(String municipalityId);
  Future<WeatherData> forIsland(String islandId);
  Future<WeatherData> forZone(String zoneId);
}

/// Stub: no hace llamadas de red. Útil en tests/desarrollo offline.
class StubWeatherService implements WeatherService {
  const StubWeatherService();

  @override
  Future<WeatherData> forMunicipality(String municipalityId) async =>
      const WeatherData.unknown();

  @override
  Future<WeatherData> forIsland(String islandId) async =>
      const WeatherData.unknown();

  @override
  Future<WeatherData> forZone(String zoneId) async =>
      const WeatherData.unknown();
}
