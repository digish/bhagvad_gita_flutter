import 'dart:convert';
import 'package:http/http.dart' as http;

class RemoteConfigService {
  // TODO: Replace with your actual GitHub Raw URL or hosted JSON URL
  static const String _configUrl =
      'https://raw.githubusercontent.com/digish/bhagvad_gita_flutter/main/assets/config/ai_config.json';

  static const String _defaultChatModel = 'gemini-flash-lite-latest';
  static const String _defaultEmbeddingModel = 'gemini-embedding-001';

  static String _chatModel = _defaultChatModel;
  static String _embeddingModel = _defaultEmbeddingModel;

  static String get chatModel => _chatModel;
  static String get embeddingModel => _embeddingModel;

  static Future<void> fetchConfig() async {
    try {
      final response = await http.get(Uri.parse(_configUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data.containsKey('chat_model')) {
          _chatModel = data['chat_model'];
        }
        if (data.containsKey('embedding_model')) {
          _embeddingModel = data['embedding_model'];
        }

        print(
          '[RemoteConfig] Updated: Chat=$_chatModel, Embed=$_embeddingModel',
        );
      } else {
        print('[RemoteConfig] Failed to load config: ${response.statusCode}');
      }
    } catch (e) {
      print('[RemoteConfig] Error fetching config: $e');
      // Fallback to defaults is automatic since variables are initialized
    }
  }
}
