import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final dbPath = path.join(
    Directory.current.path,
    'assets',
    'database',
    'geeta_v2.db',
  );
  final db = await openDatabase(dbPath);

  try {
    // Check translations language codes
    final tCodes = await db.rawQuery(
      'SELECT DISTINCT language_code FROM translations',
    );
    print('Translation Language Codes:');
    for (var row in tCodes) {
      print('- ${row['language_code']}');
    }

    // Check commentaries language codes
    final cCodes = await db.rawQuery(
      'SELECT DISTINCT language_code FROM commentaries',
    );
    print('\nCommentary Language Codes:');
    for (var row in cCodes) {
      print('- ${row['language_code']}');
    }

    // Check shloka_scripts script codes
    final sCodes = await db.rawQuery(
      'SELECT DISTINCT script_code FROM shloka_scripts',
    );
    print('\nShloka Script Codes:');
    for (var row in sCodes) {
      print('- ${row['script_code']}');
    }
  } finally {
    await db.close();
  }
}
