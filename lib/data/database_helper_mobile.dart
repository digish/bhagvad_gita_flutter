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

Future<DatabaseHelperInterface> getInitializedDatabaseHelper() async {
  print("[DB_MOBILE] Initializing database helper...");
  return await DatabaseHelperImpl.create();
}

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
    final tokens = query
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return [];

    // 1. Cross-row AND Search: Use INTERSECT to find ref_ids matching all tokens
    final intersectSubquery = tokens
        .map(
          (t) =>
              "SELECT ref_id FROM search_index WHERE search_index MATCH '$t*'",
        )
        .join(' INTERSECT ');
    final orFtsQuery = tokens.map((t) => '$t*').join(' OR ');

    final List<Map<String, dynamic>> maps = await _db.rawQuery(
      '''
      SELECT ref_id, category, term_original 
      FROM search_index 
      WHERE ref_id IN ($intersectSubquery)
      AND search_index MATCH ? 
      LIMIT 100
    ''',
      [orFtsQuery],
    );

    if (maps.isEmpty) {
      return [];
    }

    // 1.5 Calculate relevance scores for ranking
    final Map<String, int> shlokaScores = {};
    for (var m in maps) {
      final id = m['ref_id'] as String;
      final cat = (m['category'] as String).toLowerCase();
      // Weights: shloka (10), anvay (5), others (3)
      int weight = 3;
      if (cat == 'shloka') {
        weight = 10;
      } else if (cat == 'anvay') {
        weight = 5;
      }
      shlokaScores[id] = (shlokaScores[id] ?? 0) + weight;
    }

    // Sort maps by relevance score (descending)
    final sortedMaps = List<Map<String, dynamic>>.from(maps);
    sortedMaps.sort((a, b) {
      final scoreA = shlokaScores[a['ref_id']] ?? 0;
      final scoreB = shlokaScores[b['ref_id']] ?? 0;
      return scoreB.compareTo(scoreA);
    });

    // Group terms and categories by ref_id
    final Map<String, Map<String, Set<String>>> metadataById = {};
    for (var m in maps) {
      final id = m['ref_id'] as String;
      final cat = m['category'] as String;
      final term = m['term_original'] as String?;

      if (!metadataById.containsKey(id)) {
        metadataById[id] = {};
      }
      metadataById[id]!.putIfAbsent(cat, () => {}).add(term ?? '');
    }

    final uniqueIds = metadataById.keys.toList();
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

    String? generateSnippet(String? text, Set<String> terms, String rawQuery) {
      if (text == null || text.isEmpty) return null;
      final lowerText = text.toLowerCase();
      int bestIndex = -1;
      int bestLen = 0;

      for (final term in terms) {
        if (term.isEmpty) continue;
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

    // Pre-calculate all available snippets for each ID
    final Map<String, Map<String, String>> snippetsById = {};
    for (var id in metadataById.keys) {
      if (!resultsMap.containsKey(id)) continue;
      final shlokaData = resultsMap[id]!;
      final cats = metadataById[id]!;
      final snips = <String, String>{};

      cats.forEach((category, words) {
        final combinedTerms = {...words, ...tokens};
        String? s;
        if (category == 'shloka') {
          s = generateSnippet(
            shlokaData['shloka_text'] as String?,
            combinedTerms,
            query,
          );
        } else if (category == 'meaning') {
          s = generateSnippet(
            shlokaData['commentary_text'] as String?,
            combinedTerms,
            query,
          );
        } else if (category == 'bhavarth') {
          s = generateSnippet(
            shlokaData['bhavarth_en'] as String?,
            combinedTerms,
            query,
          );
        } else if (category == 'anvay') {
          s = generateSnippet(
            shlokaData['anvay_text'] as String?,
            combinedTerms,
            query,
          );
        }
        if (s != null) snips[category] = s;
      });
      snippetsById[id] = snips;
    }

    // User requested original behavior: return each match row
    // SearchProvider will then group them.
    for (var match in sortedMaps) {
      final id = match['ref_id'] as String;
      final category = match['category'] as String?;
      if (id.isEmpty || category == null) continue;

      if (resultsMap.containsKey(id)) {
        final shlokaData = Map<String, dynamic>.from(resultsMap[id]!);
        final terms = metadataById[id]?[category] ?? {};
        final combinedTerms = {...terms, ...tokens};

        shlokaData['matched_category'] = category;
        shlokaData['match_snippet'] = snippetsById[id]?[category];
        shlokaData['matched_words'] = combinedTerms.toList();

        ordered.add(
          ShlokaResult.fromMap(
            shlokaData,
            commentaries: commentariesMap[id],
            categorySnippets: snippetsById[id],
          ),
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
  Future<Map<String, dynamic>?> getWordDefinition(String query) async {
    return null;
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

    // Fetch commentaries if needed
    Map<String, List<Commentary>> commentariesMap = {};
    if (includeCommentaries) {
      final ids = maps.map((m) => m['id'].toString()).toList();
      final idsList = ids.map((id) => "'$id'").join(",");
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
    }

    return maps
        .map(
          (m) => ShlokaResult.fromMap(
            m,
            commentaries: commentariesMap[m['id'].toString()],
          ),
        )
        .toList();
  }

  @override
  Future<List<ShlokaResult>> getShlokasByReferences(
    List<Map<String, dynamic>> references, {
    String language = 'hi',
    String script = 'dev',
    bool includeCommentaries = true,
  }) async {
    if (references.isEmpty) return [];
    final ids = references.map((r) => r['id'].toString()).toList();
    final idsList = ids.map((id) => "'$id'").join(",");
    final sql = _buildQuery(
      language,
      script,
      whereClause: "m.id IN ($idsList)",
    );

    final List<Map<String, dynamic>> maps = await _db.rawQuery(sql);
    final resultsMap = {for (var r in maps) r['id'].toString(): r};

    Map<String, List<Commentary>> commentariesMap = {};
    if (includeCommentaries) {
      if (ids.isNotEmpty) {
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
    }

    return ids
        .where((id) => resultsMap.containsKey(id))
        .map(
          (id) => ShlokaResult.fromMap(
            resultsMap[id]!,
            commentaries: commentariesMap[id],
          ),
        )
        .toList();
  }

  @override
  Future<List<ShlokaResult>> getAllShlokas({
    String language = 'hi',
    String script = 'dev',
    bool includeCommentaries = true,
  }) async {
    final sql = _buildQuery(language, script);
    final fullSql =
        "$sql ORDER BY CAST(m.chapter_no AS INTEGER), CAST(m.shloka_no AS INTEGER)";
    final List<Map<String, dynamic>> maps = await _db.rawQuery(fullSql);

    Map<String, List<Commentary>> commentariesMap = {};
    if (includeCommentaries) {
      final comms = await _db.query('commentaries');
      for (var c in comms) {
        final sId = c['shloka_id'].toString();
        if (!commentariesMap.containsKey(sId)) {
          commentariesMap[sId] = [];
        }
        commentariesMap[sId]!.add(Commentary.fromMap(c));
      }
    }

    return maps
        .map(
          (m) => ShlokaResult.fromMap(
            m,
            commentaries: commentariesMap[m['id'].toString()],
          ),
        )
        .toList();
  }

  @override
  Future<ShlokaResult?> getRandomShloka({
    String language = 'hi',
    String script = 'dev',
  }) async {
    final sql = _buildQuery(language, script);
    final List<Map<String, dynamic>> maps = await _db.rawQuery(
      "$sql ORDER BY RANDOM() LIMIT 1",
    );
    if (maps.isNotEmpty) {
      final id = maps.first['id'].toString();
      return ShlokaResult.fromMap(
        maps.first,
        commentaries: await getCommentaries(id),
      );
    }
    return null;
  }

  @override
  Future<List<Commentary>> getCommentariesForShloka(
    String chapterNo,
    String shlokNo,
  ) async {
    final id = "$chapterNo.$shlokNo";
    return getCommentaries(id);
  }

  Future<List<Commentary>> getCommentaries(String shlokaId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'commentaries',
      where: 'shloka_id = ?',
      whereArgs: [shlokaId],
    );
    return maps.map((m) => Commentary.fromMap(m)).toList();
  }

  Future<List<Translation>> getTranslations(String shlokaId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'translations',
      where: 'shloka_id = ?',
      whereArgs: [shlokaId],
    );
    return maps.map((m) => Translation.fromMap(m)).toList();
  }

  @override
  Future<ShlokaResult?> getShlokaById(
    String id, {
    String language = 'hi',
    String script = 'dev',
  }) async {
    final sql = _buildQuery(language, script, whereClause: "m.id = ?");
    final List<Map<String, dynamic>> maps = await _db.rawQuery(sql, [id]);

    if (maps.isNotEmpty) {
      final commentaries = await getCommentaries(id);
      return ShlokaResult.fromMap(maps.first, commentaries: commentaries);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getChapters({
    String language = 'hi',
    String script = 'dev',
  }) async {
    // Determine translation language code (as per _buildQuery logic)
    String transCode = language;
    if (language == 'hi') {
      if (script == 'dev' || script == 'hi')
        transCode = 'hi';
      else if (script == 'en' || script == 'ro')
        transCode = 'ro';
      else
        transCode = script;
    }

    return await _db.rawQuery(
      '''
      SELECT 
        id, 
        chapter_number, 
        chapter_summary, 
        name, 
        name_meaning, 
        name_translation, 
        verses_count 
      FROM chapters 
      WHERE language = ?
    ''',
      [transCode],
    );
  }

  Future<Map<String, dynamic>?> getChapter(
    int chapterNumber, {
    String language = 'hi',
    String script = 'dev',
  }) async {
    String transCode = language;
    if (language == 'hi') {
      if (script == 'dev' || script == 'hi')
        transCode = 'hi';
      else if (script == 'en' || script == 'ro')
        transCode = 'ro';
      else
        transCode = script;
    }

    final results = await _db.rawQuery(
      '''
      SELECT * FROM chapters 
      WHERE chapter_number = ? AND language = ?
    ''',
      [chapterNumber, transCode],
    );

    return results.isNotEmpty ? results.first : null;
  }
}
