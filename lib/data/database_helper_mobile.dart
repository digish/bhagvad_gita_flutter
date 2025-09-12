/* 
*  © 2025 Digish Pandya. All rights reserved.
*
*  This mobile application, "Shrimad Bhagavad Gita," including its code, design, and original content, is released under the [MIT License] unless otherwise noted.
*
*  The sacred text of the Bhagavad Gita, as presented herein, is in the public domain. Translations, interpretations, UI elements, and artistic representations created by the developer are protected under copyright law.
*
*  This app is offered in the spirit of dharma and shared learning. You are welcome to use, modify, and distribute the source code under the terms of the MIT License. However, please preserve the integrity of the spiritual message and credit the original contributors where due.
*
*  For licensing details, see the LICENSE file in the repository.
*
**/

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
  Future<List<ShlokaResult>> getShlokasByChapter(String chapterNumber) async {
    final List<Map<String, dynamic>> maps = await _db.query('geeta',
        where: 'chapterNo = ?', whereArgs: [chapterNumber]);
    return List.generate(maps.length, (i) => ShlokaResult.fromMap(maps[i]));
  }

  @override
  Future<List<ShlokaResult>> getAllShlokas() async {
    final List<Map<String, dynamic>> maps = await _db.query('geeta');
    return List.generate(maps.length, (i) => ShlokaResult.fromMap(maps[i]));
  }

  @override
  Future<Map<String, dynamic>?> getWordDefinition(String query) async {
    final List<Map<String, dynamic>> maps = await _db.query('words',
        where: 'suggest_text_1 = ?', whereArgs: [query], limit: 1);
    return maps.isNotEmpty ? maps.first : null;
  }
}

// This function is the entry point for the mobile platform.
Future<DatabaseHelperInterface> getInitializedDatabaseHelper() async {
  return await DatabaseHelperImpl.create();
}
