

import 'package:guachinches/model/Category.dart';
import 'package:guachinches/model/restaurant.dart';

abstract class RemoteRepository{
  Future<List<Category>> getAllCategories();

  Future<List<Restaurant>> getAllRestaurants();

}