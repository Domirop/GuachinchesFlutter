import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/core/logging/app_logger.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/model/Visit.dart';

abstract class VisitsState {}

class VisitsInitial extends VisitsState {}

class VisitsLoading extends VisitsState {}

class VisitsLoaded extends VisitsState {
  final List<Visit> visits;
  VisitsLoaded(this.visits);
}

class VisitsFailure extends VisitsState {}

class VisitsCubit extends Cubit<VisitsState> {
  final RemoteRepository _repo;

  VisitsCubit(this._repo) : super(VisitsInitial());

  Future<void> loadVisits() async {
    AppLogger.info('visits-cubit', 'loadVisits() start');
    emit(VisitsLoading());
    try {
      final visits = await _repo.getAllVisits();
      AppLogger.info(
        'visits-cubit',
        'loadVisits() OK — count=${visits.length}',
      );
      emit(VisitsLoaded(visits));
    } catch (e, st) {
      // Antes era `catch (_)` silencioso que dejaba al usuario con un
      // mensaje "No hemos podido cargar las visitas" sin pista alguna.
      // Ahora elevamos a Crashlytics + log para diagnosticar.
      AppLogger.error('visits-cubit', e, st);
      emit(VisitsFailure());
    }
  }
}
