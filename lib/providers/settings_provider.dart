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

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/predefined_lists_data.dart';
import '../models/soul_status.dart';
import '../services/notification_service.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _fontSizeKey = 'fontSize';
  static const String _showBackgroundKey = 'showBackground';
  static const double _defaultFontSize = 20.0;
  static const bool _defaultShowBackground = true;

  double _fontSize = _defaultFontSize;
  double get fontSize => _fontSize;

  bool _showBackground = _defaultShowBackground;
  bool get showBackground => _showBackground;

  String? _customAiApiKey;
  String? get customAiApiKey => _customAiApiKey;

  bool _hasUsedAskAi = false;
  bool get hasUsedAskAi => _hasUsedAskAi;

  int _dailyStreak = 0;
  int get dailyStreak => _dailyStreak;

  String? _lastSoulStatusMessage;
  String? get lastSoulStatusMessage => _lastSoulStatusMessage;

  bool _streakSystemEnabled = true;
  bool get streakSystemEnabled => _streakSystemEnabled;

  // --- Peak Achievement Tracking ---
  int _peakStreakCount = 0;
  int get peakStreakCount => _peakStreakCount;

  int _peakAchievementCount = 0;
  int get peakAchievementCount => _peakAchievementCount;

  SoulStatus get peakMilestone {
    // Find the milestone for the peak streak
    for (int i = SoulStatus.allMilestones.length - 1; i >= 0; i--) {
      if (_peakStreakCount >= SoulStatus.allMilestones[i].threshold) {
        return SoulStatus.allMilestones[i];
      }
    }
    return SoulStatus.allMilestones[0]; // Default to first milestone
  }

  // --- Automatic Lifeline System ---
  int _availableLifelines = 0;
  int get availableLifelines => _availableLifelines;

  int _lastMilestoneThreshold =
      0; // Track last milestone that granted lifelines

  // --- Daily Reminders ---
  bool _reminderEnabled = false;
  bool get reminderEnabled => _reminderEnabled;

  TimeOfDay _reminderTime = const TimeOfDay(
    hour: 20,
    minute: 30,
  ); // Default 8:30 PM
  TimeOfDay get reminderTime => _reminderTime;

  bool _reminderNudgeDismissed = false;
  bool get reminderNudgeDismissed => _reminderNudgeDismissed;

  SettingsProvider() {
    _loadSettings();
  }

  /* 
   * _loadSettings logic moved to the bottom of the class 
   * to group all initialization together.
   */

  Future<void> setFontSize(double newSize) async {
    _fontSize = newSize;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    // Save the new font size to persistent storage.
    await prefs.setDouble(_fontSizeKey, newSize);
  }

  Future<void> setShowBackground(bool newValue) async {
    _showBackground = newValue;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    // Save the new background visibility to persistent storage.
    await prefs.setBool(_showBackgroundKey, newValue);
  }

  Future<void> setCustomAiApiKey(String key) async {
    _customAiApiKey = key;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_ai_api_key', key);
  }

  Future<void> clearCustomAiApiKey() async {
    _customAiApiKey = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('custom_ai_api_key');
  }

  Future<void> markAskAiUsed() async {
    if (_hasUsedAskAi) return;
    _hasUsedAskAi = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_used_ask_ai', true);
  }

  /* DEPRECATED: Replaced by CreditProvider */
  // Future<void> incrementAiQueryCount() async {}

  /* DEPRECATED: Replaced by CreditProvider.addCredits() */
  // Future<void> grantAdReward() async {}

  // --- Language & Script Support ---
  static const String _languageKey = 'language'; // 'hi' or 'en'
  static const String _scriptKey = 'script'; // 'dev', 'gu', 'te', 'ro', etc.

  static const String _defaultLanguage = 'hi';
  static const String _defaultScript = 'dev';

  String _language = _defaultLanguage; // Translation Language (Bhavarth)
  String get language => _language;

  String _script = _defaultScript; // Display Script (Lipi)
  String get script => _script;

  bool _showClassicalCommentaries = false;
  bool get showClassicalCommentaries => _showClassicalCommentaries;

  Future<void> setLanguage(String newLanguage) async {
    if (_language == newLanguage) return;
    _language = newLanguage;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, newLanguage);
  }

  Future<void> setScript(String newScript) async {
    if (_script == newScript) return;
    _script = newScript;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_scriptKey, newScript);
  }

  Future<void> setShowClassicalCommentaries(bool value) async {
    if (_showClassicalCommentaries == value) return;
    _showClassicalCommentaries = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_classical_commentaries', value);
  }

  // Helper List for Scripts with their Display Names
  static final Map<String, String> supportedScripts = {
    'dev': 'Devanagari (देवनागरी)',
    'en':
        'Roman (ABCD)', // Using 'en' here to map to 'en' in shloka_scripts (Roman) and 'ro' in translations
    'gu': 'Gujarati (ગુજરાતી)',
    'te': 'Telugu (తెలుగు)',
    'kn': 'Kannada (ಕನ್ನಡ)',
    'ta': 'Tamil (தமிழ்)',
    'bn': 'Bengali (বাংলা)',
  };
  // Note on Roman:
  // In DB: Shloka uses 'en', Translations/Commentaries use 'ro'.
  // We will store 'en' as the script key for Roman in settings for consistency with "Roman", and map it in helper.

  // Helper List for Languages
  static const Map<String, String> supportedLanguages = {
    'hi': 'Hindi (हिन्दी)',
    'en': 'English',
  };

  // --- Random Shloka Settings ---
  bool _showRandomShloka = true;
  bool get showRandomShloka => _showRandomShloka;

  // Ensure -1 is default if nothing is saved
  Set<int> _randomShlokaSources = {-1}; // -1 for Entire Gita

  // Getter for the set of sources
  Set<int> get randomShlokaSources => _randomShlokaSources;

  // Helper for single source compatibility (returns first or -1)
  int get randomShlokaSource =>
      _randomShlokaSources.isNotEmpty ? _randomShlokaSources.first : -1;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSize = prefs.getDouble(_fontSizeKey) ?? _defaultFontSize;
    _showBackground =
        prefs.getBool(_showBackgroundKey) ?? _defaultShowBackground;
    _showClassicalCommentaries =
        prefs.getBool('show_classical_commentaries') ?? false;

    // Validate Language
    String loadedLanguage = prefs.getString(_languageKey) ?? _defaultLanguage;
    if (!supportedLanguages.containsKey(loadedLanguage)) {
      loadedLanguage = _defaultLanguage;
    }
    _language = loadedLanguage;

    // Validate Script
    String loadedScript = prefs.getString(_scriptKey) ?? _defaultScript;
    if (!supportedScripts.containsKey(loadedScript)) {
      loadedScript = _defaultScript;
    }
    _script = loadedScript;

    _showRandomShloka = prefs.getBool('show_random_shloka') ?? true;

    // Load multiple sources
    final sourcesString = prefs.getString('random_shloka_sources');
    if (sourcesString != null && sourcesString.isNotEmpty) {
      _randomShlokaSources = sourcesString
          .split(',')
          .map((e) => int.tryParse(e))
          .where((e) => e != null)
          .cast<int>()
          .toSet();
    } else {
      // Migration: Check for old single source
      final oldSource = prefs.getInt('random_shloka_source');
      if (oldSource != null) {
        _randomShlokaSources = {oldSource};
      } else {
        // Default for new users: All Curated Lists
        _randomShlokaSources = PredefinedListsData.lists
            .map((l) => l.id)
            .toSet();
      }
    }

    // Load Theme Mode
    final themeString = prefs.getString('theme_mode');
    if (themeString != null) {
      if (themeString == 'light') {
        _themeMode = ThemeMode.light;
      } else if (themeString == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }
    } else {
      _themeMode = ThemeMode.system;
    }

    _customAiApiKey = prefs.getString('custom_ai_api_key');
    _hasUsedAskAi = prefs.getBool('has_used_ask_ai') ?? false;
    _lastSoulStatusMessage = prefs.getString('last_soul_status_message');
    _streakSystemEnabled = prefs.getBool('streak_system_enabled') ?? true;

    // Load Reminder Settings
    _reminderEnabled = prefs.getBool('reminder_enabled') ?? false;
    final hour = prefs.getInt('reminder_hour') ?? 20;
    final minute = prefs.getInt('reminder_minute') ?? 30;
    _reminderTime = TimeOfDay(hour: hour, minute: minute);

    _reminderNudgeDismissed =
        prefs.getBool('reminder_nudge_dismissed') ?? false;

    // Load Peak Achievement Data
    _peakStreakCount = prefs.getInt('peak_streak_count') ?? 0;
    _peakAchievementCount = prefs.getInt('peak_achievement_count') ?? 0;

    // Load Lifeline Data
    _availableLifelines = prefs.getInt('available_lifelines') ?? 0;
    _lastMilestoneThreshold = prefs.getInt('last_milestone_threshold') ?? 0;

    // --- Update Daily Streak ---
    await _updateStreak(prefs);

    notifyListeners();
  }

  Future<void> _updateStreak(SharedPreferences prefs) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastOpened = prefs.getString('last_opened_date');
    final currentStreak = prefs.getInt('daily_streak') ?? 0;

    if (lastOpened == null) {
      // First time user
      _dailyStreak = 1;
      await prefs.setString('last_opened_date', today);
      await prefs.setInt('daily_streak', 1);
      return;
    }

    if (lastOpened == today) {
      // Already opened today
      _dailyStreak = currentStreak;
      return;
    }

    final lastDate = DateTime.parse(lastOpened);
    final difference = DateTime.now().difference(lastDate).inDays;

    if (difference == 1) {
      // Consecutive day!
      _dailyStreak = currentStreak + 1;
    } else {
      // Missed day(s)!
      if (_availableLifelines > 0) {
        // Use a lifeline - preserve streak
        _availableLifelines--;
        _dailyStreak = currentStreak; // Keep current streak

        await prefs.setInt('available_lifelines', _availableLifelines);

        _lastSoulStatusMessage =
            '🛡️ Lifeline used! Your streak is protected. $_availableLifelines ${_availableLifelines == 1 ? 'lifeline' : 'lifelines'} remaining.';
        await prefs.setString(
          'last_soul_status_message',
          _lastSoulStatusMessage!,
        );
      } else {
        // No lifelines - streak breaks
        if (currentStreak >= 3) {
          _lastSoulStatusMessage = SoulStatus.getDropMessage(currentStreak);
          await prefs.setString(
            'last_soul_status_message',
            _lastSoulStatusMessage!,
          );
        }
        _dailyStreak = 1;
        _lastMilestoneThreshold = 0;
        await prefs.setInt('last_milestone_threshold', 0);
      }
    }

    await prefs.setString('last_opened_date', today);
    await prefs.setInt('daily_streak', _dailyStreak);

    // Track peak achievements (Milestone-aware)
    final currentStatus = _getCurrentMilestone(_dailyStreak);
    final peakStatus = _getCurrentMilestone(_peakStreakCount);

    if (_dailyStreak > _peakStreakCount) {
      // New absolute record!
      if (currentStatus.threshold > peakStatus.threshold) {
        // Reached a brand new higher milestone category! Reset count to 1
        _peakAchievementCount = 1;
        await prefs.setInt('peak_achievement_count', 1);
      }
      // Update peak streak
      _peakStreakCount = _dailyStreak;
      await prefs.setInt('peak_streak_count', _peakStreakCount);
    } else if (_dailyStreak == currentStatus.threshold &&
        currentStatus.threshold == peakStatus.threshold &&
        _dailyStreak > 0) {
      // User just reached the START of their peak milestone category again!
      if (difference == 1) {
        // Only increment if advancing consecutively to the threshold
        _peakAchievementCount++;
        await prefs.setInt('peak_achievement_count', _peakAchievementCount);
      }
    }

    // Grant lifelines on milestone reach (cap at 2)
    if (currentStatus.threshold > _lastMilestoneThreshold &&
        currentStatus.threshold > 0) {
      // New milestone reached! Set lifelines to 2 (refill, don't stack)
      _availableLifelines = 2;
      _lastMilestoneThreshold = currentStatus.threshold;

      await prefs.setInt('available_lifelines', _availableLifelines);
      await prefs.setInt('last_milestone_threshold', _lastMilestoneThreshold);

      // Set celebration message
      _lastSoulStatusMessage =
          '${currentStatus.title} achieved! 🎉 You have 2 lifelines to protect your streak!';
      await prefs.setString(
        'last_soul_status_message',
        _lastSoulStatusMessage!,
      );
    }
  }

  // Helper method to get current milestone for a given streak
  SoulStatus _getCurrentMilestone(int streak) {
    for (int i = SoulStatus.allMilestones.length - 1; i >= 0; i--) {
      if (streak >= SoulStatus.allMilestones[i].threshold) {
        return SoulStatus.allMilestones[i];
      }
    }
    return SoulStatus.allMilestones[0];
  }

  // DEBUG ONLY: Simulate advancing to the next day
  Future<void> debugAdvanceDay() async {
    final prefs = await SharedPreferences.getInstance();

    // Set last_opened_date to yesterday to simulate a day passing
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayString = yesterday.toIso8601String().split('T')[0];
    await prefs.setString('last_opened_date', yesterdayString);

    // Trigger the streak update logic
    await _updateStreak(prefs);

    notifyListeners();
  }

  // DEBUG ONLY: Simulate missing a day (direct simulation, not date-based)
  Future<void> debugMissDays(int daysToMiss) async {
    final prefs = await SharedPreferences.getInstance();

    // Directly simulate the miss logic for each day
    for (int i = 0; i < daysToMiss; i++) {
      if (_availableLifelines > 0) {
        // Use a lifeline - preserve streak
        _availableLifelines--;
        await prefs.setInt('available_lifelines', _availableLifelines);

        _lastSoulStatusMessage =
            '🛡️ Lifeline used! Your streak is protected. $_availableLifelines ${_availableLifelines == 1 ? 'lifeline' : 'lifelines'} remaining.';
        await prefs.setString(
          'last_soul_status_message',
          _lastSoulStatusMessage!,
        );
      } else {
        // No lifelines - streak breaks
        if (_dailyStreak >= 3) {
          _lastSoulStatusMessage = SoulStatus.getDropMessage(_dailyStreak);
          await prefs.setString(
            'last_soul_status_message',
            _lastSoulStatusMessage!,
          );
        }
        _dailyStreak = 1;
        _lastMilestoneThreshold = 0;
        await prefs.setInt('daily_streak', _dailyStreak);
        await prefs.setInt('last_milestone_threshold', 0);
        break; // Stop after streak breaks
      }
    }

    notifyListeners();
  }

  Future<void> clearSoulStatusMessage() async {
    _lastSoulStatusMessage = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_soul_status_message');
  }

  Future<void> setShowRandomShloka(bool value) async {
    if (_showRandomShloka == value) return;
    _showRandomShloka = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_random_shloka', value);
  }

  // --- Multi-select Logic ---

  Future<void> setRandomShlokaSources(Set<int> sources) async {
    _randomShlokaSources = sources;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'random_shloka_sources',
      sources.join(','),
    ); // Save as CSV
    notifyListeners();
  }

  Future<void> toggleRandomShlokaSource(int listId) async {
    final currentSources = Set<int>.from(_randomShlokaSources);

    // If 'Entire Gita' (-1) is currently selected and we select something else,
    // we might want to unselect -1, or vice versa.
    // Logic:
    // 1. If listId is -1: Clear everything else, set only {-1}.
    // 2. If listId is NOT -1:
    //    - If -1 was present, remove it.
    //    - Toggle listId.
    //    - If resulting set is empty, fallback to {-1}.

    if (listId == -1) {
      if (currentSources.contains(-1)) {
        // Tapping -1 when it's already on -> Do nothing? Or allow unselect?
        // Let's enforce at least one selection. Only allow unselect if we want to default to something else?
        // Better: Tapping "Entire Gita" selects it and clears others.
        // If it's already strictly {-1}, do nothing.
        if (currentSources.length == 1 && currentSources.contains(-1)) {
          return;
        }
        currentSources.clear();
        currentSources.add(-1);
      } else {
        // Activate Entire Gita, clear others
        currentSources.clear();
        currentSources.add(-1);
      }
    } else {
      // Toggling a specific list
      if (currentSources.contains(-1)) {
        currentSources.remove(-1); // Remove "Entire Gita" automatically
      }

      if (currentSources.contains(listId)) {
        currentSources.remove(listId);
      } else {
        currentSources.add(listId);
      }

      // If nothing left, revert to Entire Gita
      if (currentSources.isEmpty) {
        currentSources.add(-1);
      }
    }

    await setRandomShlokaSources(currentSources);
  }

  // --- Theme Mode Settings ---
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'theme_mode',
      mode.name,
    ); // Saves 'system', 'light', 'dark'
  }

  // --- Daily Reminder Logic ---

  Future<bool> setReminderEnabled(bool enabled) async {
    if (enabled) {
      // Trigger permission request at the point of enabling
      final granted = await NotificationService.instance.requestPermissions();
      if (!granted) {
        // If user denied, we don't enable it but we notify listeners to update UI
        _reminderEnabled = false;
        notifyListeners();
        return false;
      }
    }

    _reminderEnabled = enabled;
    if (enabled) {
      _reminderNudgeDismissed = false; // Reset dismissal if they enable it
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_enabled', enabled);
    if (enabled) {
      await prefs.setBool('reminder_nudge_dismissed', false);
    }

    if (enabled) {
      await _scheduleReminder();
    } else {
      await NotificationService.instance.cancelAll();
    }
    return true;
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    _reminderTime = time;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminder_hour', time.hour);
    await prefs.setInt('reminder_minute', time.minute);

    if (_reminderEnabled) {
      await _scheduleReminder();
    }
  }

  Future<void> setStreakSystemEnabled(bool newValue) async {
    _streakSystemEnabled = newValue;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('streak_system_enabled', newValue);
  }

  Future<void> _scheduleReminder() async {
    await NotificationService.instance.scheduleDailyReminder(
      hour: _reminderTime.hour,
      minute: _reminderTime.minute,
    );
  }

  // Legacy/Compatibility method for single select (used by UI if not fully updated yet or for simple calls)
  Future<void> setRandomShlokaSource(int listId) async {
    // Treat as "Select Only This"
    await setRandomShlokaSources({listId});
  }

  Future<void> dismissReminderNudge() async {
    _reminderNudgeDismissed = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_nudge_dismissed', true);
  }
}
