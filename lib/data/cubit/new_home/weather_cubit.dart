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
    try {
      final data = await _service.forIsland(islandId);
      emit(WeatherLoaded(data));
    } catch (_) {
      emit(WeatherLoaded(const WeatherData.unknown()));
    }
  }

  Future<void> loadForMunicipality(String municipalityId) async {
    try {
      final data = await _service.forMunicipality(municipalityId);
      emit(WeatherLoaded(data));
    } catch (_) {
      emit(WeatherLoaded(const WeatherData.unknown()));
    }
  }

  Future<void> loadForZone(String zoneId) async {
    try {
      final data = await _service.forZone(zoneId);
      emit(WeatherLoaded(data));
    } catch (_) {
      emit(WeatherLoaded(const WeatherData.unknown()));
    }
  }
}
