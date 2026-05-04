import 'package:flutter_bloc/flutter_bloc.dart';
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
    emit(VisitsLoading());
    try {
      final visits = await _repo.getAllVisits();
      emit(VisitsLoaded(visits));
    } catch (_) {
      emit(VisitsFailure());
    }
  }
}
