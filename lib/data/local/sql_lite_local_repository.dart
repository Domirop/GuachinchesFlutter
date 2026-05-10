import 'package:guachinches/data/local/db_provider.dart';
import 'package:guachinches/data/local/restaurant_sql_lite.dart';

import 'local_repository.dart';

class SqlLiteLocalRepository implements LocalRepository {
  @override
  Future<List<RestaurantSQLLite>> getRestaurants() async {
    final db = await DBProvider.db.database;
    final res = await db.rawQuery("SELECT * FROM fav");
    if (res.isEmpty) return [];
    return res.map(RestaurantSQLLite.fromMap).toList();
  }

  @override
  Future<RestaurantSQLLite?> getRestaurant(String restaurantId) async {
    final db = await DBProvider.db.database;
    final res = await db.rawQuery(
      "SELECT * FROM fav WHERE restaurantId = ? LIMIT 1",
      [restaurantId],
    );
    if (res.isEmpty) return null;
    return RestaurantSQLLite.fromMap(res.first);
  }

  @override
  Future<bool> isFavorite(String restaurantId) async {
    final db = await DBProvider.db.database;
    final res = await db.rawQuery(
      "SELECT 1 FROM fav WHERE restaurantId = ? LIMIT 1",
      [restaurantId],
    );
    return res.isNotEmpty;
  }

  @override
  Future<bool> insertRestaurant(String restaurantId) async {
    try {
      final db = await DBProvider.db.database;
      await db.rawInsert(
        "INSERT INTO fav (restaurantId) VALUES (?)",
        [restaurantId],
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> removeRestaurant(String restaurantId) async {
    try {
      final db = await DBProvider.db.database;
      await db.rawDelete(
        "DELETE FROM fav WHERE restaurantId = ?",
        [restaurantId],
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
