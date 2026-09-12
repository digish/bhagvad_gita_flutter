import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ask_gita_history_entry.dart';

class AskGitaHistoryService {
  static const String _storageKey = 'ask_gita_history_v1';
  static const int maxEntries = 20;

  Future<List<AskGitaHistoryEntry>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return [];

      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      return decoded
          .whereType<Map>()
          .map((e) => AskGitaHistoryEntry.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.id.isNotEmpty && e.question.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('[AskGitaHistoryService] Failed to load history: $e');
      return [];
    }
  }

  Future<void> append(AskGitaHistoryEntry entry) async {
    if (entry.answer.trim().isEmpty) return;

    final existing = await load();
    final updated = [entry, ...existing.where((e) => e.id != entry.id)]
        .take(maxEntries)
        .toList();

    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(updated.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
