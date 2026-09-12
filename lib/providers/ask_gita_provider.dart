import 'package:flutter/material.dart';
import '../models/ask_gita_history_entry.dart';
import '../models/shloka_result.dart';
import '../services/ask_gita_history_service.dart';
import '../services/ask_gita_service.dart';
import '../data/database_helper_mobile.dart'; // Or interface, assuming getInitializedDatabaseHelper is available
import '../data/database_helper_interface.dart';
import '../services/analytics_service.dart';

enum MessageSender { user, ai }

class ChatMessage {
  final String text;
  final MessageSender sender;
  final List<ShlokaResult>? references;
  final bool isStreaming;

  ChatMessage({
    required this.text,
    required this.sender,
    this.references,
    this.isStreaming = false,
  });
}

class AskGitaProvider extends ChangeNotifier {
  AskGitaService _service;
  final AskGitaHistoryService _historyService;
  String? _currentApiKey;
  // bool _isQuotaReached = false;
  // VoidCallback? _onQuerySent;

  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  DatabaseHelperInterface? _dbHelper;

  AskGitaProvider(
    String apiKey, {
    AskGitaHistoryService? historyService,
  })  : _service = AskGitaService(apiKey),
        _historyService = historyService ?? AskGitaHistoryService(),
        _currentApiKey = apiKey;

  void updateStatus({required String apiKey}) {
    if (_currentApiKey == apiKey) return;
    _currentApiKey = apiKey;
    _service = AskGitaService(apiKey);
    _service.init();
    notifyListeners();
  }

  Future<void> init() async {
    await _service.init();
    _dbHelper = await getInitializedDatabaseHelper();
  }

  Future<void> sendMessage(
    String query, {
    String language = 'hi',
    String script = 'dev',
    String? shlokaScript,
  }) async {
    final sanitized = AskGitaService.sanitizeQuery(query);
    if (sanitized.isEmpty) return;

    // 1. Add User Message
    _messages.add(ChatMessage(text: sanitized, sender: MessageSender.user));
    _isLoading = true;
    notifyListeners();

    try {
      // 2. Search for relevant Shlokas (The "Brain")
      final shlokaIds = await _service.search(sanitized);

      List<ShlokaResult> results = [];
      if (shlokaIds.isNotEmpty && _dbHelper != null) {
        // Map IDs to expected format for getShlokasByReferences
        final refs = shlokaIds.map((id) => {'id': id}).toList();
        results = await _dbHelper!.getShlokasByReferences(
          refs,
          language: language,
          script: script,
          shlokaScript: shlokaScript,
        );
      }

      // 3. Add Placeholder AI Message
      _messages.add(
        ChatMessage(
          text: '',
          sender: MessageSender.ai,
          references: results,
          isStreaming: true,
        ),
      );
      _isLoading = false; // Stop loading, start streaming
      notifyListeners();

      // 4. Stream Answer (The "Voice")
      final stream = await _service.streamAnswer(
        sanitized,
        results
            .map(
              (s) =>
                  "Chapter ${s.chapterNo} Shloka ${s.shlokNo}: ${s.bhavarth}",
            )
            .toList(),
      );

      String fullResponse = '';

      await for (final chunk in stream) {
        final text = chunk.text;
        if (text != null) {
          fullResponse += text;
          // Update the last message (AI placeholder)
          _messages.last = ChatMessage(
            text: fullResponse,
            sender: MessageSender.ai,
            references: results,
            isStreaming: true,
          );
          notifyListeners();
        }
      }

      // Finalize message
      _messages.last = ChatMessage(
        text: fullResponse,
        sender: MessageSender.ai,
        references: results,
        isStreaming: false,
      );

      AnalyticsService.instance.logAskGita(
        query: sanitized,
        referenceCount: results.length,
      );

      if (fullResponse.trim().isNotEmpty) {
        await _historyService.append(
          AskGitaHistoryEntry(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            askedAtMs: DateTime.now().millisecondsSinceEpoch,
            question: sanitized,
            answer: fullResponse,
            referenceIds: results.map((s) => s.id).toList(),
            language: language,
            script: script,
            shlokaScript: shlokaScript,
          ),
        );
      }
    } catch (e) {
      _messages.add(
        ChatMessage(
          text:
              "I am having trouble connecting to the divine source right now. Please try again. ($e)",
          sender: MessageSender.ai,
        ),
      );
      AnalyticsService.instance.logFeatureUsed(
        feature: 'ask_gita_error',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearChat() {
    _messages.clear();
    notifyListeners();
  }

  Future<List<AskGitaHistoryEntry>> getHistory() => _historyService.load();

  Future<void> clearHistory() => _historyService.clearAll();

  Future<List<ShlokaResult>> resolveHistoryReferences(
    AskGitaHistoryEntry entry,
  ) async {
    if (entry.referenceIds.isEmpty || _dbHelper == null) return [];
    final refs = entry.referenceIds.map((id) => {'id': id}).toList();
    return _dbHelper!.getShlokasByReferences(
      refs,
      language: entry.language,
      script: entry.script,
      shlokaScript: entry.shlokaScript,
    );
  }
}
