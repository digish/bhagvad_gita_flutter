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
import '../services/daily_message_service.dart';
import '../services/analytics_service.dart';

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

  bool _hasUsedExploreMore = false;
  bool get hasUsedExploreMore => _hasUsedExploreMore;

  int _dailyStreak = 0;
  int get dailyStreak => _dailyStreak;

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

  // Legacy flag — migrated into showSacredSutraQuote on load.
  bool _sacredSutraPromoDismissed = false;

  // --- Daily Journey home cards ---
  bool _showSacredSutraQuote = true;
  bool get showSacredSutraQuote => _showSacredSutraQuote;

  bool _showTodaysAction = true;
  bool get showTodaysAction => _showTodaysAction;

  bool _showTodaysAiQuestion = true;
  bool get showTodaysAiQuestion => _showTodaysAiQuestion;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

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
    AnalyticsService.instance.logConfigChange(
      setting: 'font_size',
      value: newSize.round().toString(),
    );
  }

  Future<void> setShowBackground(bool newValue) async {
    _showBackground = newValue;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    // Save the new background visibility to persistent storage.
    await prefs.setBool(_showBackgroundKey, newValue);
    AnalyticsService.instance.logConfigChange(
      setting: 'show_background',
      value: newValue.toString(),
    );
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

  Future<void> markExploreMoreUsed() async {
    if (_hasUsedExploreMore) return;
    _hasUsedExploreMore = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_used_explore_more', true);
  }

  /* DEPRECATED: Replaced by CreditProvider */
  // Future<void> incrementAiQueryCount() async {}

  /* DEPRECATED: Replaced by CreditProvider.addCredits() */
  // Future<void> grantAdReward() async {}

  bool _hasSeenLanguagePrompt = false;
  bool get hasSeenLanguagePrompt => _hasSeenLanguagePrompt;

  Future<void> markLanguagePromptSeen() async {
    if (_hasSeenLanguagePrompt) return;
    _hasSeenLanguagePrompt = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_language_prompt', true);
  }

  // --- Language & Script Support ---
  static const String _languageKey = 'language'; // 'hi' or 'en'
  static const String _scriptKey = 'script'; // 'dev', 'gu', 'te', 'ro', etc.
  static const String _forceSanskritShlokaKey = 'force_sanskrit_shloka';

  static const String _defaultLanguage = 'en';
  static const String _defaultScript = 'en';

  String _language = _defaultLanguage; // Translation Language (Bhavarth)
  String get language => _language;

  String _script = _defaultScript; // Display Script (Lipi)
  String get script => _script;

  /// When true, mool shloka & anvay always use Devanagari ('dev').
  /// App language/script still controls translation (bhavarth) and UI labels.
  bool _forceSanskritShloka = false;
  bool get forceSanskritShloka => _forceSanskritShloka;

  /// Script used when loading shloka/anvay text from the DB.
  String get shlokaScript => _forceSanskritShloka ? 'dev' : _script;

  bool _showClassicalCommentaries = false;
  bool get showClassicalCommentaries => _showClassicalCommentaries;

  Future<void> setLanguage(String newLanguage) async {
    if (_language == newLanguage) return;
    _language = newLanguage;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, newLanguage);
    AnalyticsService.instance.logConfigChange(
      setting: 'language',
      value: newLanguage,
    );
    AnalyticsService.instance.setUserConfig(language: newLanguage);
  }

  Future<void> setScript(String newScript) async {
    if (_script == newScript) return;
    _script = newScript;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_scriptKey, newScript);
    AnalyticsService.instance.logConfigChange(
      setting: 'script',
      value: newScript,
    );
    AnalyticsService.instance.setUserConfig(script: newScript);
  }

  Future<void> setForceSanskritShloka(bool value) async {
    if (_forceSanskritShloka == value) return;
    _forceSanskritShloka = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_forceSanskritShlokaKey, value);
    AnalyticsService.instance.logConfigChange(
      setting: 'force_sanskrit_shloka',
      value: value.toString(),
    );
    AnalyticsService.instance.setUserConfig(forceSanskritShloka: value);
  }

  Future<void> setShowClassicalCommentaries(bool value) async {
    if (_showClassicalCommentaries == value) return;
    _showClassicalCommentaries = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_classical_commentaries', value);
    AnalyticsService.instance.logConfigChange(
      setting: 'classical_commentaries',
      value: value.toString(),
    );
    AnalyticsService.instance.setUserConfig(showClassicalCommentaries: value);
  }

  // Helper List for Scripts with their Display Names
  static final Map<String, String> supportedScripts = {
    'dev': 'Hindi (हिन्दी)',
    'en': 'English',
    'gu': 'Gujarati (ગુજરાતી)',
    'te': 'Telugu (తెలుగు)',
    'kn': 'Kannada (ಕನ್ನಡ)',
    'ta': 'Tamil (தமிழ்)',
    'bn': 'Bengali (বাংলা)',
  };

  Future<void> setAppLanguage(String newScript) async {
    await setScript(newScript);
    if (newScript == 'en') {
      await setLanguage('en');
    } else {
      await setLanguage('hi');
    }
  }
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
    _forceSanskritShloka = prefs.getBool(_forceSanskritShlokaKey) ?? false;

    _hasSeenLanguagePrompt = prefs.getBool('has_seen_language_prompt') ?? false;
    // Auto-mark as seen if they have already changed the language from default
    if (!_hasSeenLanguagePrompt && (_language != _defaultLanguage || _script != _defaultScript)) {
      _hasSeenLanguagePrompt = true;
      prefs.setBool('has_seen_language_prompt', true);
    }

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
    _hasUsedExploreMore = prefs.getBool('has_used_explore_more') ?? false;
    // Streak alerts are silent — clear any legacy queued dialog messages.
    await prefs.remove('last_soul_status_message');
    _streakSystemEnabled = prefs.getBool('streak_system_enabled') ?? true;

    // Load Reminder Settings
    _reminderEnabled = prefs.getBool('reminder_enabled') ?? false;
    final hour = prefs.getInt('reminder_hour') ?? 20;
    final minute = prefs.getInt('reminder_minute') ?? 30;
    _reminderTime = TimeOfDay(hour: hour, minute: minute);

    _reminderNudgeDismissed =
        prefs.getBool('reminder_nudge_dismissed') ?? false;

    _sacredSutraPromoDismissed =
        prefs.getBool('sacred_sutra_promo_dismissed') ?? false;

    // Prefer explicit toggle; migrate old permanent-dismiss into off state.
    _showSacredSutraQuote =
        prefs.getBool('show_sacred_sutra_quote') ??
        !(_sacredSutraPromoDismissed);
    _showTodaysAction = prefs.getBool('show_todays_action') ?? true;
    _showTodaysAiQuestion = prefs.getBool('show_todays_ai_question') ?? true;

    // Load Peak Achievement Data
    _peakStreakCount = prefs.getInt('peak_streak_count') ?? 0;
    _peakAchievementCount = prefs.getInt('peak_achievement_count') ?? 0;

    // Load Lifeline Data
    _availableLifelines = prefs.getInt('available_lifelines') ?? 0;
    _lastMilestoneThreshold = prefs.getInt('last_milestone_threshold') ?? 0;

    // --- Update Daily Streak ---
    await _updateStreak(prefs);

    // --- Top-up Notification Schedule ---
    if (_reminderEnabled) {
      // Re-calculate the next 30 days starting from the current progressed message index
      await _scheduleReminder();
    }

    _isInitialized = true;
    notifyListeners();

    AnalyticsService.instance.setUserConfig(
      language: _language,
      script: _script,
      theme: _themeMode.name,
      forceSanskritShloka: _forceSanskritShloka,
      showClassicalCommentaries: _showClassicalCommentaries,
      reminderEnabled: _reminderEnabled,
    );
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
      await DailyMessageService.advanceDay(); // Progress message
    } else {
      // Missed day(s)!
      if (_availableLifelines > 0) {
        // Use a lifeline - preserve streak
        _availableLifelines--;
        _dailyStreak = currentStreak; // Keep current streak
        await DailyMessageService.advanceDay(); // User returned, progress message

        await prefs.setInt('available_lifelines', _availableLifelines);
      } else {
        // No lifelines - streak breaks silently
        _dailyStreak = 1;
        _lastMilestoneThreshold = 0;
        await prefs.setInt('last_milestone_threshold', 0);
        await DailyMessageService.advanceDay(); // Progress message on restart
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
      } else {
        // No lifelines - streak breaks silently
        _dailyStreak = 1;
        _lastMilestoneThreshold = 0;
        await prefs.setInt('daily_streak', _dailyStreak);
        await prefs.setInt('last_milestone_threshold', 0);
        break; // Stop after streak breaks
      }
    }

    notifyListeners();
  }

  Future<void> setShowRandomShloka(bool value) async {
    if (_showRandomShloka == value) return;
    _showRandomShloka = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_random_shloka', value);
    AnalyticsService.instance.logConfigChange(
      setting: 'show_random_shloka',
      value: value.toString(),
    );
  }

  Future<void> setShowSacredSutraQuote(bool value) async {
    if (_showSacredSutraQuote == value) return;
    _showSacredSutraQuote = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_sacred_sutra_quote', value);
    AnalyticsService.instance.logConfigChange(
      setting: 'show_sacred_sutra_quote',
      value: value.toString(),
    );
  }

  Future<void> setShowTodaysAction(bool value) async {
    if (_showTodaysAction == value) return;
    _showTodaysAction = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_todays_action', value);
    AnalyticsService.instance.logConfigChange(
      setting: 'show_todays_action',
      value: value.toString(),
    );
  }

  Future<void> setShowTodaysAiQuestion(bool value) async {
    if (_showTodaysAiQuestion == value) return;
    _showTodaysAiQuestion = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_todays_ai_question', value);
    AnalyticsService.instance.logConfigChange(
      setting: 'show_todays_ai_question',
      value: value.toString(),
    );
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
    AnalyticsService.instance.logConfigChange(
      setting: 'random_shloka_sources',
      value: sources.join(','),
    );
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
    AnalyticsService.instance.logConfigChange(
      setting: 'theme_mode',
      value: mode.name,
    );
    AnalyticsService.instance.setUserConfig(theme: mode.name);
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

    AnalyticsService.instance.logConfigChange(
      setting: 'reminder_enabled',
      value: enabled.toString(),
    );
    AnalyticsService.instance.setUserConfig(reminderEnabled: enabled);

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

    AnalyticsService.instance.logConfigChange(
      setting: 'reminder_time',
      value:
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
    );

    if (_reminderEnabled) {
      await _scheduleReminder();
    }
  }

  Future<void> setStreakSystemEnabled(bool newValue) async {
    _streakSystemEnabled = newValue;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('streak_system_enabled', newValue);
    AnalyticsService.instance.logConfigChange(
      setting: 'streak_system_enabled',
      value: newValue.toString(),
    );
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
