import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/data/model/weather_data.dart';
import 'package:guachinches/services/weather_service.dart';

class ZoneWeatherState {
  final Map<String, WeatherData> byZoneId;
  const ZoneWeatherState({this.byZoneId = const {}});
}

class ZoneWeatherCubit extends Cubit<ZoneWeatherState> {
  final WeatherService _service;

  ZoneWeatherCubit(this._service) : super(const ZoneWeatherState());

  Future<void> loadForIsland(String islandId) async {
    emit(const ZoneWeatherState());
    final bundle = await _service.bundleForIsland(islandId);
    final map = <String, WeatherData>{};
    for (final entry in bundle.zones) {
      map[entry.id] = WeatherData(
        tempC: entry.weather.tempC,
        condition: entry.weather.condition,
        emoji: entry.weather.emoji,
      );
    }
    debugPrint('[ZoneWeatherCubit] loaded ${map.length} zones for island $islandId');
    emit(ZoneWeatherState(byZoneId: map));
  }
}
