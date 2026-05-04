import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/model/weather_data.dart';
import 'package:guachinches/services/weather_service.dart';

/// Implementación HTTP del WeatherService — delega en RemoteRepository.
/// El backend cachea 30 min, no añadimos cache adicional en cliente.
class HttpWeatherService implements WeatherService {
  final RemoteRepository _repo;

  HttpWeatherService(this._repo);

  @override
  Future<WeatherData> forIsland(String islandId) async {
    try {
      return await _repo.getWeatherForIsland(islandId);
    } catch (_) {
      return const WeatherData.unknown();
    }
  }

  @override
  Future<WeatherData> forMunicipality(String municipalityId) async {
    try {
      return await _repo.getWeatherForMunicipality(municipalityId);
    } catch (_) {
      return const WeatherData.unknown();
    }
  }

  @override
  Future<WeatherData> forZone(String zoneId) async {
    try {
      return await _repo.getWeatherForZone(zoneId);
    } catch (_) {
      return const WeatherData.unknown();
    }
  }
}
