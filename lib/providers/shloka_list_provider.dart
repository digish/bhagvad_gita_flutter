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

class ShlokaListProvider extends ChangeNotifier {
  final DatabaseHelperInterface _dbHelper;
  final String _searchQuery;
  final String _language;
  final String _script; // NEW field

  bool _isLoading = true;
  List<ShlokaResult> _shlokas = [];
  int? _initialScrollIndex;
  String? _lastScrolledId;

  bool get isLoading => _isLoading;
  List<ShlokaResult> get shlokas => _shlokas;
  int? get initialScrollIndex => _initialScrollIndex;
  String? get lastScrolledId => _lastScrolledId;

  // Updated constructor to accept script
  ShlokaListProvider(
    this._searchQuery,
    this._dbHelper,
    this._language,
    this._script,
  ) {
    _fetchShlokas();
  }

  /// A helper to parse the special format like "@ Adhyay :1 & Shlok :21"
  Map<String, int>? _parseSpecialFormat(String text) {
    final regExp = RegExp(r'@ Adhyay :(\d+) & Shlok :(\d+)');
    final match = regExp.firstMatch(text);
    if (match != null && match.groupCount == 2) {
      final chapter = int.tryParse(match.group(1)!);
      final shlok = int.tryParse(match.group(2)!);
      if (chapter != null && shlok != null) {
        return {'chapter': chapter, 'shlok': shlok};
      }
    }
    return null;
  }

  /// Fetches shlokas based on the query, now using the cross-platform interface.
  Future<void> _fetchShlokas() async {
    _isLoading = true;
    notifyListeners();

    // Case #0: Query is a "chapter,shloka" or "chapter.shloka" reference.
    final shlokaRefMatch = RegExp(r'^(\d+)[,.](\d+)$').firstMatch(_searchQuery);

    // Case #0.5: Query is a list of shloka IDs (e.g. "ids:1.1,2.45")
    if (_searchQuery.startsWith('ids:')) {
      final idsStr = _searchQuery.replaceFirst('ids:', '');
      final ids = idsStr
          .split(',')
          .where((id) => id.trim().isNotEmpty)
          .toList();

      final List<ShlokaResult> fetched = [];
      for (final id in ids) {
        final parts = id.trim().split('.');
        if (parts.length == 2) {
          final chapter = int.tryParse(parts[0]);
          final shlokNum = int.tryParse(parts[1]);
          if (chapter != null && shlokNum != null) {
            final chapterShlokas = await _dbHelper.getShlokasByChapter(
              chapter,
              language: _language,
              script: _script,
            );
            final match = chapterShlokas
                .where((s) => int.tryParse(s.shlokNo) == shlokNum)
                .toList();
            fetched.addAll(match);
          }
        }
      }
      _shlokas = fetched;
    } else if (shlokaRefMatch != null) {
      final chapterStr = shlokaRefMatch.group(1)!;
      final chapter = int.tryParse(chapterStr);
      final shlokNum = int.tryParse(shlokaRefMatch.group(2)!);

      if (chapter != null) {
        _shlokas = await _dbHelper.getShlokasByChapter(
          chapter,
          language: _language,
          script: _script,
        );
        if (shlokNum != null) {
          final index = _shlokas.indexWhere(
            (s) => int.tryParse(s.shlokNo) == shlokNum,
          );
          if (index != -1) {
            _initialScrollIndex = index;
            debugPrint(
              'ShlokaListProvider: setting initialScrollIndex to $index for $chapter.$shlokNum',
            );
          }
        }
      }
    }
    // Case #1: Query is a single number (chapter search).
    else if (int.tryParse(_searchQuery) != null) {
      debugPrint(
        'ShlokaListProvider: chapter search exact match for $_searchQuery',
      );
      final chapter = int.parse(_searchQuery);
      _shlokas = await _dbHelper.getShlokasByChapter(
        chapter,
        language: _language,
        script: _script,
      );
    }
    // Case #2 & #3: It's a text query.
    else {
      final wordDefinition = await _dbHelper.getWordDefinition(_searchQuery);
      final stage1Result = wordDefinition?['suggest_text_2'] as String?;

      if (stage1Result != null) {
        final parsedData = _parseSpecialFormat(stage1Result);
        if (parsedData != null) {
          final chapter = parsedData['chapter']!;
          final shlokNum = parsedData['shlok'];
          _shlokas = await _dbHelper.getShlokasByChapter(
            chapter,
            language: _language,
            script: _script,
          );
          if (shlokNum != null) {
            final index = _shlokas.indexWhere(
              (s) => int.tryParse(s.shlokNo) == shlokNum,
            );
            if (index != -1) {
              _initialScrollIndex = index;
              debugPrint(
                'ShlokaListProvider: setting initialScrollIndex to $index for $chapter.$shlokNum (special)',
              );
            }
          }
        } else {
          // Case #2 (continued): No special format, search for both terms.
          // We perform two separate searches and merge the results.
          final results1 = await _dbHelper.searchShlokas(
            _searchQuery,
            language: _language,
            script: _script, // Pass script
          );
          final results2 = await _dbHelper.searchShlokas(
            stage1Result,
            language: _language,
            script: _script, // Pass script
          );

          // Use a Set to automatically handle duplicates before converting to a List.
          _shlokas = {...results1, ...results2}.toList();
        }
      } else {
        // Case #2 (no lookup result): Just search for the original query.
        _shlokas = await _dbHelper.searchShlokas(
          _searchQuery,
          language: _language,
          script: _script, // Pass script
        );
      }
    }

    // ✨ Deduplicate before completing list
    final seenIds = <String>{};
    _shlokas = _shlokas.where((shloka) => seenIds.add(shloka.id)).toList();

    _isLoading = false;
    notifyListeners();
  }

  /// Used by the UI to clear the scroll index after scrolling is complete.
  void clearScrollIndex() {
    _initialScrollIndex = null;
  }

  void setLastScrolledId(String? id) {
    _lastScrolledId = id;
  }
}
