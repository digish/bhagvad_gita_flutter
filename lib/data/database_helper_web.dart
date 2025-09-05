import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../models/shloka_result.dart';
import '../models/word_result.dart';
import 'database_helper_interface.dart';

// This is the web implementation using sqflite_common_ffi_web.
class DatabaseHelperImpl implements DatabaseHelperInterface {
  late final Database _db;

  DatabaseHelperImpl._(this._db);

  static Future<DatabaseHelperImpl> create() async {
    // For the web, we load the database from the asset bundle as bytes.
    ByteData data = await rootBundle.load('database/geeta');
    List<int> bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    // Define the path for our database in the browser's virtual file system.
    final dbPath = 'geeta';

    // 1. Write the database bytes to the virtual path.
    await databaseFactoryFfiWeb.writeDatabaseBytes(dbPath, Uint8List.fromList(bytes));

    // 2. Open the database from that virtual path.
    final db = await databaseFactoryFfiWeb.openDatabase(dbPath);
    
    return DatabaseHelperImpl._(db);
  }

  @override
  Future<List<ShlokaResult>> getShlokasByChapter(String chapter) async {
    final List<Map<String, dynamic>> maps = await _db
        .query('geeta', where: 'chapterNo = ?', whereArgs: [chapter]);
    return List.generate(maps.length, (i) => ShlokaResult.fromMap(maps[i]));
  }

  @override
  Future<List<ShlokaResult>> getAllShlokas() async {
    final List<Map<String, dynamic>> maps = await _db.query('geeta');
    return List.generate(maps.length, (i) => ShlokaResult.fromMap(maps[i]));
  }

  @override
  Future<List<ShlokaResult>> searchShlokas(String query) async {
    final List<Map<String, dynamic>> maps = await _db.query('geeta',
        where: 'shlok LIKE ? OR anvay LIKE ? OR bhavarth LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        limit: 20);
    return List.generate(maps.length, (i) => ShlokaResult.fromMap(maps[i]));
  }

  @override
  Future<List<WordResult>> searchWords(String query) async {
    final List<Map<String, dynamic>> maps = await _db.query('words',
        where: 'suggest_text_1 LIKE ?', whereArgs: ['%$query%'], limit: 10);
    return List.generate(maps.length, (i) => WordResult.fromMap(maps[i]));
  }

  @override
  Future<Map<String, dynamic>?> getWordDefinition(String query) async {
    final List<Map<String, dynamic>> maps = await _db.query('words',
        where: 'suggest_text_1 = ?', whereArgs: [query], limit: 1);
    return maps.isNotEmpty ? maps.first : null;
  }
}

// This function is the entry point for the web platform.
Future<DatabaseHelperInterface> getInitializedDatabaseHelper() async {
  return await DatabaseHelperImpl.create();
}

