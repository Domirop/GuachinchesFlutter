import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:guachinches/data/cubit/categorias/categories_cubit.dart';

class CategoriasPresenter{
  final CategoriasView _view;
  // CategoriesCubit _categoriesCubit;

  final storage = new FlutterSecureStorage();

  // CategoriasPresenter(this._view, this._categoriesCubit);
  CategoriasPresenter(this._view);

  getAllCategories() async {
    // await _categoriesCubit.getCategories();
  }

  setCategoryToSelect(String id ) async {
    await storage.write(key: "category", value: id);
    _view.categorySelected();
  }

}
abstract class CategoriasView{
  categorySelected();
}
