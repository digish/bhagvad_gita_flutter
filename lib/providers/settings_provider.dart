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

class SettingsProvider extends ChangeNotifier {
  static const String _fontSizeKey = 'fontSize';
  static const String _showBackgroundKey = 'showBackground';
  static const double _defaultFontSize = 20.0;
  static const bool _defaultShowBackground = true;

  double _fontSize = _defaultFontSize;
  double get fontSize => _fontSize;

  bool _showBackground = _defaultShowBackground;
  bool get showBackground => _showBackground;

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

  // --- Language & Script Support ---
  static const String _languageKey = 'language'; // 'hi' or 'en'
  static const String _scriptKey = 'script'; // 'dev', 'gu', 'te', 'ro', etc.

  static const String _defaultLanguage = 'hi';
  static const String _defaultScript = 'dev';

  String _language = _defaultLanguage; // Translation Language (Bhavarth)
  String get language => _language;

  String _script = _defaultScript; // Display Script (Lipi)
  String get script => _script;

  bool _showClassicalCommentaries = true;
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

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSize = prefs.getDouble(_fontSizeKey) ?? _defaultFontSize;
    _showBackground =
        prefs.getBool(_showBackgroundKey) ?? _defaultShowBackground;
    _showClassicalCommentaries =
        prefs.getBool('show_classical_commentaries') ?? true;

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
    _randomShlokaSource = prefs.getInt('random_shloka_source') ?? -1;

    notifyListeners();
  }

  // --- Random Shloka Settings ---
  bool _showRandomShloka = true;
  bool get showRandomShloka => _showRandomShloka;

  int _randomShlokaSource = -1; // -1 for Entire Gita
  int get randomShlokaSource => _randomShlokaSource;

  Future<void> setShowRandomShloka(bool value) async {
    if (_showRandomShloka == value) return;
    _showRandomShloka = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_random_shloka', value);
  }

  Future<void> setRandomShlokaSource(int listId) async {
    if (_randomShlokaSource == listId) return;
    _randomShlokaSource = listId;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('random_shloka_source', listId);
  }
}
