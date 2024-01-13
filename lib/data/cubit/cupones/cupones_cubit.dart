import 'package:bloc/bloc.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/cupones/cupones_state.dart';
import 'package:guachinches/data/model/CuponesAgrupados.dart';
import 'package:guachinches/data/model/restaurant.dart';

class CuponesCubit extends Cubit<CuponesState> {
  late final RemoteRepository _remoteRepository;
  late Restaurant restaurant;

  CuponesCubit(this._remoteRepository) : super(CuponesInitial());

  Future<void> getCuponesHistorias() async {
    List<CuponesAgrupados> cuponesAgrupados = await _remoteRepository.getCuponesHistorias();
    emit(CuponesLoaded(cuponesAgrupados));
  }
}
