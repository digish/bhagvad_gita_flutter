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

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/bookmark.dart';

class UserDatabaseHelper {
  UserDatabaseHelper._privateConstructor();
  static final UserDatabaseHelper instance =
      UserDatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // This creates a new DB file if it doesn't exist.
  // It does NOT copy from assets.
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'geetaUser.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // This is the equivalent of onCreate in your DictionaryOpenHelper
  Future<void> _onCreate(Database db, int version) async {
    // Note: FTS3 is supported in sqflite.
    await db.execute('''
      CREATE VIRTUAL TABLE bmarks USING fts3(
        bmarkLabel TEXT,
        chapterNo TEXT,
        shlokNo TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Check if table exists before creating it to avoid errors if users already have it
      // or if FTS3 behaves differently.
      try {
        await db.execute('''
          CREATE VIRTUAL TABLE IF NOT EXISTS bmarks USING fts3(
            bmarkLabel TEXT,
            chapterNo TEXT,
            shlokNo TEXT
          )
        ''');
      } catch (e) {
        // Fallback for versions that might not support IF NOT EXISTS for Virtual Tables
        var res = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='bmarks'",
        );
        if (res.isEmpty) {
          await db.execute('''
            CREATE VIRTUAL TABLE bmarks USING fts3(
              bmarkLabel TEXT,
              chapterNo TEXT,
              shlokNo TEXT
            )
          ''');
        }
      }
    }
  }

  // Port of addBookmark
  Future<void> addBookmark(String chapter, String shlok) async {
    final db = await instance.database;
    await db.insert('bmarks', {
      'bmarkLabel': '$chapter:$shlok',
      'chapterNo': chapter,
      'shlokNo': shlok,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Port of removeBookmark
  Future<void> removeBookmark(String chapter, String shlok) async {
    final db = await instance.database;
    await db.delete(
      'bmarks',
      where: 'bmarkLabel = ?',
      whereArgs: ['$chapter:$shlok'],
    );
  }

  // Port of getAllBookmarks
  Future<List<Bookmark>> getAllBookmarks() async {
    final db = await instance.database;
    // Explicitly select rowid as 'rowid' so it appears in the map
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT rowid, * FROM bmarks',
    );

    if (maps.isEmpty) {
      return [];
    }

    return List.generate(maps.length, (i) {
      return Bookmark.fromMap(maps[i]);
    });
  }
}
