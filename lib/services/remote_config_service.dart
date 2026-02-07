import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RemoteConfigService {
  // TODO: Replace with your actual GitHub Raw URL or hosted JSON URL
  static const String _configUrl =
      'https://raw.githubusercontent.com/digish/bhagvad_gita_flutter/main/assets/config/ai_config.json';

  static const String _prefKeyConfigData = 'ai_config_data';
  static const String _prefKeyLastFetch = 'ai_config_last_fetch';

  static const String _defaultChatModel = 'gemini-flash-lite-latest';
  static const String _defaultEmbeddingModel = 'gemini-embedding-001';

  static String _chatModel = _defaultChatModel;
  static String _embeddingModel = _defaultEmbeddingModel;

  static String get chatModel => _chatModel;
  static String get embeddingModel => _embeddingModel;

  static Future<void> fetchConfig() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Load cached config first
    _loadFromCache(prefs);

    // 2. Check if we need to fetch fresh config (older than 24 hours)
    final lastFetchMs = prefs.getInt(_prefKeyLastFetch) ?? 0;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final oneDayMs = 24 * 60 * 60 * 1000;

    if (nowMs - lastFetchMs < oneDayMs) {
      print('[RemoteConfig] Using cached config (Fresh)');
      return;
    }

    try {
      print('[RemoteConfig] Fetching fresh config...');
      final response = await http.get(Uri.parse(_configUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Update local variables
        _updateVariables(data);

        // Update Cache
        await prefs.setString(_prefKeyConfigData, response.body);
        await prefs.setInt(_prefKeyLastFetch, nowMs);

        print(
          '[RemoteConfig] Updated & Cached: Chat=$_chatModel, Embed=$_embeddingModel',
        );
      } else {
        print('[RemoteConfig] Failed to load config: ${response.statusCode}');
      }
    } catch (e) {
      print('[RemoteConfig] Error fetching config: $e');
      // Fallback to cache (already loaded) or defaults
    }
  }

  static void _loadFromCache(SharedPreferences prefs) {
    if (prefs.containsKey(_prefKeyConfigData)) {
      try {
        final jsonString = prefs.getString(_prefKeyConfigData);
        if (jsonString != null) {
          final Map<String, dynamic> data = jsonDecode(jsonString);
          _updateVariables(data);
          print('[RemoteConfig] Loaded from Cache');
        }
      } catch (e) {
        print('[RemoteConfig] Error loading cache: $e');
      }
    }
  }

  static void _updateVariables(Map<String, dynamic> data) {
    if (data.containsKey('chat_model')) {
      _chatModel = data['chat_model'];
    }
    if (data.containsKey('embedding_model')) {
      _embeddingModel = data['embedding_model'];
    }
  }
}
