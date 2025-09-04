class ShlokaResult {
  final int id;
  final String chapterNo;
  final String shlokNo;
  final String shlok;
  final String anvay;
  final String bhavarth;
  final String? speaker;
  final String? tag;
  final String? annotation;

  ShlokaResult({
    required this.id,
    required this.chapterNo,
    required this.shlokNo,
    required this.shlok,
    required this.anvay,
    required this.bhavarth,
    this.speaker,
    this.tag,
    this.annotation,
  });

  // This factory constructor has been updated to be fully null-safe.
  factory ShlokaResult.fromMap(Map<String, dynamic> map) {
    return ShlokaResult(
      // THE FIX:
      // We handle both possible ID columns ('rowid' or '_id'), check if the
      // result is an int, and provide a fallback value of 0 if it's null.
      id: (map['rowid'] ?? map['_id']) as int? ?? 0,
      
      // These lines ensure that if any required text columns are null, 
      // we get an empty string instead of a null value, preventing other errors.
      chapterNo: map['chapterNo'] as String? ?? '',
      shlokNo: map['shlokNo'] as String? ?? '',
      shlok: map['shlok'] as String? ?? '',
      anvay: map['anvay'] as String? ?? '',
      bhavarth: map['bhavarth'] as String? ?? '',

      // These fields are nullable in our class, so a simple cast is safe.
      speaker: map['speaker'] as String?,
      tag: map['tag'] as String?,
      annotation: map['annotation'] as String?,
    );
  }

  // --- HASHCODE and EQUALS ---
  // Adding these allows Sets to correctly identify unique shlokas,
  // which is important for merging search results.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShlokaResult &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

