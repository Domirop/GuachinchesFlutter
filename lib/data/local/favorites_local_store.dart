import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

abstract class FavoritesLocalStore {
  Future<List<String>> getByUser(String userId);
  Future<void> upsert(
    String userId,
    String restaurantId, {
    required int ts,
    required int syncPending,
  });
  Future<void> delete(String userId, String restaurantId);
  Future<List<Map<String, dynamic>>> getPending(String userId);
  Future<void> markSynced(String userId, String restaurantId);
}

class SqliteFavoritesLocalStore implements FavoritesLocalStore {
  Database? _db;

  Future<Database> _open() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    _db = await openDatabase(
      '${dir.path}/favorites.db',
      version: 1,
      onCreate: (db, _) async {
        await db.execute(
          'CREATE TABLE favorites('
          'user_id TEXT NOT NULL, '
          'restaurant_id TEXT NOT NULL, '
          'ts INTEGER NOT NULL, '
          'sync_pending INTEGER NOT NULL DEFAULT 0, '
          'PRIMARY KEY(user_id, restaurant_id))',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_favorites_pending '
          'ON favorites(sync_pending) WHERE sync_pending=1',
        );
      },
    );
    return _db!;
  }

  @override
  Future<List<String>> getByUser(String userId) async {
    final db = await _open();
    final rows = await db.query(
      'favorites',
      columns: ['restaurant_id'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return rows.map((r) => r['restaurant_id'] as String).toList();
  }

  @override
  Future<void> upsert(
    String userId,
    String restaurantId, {
    required int ts,
    required int syncPending,
  }) async {
    final db = await _open();
    await db.insert(
      'favorites',
      {
        'user_id': userId,
        'restaurant_id': restaurantId,
        'ts': ts,
        'sync_pending': syncPending,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> delete(String userId, String restaurantId) async {
    final db = await _open();
    await db.delete(
      'favorites',
      where: 'user_id = ? AND restaurant_id = ?',
      whereArgs: [userId, restaurantId],
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getPending(String userId) async {
    final db = await _open();
    return db.query(
      'favorites',
      where: 'user_id = ? AND sync_pending = 1',
      whereArgs: [userId],
    );
  }

  @override
  Future<void> markSynced(String userId, String restaurantId) async {
    final db = await _open();
    await db.update(
      'favorites',
      {'sync_pending': 0},
      where: 'user_id = ? AND restaurant_id = ?',
      whereArgs: [userId, restaurantId],
    );
  }
}

class InMemoryFavoritesLocalStore implements FavoritesLocalStore {
  final _rows = <String, Map<String, dynamic>>{};

  String _key(String userId, String restaurantId) => '$userId:$restaurantId';

  @override
  Future<List<String>> getByUser(String userId) async {
    return _rows.values
        .where((r) => r['user_id'] == userId)
        .map((r) => r['restaurant_id'] as String)
        .toList();
  }

  @override
  Future<void> upsert(
    String userId,
    String restaurantId, {
    required int ts,
    required int syncPending,
  }) async {
    _rows[_key(userId, restaurantId)] = {
      'user_id': userId,
      'restaurant_id': restaurantId,
      'ts': ts,
      'sync_pending': syncPending,
    };
  }

  @override
  Future<void> delete(String userId, String restaurantId) async {
    _rows.remove(_key(userId, restaurantId));
  }

  @override
  Future<List<Map<String, dynamic>>> getPending(String userId) async {
    return _rows.values
        .where((r) => r['user_id'] == userId && r['sync_pending'] == 1)
        .toList();
  }

  @override
  Future<void> markSynced(String userId, String restaurantId) async {
    final k = _key(userId, restaurantId);
    if (_rows.containsKey(k)) {
      _rows[k] = Map<String, dynamic>.from(_rows[k]!)
        ..['sync_pending'] = 0;
    }
  }
}
