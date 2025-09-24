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

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // Load the saved font size, or fall back to the default.
    _fontSize = prefs.getDouble(_fontSizeKey) ?? _defaultFontSize;
    // Load the saved background visibility, or fall back to the default.
    _showBackground = prefs.getBool(_showBackgroundKey) ?? _defaultShowBackground;
    notifyListeners();
  }

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
}
