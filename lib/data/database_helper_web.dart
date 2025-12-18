/* 
*  © 2025 Digish Pandya. All rights reserved.
*/

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
    ByteData data = await rootBundle.load('assets/database/geeta_v2.db');
    List<int> bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );

    // Define the path for our database in the browser's virtual file system.
    final dbPath = 'geeta_v2.db';

    // 1. Write the database bytes to the virtual path.
    await databaseFactoryFfiWeb.writeDatabaseBytes(
      dbPath,
      Uint8List.fromList(bytes),
    );

    // 2. Open the database from that virtual path.
    final db = await databaseFactoryFfiWeb.openDatabase(dbPath);

    return DatabaseHelperImpl._(db);
  }

  // Enhanced _buildQuery to handle Script and Language
  String _buildQuery(
    String language,
    String script, {
    String? whereClause,
    String extraColumns = '',
    String extraJoin = '',
  }) {
    String scriptCode = script;
    if (script == 'ro') scriptCode = 'en';
    if (script == 'hi') scriptCode = 'dev';

    String transCode = language;

    if (language == 'hi') {
      if (script == 'dev' || script == 'hi') {
        transCode = 'hi';
      } else if (script == 'en') {
        transCode = 'ro';
      } else if (script == 'ro') {
        transCode = 'ro';
      } else {
        transCode = script;
      }
    }

    return '''
      SELECT 
        m.id, 
        m.chapter_no, 
        m.shloka_no,
        m.speaker,
        m.sanskrit_romanized,
        m.audio_path,
        s.shloka_text, 
        s.anvay_text, 
        t.bhavarth$extraColumns
      FROM master_shlokas m
      JOIN shloka_scripts s ON m.id = s.shloka_id AND s.script_code = '$scriptCode'
      LEFT JOIN translations t ON m.id = t.shloka_id AND t.language_code = '$transCode'
      $extraJoin
      ${whereClause != null ? 'WHERE $whereClause' : ''}
    ''';
  }

  @override
  Future<List<ShlokaResult>> searchShlokas(
    String query, {
    String language = 'hi',
    String script = 'dev',
  }) async {
    final List<Map<String, dynamic>> maps = await _db.rawQuery(
      '''
      SELECT ref_id FROM search_index 
      WHERE search_index MATCH ? 
      LIMIT 20
    ''',
      [query],
    );

    List<String> ids = maps.map((m) => m['ref_id'] as String).toList();
    if (ids.isEmpty) return [];

    final idsQuote = ids.map((id) => "'$id'").join(",");
    final sql = _buildQuery(
      language,
      script,
      whereClause: "m.id IN ($idsQuote)",
    );

    final List<Map<String, dynamic>> results = await _db.rawQuery(sql);

    final resultsMap = {for (var r in results) r['id'].toString(): r};
    List<ShlokaResult> ordered = [];
    for (String id in ids) {
      if (resultsMap.containsKey(id)) {
        ordered.add(ShlokaResult.fromMap(resultsMap[id]!));
      }
    }
    return ordered;
  }

  @override
  Future<List<ShlokaResult>> getShlokasByChapter(
    int chapter, {
    String language = 'hi',
    String script = 'dev',
  }) async {
    final sql = _buildQuery(language, script, whereClause: "m.chapter_no = ?");
    final fullSql = "$sql ORDER BY m.shloka_no ASC";

    final List<Map<String, dynamic>> maps = await _db.rawQuery(fullSql, [
      chapter,
    ]);
    return List.generate(maps.length, (i) => ShlokaResult.fromMap(maps[i]));
  }

  @override
  Future<List<ShlokaResult>> getAllShlokas({
    String language = 'hi',
    String script = 'dev',
  }) async {
    final sql = _buildQuery(language, script);
    final List<Map<String, dynamic>> maps = await _db.rawQuery(sql);
    return List.generate(maps.length, (i) => ShlokaResult.fromMap(maps[i]));
  }

  @override
  Future<List<WordResult>> searchWords(String query) async {
    return [];
  }

  @override
  Future<Map<String, dynamic>?> getWordDefinition(String query) async {
    return null;
  }
}

Future<DatabaseHelperInterface> getInitializedDatabaseHelper() async {
  return await DatabaseHelperImpl.create();
}
