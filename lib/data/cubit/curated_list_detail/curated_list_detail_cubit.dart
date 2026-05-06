import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/model/curated_list.dart';

sealed class CuratedListDetailState {}

class CuratedListDetailInitial extends CuratedListDetailState {}

class CuratedListDetailLoading extends CuratedListDetailState {}

class CuratedListDetailLoaded extends CuratedListDetailState {
  final CuratedListDetail detail;
  CuratedListDetailLoaded(this.detail);
}

class CuratedListDetailFailure extends CuratedListDetailState {
  final String message;
  CuratedListDetailFailure(this.message);
}

class CuratedListDetailCubit extends Cubit<CuratedListDetailState> {
  final RemoteRepository _repo;

  CuratedListDetailCubit(this._repo) : super(CuratedListDetailInitial());

  Future<void> load(String id) async {
    emit(CuratedListDetailLoading());
    try {
      final detail = await _repo.getCuratedListById(id);
      emit(CuratedListDetailLoaded(detail));
    } catch (e) {
      emit(CuratedListDetailFailure(e.toString()));
    }
  }
}
