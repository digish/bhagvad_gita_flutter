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

import 'package:shared_preferences/shared_preferences.dart';
import '../core/secrets_config.dart';

class AiQuestionBank {
  static const List<String> questions = SecretsConfig.questionBank;
  static const String _pointerKey = 'ai_question_pointer';
  static const String _shuffledOrderKey = 'ai_question_shuffled_order';

  /// Returns a random subset of questions with guaranteed no-repeats
  /// until the entire catalog has been shown.
  static Future<List<String>> getNonRepeatingRandomSuggestions({
    int count = 4,
  }) async {
    if (questions.isEmpty) return [];

    final prefs = await SharedPreferences.getInstance();

    // 1. Load the stored shuffled order
    List<int> shuffledIndices = [];
    String? storedOrder = prefs.getString(_shuffledOrderKey);
    if (storedOrder != null && storedOrder.isNotEmpty) {
      shuffledIndices = storedOrder
          .split(',')
          .map((e) => int.tryParse(e) ?? 0)
          .toList();
    }

    // 2. If we don't have a valid shuffled list (or it's the wrong size), generate a new one
    if (shuffledIndices.length != questions.length) {
      shuffledIndices = List.generate(questions.length, (i) => i)..shuffle();
      await prefs.setString(_shuffledOrderKey, shuffledIndices.join(','));
      await prefs.setInt(_pointerKey, 0); // Reset pointer
    }

    int pointer = prefs.getInt(_pointerKey) ?? 0;
    List<String> suggestions = [];

    // 3. Pull the requested amount of questions
    for (int i = 0; i < count; i++) {
      if (pointer >= shuffledIndices.length) {
        // We finished the entire list! Reshuffle and start over seamlessly
        shuffledIndices = List.generate(questions.length, (i) => i)..shuffle();
        await prefs.setString(_shuffledOrderKey, shuffledIndices.join(','));
        pointer = 0;
      }

      // Ensure index is valid safely
      int indexToFetch = shuffledIndices[pointer];
      if (indexToFetch >= 0 && indexToFetch < questions.length) {
        suggestions.add(questions[indexToFetch]);
      }
      pointer++;
    }

    // 4. Save the advanced pointer
    await prefs.setInt(_pointerKey, pointer);

    return suggestions;
  }
}
