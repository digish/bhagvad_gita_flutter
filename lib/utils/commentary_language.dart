import '../models/shloka_result.dart';

/// Display order for commentary language chips (Sanskrit → English → Hindi).
const List<String> kCommentaryLanguageOrder = ['sa', 'en', 'hi'];

String commentaryLanguageShortLabel(String code) {
  switch (code.toLowerCase()) {
    case 'sa':
      return 'SA';
    case 'en':
    case 'ro':
      return 'EN';
    case 'hi':
    case 'dev':
      return 'HI';
    default:
      return code.toUpperCase();
  }
}

String commentaryAuthorShortName(String author) {
  final name = author.toLowerCase();
  if (name.contains('shankar')) return 'Shankara';
  if (name.contains('ramanuj')) return 'Ramanuja';
  if (name.contains('madhv')) return 'Madhva';
  if (name.contains('ai insight') ||
      name.contains('ai wisdom') ||
      name.contains('ai generated')) {
    return 'AI';
  }
  if (name.contains('ramsukhdas')) return 'Ramsukhdas';
  if (name.contains('chinmayananda')) return 'Chinmaya';
  if (name.contains('gandhi')) return 'Gandhi';

  final first = author.split(RegExp(r'\s+')).first;
  if (first.length <= 12) return first;
  return '${first.substring(0, 11)}…';
}

String? nextCommentaryLanguage(
  List<String> availableLanguageCodes,
  String currentLanguageCode,
) {
  if (availableLanguageCodes.length <= 1) return null;
  final current = currentLanguageCode.toLowerCase();
  final index = availableLanguageCodes.indexWhere(
    (code) => code.toLowerCase() == current,
  );
  if (index == -1) return availableLanguageCodes.first;
  return availableLanguageCodes[(index + 1) % availableLanguageCodes.length];
}

String commentaryLanguageLabel(String code) {
  switch (code.toLowerCase()) {
    case 'en':
    case 'ro':
      return 'English';
    case 'hi':
    case 'dev':
      return 'Hindi';
    case 'sa':
      return 'Sanskrit';
    default:
      return code.toUpperCase();
  }
}

List<String> sortedCommentaryLanguageCodes(Iterable<String> codes) {
  final set = codes.map((c) => c.toLowerCase()).toSet();
  final ordered = <String>[
    for (final code in kCommentaryLanguageOrder)
      if (set.contains(code)) code,
  ];
  for (final code in set) {
    if (!ordered.contains(code)) ordered.add(code);
  }
  return ordered;
}

List<String> availableLanguageCodesForVariants(List<Commentary> variants) {
  return sortedCommentaryLanguageCodes(
    variants.where((c) => c.content.isNotEmpty).map((c) => c.languageCode),
  );
}

Map<String, List<Commentary>> groupCommentariesByAuthor(
  List<Commentary> commentaries, {
  bool Function(String authorName)? includeAuthor,
}) {
  final grouped = <String, List<Commentary>>{};
  for (final c in commentaries) {
    if (c.content.isEmpty) continue;
    final author = c.canonicalAuthorName;
    if (includeAuthor != null && !includeAuthor(author)) continue;
    grouped.putIfAbsent(author, () => []).add(c);
  }
  return grouped;
}

List<Commentary> variantsForAuthor(List<Commentary>? all, String author) {
  if (all == null) return [];
  return all
      .where((c) => c.canonicalAuthorName == author && c.content.isNotEmpty)
      .toList();
}

Commentary? commentaryForAuthorAndLanguage(
  List<Commentary>? all,
  String author,
  String languageCode,
) {
  final variants = variantsForAuthor(all, author);
  if (variants.isEmpty) return null;

  for (final c in variants) {
    if (c.languageCode.toLowerCase() == languageCode.toLowerCase()) {
      return c;
    }
  }
  return null;
}

/// Picks a sensible initial language when the user has not chosen yet.
String defaultCommentaryLanguage(
  List<Commentary> variants, {
  String preferredLanguage = 'en',
}) {
  final available = availableLanguageCodesForVariants(variants);
  if (available.isEmpty) return preferredLanguage;

  final pref = preferredLanguage.toLowerCase();
  if (available.contains(pref)) return pref;

  if (pref == 'hi' && available.contains('sa')) return 'sa';

  for (final code in kCommentaryLanguageOrder) {
    if (available.contains(code)) return code;
  }
  return available.first;
}

/// Resolves [languageCode] for [author], or the first available variant.
Commentary? resolveCommentaryVariant(
  List<Commentary>? all,
  String author,
  String languageCode,
) {
  final exact = commentaryForAuthorAndLanguage(all, author, languageCode);
  if (exact != null) return exact;
  final variants = variantsForAuthor(all, author);
  return variants.isEmpty ? null : variants.first;
}

List<String> availableLanguagesForAuthorInChapter(
  List<ShlokaResult> shlokas,
  String author,
) {
  final codes = <String>{};
  for (final shloka in shlokas) {
    for (final c in variantsForAuthor(shloka.commentaries, author)) {
      codes.add(c.languageCode.toLowerCase());
    }
  }
  return sortedCommentaryLanguageCodes(codes);
}
