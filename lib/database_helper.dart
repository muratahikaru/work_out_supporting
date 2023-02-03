import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final _databaseName = "MyDatabase.db";
  static final _databaseVersion = 1;

  static final table = "work_out_history";

  static final columnId = "_id";
  static final columnDate = "date";
  static final columnTraining = "training";
  static final columnCount = "count";

  DatabaseHelper._privateConstructor();

  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database?> get database async {
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();

    String path = join(documentsDirectory.path, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute(
      '''
        CREATE TABLE $table (
          $columnId INTEGER PRIMARY KEY,
          $columnDate TEXT NOT NULL,
          $columnTraining TEXT NOT NULL,
          $columnCount INTEGER NOT NULL
        )
      '''
    );
  }

  Future<int> insert(Map<String, dynamic> row) async {
    Database? db = await instance.database;
    return await db!.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> getTrainingData(String date) async {
    Database? db = await instance.database;
    return db!.query(
      table,
      where: "date = ?",
      whereArgs: [date],
    );
  }

  Future<void> delete(int id) async {
    Database? db = await instance.database;
    await db!.delete(
      table,
      where: "_id = ?",
      whereArgs: [id],
    );
  }

}
