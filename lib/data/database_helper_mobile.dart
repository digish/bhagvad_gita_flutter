import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/shloka_result.dart';
import '../models/word_result.dart';
import 'database_helper_interface.dart';

class DatabaseHelperImpl implements DatabaseHelperInterface {
  late final Database _db;

  DatabaseHelperImpl._(this._db);

  static Future<DatabaseHelperImpl> create() async {
    String path = join(await getDatabasesPath(), 'geeta');
    var exists = await databaseExists(path);

    if (!exists) {
      debugPrint("[DB_MOBILE] Database not found, copying from assets...");
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      ByteData data = await rootBundle.load('assets/database/geeta');
      List<int> bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      await File(path).writeAsBytes(bytes, flush: true);
      debugPrint("[DB_MOBILE] Database copied successfully.");
    } else {
      debugPrint("[DB_MOBILE] Database found at path: $path");
    }

    final db = await openDatabase(path, readOnly: true);
    return DatabaseHelperImpl._(db);
  }

  @override
  Future<List<ShlokaResult>> searchShlokas(String query) async {
    debugPrint("[DB_MOBILE] Searching shlokas for: '$query'");
    final List<Map<String, dynamic>> maps = await _db.query('geeta',
        where: 'shlok LIKE ? OR anvay LIKE ? OR bhavarth LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        limit: 20);
    debugPrint("[DB_MOBILE] Found ${maps.length} shlokas for '$query'");
    return List.generate(maps.length, (i) => ShlokaResult.fromMap(maps[i]));
  }

  @override
  Future<List<WordResult>> searchWords(String query) async {
    debugPrint("[DB_MOBILE] Searching words for: '$query'");
    final List<Map<String, dynamic>> maps = await _db.query('words',
        where: 'suggest_text_1 LIKE ?', whereArgs: ['%$query%'], limit: 10);
    debugPrint("[DB_MOBILE] Found ${maps.length} words for '$query'");
    return List.generate(maps.length, (i) => WordResult.fromMap(maps[i]));
  }

  @override
  Future<List<ShlokaResult>> getShlokasByChapter(String chapterNumber) async {
    debugPrint("[DB_MOBILE] Getting shlokas for chapter: $chapterNumber");
    final List<Map<String, dynamic>> maps = await _db.query('geeta',
        where: 'chapterNo = ?', whereArgs: [chapterNumber]);
    debugPrint("[DB_MOBILE] Found ${maps.length} shlokas for chapter $chapterNumber");
    return List.generate(maps.length, (i) => ShlokaResult.fromMap(maps[i]));
  }

  @override
  Future<List<ShlokaResult>> getAllShlokas() async {
    debugPrint("[DB_MOBILE] Getting all shlokas...");
    final List<Map<String, dynamic>> maps = await _db.query('geeta');
    debugPrint("[DB_MOBILE] Found ${maps.length} total shlokas.");
    return List.generate(maps.length, (i) => ShlokaResult.fromMap(maps[i]));
  }

  @override
  Future<Map<String, dynamic>?> getWordDefinition(String query) async {
    debugPrint("[DB_MOBILE] Getting word definition for: '$query'");
    final List<Map<String, dynamic>> maps = await _db.query('words',
        where: 'suggest_text_1 = ?', whereArgs: [query], limit: 1);
    debugPrint("[DB_MOBILE] Found definition for '$query': ${maps.isNotEmpty}");
    return maps.isNotEmpty ? maps.first : null;
  }
}

// This function is the entry point for the mobile platform.
Future<DatabaseHelperInterface> getInitializedDatabaseHelper() async {
  return await DatabaseHelperImpl.create();
}

