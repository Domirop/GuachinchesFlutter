import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/data/model/Municipality.dart';
import 'package:guachinches/data/model/fotoBanner.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/data/model/user_info.dart';

abstract class RemoteRepository{
  Future<List<ModelCategory>> getAllCategories();
  Future<List<Restaurant>> getAllRestaurants();
  Future<List<Municipality>> getAllMunicipalities();
  Future<UserInfo> getUserInfo(String userId);
  Future<bool> updateReview(String userId, String reviewId, String title,String rating, String review);
  Future<bool> saveReview(String userId, Restaurant restaurant ,String title, String review, String rating);
  Future<dynamic> loginUser(String login, String password);
  Future<List<FotoBanner>> getGlobalImages();
  Future<bool> registerUser(Map data);
}
