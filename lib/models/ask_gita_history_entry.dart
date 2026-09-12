class AskGitaHistoryEntry {
  final String id;
  final int askedAtMs;
  final String question;
  final String answer;
  final List<String> referenceIds;
  final String language;
  final String script;
  final String? shlokaScript;

  const AskGitaHistoryEntry({
    required this.id,
    required this.askedAtMs,
    required this.question,
    required this.answer,
    required this.referenceIds,
    required this.language,
    required this.script,
    this.shlokaScript,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'askedAtMs': askedAtMs,
        'question': question,
        'answer': answer,
        'referenceIds': referenceIds,
        'language': language,
        'script': script,
        if (shlokaScript != null) 'shlokaScript': shlokaScript,
      };

  factory AskGitaHistoryEntry.fromJson(Map<String, dynamic> json) {
    return AskGitaHistoryEntry(
      id: json['id']?.toString() ?? '',
      askedAtMs: json['askedAtMs'] is int
          ? json['askedAtMs'] as int
          : int.tryParse(json['askedAtMs']?.toString() ?? '') ??
              DateTime.now().millisecondsSinceEpoch,
      question: json['question']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
      referenceIds: (json['referenceIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      language: json['language']?.toString() ?? 'hi',
      script: json['script']?.toString() ?? 'dev',
      shlokaScript: json['shlokaScript']?.toString(),
    );
  }
}
