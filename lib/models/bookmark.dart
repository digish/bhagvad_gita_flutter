class Bookmark {
  final int id;
  final String chapterNo;
  final String shlokNo;
  final String label;

  Bookmark({
    required this.id,
    required this.chapterNo,
    required this.shlokNo,
    required this.label,
  });

  factory Bookmark.fromMap(Map<String, dynamic> map) {
    return Bookmark(
      id: map['rowid'] ?? map['_id'] ?? 0, // Fallback to 0 if null
      chapterNo: map['chapterNo'] as String,
      shlokNo: map['shlokNo'] as String,
      label: map['bmarkLabel'] as String,
    );
  }
}
