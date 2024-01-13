import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBProvider {
  DBProvider._();
  static final DBProvider db = DBProvider._();

  late  Database _database;

  Future<Database> get database async {
    // if (_database != null)
    //   return _database;
    // if _database is null we instantiate it
    _database = await initDB();
    return _database;
  }

  initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "Guachinches.db");
    return await openDatabase(path, version: 2 , onOpen: (db) {
    }, onCreate: (Database db, int version) async {
      await db.execute("CREATE TABLE fav ("
          "Id INTEGER PRIMARY KEY AUTOINCREMENT,"
          "restaurantId VARCHAR(500)"
          ")");
    });
  }
}
