import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/model/zone.dart';

sealed class ZonesState {}

class ZonesInitial extends ZonesState {}

class ZonesLoading extends ZonesState {}

class ZonesLoaded extends ZonesState {
  final List<Zone> zones;
  ZonesLoaded(this.zones);
}

class ZonesFailure extends ZonesState {
  final String message;
  ZonesFailure(this.message);
}

class ZonesCubit extends Cubit<ZonesState> {
  final RemoteRepository _repo;

  ZonesCubit(this._repo) : super(ZonesInitial());

  Future<void> loadForIsland(String islandId) async {
    emit(ZonesLoading());
    try {
      final zones = await _repo.getZonesByIsland(islandId);
      emit(ZonesLoaded(zones));
    } catch (e) {
      emit(ZonesFailure(e.toString()));
    }
  }
}
