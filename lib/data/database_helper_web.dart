import 'database_helper_interface.dart';
import '../models/shloka_result.dart';
import '../models/word_result.dart';

// Web Support Stub
// Since web is not a priority, we provide a valid compilation stub that errors at runtime if used.
class DatabaseHelperImpl implements DatabaseHelperInterface {
  static Future<DatabaseHelperImpl> create() async {
    throw UnimplementedError("Web database not implemented.");
  }

  @override
  Future<List<ShlokaResult>> getAllShlokas({
    String language = 'hi',
    String script = 'dev',
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<Map<String, dynamic>>> getEmbeddings() {
    throw UnimplementedError();
  }

  @override
  Future<ShlokaResult?> getRandomShloka({
    String language = 'hi',
    String script = 'dev',
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ShlokaResult?> getShlokaById(
    String id, {
    String language = 'hi',
    String script = 'dev',
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<ShlokaResult>> getShlokasByChapter(
    int chapter, {
    String language = 'hi',
    String script = 'dev',
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<WordResult>> searchWords(String query) {
    throw UnimplementedError();
  }

  @override
  Future<List<ShlokaResult>> searchShlokas(
    String query, {
    String language = 'hi',
    String script = 'dev',
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>?> getWordDefinition(String query) {
    throw UnimplementedError();
  }
}

Future<DatabaseHelperInterface> getInitializedDatabaseHelper() async {
  return await DatabaseHelperImpl.create();
}
