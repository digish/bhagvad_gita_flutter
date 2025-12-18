import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;
import 'package:bhagvadgeeta/models/shloka_result.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  late Database db;

  setUpAll(() async {
    final testDbPath = path.join(
      Directory.current.path,
      'test',
      'test_geeta_v2.db',
    );
    // Ensure the directory exists
    await Directory(path.dirname(testDbPath)).create(recursive: true);

    final dbFile = File(testDbPath);
    if (await dbFile.exists()) {
      await dbFile.delete();
    }

    // Use the v2 database this time
    final assetPath = path.join(
      Directory.current.path,
      'assets',
      'database',
      'geeta_v2.db',
    );
    final assetBytes = await File(assetPath).readAsBytes();
    await dbFile.writeAsBytes(assetBytes, flush: true);

    db = await openDatabase(testDbPath);
  });

  tearDownAll(() async {
    await db.close();
  });

  test('Fetch commentaries for Chapter 1', () async {
    // 1. Fetch shlokas
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      "SELECT m.id, m.chapter_no, m.shloka_no, m.speaker, m.sanskrit_romanized, "
      "m.audio_path, s.shloka_text, s.anvay_text, t.bhavarth "
      "FROM master_shlokas m "
      "JOIN shloka_scripts s ON m.id = s.shloka_id AND s.script_code = 'dev' "
      "LEFT JOIN translations t ON m.id = t.shloka_id AND t.language_code = 'hi' "
      "WHERE m.chapter_no = 1 ORDER BY m.shloka_no ASC LIMIT 5",
    );

    expect(maps, isNotEmpty);

    // 2. Mock the logic of getShlokasByChapter
    final ids = maps.map((m) => "'${m['id']}'").join(',');
    final comms = await db.rawQuery(
      "SELECT * FROM commentaries WHERE shloka_id IN ($ids)",
    );

    // Grouping logic
    final Map<String, List<Commentary>> commentariesMap = {};
    for (var c in comms) {
      final sId = c['shloka_id'].toString();
      if (!commentariesMap.containsKey(sId)) {
        commentariesMap[sId] = [];
      }
      commentariesMap[sId]!.add(Commentary.fromMap(c));
    }

    // 3. Verify
    final results = List.generate(maps.length, (i) {
      final m = maps[i];
      final id = m['id'].toString();
      return ShlokaResult.fromMap(m, commentaries: commentariesMap[id]);
    });

    for (var result in results) {
      print(
        'Shloka ${result.id} has ${result.commentaries?.length ?? 0} commentaries',
      );
      if (result.commentaries != null) {
        for (var c in result.commentaries!) {
          print(' - ${c.authorName} (${c.languageCode})');
        }
      }
    }

    expect(
      results.first.commentaries,
      isNotEmpty,
    ); // Assuming DB has commentaries for 1.1
  });
}
