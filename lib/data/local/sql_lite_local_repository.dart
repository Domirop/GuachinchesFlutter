import 'package:guachinches/data/local/db_provider.dart';
import 'package:guachinches/data/local/restaurant_sql_lite.dart';

import 'local_repository.dart';

class SqlLiteLocalRepository implements LocalRepository {


  @override
  Future<List<RestaurantSQLLite>> getRestaurants() async {
    final db = await DBProvider.db.database;
    var res = await db.rawQuery("select * from fav");
    List<RestaurantSQLLite> restaurants = [];
    if(res.isNotEmpty){
      res.forEach((element) {
        RestaurantSQLLite restaurantSQLLite = RestaurantSQLLite.fromMap(element);
        restaurants.add(restaurantSQLLite);
      });
      return restaurants;
    }else{
      return [];
    }
  }

  @override
  Future<RestaurantSQLLite> getRestaurant(String restaurantId) async {
    final db = await DBProvider.db.database;
    String query = "select * from fav where restaurantId='" + restaurantId + "'";
    var res = await db.rawQuery(query);
    if(res.isEmpty) return null;
    else return RestaurantSQLLite.fromMap(res[0]);
  }

  @override
  Future<bool> insertRestaurant(String restaurantId) async {
    try {
      final db = await DBProvider.db.database;
      var res = await db.rawInsert("INSERT Into fav (restaurantId)"
          " VALUES ('" + restaurantId + "')");
      return true;
    } on Exception catch (e) {
      return false;
    }
  }

  @override
  Future<bool> removeRestaurant(String restaurantId) async {
    try {
      final db = await DBProvider.db.database;
      var res = await db.rawInsert("DELETE FROM fav where restaurantId='" + restaurantId + "'");
      return false;
    } on Exception catch (e) {
      return true;
    }
  }
}