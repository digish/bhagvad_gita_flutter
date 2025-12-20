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

import '../models/shloka_result.dart';
import '../models/word_result.dart';

// This abstract class defines a "contract" for our database helpers.
// Both the mobile and web versions will adhere to this contract.
abstract class DatabaseHelperInterface {
  Future<List<ShlokaResult>> getShlokasByChapter(
    int chapter, {
    String language = 'hi',
    String script = 'dev',
  });
  Future<List<ShlokaResult>> getAllShlokas({
    String language = 'hi',
    String script = 'dev',
  });
  Future<List<ShlokaResult>> searchShlokas(
    String query, {
    String language = 'hi',
    String script = 'dev',
  });
  Future<List<WordResult>> searchWords(String query);
  Future<Map<String, dynamic>?> getWordDefinition(String query);
  Future<ShlokaResult?> getRandomShloka({
    String language = 'hi',
    String script = 'dev',
  });
  Future<ShlokaResult?> getShlokaById(
    String id, {
    String language = 'hi',
    String script = 'dev',
  });

  /// Fetches all embeddings for AI Search
  Future<List<Map<String, dynamic>>> getEmbeddings();
}
