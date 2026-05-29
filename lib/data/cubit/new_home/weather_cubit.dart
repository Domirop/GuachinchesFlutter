import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/data/model/weather_data.dart';
import 'package:guachinches/services/weather_service.dart';

sealed class WeatherState {}
class WeatherInitial extends WeatherState {}
class WeatherLoaded extends WeatherState {
  final WeatherData data;
  WeatherLoaded(this.data);
}

class WeatherCubit extends Cubit<WeatherState> {
  final WeatherService _service;

  WeatherCubit(this._service) : super(WeatherInitial());

  Future<void> loadForIsland(String islandId) async {
    debugPrint('[WeatherCubit] loadForIsland($islandId)');
    try {
      final data = await _service.forIsland(islandId);
      debugPrint('[WeatherCubit] island → tempC=${data.tempC} cond=${data.condition}');
      emit(WeatherLoaded(data));
    } catch (e) {
      debugPrint('[WeatherCubit] island ERROR: $e');
      emit(WeatherLoaded(const WeatherData.unknown()));
    }
  }

  Future<void> loadForMunicipality(String municipalityId) async {
    debugPrint('[WeatherCubit] loadForMunicipality($municipalityId)');
    try {
      final data = await _service.forMunicipality(municipalityId);
      debugPrint('[WeatherCubit] municipality → tempC=${data.tempC} cond=${data.condition}');
      emit(WeatherLoaded(data));
    } catch (e) {
      debugPrint('[WeatherCubit] municipality ERROR: $e');
      emit(WeatherLoaded(const WeatherData.unknown()));
    }
  }

  Future<void> loadForZone(String zoneId) async {
    debugPrint('[WeatherCubit] loadForZone($zoneId)');
    try {
      final data = await _service.forZone(zoneId);
      debugPrint('[WeatherCubit] zone → tempC=${data.tempC} cond=${data.condition}');
      emit(WeatherLoaded(data));
    } catch (e) {
      debugPrint('[WeatherCubit] zone ERROR: $e');
      emit(WeatherLoaded(const WeatherData.unknown()));
    }
  }
}
