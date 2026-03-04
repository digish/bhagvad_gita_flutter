import '../core/secrets_config.dart';

import 'package:shared_preferences/shared_preferences.dart';

/// Service that provides 365 unique daily motivational messages from the Bhagavad Gita.
/// Messages rotate sequentially based on user progress.
class DailyMessageService {
  static const String _messageIndexKey = 'daily_message_index';

  /// Fetch the next 30 sequential messages starting from the user's current progress.
  /// This doesn't actually advance the permanent pointer, so they can be securely
  /// laid out in the notification queue.
  static Future<List<String>> getNextSequentialMessages(int count) async {
    final prefs = await SharedPreferences.getInstance();
    final currentIndex = prefs.getInt(_messageIndexKey) ?? 0;

    List<String> nextMessages = [];
    for (int i = 0; i < count; i++) {
      int fetchIndex = (currentIndex + i) % _messages.length;
      nextMessages.add(_messages[fetchIndex]);
    }

    return nextMessages;
  }

  /// Get today's motivational message based on current progress.
  /// Note: The actual sequential advancement logic will be handled
  /// during app launch in SettingsProvider when a day transition occurs.
  static Future<String> getTodaysMessage() async {
    final prefs = await SharedPreferences.getInstance();
    final currentIndex = prefs.getInt(_messageIndexKey) ?? 0;
    return _messages[currentIndex % _messages.length];
  }

  /// Advance the message pointer. Call this when a new day starts.
  static Future<void> advanceDay() async {
    final prefs = await SharedPreferences.getInstance();
    final currentIndex = prefs.getInt(_messageIndexKey) ?? 0;
    await prefs.setInt(_messageIndexKey, (currentIndex + 1) % _messages.length);
  }

  /// 365 unique motivational messages from the Bhagavad Gita.
  /// Organized by themes: Karma Yoga, Bhakti, Jnana, Dharma, Discipline, etc.
  static final List<String> _messages = SecretsConfig.dailyMessages;
}
