import '../core/secrets_config.dart';

/// Service that provides 365 unique daily motivational messages from the Bhagavad Gita.
/// Messages rotate based on the day of the year (1-365).
class DailyMessageService {
  /// Get the motivational message for a specific day of the year.
  /// [dayOfYear] should be between 1 and 365 (366 for leap years, which wraps to day 365).
  static String getMessageForDay(int dayOfYear) {
    // Handle leap years by wrapping day 366 to day 365
    final index = (dayOfYear - 1).clamp(0, 364);
    return _messages[index];
  }

  /// Get today's motivational message based on current date.
  static String getTodaysMessage() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
    return getMessageForDay(dayOfYear);
  }

  /// 365 unique motivational messages from the Bhagavad Gita.
  /// Organized by themes: Karma Yoga, Bhakti, Jnana, Dharma, Discipline, etc.
  static final List<String> _messages = SecretsConfig.dailyMessages;
}
