import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('Inspect commentaries table schema', () async {
    final dbPath = path.join(
      Directory.current.path,
      'assets',
      'database',
      'geeta_v2.db',
    );
    if (!File(dbPath).existsSync()) {
      print('Database not found at $dbPath');
      return;
    }

    final db = await openDatabase(dbPath, readOnly: true);

    print('\n--- Table: commentaries ---');
    final tableInfo = await db.rawQuery("PRAGMA table_info(commentaries)");
    for (var col in tableInfo) {
      print(col);
    }

    print('\n--- Table: translations ---');
    final tInfo = await db.rawQuery("PRAGMA table_info(translations)");
    for (var col in tInfo) {
      print(col);
    }

    print('\n--- Sample Commentary Data ---');
    // Fetch one row to see content
    final sample = await db.rawQuery("SELECT * FROM commentaries LIMIT 1");
    print(sample);

    await db.close();
  });
}
