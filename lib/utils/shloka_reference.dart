import '../data/database_helper_interface.dart';
import '../models/shloka_result.dart';

/// Two numbers separated by comma, semicolon, dot, or whitespace (`15,3` / `15 3`).
final RegExp shlokaTwoNumberReferencePattern = RegExp(
  r'^\s*(\d+)\s*(?:[,.;]|\s+)\s*(\d+)\s*$',
);

bool isTwoNumberShlokaReference(String query) =>
    shlokaTwoNumberReferencePattern.hasMatch(query.trim());

/// Primary reading: first number = chapter, second = shloka.
({int chapter, int shloka})? parseShlokaChapterReference(String query) {
  final match = shlokaTwoNumberReferencePattern.firstMatch(query.trim());
  if (match == null) return null;
  final chapter = int.tryParse(match.group(1)!);
  final shloka = int.tryParse(match.group(2)!);
  if (chapter == null || shloka == null) return null;
  return (chapter: chapter, shloka: shloka);
}

/// All chapter/shloka pairs to try (primary + swapped when different).
List<({int chapter, int shloka})> interpretShlokaReferences(String query) {
  final match = shlokaTwoNumberReferencePattern.firstMatch(query.trim());
  if (match == null) return [];
  final a = int.tryParse(match.group(1)!);
  final b = int.tryParse(match.group(2)!);
  if (a == null || b == null) return [];
  final refs = <({int chapter, int shloka})>[(chapter: a, shloka: b)];
  if (a != b) {
    refs.add((chapter: b, shloka: a));
  }
  return refs;
}

ShlokaResult asNavigationSearchHit(ShlokaResult s) {
  final snippets = <String, String>{
    'shloka': s.shlok,
  };
  if (s.anvay.trim().isNotEmpty) {
    snippets['anvay'] = s.anvay;
  }
  if (s.bhavarth.trim().isNotEmpty) {
    snippets['bhavarth'] = s.bhavarth;
  }

  return ShlokaResult(
    id: s.id,
    chapterNo: s.chapterNo,
    shlokNo: s.shlokNo,
    shlok: s.shlok,
    anvay: s.anvay,
    bhavarth: s.bhavarth,
    speaker: s.speaker,
    sanskritRomanized: s.sanskritRomanized,
    audioPath: s.audioPath,
    matchedCategory: 'navigation',
    matchedWords: s.matchedWords,
    categorySnippets: snippets,
    commentaries: s.commentaries,
  );
}

Future<ShlokaResult?> _fetchOneReference(
  DatabaseHelperInterface db, {
  required int chapter,
  required int shloka,
  required String language,
  required String script,
  String? shlokaScript,
}) async {
  final chapterShlokas = await db.getShlokasByChapter(
    chapter,
    language: language,
    script: script,
    shlokaScript: shlokaScript,
  );
  final hit = chapterShlokas
      .where((s) => int.tryParse(s.shlokNo) == shloka)
      .toList();
  if (hit.isEmpty) return null;
  return asNavigationSearchHit(hit.first);
}

Future<ShlokaResult?> fetchShlokaByChapterReference(
  DatabaseHelperInterface db, {
  required String query,
  required String language,
  required String script,
  String? shlokaScript,
}) async {
  final ref = parseShlokaChapterReference(query);
  if (ref == null) return null;
  return _fetchOneReference(
    db,
    chapter: ref.chapter,
    shloka: ref.shloka,
    language: language,
    script: script,
    shlokaScript: shlokaScript,
  );
}

Future<List<ShlokaResult>> fetchShlokasByReferenceQuery(
  DatabaseHelperInterface db, {
  required String query,
  required String language,
  required String script,
  String? shlokaScript,
}) async {
  final refs = interpretShlokaReferences(query);
  if (refs.isEmpty) return [];

  final results = <ShlokaResult>[];
  final seen = <String>{};
  for (final ref in refs) {
    final hit = await _fetchOneReference(
      db,
      chapter: ref.chapter,
      shloka: ref.shloka,
      language: language,
      script: script,
      shlokaScript: shlokaScript,
    );
    if (hit != null && seen.add(hit.id)) {
      results.add(hit);
    }
  }
  return results;
}
