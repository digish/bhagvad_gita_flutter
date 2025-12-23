import 'dart:convert';
import 'dart:math';
import '../../data/database_helper_interface.dart';
import '../../models/shloka_result.dart';
import 'ai_service.dart';

class _ChunkMatch {
  final String shlokaId;
  final String chunkText;
  final String sourceType;
  final double score;

  _ChunkMatch({
    required this.shlokaId,
    required this.chunkText,
    required this.sourceType,
    required this.score,
  });
}

class SimilaritySearch {
  final DatabaseHelperInterface _dbHelper;
  final AIService _aiService = AIService();

  SimilaritySearch(this._dbHelper);

  // Cache: List of {shloka_id, chunk_text, vector, source_type}
  List<Map<String, dynamic>>? _cachedEmbeddings;

  Future<void> preloadEmbeddings() async {
    if (_cachedEmbeddings != null) return;

    // Returns rows from ai_search_index
    // Expected columns: shloka_id, chunk_text, embedding, source_type
    final rows = await _dbHelper.getEmbeddings();

    _cachedEmbeddings = rows.map((row) {
      List<dynamic> jsonList = jsonDecode(row['embedding']);
      List<double> vector = jsonList.cast<double>();
      return {
        'shloka_id': row['shloka_id'],
        'chunk_text': row['chunk_text'],
        'source_type': row['source_type'],
        'vector': vector,
      };
    }).toList();
  }

  Future<List<ShlokaResult>> search(
    String query, {
    int topK = 20,
    String language = 'hi',
    String script = 'dev',
  }) async {
    // 1. Get Query Vector
    List<double> queryVector;
    try {
      queryVector = await _aiService.getQueryVector(query);
    } catch (e) {
      print("Error generating query vector: $e");
      return [];
    }

    // 2. Load DB Vectors
    if (_cachedEmbeddings == null) {
      await preloadEmbeddings();
    }
    if (_cachedEmbeddings == null || _cachedEmbeddings!.isEmpty) {
      return [];
    }

    // 3. Compute Cosine Similarity for ALL chunks
    Map<String, List<_ChunkMatch>> hitsByShloka = {};

    for (var item in _cachedEmbeddings!) {
      List<double> docVector = item['vector'];
      double score = _cosineSimilarity(queryVector, docVector);

      // Filter out very low coherence to reduce noise processing
      if (score > 0.1) {
        String id = item['shloka_id'];
        if (!hitsByShloka.containsKey(id)) {
          hitsByShloka[id] = [];
        }
        hitsByShloka[id]!.add(
          _ChunkMatch(
            shlokaId: id,
            chunkText: item['chunk_text'] ?? '',
            sourceType: item['source_type'] ?? 'unknown',
            score: score,
          ),
        );
      }
    }

    // 4. Aggregate & Rank
    List<Map<String, dynamic>> rankedResults = [];

    for (var id in hitsByShloka.keys) {
      var chunks = hitsByShloka[id]!;
      // Find best chunk
      _ChunkMatch bestChunk = chunks.reduce(
        (a, b) => a.score > b.score ? a : b,
      );

      double baseScore = bestChunk.score;

      // Bonus: +0.05 if >1 chunks have score > 0.6
      int strongMatches = chunks.where((c) => c.score > 0.6).length;
      double bonus = (strongMatches > 1) ? 0.05 : 0.0;

      double finalScore = baseScore + bonus;

      rankedResults.add({
        'id': id,
        'finalScore': finalScore,
        'bestChunk': bestChunk,
        'matchCount': chunks.length, // Store how many vectors matched
      });
    }

    // Sort Descending by Final Score
    rankedResults.sort(
      (a, b) =>
          (b['finalScore'] as double).compareTo(a['finalScore'] as double),
    );

    // Top K
    final topResults = rankedResults.take(topK).toList();

    // 5. Hydrate Results
    List<ShlokaResult> finalOutput = [];

    // Fetch details in parallel
    for (int i = 0; i < topResults.length; i++) {
      var r = topResults[i];
      String id = r['id'];
      _ChunkMatch bestChunk = r['bestChunk'];
      double finalScore = r['finalScore'];
      int matchCount = r['matchCount'];
      bool isTopTwo = i < 2; // Check if it's one of the top 2 results

      finalOutput.add(
        await _hydrateShloka(
              id,
              bestChunk,
              finalScore,
              matchCount,
              isTopResult: isTopTwo,
              language: language,
              script: script,
            ) ??
            ShlokaResult(
              id: id,
              chapterNo: '',
              shlokNo: '',
              shlok: '',
              anvay: '',
              bhavarth: '',
              matchSnippet: 'Error loading',
            ),
      );
    }

    // Clean up any potential failed loads (though we handle null fallback above)
    return finalOutput.where((s) => s.chapterNo.isNotEmpty).toList();
  }

  Future<ShlokaResult?> _hydrateShloka(
    String id,
    _ChunkMatch match,
    double finalScore,
    int matchCount, {
    bool isTopResult = false,
    String language = 'hi',
    String script = 'dev',
  }) async {
    final shloka = await _dbHelper.getShlokaById(
      id,
      language: language,
      script: script,
    );
    if (shloka != null) {
      String source = match.sourceType.toUpperCase();
      String confidence = (finalScore * 100).toStringAsFixed(1); // Show decimal

      // Basic Info: Score & Count
      String debugInfo = "Confidence: $confidence% | Matches: $matchCount";

      // Conditional text display
      String textDisplay = "";
      if (isTopResult) {
        // For top results, show the actual text matched
        textDisplay = "\n$source Match: \"${match.chunkText}\"";
      } else {
        // For others, just show source type
        textDisplay = "\nMatched in: $source";
      }

      shloka.matchSnippet = "$debugInfo$textDisplay";
    }
    return shloka;
  }

  double calculateMagnitude(List<double> vector) {
    double sumOfSquares = 0.0;
    for (var value in vector) {
      sumOfSquares += value * value;
    }
    return sqrt(sumOfSquares);
  }

  double _cosineSimilarity(List<double> vecA, List<double> vecB) {
    if (vecA.length != vecB.length) return 0.0;

    double dotProduct = 0.0;
    for (int i = 0; i < vecA.length; i++) {
      dotProduct += vecA[i] * vecB[i];
    }

    double magnitudeA = calculateMagnitude(vecA);
    double magnitudeB = calculateMagnitude(vecB);

    if (magnitudeA == 0.0 || magnitudeB == 0.0) return 0.0;

    return dotProduct / (magnitudeA * magnitudeB);
  }
}
