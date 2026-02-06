import 'dart:convert';
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

// Configuration
// Use absolute path relative to project root
final String dbPath = p.join(
  Directory.current.path,
  'assets',
  'database',
  'geeta_v2.db',
);
const String outputPath = 'assets/gita_embeddings.json';
const String modelName = 'gemini-embedding-001'; // Correct model from list

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart tool/generate_embeddings.dart <GEMINI_API_KEY>');
    exit(1);
  }
  final apiKey = args[0];
  int? limit;
  if (args.length > 1) {
    limit = int.tryParse(args[1]);
    if (limit != null) {
      print('Running with LIMIT: $limit items');
    }
  }

  // 1.5 List Models to debug (Commented out after finding correct model)
  // 1.5 List Models to debug
  print('Listing available models...');
  await listAvailableModels(apiKey);

  // 1. Initialize SQLite FFI
  sqfliteFfiInit();
  final databaseFactory = databaseFactoryFfi;
  print('Opening database: $dbPath');
  // Check if file exists first
  if (!File(dbPath).existsSync()) {
    print('ERROR: Database file not found at $dbPath');
    exit(1);
  }

  final db = await databaseFactory.openDatabase(dbPath);

  // 3. Fetch English Meaning (Bhavarth) & Text
  print('Fetching shlokas...');
  final results = await db.rawQuery('''
    SELECT m.id, m.chapter_no, m.shloka_no, t.bhavarth, s.shloka_text
    FROM master_shlokas m
    JOIN translations t ON m.id = t.shloka_id AND t.language_code = 'en'
    JOIN shloka_scripts s ON m.id = s.shloka_id AND s.script_code = 'en'
    ORDER BY CAST(m.chapter_no AS INTEGER), CAST(m.shloka_no AS INTEGER)
  ''');

  print('Found ${results.length} shlokas to embed.');

  // 4. Initialize Gemini
  final model = GenerativeModel(model: modelName, apiKey: apiKey);

  // 5. Generate Embeddings (Batching if needed, but doing 1-by-1 for safety/simplicity first)
  List<Map<String, dynamic>> outputData = [];

  // Load existing data if available (Resumability)
  final outputFile = File(outputPath);
  if (outputFile.existsSync()) {
    try {
      final existingJson = await outputFile.readAsString();
      if (existingJson.isNotEmpty) {
        final List<dynamic> loaded = jsonDecode(existingJson);
        outputData = loaded.cast<Map<String, dynamic>>();
        print('Loaded ${outputData.length} existing embeddings. Resuming...');
      }
    } catch (e) {
      print('Error loading existing file: $e. Starting fresh.');
    }
  }

  // Set of existing IDs for fast lookup
  final existingIds = outputData.map((e) => e['id'].toString()).toSet();

  int count = 0;
  int newlyAdded = 0;

  for (var row in results) {
    count++;
    final id = row['id'].toString();

    // SKIP if already exists
    if (existingIds.contains(id)) {
      if (count % 50 == 0) {
        stdout.write('\rSkipping cached: $count / ${results.length}');
      }
      continue;
    }

    final textToEmbed = row['bhavarth'] as String;

    // Combine Chapter/Verse context with meaning for better retrieval
    final content =
        "Chapter ${row['chapter_no']} Shloka ${row['shloka_no']}. $textToEmbed";

    try {
      stdout.write('\rGenerating $id: $count / ${results.length}');

      final response = await model.embedContent(Content.text(content));
      final vector = response.embedding.values;

      outputData.add({'id': id, 'vector': vector});
      existingIds.add(id); // Mark as done
      newlyAdded++;

      // INCREMENTAL SAVE (Every 10 items)
      if (newlyAdded % 10 == 0) {
        await outputFile.writeAsString(jsonEncode(outputData));
      }

      // Check Limit
      if (limit != null && newlyAdded >= limit) {
        print('\nReached limit of $limit items. Stopping.');
        break;
      }

      // Rate limit sleep
      await Future.delayed(
        Duration(milliseconds: 100),
      ); // Increased delay for safety
    } catch (e) {
      print('\nDataset Error at ID $id: $e');
      // Continue to next, don't crash entire script
    }
  }

  // Final Save
  print('\nSaving final output to $outputPath...');
  await outputFile.writeAsString(jsonEncode(outputData));

  print('Done! Total embeddings: ${outputData.length}.');
  await db.close();
}

Future<void> listAvailableModels(String apiKey) async {
  try {
    final client = HttpClient();
    final request = await client.getUrl(
      Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey',
      ),
    );
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode == 200) {
      final json = jsonDecode(body);
      final models = json['models'] as List;
      print('\n--- AVAILABLE MODELS ---');
      for (var m in models) {
        final name = m['name'];
        final supportedMethods = m['supportedGenerationMethods'] as List?;
        final methodsStr = supportedMethods?.join(', ') ?? 'Unknown';
        print('Model: $name');
        print('  Methods: $methodsStr');
      }
      print('------------------------\n');
    } else {
      print('Failed to list models: ${response.statusCode} $body');
    }
  } catch (e) {
    print('Error listing models: $e');
  }
}
