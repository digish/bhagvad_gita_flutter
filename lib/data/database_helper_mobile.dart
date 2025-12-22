/* 
*  © 2025 Digish Pandya. All rights reserved.
*/

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../models/shloka_result.dart';
import '../models/word_result.dart';
import 'database_helper_interface.dart';

class DatabaseHelperImpl implements DatabaseHelperInterface {
  static const int DB_VERSION = 2; // Increment this to force DB update
  late Database _db;

  DatabaseHelperImpl._(this._db);

  static Future<DatabaseHelperImpl> create() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, "geeta_v2.db");

    // Check version
    final prefs = await SharedPreferences.getInstance();
    final savedVersion = prefs.getInt('db_version') ?? 0;

    bool exists = await databaseExists(path);

    // Force update if version mismatch (or file missing)
    if (!exists || savedVersion < DB_VERSION) {
      print(
        "[DB_MOBILE] New DB version ($DB_VERSION) detected (current: $savedVersion). Updating...",
      );

      try {
        // Close existing DB connections if any? (Not easily possible statically, rely on restart)

        // 1. Clean up OLD databases to save space
        final oldDbV1 = File(join(documentsDirectory.path, "geeta_v1.db"));
        if (await oldDbV1.exists()) {
          print("[DB_MOBILE] Deleting old DB: geeta_v1.db");
          await oldDbV1.delete();
        }
        final oldDbLegacy = File(join(documentsDirectory.path, "geeta.db"));
        if (await oldDbLegacy.exists()) {
          print("[DB_MOBILE] Deleting old DB: geeta.db");
          await oldDbLegacy.delete();
        }

        // 2. Delete current file if it exists (to overwrite)
        if (exists) {
          print("[DB_MOBILE] Deleting outdated DB file: $path");
          await deleteDatabase(path);
        }

        // 3. Copy new DB
        print("[DB_MOBILE] Copying new database from assets...");
        await Directory(dirname(path)).create(recursive: true);
        ByteData data = await rootBundle.load(
          join("assets", "database", "geeta_v2.db"),
        );
        List<int> bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        await File(path).writeAsBytes(bytes, flush: true);

        // 4. Update preference
        await prefs.setInt('db_version', DB_VERSION);
        print("[DB_MOBILE] Database updated to version $DB_VERSION.");
      } catch (e) {
        print("Error copying database: $e");
        // If copy fails, we might still try to open what's there if it exists?
        // Or rethrow to show error. Rethrow is safer.
        rethrow;
      }
    } else {
      print(
        "[DB_MOBILE] Opening existing database (Version $savedVersion): $path",
      );
    }

    final db = await openDatabase(path, readOnly: true);
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
    // 1. Determine Shloka Script Code (shloka_scripts table)
    // Map 'ro' -> 'en' because shloka_scripts uses 'en' for Roman.
    // Map 'hi' -> 'dev' because user might pass 'hi' as script for consistency, though 'dev' is standard.
    String scriptCode = script;
    if (script == 'ro') scriptCode = 'en';
    if (script == 'hi') scriptCode = 'dev';

    // 2. Determine Translation Language Code (translations table)
    // If user wants English translation, always 'en'.
    // If user wants Hindi translation, respect the Script (Lipi).
    String transCode = language; // Default to 'hi' or 'en' passed in

    if (language == 'hi') {
      // If Hindi translation is requested, check the script preference
      if (script == 'dev' || script == 'hi') {
        transCode = 'hi'; // Standard Hindi Devanagari
      } else if (script == 'en') {
        transCode = 'ro'; // Romanized Hindi (User selected Roman script)
      } else if (script == 'ro') {
        transCode = 'ro'; // Romanized Hindi
      } else {
        // For gu, te, kn, ta, bn, etc., the translation table supports these codes directly for Hindi text.
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
    // 1. FTS Search to get relevant IDs, Categories, AND Original Terms
    final List<Map<String, dynamic>> maps = await _db.rawQuery(
      '''
      SELECT ref_id, category, term_original 
      FROM search_index 
      WHERE search_index MATCH ? 
      LIMIT 100
    ''',
      ['$query*'],
    );

    if (maps.isEmpty) return [];

    final Map<String, Set<String>> matchedTermsById = {};
    for (var m in maps) {
      final id = m['ref_id'] as String;
      final term = m['term_original'] as String?;
      if (term != null) {
        matchedTermsById.putIfAbsent(id, () => {}).add(term);
      }
    }

    final uniqueIds = matchedTermsById.keys.toList();
    if (uniqueIds.isEmpty) return [];

    // 2. Fetch Full Details
    final idsQuote = uniqueIds.map((id) => "'$id'").join(",");

    const extraJoins = """
      LEFT JOIN commentaries c ON m.id = c.shloka_id AND c.language_code = 'en'
      LEFT JOIN translations t_en ON m.id = t_en.shloka_id AND t_en.language_code = 'en'
    """;

    final sql = _buildQuery(
      language,
      script,
      whereClause: "m.id IN ($idsQuote) GROUP BY m.id",
      extraJoin: extraJoins,
      extraColumns:
          ", GROUP_CONCAT(c.content, ' ') as commentary_text, t_en.bhavarth as bhavarth_en",
    );

    // 3. Fetch Commentaries for matched IDs
    final idsList = uniqueIds.map((id) => "'$id'").join(",");
    final Map<String, List<Commentary>> commentariesMap = {};

    if (idsList.isNotEmpty) {
      final comms = await _db.rawQuery(
        "SELECT * FROM commentaries WHERE shloka_id IN ($idsList)",
      );
      for (var c in comms) {
        final sId = c['shloka_id'].toString();
        if (!commentariesMap.containsKey(sId)) {
          commentariesMap[sId] = [];
        }
        commentariesMap[sId]!.add(Commentary.fromMap(c));
      }
    }

    final List<Map<String, dynamic>> results = await _db.rawQuery(sql);
    final resultsMap = {for (var r in results) r['id'].toString(): r};

    List<ShlokaResult> ordered = [];
    final seenIds = <String>{};

    String? generateSnippet(String? text, Set<String> terms, String rawQuery) {
      if (text == null || text.isEmpty) return null;
      final lowerText = text.toLowerCase();
      int bestIndex = -1;
      int bestLen = 0;

      for (final term in terms) {
        final idx = lowerText.indexOf(term.toLowerCase());
        if (idx != -1) {
          if (bestIndex == -1 || idx < bestIndex) {
            bestIndex = idx;
            bestLen = term.length;
          }
        }
      }

      if (bestIndex == -1 && rawQuery.isNotEmpty) {
        final idx = lowerText.indexOf(rawQuery.toLowerCase());
        if (idx != -1) {
          bestIndex = idx;
          bestLen = rawQuery.length;
        }
      }

      if (bestIndex == -1) return null;
      final start = (bestIndex - 60).clamp(0, text.length);
      final end = (bestIndex + bestLen + 60).clamp(0, text.length);
      String snippet = text.substring(start, end);
      if (start > 0) snippet = "...$snippet";
      if (end < text.length) snippet = "$snippet...";
      return snippet.replaceAll(RegExp(r'\s+'), ' ');
    }

    for (var match in maps) {
      String id = match['ref_id'] as String;
      if (seenIds.contains(id)) continue;
      seenIds.add(id);

      String category = match['category'] as String;

      if (resultsMap.containsKey(id)) {
        final shlokaData = Map<String, dynamic>.from(resultsMap[id]!);
        final terms = matchedTermsById[id] ?? {};
        if (terms.isEmpty) terms.add(query);

        String? snippet;
        if (category == 'meaning') {
          snippet = generateSnippet(
            shlokaData['commentary_text'] as String?,
            terms,
            query,
          );
        } else if (category == 'bhavarth') {
          snippet = generateSnippet(
            shlokaData['bhavarth_en'] as String?,
            terms,
            query,
          );
        } else if (category == 'anvay') {
          snippet = generateSnippet(
            shlokaData['anvay_text'] as String?,
            terms,
            query,
          );
        }

        shlokaData['matched_category'] = category;
        shlokaData['match_snippet'] = snippet;
        shlokaData['matched_words'] = terms.toList();

        ordered.add(
          ShlokaResult.fromMap(shlokaData, commentaries: commentariesMap[id]),
        );
      }
    }

    return ordered;
  }

  @override
  Future<List<WordResult>> searchWords(String query) async {
    return [];
  }

  @override
  Future<List<ShlokaResult>> getShlokasByChapter(
    int chapter, {
    String language = 'hi',
    String script = 'dev',
    bool includeCommentaries = true,
  }) async {
    final sql = _buildQuery(language, script, whereClause: "m.chapter_no = ?");
    final fullSql = "$sql ORDER BY m.shloka_no ASC";

    final List<Map<String, dynamic>> maps = await _db.rawQuery(fullSql, [
      chapter,
    ]);

    if (maps.isNotEmpty && includeCommentaries) {
      final ids = maps.map((m) => "'${m['id']}'").join(',');
      final comms = await _db.rawQuery(
        "SELECT * FROM commentaries WHERE shloka_id IN ($ids)",
      );

      final Map<String, List<Commentary>> commentariesMap = {};
      for (var c in comms) {
        final sId = c['shloka_id'].toString();
        if (!commentariesMap.containsKey(sId)) {
          commentariesMap[sId] = [];
        }
        commentariesMap[sId]!.add(Commentary.fromMap(c));
      }

      return List.generate(maps.length, (i) {
        final m = maps[i];
        final id = m['id'].toString();
        return ShlokaResult.fromMap(m, commentaries: commentariesMap[id]);
      });
    }

    return List.generate(maps.length, (i) => ShlokaResult.fromMap(maps[i]));
  }

  @override
  Future<List<ShlokaResult>> getAllShlokas({
    String language = 'hi',
    String script = 'dev',
    bool includeCommentaries = true,
  }) async {
    final sql =
        "${_buildQuery(language, script)} ORDER BY CAST(m.chapter_no AS INTEGER) ASC, CAST(m.shloka_no AS INTEGER) ASC";
    final List<Map<String, dynamic>> maps = await _db.rawQuery(sql);

    // If commentaries are not requested, return results without them.
    if (!includeCommentaries) {
      return List.generate(
        maps.length,
        (i) => ShlokaResult.fromMap(maps[i], commentaries: null),
      );
    }

    // Fetch all commentaries
    // Note: This might be large, but necessary for offline functionality requested.
    // Optimization: Depending on DB size, we might want to defer this, but
    // for now we assume it fits in memory (commentaries are text).
    final comms = await _db.query('commentaries');

    final Map<String, List<Commentary>> commentariesMap = {};
    for (var c in comms) {
      final sId = c['shloka_id'].toString();
      if (!commentariesMap.containsKey(sId)) {
        commentariesMap[sId] = [];
      }
      commentariesMap[sId]!.add(Commentary.fromMap(c));
    }

    return List.generate(maps.length, (i) {
      final m = maps[i];
      final id = m['id'].toString();
      return ShlokaResult.fromMap(m, commentaries: commentariesMap[id]);
    });
  }

  @override
  Future<List<Commentary>> getCommentariesForShloka(
    String chapterNo,
    String shlokNo,
  ) async {
    // 1. Find Shloka ID
    final List<Map<String, dynamic>> idResult = await _db.query(
      'master_shlokas',
      columns: ['id'],
      where: 'chapter_no = ? AND shloka_no = ?',
      whereArgs: [chapterNo, shlokNo],
    );

    if (idResult.isEmpty) return [];

    final id = idResult.first['id'];

    // 2. Fetch Commentaries
    final List<Map<String, dynamic>> comms = await _db.query(
      'commentaries',
      where: 'shloka_id = ?',
      whereArgs: [id],
    );

    return comms.map((c) => Commentary.fromMap(c)).toList();
  }

  @override
  Future<Map<String, dynamic>?> getWordDefinition(String query) async {
    // Unimplemented for now in V2 schema
    return null;
  }

  @override
  Future<ShlokaResult?> getRandomShloka({
    String language = 'hi',
    String script = 'dev',
  }) async {
    final sql = _buildQuery(language, script);
    final fullSql = "$sql ORDER BY RANDOM() LIMIT 1";

    final List<Map<String, dynamic>> maps = await _db.rawQuery(fullSql);
    if (maps.isEmpty) return null;

    final m = maps.first;
    final id = m['id'].toString();

    // Fetch commentaries for this specific shloka
    final comms = await _db.rawQuery(
      "SELECT * FROM commentaries WHERE shloka_id = ?",
      [id],
    );

    final List<Commentary> commentaries = comms
        .map((c) => Commentary.fromMap(c))
        .toList();

    return ShlokaResult.fromMap(m, commentaries: commentaries);
  }

  @override
  Future<ShlokaResult?> getShlokaById(
    String id, {
    String language = 'hi',
    String script = 'dev',
  }) async {
    final sql = _buildQuery(language, script, whereClause: "m.id = ?");
    final List<Map<String, dynamic>> maps = await _db.rawQuery(sql, [id]);

    if (maps.isEmpty) return null;

    final m = maps.first;

    // Fetch commentaries for this specific shloka
    final comms = await _db.rawQuery(
      "SELECT * FROM commentaries WHERE shloka_id = ?",
      [id],
    );

    final List<Commentary> commentaries = comms
        .map((c) => Commentary.fromMap(c))
        .toList();

    return ShlokaResult.fromMap(m, commentaries: commentaries);
  }

  @override
  Future<List<ShlokaResult>> getShlokasByReferences(
    List<Map<String, dynamic>> references, {
    String language = 'hi',
    String script = 'dev',
    bool includeCommentaries = true,
  }) async {
    if (references.isEmpty) return [];

    final keys = references
        .map((r) => "'${r['chapter_no']}:${r['shlok_no']}'")
        .join(",");

    final whereClause = "m.chapter_no || ':' || m.shloka_no IN ($keys)";

    final sql = _buildQuery(language, script, whereClause: whereClause);
    final fullSql =
        "$sql ORDER BY CAST(m.chapter_no AS INTEGER) ASC, CAST(m.shloka_no AS INTEGER) ASC";

    final List<Map<String, dynamic>> maps = await _db.rawQuery(fullSql);

    if (maps.isEmpty) return [];

    if (!includeCommentaries) {
      return List.generate(
        maps.length,
        (i) => ShlokaResult.fromMap(maps[i], commentaries: null),
      );
    }

    final ids = maps.map((m) => "'${m['id']}'").join(',');
    final comms = await _db.rawQuery(
      "SELECT * FROM commentaries WHERE shloka_id IN ($ids)",
    );

    final Map<String, List<Commentary>> commentariesMap = {};
    for (var c in comms) {
      final sId = c['shloka_id'].toString();
      if (!commentariesMap.containsKey(sId)) {
        commentariesMap[sId] = [];
      }
      commentariesMap[sId]!.add(Commentary.fromMap(c));
    }

    return List.generate(maps.length, (i) {
      final m = maps[i];
      final id = m['id'].toString();
      return ShlokaResult.fromMap(m, commentaries: commentariesMap[id]);
    });
  }
}

// Top-level function for conditional import
Future<DatabaseHelperInterface> getInitializedDatabaseHelper() async {
  return await DatabaseHelperImpl.create();
}
