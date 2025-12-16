import 'package:flutter/foundation.dart';
import '../data/user_database_helper.dart';
import '../models/shloka_list.dart';
import '../data/database_helper_interface.dart';
import '../models/shloka_result.dart';

class BookmarkProvider extends ChangeNotifier {
  List<ShlokaList> _lists = [];
  bool _isLoading = false;

  // Cache to quickly check if a shloka is in ANY list (for the icon state)
  // Key: "chapter:shloka", Value: List of List IDs
  final Map<String, Set<int>> _shlokaStateCache = {};

  List<ShlokaList> get lists => _lists;
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
    for (var item in items) {
      final key = '${item['chapter_no']}:${item['shlok_no']}';
      final listId = item['list_id'] as int;
      if (_shlokaStateCache.containsKey(key)) {
        _shlokaStateCache[key]!.add(listId);
      } else {
        _shlokaStateCache[key] = {listId};
      }
    }
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
  }

  Future<void> deleteList(int id) async {
    await UserDatabaseHelper.instance.deleteList(id);
    // Also clear from cache locally if needed, or just clear whole cache
    _shlokaStateCache.clear();
    await loadLists();
  }

  Future<void> renameList(int id, String newName) async {
    await UserDatabaseHelper.instance.renameList(id, newName);
    await loadLists();
  }

  Future<void> addShlokaToList(int listId, String chapter, String shlok) async {
    await UserDatabaseHelper.instance.addShlokaToList(listId, chapter, shlok);

    // Update cache
    final key = '$chapter:$shlok';
    if (_shlokaStateCache.containsKey(key)) {
      _shlokaStateCache[key]!.add(listId);
    } else {
      _shlokaStateCache[key] = {listId};
    }
    notifyListeners();
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
      _shlokaStateCache[key]!.remove(listId);
    }
    notifyListeners();
  }

  // Fetch details using the new List system
  Future<List<ShlokaResult>> getShlokasForList(
    DatabaseHelperInterface mainDb,
    int listId,
  ) async {
    final savedItems = await UserDatabaseHelper.instance.getShlokasInList(
      listId,
    );
    if (savedItems.isEmpty) return [];

    final allShlokas = await mainDb.getAllShlokas();

    // Create a set of keys for O(1) lookup
    final savedKeys = savedItems
        .map((i) => '${i['chapter_no']}:${i['shlok_no']}')
        .toSet();

    return allShlokas.where((s) {
      return savedKeys.contains('${s.chapterNo}:${s.shlokNo}');
    }).toList();
  }
}
