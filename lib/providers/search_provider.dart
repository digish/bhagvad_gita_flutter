import 'dart:async';
import 'package:flutter/material.dart';
import '../data/database_helper.dart'; // Import the conditional factory
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
  // It no longer creates its own instance. It receives the initialized one.
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
        // Use the dbHelper instance passed to the provider
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
