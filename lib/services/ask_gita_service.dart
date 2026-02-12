import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../services/remote_config_service.dart';
import '../core/secrets_config.dart';

class AskGitaService {
  static const String _embeddingsPath = 'assets/gita_embeddings.json';

  final String apiKey;
  late final GenerativeModel _embeddingModel;
  late final GenerativeModel _chatModel;

  List<_EmbeddingItem> _vectorStore = [];
  bool _isLoaded = false;

  AskGitaService(this.apiKey) {
    _embeddingModel = GenerativeModel(
      model: RemoteConfigService.embeddingModel,
      apiKey: apiKey,
    );
    _chatModel = GenerativeModel(
      model: RemoteConfigService.chatModel,
      apiKey: apiKey,
    );
  }

  Future<void> init() async {
    if (_isLoaded) return;

    try {
      final jsonString = await rootBundle.loadString(_embeddingsPath);
      final List<dynamic> jsonList = jsonDecode(jsonString);

      _vectorStore = jsonList.map((item) {
        return _EmbeddingItem(
          id: item['id'],
          vector: (item['vector'] as List).cast<double>(),
        );
      }).toList();

      _isLoaded = true;
      print('[AskGitaService] Loaded ${_vectorStore.length} embeddings.');
    } catch (e) {
      print('[AskGitaService] Error loading embeddings: $e');
    }
  }

  // Returns list of Shloka IDs (e.g. ["1.1", "2.45"])
  Future<List<String>> search(String query) async {
    if (!_isLoaded) await init();

    try {
      // 1. Embed User Query
      final content = Content.text(query);
      final response = await _embeddingModel.embedContent(content);
      final queryVector = response.embedding.values;

      // 2. Cosine Similarity Search
      final List<_ScoredItem> scores = [];

      for (var item in _vectorStore) {
        final score = _cosineSimilarity(queryVector, item.vector);
        scores.add(_ScoredItem(item.id, score));
      }

      // 3. Sort & Top K
      scores.sort((a, b) => b.score.compareTo(a.score));

      // Return Top 3 matches
      return scores.take(3).map((s) => s.id).toList();
    } catch (e) {
      print('[AskGitaService] Search error: $e');
      return [];
    }
  }

  Future<Stream<GenerateContentResponse>> streamAnswer(
    String userQuery,
    List<String> contextShlokas, // Passed from UI/Provider to keep service pure
  ) async {
    // Construct the Prompt using the SecretsConfig
    final prompt = SecretsConfig.aiSystemPrompt
        .replaceFirst('{{CONTEXT_SHLOKAS}}', contextShlokas.toString())
        .replaceFirst('{{USER_QUERY}}', userQuery);

    final content = [Content.text(prompt)];
    return _chatModel.generateContentStream(content);
  }

  // --- Math Util ---
  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;
    double dot = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    return dot / (sqrt(normA) * sqrt(normB));
  }
}

class _EmbeddingItem {
  final String id;
  final List<double> vector;

  _EmbeddingItem({required this.id, required this.vector});
}

class _ScoredItem {
  final String id;
  final double score;

  _ScoredItem(this.id, this.score);
}
