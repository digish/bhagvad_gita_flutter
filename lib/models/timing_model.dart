class WordTiming {
  final String word;
  final double start; // seconds
  final double end; // seconds

  WordTiming({required this.word, required this.start, required this.end});

  factory WordTiming.fromMap(Map<String, dynamic> map) {
    return WordTiming(
      word: map['word']?.toString() ?? '',
      start: (map['start'] as num).toDouble(),
      end: (map['end'] as num).toDouble(),
    );
  }

  @override
  String toString() => 'WordTiming(word: $word, start: $start, end: $end)';
}
