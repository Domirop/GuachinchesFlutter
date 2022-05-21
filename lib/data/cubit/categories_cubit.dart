import 'package:bloc/bloc.dart';

import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/categories_state.dart';
import 'package:guachinches/data/model/Category.dart';

class CategoriesCubit extends Cubit<CategoriesState> {
  final RemoteRepository _remoteRepository;
  ModelCategory _category;

  CategoriesCubit(this._remoteRepository) : super(CategoriesInitial());

  Future<void> getCategories() async {
    List<ModelCategory> categories = await _remoteRepository.getAllCategories();
    emit(CategoriesLoaded(categories));
  }
}
