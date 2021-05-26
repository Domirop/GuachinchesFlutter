import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guachinches/data/RemoteRepository.dart';
import 'package:guachinches/data/cubit/categories_cubit.dart';
import 'package:guachinches/model/Category.dart';

class CategoriasPresenter{
  final RemoteRepository _remoteRepository;
  final CategoriasView _view;
  CategoriesCubit _categoriesCubit;

  final storage = new FlutterSecureStorage();

  CategoriasPresenter(this._remoteRepository, this._view, this._categoriesCubit);

  getAllCategories() async {
    await _categoriesCubit.getCategories();
  }

}
abstract class CategoriasView{
  setAllCategories(List<ModelCategory> categories);
}
