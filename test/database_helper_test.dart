import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bhagvadgeeta/models/shloka_result.dart';
import 'package:bhagvadgeeta/models/word_result.dart';

void main() {
  // Initialize FFI for desktop testing
  sqfliteFfiInit();
  
  // Use the FFI database factory
  databaseFactory = databaseFactoryFfi;

  // This is a late-initialized variable for our test database
  late Database db;

  // This block runs once before all tests
  setUpAll(() async {
    // Define the path for our temporary test database
    final testDbPath = path.join(Directory.current.path, 'test', 'test_geeta');

    // Make sure the directory exists
    await Directory(path.dirname(testDbPath)).create(recursive: true);

    // If a previous test run failed, delete the old test DB
    final dbFile = File(testDbPath);
    if (await dbFile.exists()) {
      await dbFile.delete();
    }

    // Read the bytes from your asset database
    final assetBytes = await File('assets/database/geeta').readAsBytes();

    // Write the bytes to the temporary test database file
    await dbFile.writeAsBytes(assetBytes, flush: true);

    // Open the newly created test database
    db = await openDatabase(testDbPath);
  });

  // This block runs once after all tests are complete
  tearDownAll(() async {
    await db.close();
  });

test('Print first 5 shlokas for manual verification', () async {
  // Act: Fetch the first 5 rows from the 'geeta' table
  final List<Map<String, dynamic>> maps = await db.rawQuery(
    "SELECT rowid, chapterNo, shlokNo, shlok, bhavarth FROM geeta LIMIT 5",
  );

  // Assert & Print
  expect(maps.length, 5); // Ensure we got 5 rows

  print("\n--- First 5 Shlokas from the database ---");
  for (final row in maps) {
    print("-----------------------------------------");
    print("  ID: ${row['rowid']}");
    print("  Location: Chapter ${row['chapterNo']}, Shloka ${row['shlokNo']}");
    print("  Shlok: ${row['shlok']}");
    print("  Bhavarth: ${row['bhavarth']}");
  }
  print("-----------------------------------------\n");
});

test('Search for word "arjun" should return suggestions', () async {
  // Act: Call the searchWords method
  final List<Map<String, dynamic>> maps = await db.rawQuery(
      "SELECT rowid, word, definition FROM words WHERE word LIKE ?",
      ['%arjun%'], // A common search fragment
  );
  // We need to import the WordResult model for this
  final results = maps.map((map) => WordResult.fromMap(map)).toList();

  // Assert
  expect(results, isNotEmpty); // We expect to find at least one match
  expect(results.first, isA<WordResult>()); // Verify the type is correct

  print('Found ${results.length} word suggestions for "arjun"');
  // Optional: Print the first result to see the data
  if (results.isNotEmpty) {
    print('First suggestion: ${results.first.word} -> ${results.first.definition}');
  }
});

  test('Database is valid and geeta table exists', () async {
    final result = await db.rawQuery("SELECT count(*) FROM geeta");
    // If the query runs without error and returns a result, the table exists.
    expect(result.first.values.first, greaterThan(0));
  });

  test('Search for "karma" should return shlokas', () async {
    // Act: Query the test database directly
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      "SELECT rowid, * FROM geeta WHERE shlok LIKE ?",
      ['%karma%'],
    );
    final results = maps.map((map) => ShlokaResult.fromMap(map)).toList();

    // Assert
    expect(results, isNotEmpty);
    expect(results.first, isA<ShlokaResult>());
    print('Found ${results.length} shlokas for "karma"');
  });

  test('Search for chapter 1 should return shlokas', () async {
    // Act
    final List<Map<String, dynamic>> maps = await db.rawQuery(
        "SELECT rowid, * FROM geeta WHERE chapterNo = ?",
        ['1'],
    );
    final results = maps.map((map) => ShlokaResult.fromMap(map)).toList();
    
    // Assert
    expect(results.length, greaterThan(40));
  });
}