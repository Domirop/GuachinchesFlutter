import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/model/curated_list.dart';

sealed class CuratedListsState {}

class CuratedListsInitial extends CuratedListsState {}

class CuratedListsLoading extends CuratedListsState {}

class CuratedListsLoaded extends CuratedListsState {
  final List<CuratedList> lists;
  CuratedListsLoaded(this.lists);
}

class CuratedListsFailure extends CuratedListsState {
  final String message;
  CuratedListsFailure(this.message);
}

class CuratedListsCubit extends Cubit<CuratedListsState> {
  final RemoteRepository _repo;

  CuratedListsCubit(this._repo) : super(CuratedListsInitial());

  Future<void> loadForIsland(String? islandId) async {
    emit(CuratedListsLoading());
    try {
      final lists = await _repo.getCuratedLists(islandId: islandId);
      emit(CuratedListsLoaded(lists));
    } catch (e) {
      emit(CuratedListsFailure(e.toString()));
    }
  }

  /// Reload without flashing a loading skeleton. If there is already a loaded
  /// state, it stays visible while the fetch runs. Only falls back to
  /// CuratedListsFailure if there was no previous data.
  Future<void> refresh(String? islandId) async {
    final previous = state;
    try {
      final lists = await _repo.getCuratedLists(islandId: islandId);
      emit(CuratedListsLoaded(lists));
    } catch (e) {
      if (previous is! CuratedListsLoaded) {
        emit(CuratedListsFailure(e.toString()));
      }
    }
  }
}
