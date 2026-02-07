import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/timing_model.dart';

class TimingService {
  // Cache mechanism: Map<ShlokaID, List<WordTiming>>
  static final Map<String, List<WordTiming>> _cache = {};
  static bool _timingsLoaded = false;

  /// Loads the timings.json file into memory.
  /// Should be called at app startup or when karaoke mode is first activated.
  static Future<void> loadTimings() async {
    if (_timingsLoaded) return;

    try {
      final jsonString = await rootBundle.loadString(
        'assets/database/timings.json',
      );
      final Map<String, dynamic> data = json.decode(jsonString);

      data.forEach((key, value) {
        if (value is List) {
          _cache[key] = value
              .map((e) => WordTiming.fromMap(e as Map<String, dynamic>))
              .toList();
        }
      });

      _timingsLoaded = true;
      debugPrint("TimingService: Loaded timings for ${_cache.length} shlokas.");
    } catch (e) {
      debugPrint("TimingService: Error loading timings: $e");
    }
  }

  /// Retrieves the list of word timings for a given shloka ID (e.g., "1.1").
  static List<WordTiming>? getTimings(String shlokaId) {
    return _cache[shlokaId];
  }

  /// Helper: Find the current word at a specific timestamp
  static WordTiming? getWordAt(String shlokaId, Duration position) {
    final timings = _cache[shlokaId];
    if (timings == null) return null;

    final seconds = position.inMilliseconds / 1000.0;

    // Simple linear scan (list is short, usually < 20 words)
    for (final timing in timings) {
      if (seconds >= timing.start && seconds <= timing.end) {
        return timing;
      }
    }
    return null;
  }
}
