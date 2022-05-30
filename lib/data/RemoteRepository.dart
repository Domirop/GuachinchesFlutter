import 'package:guachinches/data/model/Category.dart';
import 'package:guachinches/data/model/CuponesAgrupados.dart';
import 'package:guachinches/data/model/Municipality.dart';
import 'package:guachinches/data/model/TopRestaurants.dart';
import 'package:guachinches/data/model/fotoBanner.dart';
import 'package:guachinches/data/model/restaurant.dart';
import 'package:guachinches/data/model/restaurant_response.dart';
import 'package:guachinches/data/model/user_info.dart';
import 'package:guachinches/data/model/version.dart';

abstract class RemoteRepository{
  Future<List<ModelCategory>> getAllCategories();
  Future<RestaurantResponse> getAllRestaurants(int number);
  Future<List<TopRestaurants>> getTopRestaurants();
  Future<List<Municipality>> getAllMunicipalities();
  Future<UserInfo> getUserInfo(String userId);
  Future<bool> updateReview(String userId, String reviewId, String title,String rating, String review);
  Future<bool> saveReview(String userId, Restaurant restaurant ,String title, String review, String rating);
  Future<dynamic> loginUser(String login, String password);
  Future<List<FotoBanner>> getGlobalImages();
  Future<bool> registerUser(Map data);
  Future<Version> getVersion();
  Future<List<CuponesAgrupados>> getCuponesHistorias();
  Future<bool> saveCupon(String cuponId, String userId);
  Future<Restaurant> getRestaurantById(String id);
}
