import 'package:flutter/foundation.dart';
import '../data/user_database_helper.dart';
import '../models/bookmark.dart';
import '../data/database_helper_interface.dart';
import '../models/shloka_result.dart';

class BookmarkProvider extends ChangeNotifier {
  List<Bookmark> _bookmarks = [];
  bool _isLoading = false;

  List<Bookmark> get bookmarks => _bookmarks;
  bool get isLoading => _isLoading;

  BookmarkProvider() {
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    _isLoading = true;
    notifyListeners();
    try {
      _bookmarks = await UserDatabaseHelper.instance.getAllBookmarks();
    } catch (e) {
      debugPrint("Error loading bookmarks: $e");
      _bookmarks = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  bool isBookmarked(String chapterNo, String shlokNo) {
    return _bookmarks.any(
      (b) => b.chapterNo == chapterNo && b.shlokNo == shlokNo,
    );
  }

  Future<void> toggleBookmark(String chapterNo, String shlokNo) async {
    try {
      if (isBookmarked(chapterNo, shlokNo)) {
        await UserDatabaseHelper.instance.removeBookmark(chapterNo, shlokNo);
      } else {
        await UserDatabaseHelper.instance.addBookmark(chapterNo, shlokNo);
      }
      await _loadBookmarks();
    } catch (e) {
      debugPrint("Error toggling bookmark: $e");
    }
  }

  Future<List<ShlokaResult>> getBookmarkedShlokasDetails(
    DatabaseHelperInterface mainDb,
  ) async {
    // This is not the most efficient way if we have many bookmarks and a large DB,
    // but for < 700 items it's perfectly fine to just fetch all needed or even all shlokas.
    // A better approach would be to add a batch fetch method to the interface.
    // For now, let's fetch all shlokas and filter.

    // Optimisation: If we have 0 bookmarks, return empty immediately.
    if (_bookmarks.isEmpty) return [];

    final allShlokas = await mainDb.getAllShlokas();

    // Create a set of bookmark keys "chapter:shloka" for O(1) lookup
    final bookmarkKeys = _bookmarks
        .map((b) => '${b.chapterNo}:${b.shlokNo}')
        .toSet();

    return allShlokas.where((s) {
      return bookmarkKeys.contains('${s.chapterNo}:${s.shlokNo}');
    }).toList();
  }
}
