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

import '../models/shloka_result.dart';
import '../data/database_helper_interface.dart';

class ParayanProvider extends ChangeNotifier {
  // Receives an initialized DatabaseHelperInterface for platform-agnostic DB access.
  // Receives an initialized DatabaseHelperInterface for platform-agnostic DB access.
  final DatabaseHelperInterface _dbHelper;
  String _language;
  String _script;

  bool _isLoading = true;
  List<ShlokaResult> _shlokas = [];
  List<int> _chapterStartIndices = [];
  List<int> get chapterStartIndices => _chapterStartIndices;

  bool get isLoading => _isLoading;
  List<ShlokaResult> get shlokas => _shlokas;

  ParayanProvider(this._dbHelper, this._language, this._script) {
    _fetchAllShlokas();
  }

  Future<void> updateSettings({
    required String language,
    required String script,
  }) async {
    if (_language == language && _script == script) return;
    _language = language;
    _script = script;
    await _fetchAllShlokas();
  }

  Future<void> _fetchAllShlokas() async {
    _isLoading = true;
    notifyListeners();

    _chapterStartIndices = [];
    _shlokas =
        (await _dbHelper.getAllShlokas(
          language: _language,
          script: _script,
        )).where((shloka) {
          final isValidChapter = int.tryParse(shloka.chapterNo) != null;
          final isValidShlok = int.tryParse(shloka.shlokNo) != null;
          return isValidChapter && isValidShlok;
        }).toList();

    for (int i = 0; i < _shlokas.length; i++) {
      if (i == 0 || _shlokas[i].chapterNo != _shlokas[i - 1].chapterNo) {
        _chapterStartIndices.add(i);
      }
    }
    if (_chapterStartIndices.length > 18) {
      _chapterStartIndices = _chapterStartIndices.sublist(0, 18);
    }

    _isLoading = false;
    notifyListeners();
  }
}
