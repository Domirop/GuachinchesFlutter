
import 'package:guachinches/data/local/restaurant_sql_lite.dart';

abstract class LocalRepository{
  Future<bool> insertRestaurant(String restaurantId);
  Future<RestaurantSQLLite> getRestaurant(String restaurantId);
  Future<bool> removeRestaurant(String restaurantId);
  Future<List<RestaurantSQLLite>> getRestaurants();
}