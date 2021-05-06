

import 'package:guachinches/model/Category.dart';
import 'package:guachinches/model/Municipality.dart';
import 'package:guachinches/model/restaurant.dart';
import 'package:guachinches/model/user_info.dart';

abstract class RemoteRepository{
  Future<List<Category>> getAllCategories();
  Future<List<Restaurant>> getAllRestaurants();
  Future<List<Municipality>> getAllMunicipalities();
  Future<UserInfo> getUserInfo(String userId);
  Future<bool> updateReview(String userId, String reviewId, String title,String rating, String review);
  Future<bool> saveReview(String userId, Restaurant restaurant ,String title, String review, String rating);
  Future<String> loginUser(String login, String password);
}
