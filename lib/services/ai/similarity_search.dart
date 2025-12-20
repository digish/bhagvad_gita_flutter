import 'dart:convert';
import 'dart:math';
import '../../data/database_helper_interface.dart';
import 'ai_service.dart';

class ShlokaMatch {
  final String shlokaId;
  final String bhavarth;
  final double score;

  ShlokaMatch({
    required this.shlokaId,
    required this.bhavarth,
    required this.score,
  });
}

class SimilaritySearch {
  final DatabaseHelperInterface _dbHelper;
  final AIService _aiService = AIService();

  SimilaritySearch(this._dbHelper);

  // Cache database embeddings to avoid parsing JSON every search?
  // Use with caution for large DBs. 700 * 2 = 1400 rows is small enough (~5MB maybe).
  List<Map<String, dynamic>>? _cachedEmbeddings;

  Future<void> preloadEmbeddings() async {
    if (_cachedEmbeddings != null) return;

    final rows = await _dbHelper.getEmbeddings();

    _cachedEmbeddings = rows.map((row) {
      // Parse JSON string to List<double>
      List<dynamic> jsonList = jsonDecode(row['embedding']);
      List<double> vector = jsonList.cast<double>();
      return {
        'shloka_id': row['shloka_id'],
        'bhavarth': row['bhavarth'],
        'vector': vector,
      };
    }).toList();
  }

  Future<List<ShlokaMatch>> search(String query, {int topK = 10}) async {
    // 1. Get Query Vector
    List<double> queryVector;
    try {
      queryVector = await _aiService.getQueryVector(query);
    } catch (e) {
      print("Error generating query vector: $e");
      return [];
    }

    // 2. Load DB Vectors (if not cached)
    if (_cachedEmbeddings == null) {
      await preloadEmbeddings();
    }

    if (_cachedEmbeddings == null || _cachedEmbeddings!.isEmpty) {
      return [];
    }

    // 3. Compute Cosine Similarity
    List<ShlokaMatch> matches = [];

    for (var item in _cachedEmbeddings!) {
      List<double> docVector = item['vector'];
      double score = _cosineSimilarity(queryVector, docVector);

      matches.add(
        ShlokaMatch(
          shlokaId: item['shloka_id'],
          bhavarth: item['bhavarth'],
          score: score,
        ),
      );
    }

    // 4. Sort and Return Top K
    matches.sort((a, b) => b.score.compareTo(a.score)); // Descending order

    return matches.take(topK).toList();
  }

  double _cosineSimilarity(List<double> vecA, List<double> vecB) {
    if (vecA.length != vecB.length) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < vecA.length; i++) {
      dotProduct += vecA[i] * vecB[i];
      normA += vecA[i] * vecA[i];
      normB += vecB[i] * vecB[i];
    }

    if (normA == 0.0 || normB == 0.0) return 0.0;

    return dotProduct / (sqrt(normA) * sqrt(normB));
  }
}
