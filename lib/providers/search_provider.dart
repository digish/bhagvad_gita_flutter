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

import 'dart:async';
import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../models/shloka_result.dart';
import '../models/word_result.dart';
import '../data/database_helper_interface.dart';

abstract class SearchResultItem {}
class ShlokaItem extends SearchResultItem {
  final ShlokaResult shloka;
  ShlokaItem(this.shloka);
}
class WordItem extends SearchResultItem {
  final WordResult word;
  WordItem(this.word);
}

class SearchProvider extends ChangeNotifier {
  final DatabaseHelperInterface _dbHelper;
  SearchProvider(this._dbHelper);
  
  String _searchQuery = '';
  List<SearchResultItem> _searchResults = [];
  Timer? _debounce;

  String get searchQuery => _searchQuery;
  List<SearchResultItem> get searchResults => _searchResults;

  void onSearchQueryChanged(String query) {
    _searchQuery = query;
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (_searchQuery.isEmpty) {
        _searchResults = [];
      } else {
        final words = await _dbHelper.searchWords(_searchQuery);
        final shlokas = await _dbHelper.searchShlokas(_searchQuery);
        _searchResults = [
          ...words.map((w) => WordItem(w)),
          ...shlokas.map((s) => ShlokaItem(s)),
        ];
      }
      notifyListeners();
    });
    notifyListeners();
  }
}
