import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../models/shloka_result.dart';
import '../data/database_helper_interface.dart';

class ShlokaListProvider extends ChangeNotifier {
  final DatabaseHelperInterface _dbHelper;
  final String _searchQuery;

  bool _isLoading = true;
  List<ShlokaResult> _shlokas = [];
  int? _initialScrollIndex;

  bool get isLoading => _isLoading;
  List<ShlokaResult> get shlokas => _shlokas;
  int? get initialScrollIndex => _initialScrollIndex;

  ShlokaListProvider(this._searchQuery, this._dbHelper) {
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

    // Case #1: Query is a single number (chapter search).
    if (int.tryParse(_searchQuery) != null) {
      _shlokas = await _dbHelper.getShlokasByChapter(_searchQuery);
    }
    // Case #2 & #3: It's a text query.
    else {
      // Stage 1: Perform a one-way lookup using the interface method.
      final wordDefinition = await _dbHelper.getWordDefinition(_searchQuery);
      final stage1Result = wordDefinition?['suggest_text_2'] as String?;

      // Stage 2: Check if the result is a special chapter/shloka reference.
      if (stage1Result != null) {
        final parsedData = _parseSpecialFormat(stage1Result);
        if (parsedData != null) {
          // Case #3: Special format found. Fetch the chapter and set the scroll index.
          final chapter = parsedData['chapter']!.toString();
          final shlokNum = parsedData['shlok'];
          _shlokas = await _dbHelper.getShlokasByChapter(chapter);
          if (shlokNum != null) {
            _initialScrollIndex = _shlokas
                .indexWhere((s) => int.tryParse(s.shlokNo) == shlokNum);
            if (_initialScrollIndex == -1) _initialScrollIndex = null;
          }
        } else {
          // Case #2 (continued): No special format, search for both terms.
          // We perform two separate searches and merge the results.
          final results1 = await _dbHelper.searchShlokas(_searchQuery);
          final results2 = await _dbHelper.searchShlokas(stage1Result);
          
          // Use a Set to automatically handle duplicates before converting to a List.
          _shlokas = {...results1, ...results2}.toList();
        }
      } else {
        // Case #2 (no lookup result): Just search for the original query.
        _shlokas = await _dbHelper.searchShlokas(_searchQuery);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Used by the UI to clear the scroll index after scrolling is complete.
  void clearScrollIndex() {
    _initialScrollIndex = null;
  }
}

