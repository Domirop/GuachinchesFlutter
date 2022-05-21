import 'package:guachinches/data/model/Category.dart';
import 'package:flutter/foundation.dart';

@immutable
abstract class CategoriesState {
  const CategoriesState();

}

class CategoriesInitial extends CategoriesState {
  const CategoriesInitial();
}

class CategoriesLoaded extends CategoriesState {
  final List<ModelCategory> categories;
  const CategoriesLoaded(this.categories);

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is CategoriesLoaded && o.categories == categories;
  }

  @override
  int get hashCode => categories.hashCode;
}
