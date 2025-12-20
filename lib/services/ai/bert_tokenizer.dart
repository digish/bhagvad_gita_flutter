class BertTokenizer {
  final Map<String, int> vocab;
  final int maxLen;
  final bool doLowerCase;

  BertTokenizer(this.vocab, {this.maxLen = 128, this.doLowerCase = true});

  /// Loads vocabulary from a string content (read from assets)
  static BertTokenizer fromString(String vocabContent, {int maxLen = 128}) {
    final vocab = <String, int>{};
    final lines = vocabContent.split('\n');
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].trim().isNotEmpty) {
        vocab[lines[i].trim()] = i;
      }
    }
    return BertTokenizer(vocab, maxLen: maxLen);
  }

  /// Tokenizes the input text and returns inputIds and attentionMask
  Map<String, List<int>> tokenize(String text) {
    if (doLowerCase) {
      text = text.toLowerCase();
    }

    // Basic cleaning: remove punctuation using Unicode aware regex
    // This regex keeps alphanumeric characters (including Hindi) and spaces.
    // It removes punctuation symbols.
    // \p{L} matches any unicode letter, \p{N} matches any number.
    // We replace anything that is NOT a letter, number, or whitespace with empty string.
    text = text.replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), '');

    // Basic whitespace tokenization
    final tokens = text
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();

    final List<int> ids = [];

    // Add [CLS] token at the start
    ids.add(vocab['[CLS]'] ?? 101); // 101 is usually [CLS] in BERT/XLM-R

    for (var word in tokens) {
      if (ids.length >= maxLen - 1) break; // Reserve space for [SEP]

      // Simple WordPiece/Subword tokenization logic could go here.
      // For this simplified version (and since many specific multilingual models use SentencePiece),
      // we will do a direct lookup. If a word isn't in vocab, we map to [UNK].
      // ideally, one should use a proper WordPiece algorithm here.

      if (vocab.containsKey(word)) {
        ids.add(vocab[word]!);
      } else {
        // Try to tokenize as subwords if the exact word isn't found?
        // This is complex to implement fully without a library.
        // Fallback to [UNK] for now to keep it simple as requested.
        // 'sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2' is XLM-R based usually.
        // If using BERT vocab, [UNK] is usually 100.
        ids.add(vocab['[UNK]'] ?? 100);
      }
    }

    // Add [SEP] token at the end
    if (ids.length < maxLen) {
      ids.add(vocab['[SEP]'] ?? 102); // 102 is usually [SEP]
    } else {
      // If we hit the limit, replace the last token with [SEP]
      ids[maxLen - 1] = vocab['[SEP]'] ?? 102;
    }

    // Padding
    final inputIds = List<int>.from(ids); // growable by default
    final attentionMask = List<int>.filled(
      ids.length,
      1,
      growable: true,
    ); // Explicitly growable

    while (inputIds.length < maxLen) {
      inputIds.add(0); // 0 is usually [PAD]
      attentionMask.add(0); // 0 for padding
    }

    // Truncate if exceeds (shouldn't happen due to logic above, but safety)
    if (inputIds.length > maxLen) {
      return {
        'inputIds': inputIds.sublist(0, maxLen),
        'attentionMask': attentionMask.sublist(0, maxLen),
      };
    }

    return {'inputIds': inputIds, 'attentionMask': attentionMask};
  }
}
