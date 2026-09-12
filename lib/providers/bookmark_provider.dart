import 'package:flutter/foundation.dart';
import '../data/user_database_helper.dart';
import '../models/shloka_list.dart';
import '../data/database_helper_interface.dart';
import '../models/shloka_result.dart';
import '../data/predefined_lists_data.dart';
import '../services/analytics_service.dart';

class BookmarkProvider extends ChangeNotifier {
  List<ShlokaList> _lists = [];
  bool _isLoading = false;

  // Cache to quickly check if a shloka is in ANY list (for the icon state)
  // Key: "chapter:shloka", Value: List of List IDs
  final Map<String, Set<int>> _shlokaStateCache = {};
  final Map<int, int> _listItemCounts = {};

  List<ShlokaList> get lists => _lists;
  List<ShlokaList> get predefinedLists => PredefinedListsData.lists;
  bool get isLoading => _isLoading;

  BookmarkProvider() {
    loadLists();
  }

  Future<void> loadLists() async {
    _isLoading = true;
    notifyListeners();
    try {
      _lists = await UserDatabaseHelper.instance.getAllLists();
      await _loadAllListItems();
    } catch (e) {
      debugPrint("Error loading lists: $e");
      _lists = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadAllListItems() async {
    final items = await UserDatabaseHelper.instance.getAllListItems();
    _shlokaStateCache.clear();
    _listItemCounts.clear();
    for (var item in items) {
      final key = '${item['chapter_no']}:${item['shlok_no']}';
      final listId = item['list_id'] as int;
      if (_shlokaStateCache.containsKey(key)) {
        _shlokaStateCache[key]!.add(listId);
      } else {
        _shlokaStateCache[key] = {listId};
      }
      _listItemCounts[listId] = (_listItemCounts[listId] ?? 0) + 1;
    }
  }

  int shlokaCountForList(int listId) {
    if (listId < 0) {
      return PredefinedListsData.getShlokasForList(listId).length;
    }
    return _listItemCounts[listId] ?? 0;
  }

  // Returns true if the shloka is in ANY list (Synchronous check)
  bool isBookmarked(String chapterNo, String shlokNo) {
    final key = '$chapterNo:$shlokNo';
    return _shlokaStateCache.containsKey(key) &&
        _shlokaStateCache[key]!.isNotEmpty;
  }

  // Get all lists that contain this shloka
  Future<List<int>> getListsForShloka(String chapterNo, String shlokNo) async {
    // We can rely on cache mostly, but let's just return what we have
    final key = '$chapterNo:$shlokNo';
    if (_shlokaStateCache.containsKey(key)) {
      return _shlokaStateCache[key]!.toList();
    }
    return [];
  }

  Future<void> createList(String name) async {
    await UserDatabaseHelper.instance.createList(name);
    await loadLists();
    AnalyticsService.instance.logBookmark(action: 'create_list', listName: name);
  }

  Future<void> deleteList(int id) async {
    await UserDatabaseHelper.instance.deleteList(id);
    // Also clear from cache locally if needed, or just clear whole cache
    _shlokaStateCache.clear();
    await loadLists();
    AnalyticsService.instance.logBookmark(action: 'delete_list');
  }

  Future<void> renameList(int id, String newName) async {
    await UserDatabaseHelper.instance.renameList(id, newName);
    await loadLists();
    AnalyticsService.instance.logBookmark(
      action: 'rename_list',
      listName: newName,
    );
  }

  Future<void> addShlokaToList(int listId, String chapter, String shlok) async {
    await UserDatabaseHelper.instance.addShlokaToList(listId, chapter, shlok);

    // Update cache
    final key = '$chapter:$shlok';
    if (_shlokaStateCache.containsKey(key)) {
      final added = _shlokaStateCache[key]!.add(listId);
      if (added) {
        _listItemCounts[listId] = (_listItemCounts[listId] ?? 0) + 1;
      }
    } else {
      _shlokaStateCache[key] = {listId};
      _listItemCounts[listId] = (_listItemCounts[listId] ?? 0) + 1;
    }
    notifyListeners();
    AnalyticsService.instance.logBookmark(
      action: 'add_shloka',
      shlokaId: '$chapter.$shlok',
    );
  }

  Future<void> removeShlokaFromList(
    int listId,
    String chapter,
    String shlok,
  ) async {
    await UserDatabaseHelper.instance.removeShlokaFromList(
      listId,
      chapter,
      shlok,
    );

    // Update cache
    final key = '$chapter:$shlok';
    if (_shlokaStateCache.containsKey(key)) {
      final removed = _shlokaStateCache[key]!.remove(listId);
      if (removed) {
        final count = _listItemCounts[listId];
        if (count != null && count > 1) {
          _listItemCounts[listId] = count - 1;
        } else {
          _listItemCounts.remove(listId);
        }
      }
    }
    notifyListeners();
    AnalyticsService.instance.logBookmark(
      action: 'remove_shloka',
      shlokaId: '$chapter.$shlok',
    );
  }

  Future<List<ShlokaResult>> getShlokasForList(
    DatabaseHelperInterface mainDb,
    int listId, {
    String language = 'hi',
    String script = 'dev',
    String? shlokaScript,
  }) async {
    List<Map<String, dynamic>> references = [];

    if (listId < 0) {
      // Predefined List
      final items = PredefinedListsData.getShlokasForList(listId);
      for (var item in items) {
        final parts = item.split('.');
        if (parts.length == 2) {
          references.add({
            'id': item,
            'chapter_no': parts[0],
            'shlok_no': parts[1],
          });
        }
      }
    } else {
      final savedItems = await UserDatabaseHelper.instance.getShlokasInList(
        listId,
      );
      if (savedItems.isEmpty) return [];
      // savedItems is List<Map<String, Object?>>, we cast or use as is if keys match
      // UserDatabaseHelper uses 'chapter_no' and 'shlok_no' which matches what we need
      references = savedItems.map((item) {
        return {...item, 'id': '${item['chapter_no']}.${item['shlok_no']}'};
      }).toList();
    }

    if (references.isEmpty) return [];

    return await mainDb.getShlokasByReferences(
      references,
      language: language,
      script: script,
      shlokaScript: shlokaScript,
      includeCommentaries: false, // Optimize memory
    );
  }
}
