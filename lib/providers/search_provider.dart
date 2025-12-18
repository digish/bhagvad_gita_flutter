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

class HeaderItem extends SearchResultItem {
  final String title;
  HeaderItem(this.title);
}

class SearchProvider extends ChangeNotifier {
  final DatabaseHelperInterface _dbHelper;
  final String _language;
  final String _script; // NEW field
  SearchProvider(this._dbHelper, this._language, this._script);

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
        final shlokas = await _dbHelper.searchShlokas(
          _searchQuery,
          language: _language,
          script: _script, // Pass script
        );

        // Deduplication Logic
        final uniqueShlokas = <String, ShlokaResult>{};
        final categoryPriority = {
          'navigation': 0,
          'shloka': 1,
          'anvay': 2,
          'bhavarth': 3,
          'meaning': 4,
          'other': 5,
        };

        for (var s in shlokas) {
          final id = s.id;
          final cat = s.matchedCategory ?? 'other';

          if (!uniqueShlokas.containsKey(id)) {
            uniqueShlokas[id] = s;
          } else {
            final currentBest = uniqueShlokas[id]!.matchedCategory ?? 'other';
            final currentPriority = categoryPriority[currentBest] ?? 99;
            final newPriority = categoryPriority[cat] ?? 99;

            if (newPriority < currentPriority) {
              uniqueShlokas[id] = s; // Replace with better match
            }
          }
        }

        // Grouping Logic (using unique items)
        final grouped = <String, List<ShlokaResult>>{};
        for (var s in uniqueShlokas.values) {
          final cat = s.matchedCategory ?? 'Other';
          grouped.putIfAbsent(cat, () => []).add(s);
        }

        final orderedCategories = [
          'navigation',
          'shloka',
          'anvay',
          'bhavarth',
          'meaning',
        ];
        final newResults = <SearchResultItem>[];

        // Add Words first (if implementation available)
        newResults.addAll(words.map((w) => WordItem(w)));

        // Add prioritized categories
        for (var cat in orderedCategories) {
          if (grouped.containsKey(cat)) {
            newResults.add(HeaderItem(cat.toUpperCase()));
            newResults.addAll(grouped[cat]!.map((s) => ShlokaItem(s)));
            grouped.remove(cat);
          }
        }

        // Add remaining items
        grouped.forEach((cat, list) {
          newResults.add(HeaderItem(cat.toUpperCase()));
          newResults.addAll(list.map((s) => ShlokaItem(s)));
        });

        _searchResults = newResults;
      }
      notifyListeners();
    });
    notifyListeners(); // Immediate notification for loading/clearing if needed
  }
}
