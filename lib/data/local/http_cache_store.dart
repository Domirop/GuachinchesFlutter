import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

abstract class CacheStorage {
  Future<Map<String, dynamic>?> get(String key);
  Future<void> put(String key, String body, int ts);
  Future<void> deleteByPrefix(String prefix);
  Future<void> deleteAll();
}

class InMemoryCacheStorage implements CacheStorage {
  final _store = <String, Map<String, dynamic>>{};

  @override
  Future<Map<String, dynamic>?> get(String key) async => _store[key];

  @override
  Future<void> put(String key, String body, int ts) async {
    _store[key] = {'key': key, 'body': body, 'ts': ts};
  }

  @override
  Future<void> deleteByPrefix(String prefix) async {
    _store.removeWhere((k, _) => k.startsWith(prefix));
  }

  @override
  Future<void> deleteAll() async => _store.clear();
}

class _SqliteStorage implements CacheStorage {
  Database? _db;

  Future<Database> _open() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    _db = await openDatabase(
      '${dir.path}/http_cache.db',
      version: 1,
      onCreate: (db, _) => db.execute(
        'CREATE TABLE http_cache('
        'key TEXT PRIMARY KEY, body TEXT NOT NULL, ts INTEGER NOT NULL)',
      ),
    );
    return _db!;
  }

  @override
  Future<Map<String, dynamic>?> get(String key) async {
    final db = await _open();
    final rows = await db.query(
      'http_cache',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  @override
  Future<void> put(String key, String body, int ts) async {
    final db = await _open();
    await db.insert(
      'http_cache',
      {'key': key, 'body': body, 'ts': ts},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteByPrefix(String prefix) async {
    final db = await _open();
    await db.delete('http_cache', where: 'key LIKE ?', whereArgs: ['$prefix%']);
  }

  @override
  Future<void> deleteAll() async {
    final db = await _open();
    await db.delete('http_cache');
  }
}

class HttpCacheStore {
  final CacheStorage _storage;

  static final HttpCacheStore instance = HttpCacheStore._();
  HttpCacheStore._() : _storage = _SqliteStorage();
  HttpCacheStore.withStorage(CacheStorage storage) : _storage = storage;

  Future<String?> read(String key, {required Duration maxAge}) async {
    final row = await _storage.get(key);
    if (row == null) return null;
    final ts = row['ts'] as int;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (ts <= now - maxAge.inMilliseconds) return null;
    return row['body'] as String;
  }

  Future<String?> readStale(String key) async {
    final row = await _storage.get(key);
    return row == null ? null : row['body'] as String;
  }

  Future<void> write(String key, String body) async {
    await _storage.put(key, body, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> invalidate(String prefix) => _storage.deleteByPrefix(prefix);

  Future<void> clear() => _storage.deleteAll();
}
