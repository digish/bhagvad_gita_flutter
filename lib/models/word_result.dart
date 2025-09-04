class WordResult {
  final int id;
  final String word;
  final String definition;

  WordResult({
    required this.id,
    required this.word,
    required this.definition,
  });

  // This factory constructor has been updated to use the correct database column names.
  factory WordResult.fromMap(Map<String, dynamic> map) {
    return WordResult(
      // This part is correct.
      id: (map['rowid'] ?? map['_id']) as int? ?? 0,
      
      // THE FIX:
      // We now use the actual column names from your 'words' table.
      word: map['suggest_text_1'] as String? ?? '',
      definition: map['suggest_text_2'] as String? ?? '',
    );
  }
}

