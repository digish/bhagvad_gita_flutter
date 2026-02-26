import 'dart:convert';

class ShlokaResult {
  final String id; // Changed from int to String (e.g., "1.1")
  final String chapterNo;
  final String shlokNo;
  final String shlok;
  final String anvay;
  final String bhavarth;
  final String? speaker;
  // Deprecated fields from old DB, keeping nullable for safety or removing if confirmed unused.
  // Assuming 'tag' and 'annotation' are not in new V2 schema.

  // New field
  final String? sanskritRomanized;
  // Added fields from new schema
  final String? audioPath;

  // Search metadata
  final String? matchedCategory;
  final String? matchSnippet;
  final List<String>? matchedWords;
  final Map<String, String>?
  categorySnippets; // NEW: Map of category -> snippet

  // Commentaries
  final List<Commentary>? commentaries;

  ShlokaResult({
    required this.id,
    required this.chapterNo,
    required this.shlokNo,
    required this.shlok,
    required this.anvay,
    required this.bhavarth,
    this.speaker,
    this.sanskritRomanized,
    this.audioPath,
    this.matchedCategory,
    this.matchSnippet,
    this.matchedWords,
    this.categorySnippets,
    this.commentaries,
  });

  factory ShlokaResult.fromMap(
    Map<String, dynamic> map, {
    List<Commentary>? commentaries,
    Map<String, String>? categorySnippets,
  }) {
    return ShlokaResult(
      // V2 Schema: id is "1.1" (TEXT)
      // If we are getting 'rowid' from FTS, we might need to fetch the real ID via ref_id.
      // But typically our JOIN query will return master_shlokas.id
      id: map['id']?.toString() ?? map['shloka_id']?.toString() ?? '',

      chapterNo:
          map['chapter_no']?.toString() ?? map['chapterNo']?.toString() ?? '',
      shlokNo: map['shloka_no']?.toString() ?? map['shlokNo']?.toString() ?? '',

      // These come from JOINs
      shlok: map['shloka_text']?.toString() ?? map['shlok']?.toString() ?? '',
      anvay: map['anvay_text']?.toString() ?? map['anvay']?.toString() ?? '',
      bhavarth: map['bhavarth']?.toString() ?? '',

      // Master fields
      speaker: map['speaker']?.toString(), // Restored
      sanskritRomanized: map['sanskrit_romanized']?.toString(),
      audioPath: map['audio_path']?.toString(),

      // Search metadata
      matchedCategory: map['matched_category']?.toString(),
      matchSnippet: map['match_snippet']?.toString(),
      matchedWords: (map['matched_words'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),

      categorySnippets:
          categorySnippets ?? map['category_snippets'] as Map<String, String>?,
      commentaries: commentaries,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShlokaResult &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class Commentary {
  final String authorName;
  final String languageCode;
  final String content;

  Commentary({
    required this.authorName,
    required this.languageCode,
    required this.content,
  });

  bool get isAI =>
      authorName == 'AI Generated' ||
      authorName == 'AI Insights' ||
      authorName == 'Gita AI Wisdom';

  String get displayAuthorName {
    if (isAI) return 'Gita AI Wisdom';
    return authorName;
  }

  ModernCommentary? get modern {
    if (!isAI) return null;
    try {
      final Map<String, dynamic> data = jsonDecode(content);
      return ModernCommentary.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  factory Commentary.fromMap(Map<String, dynamic> map) {
    return Commentary(
      authorName: map['author_name']?.toString() ?? 'Unknown',
      languageCode: map['language_code']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
    );
  }
}

class ModernCommentary {
  final String headline;
  final String? context;
  final String coreConcept;
  final String modernRelevance;
  final String actionableTakeaway;
  final List<String> keywords;

  ModernCommentary({
    required this.headline,
    this.context,
    required this.coreConcept,
    required this.modernRelevance,
    required this.actionableTakeaway,
    required this.keywords,
  });

  factory ModernCommentary.fromMap(Map<String, dynamic> map) {
    return ModernCommentary(
      headline: map['headline']?.toString() ?? '',
      context: map['context']?.toString(),
      coreConcept: map['core_concept']?.toString() ?? '',
      modernRelevance: map['modern_relevance']?.toString() ?? '',
      actionableTakeaway: map['actionable_takeaway']?.toString() ?? '',
      keywords:
          (map['keywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class Translation {
  final String languageCode;
  final String bhavarth;

  Translation({required this.languageCode, required this.bhavarth});

  factory Translation.fromMap(Map<String, dynamic> map) {
    return Translation(
      languageCode: map['language_code']?.toString() ?? '',
      bhavarth: map['bhavarth']?.toString() ?? '',
    );
  }
}
