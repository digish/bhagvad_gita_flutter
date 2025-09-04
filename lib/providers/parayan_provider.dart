import 'package:flutter/material.dart';
import '../data/database_helper.dart'; // Import the new conditional factory
import '../models/shloka_result.dart';
import '../data/database_helper_interface.dart';

class ParayanProvider extends ChangeNotifier {
  // 1. It no longer creates its own instance. It receives the initialized one.
  final DatabaseHelperInterface _dbHelper;

  bool _isLoading = true;
  List<ShlokaResult> _shlokas = [];
  List<int> _chapterStartIndices = [];
  List<int> get chapterStartIndices => _chapterStartIndices;

  bool get isLoading => _isLoading;
  List<ShlokaResult> get shlokas => _shlokas;

  // 2. The constructor now accepts the database helper.
  ParayanProvider(this._dbHelper) {
    _fetchAllShlokas();
  }

  Future<void> _fetchAllShlokas() async {
    _chapterStartIndices = [];

    // The rest of your logic remains exactly the same!
    _shlokas = (await _dbHelper.getAllShlokas()).where((shloka) {
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
