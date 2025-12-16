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
import '../models/shloka_list.dart';

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
      version: 3,
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

    // Create new tables for Lists feature
    await _createListTables(db);

    // If we are creating fresh, let's add a default "Bookmarks" list
    await db.insert('lists', {
      'name': 'Bookmarks',
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> _createListTables(Database db) async {
    await db.execute('''
      CREATE TABLE lists(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        created_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE list_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        list_id INTEGER,
        chapter_no TEXT,
        shlok_no TEXT,
        created_at INTEGER,
        FOREIGN KEY(list_id) REFERENCES lists(id) ON DELETE CASCADE
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

    if (oldVersion < 3) {
      // Create new tables
      await _createListTables(db);

      // Create default "Bookmarks" list
      int listId = await db.insert('lists', {
        'name': 'Bookmarks',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });

      // Migrate existing bookmarks to this list
      try {
        List<Map<String, dynamic>> existing = await db.rawQuery(
          'SELECT * FROM bmarks',
        );
        for (var row in existing) {
          await db.insert('list_items', {
            'list_id': listId,
            'chapter_no': row['chapterNo'],
            'shlok_no': row['shlokNo'],
            'created_at': DateTime.now().millisecondsSinceEpoch,
          });
        }
      } catch (e) {
        // Ignore if bmarks issues
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

  // --- List CRUD ---

  Future<int> createList(String name) async {
    final db = await instance.database;
    return await db.insert('lists', {
      'name': name,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<ShlokaList>> getAllLists() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'lists',
      orderBy: 'created_at ASC',
    );
    return List.generate(maps.length, (i) {
      return ShlokaList.fromMap(maps[i]);
    });
  }

  Future<void> deleteList(int id) async {
    final db = await instance.database;
    await db.delete('lists', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> renameList(int id, String newName) async {
    final db = await instance.database;
    await db.update(
      'lists',
      {'name': newName},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- List Item CRUD ---

  Future<void> addShlokaToList(int listId, String chapter, String shlok) async {
    final db = await instance.database;
    // Check if already exists in this list
    final existing = await db.query(
      'list_items',
      where: 'list_id = ? AND chapter_no = ? AND shlok_no = ?',
      whereArgs: [listId, chapter, shlok],
    );

    if (existing.isEmpty) {
      await db.insert('list_items', {
        'list_id': listId,
        'chapter_no': chapter,
        'shlok_no': shlok,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  Future<void> removeShlokaFromList(
    int listId,
    String chapter,
    String shlok,
  ) async {
    final db = await instance.database;
    await db.delete(
      'list_items',
      where: 'list_id = ? AND chapter_no = ? AND shlok_no = ?',
      whereArgs: [listId, chapter, shlok],
    );
  }

  Future<List<int>> getListsForShloka(String chapter, String shlok) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'list_items',
      columns: ['list_id'],
      where: 'chapter_no = ? AND shlok_no = ?',
      whereArgs: [chapter, shlok],
    );
    return maps.map((e) => e['list_id'] as int).toList();
  }

  // Get all shlokas for a specific list
  Future<List<Map<String, dynamic>>> getShlokasInList(int listId) async {
    final db = await instance.database;
    return await db.query(
      'list_items',
      where: 'list_id = ?',
      whereArgs: [listId],
      orderBy: 'created_at DESC', // Newest first
    );
  }

  Future<List<Map<String, dynamic>>> getAllListItems() async {
    final db = await instance.database;
    return await db.query('list_items');
  }
}
