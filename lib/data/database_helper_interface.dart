import '../models/shloka_result.dart';
import '../models/word_result.dart';

// This abstract class defines a "contract" for our database helpers.
// Both the mobile and web versions will adhere to this contract.
abstract class DatabaseHelperInterface {
  Future<List<ShlokaResult>> getShlokasByChapter(String chapter);
  Future<List<ShlokaResult>> getAllShlokas();
  Future<List<ShlokaResult>> searchShlokas(String query);
  Future<List<WordResult>> searchWords(String query);
  Future<Map<String, dynamic>?> getWordDefinition(String query);
}
