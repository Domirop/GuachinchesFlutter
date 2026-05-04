import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/model/Island.dart';

sealed class IslandsState {}

class IslandsInitial extends IslandsState {}

class IslandsLoading extends IslandsState {}

class IslandsLoaded extends IslandsState {
  final List<Island> islands;
  IslandsLoaded(this.islands);
}

class IslandsFailure extends IslandsState {
  final String message;
  IslandsFailure(this.message);
}

class IslandsCubit extends Cubit<IslandsState> {
  final RemoteRepository _repo;

  IslandsCubit(this._repo) : super(IslandsInitial());

  Future<void> load() async {
    print('[IslandsCubit] load() start');
    emit(IslandsLoading());
    try {
      final list = await _repo.getIslands();
      print('[IslandsCubit] loaded ${list.length} islas');
      emit(IslandsLoaded(list));
    } catch (e, st) {
      print('[IslandsCubit] FAIL: $e\n$st');
      emit(IslandsFailure(e.toString()));
    }
  }
}
