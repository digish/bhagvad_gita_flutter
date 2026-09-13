/* 
*  © 2025 Digish Pandya. All rights reserved.
*
*  This mobile application, "Shrimad Bhagavad Gita," including its code, design, and original content, is released under the [MIT License] unless otherwise noted.
*/

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// Central Google Analytics (Firebase) facade for screen, feature, config, and link events.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  FirebaseAnalytics? _analytics;
  bool _ready = false;

  bool get isReady => _ready;

  FirebaseAnalyticsObserver? get navigatorObserver =>
      _ready && _analytics != null
          ? FirebaseAnalyticsObserver(analytics: _analytics!)
          : null;

  Future<void> init() async {
    if (_ready) return;
    if (!DefaultFirebaseOptions.isConfigured) {
      debugPrint(
        '[Analytics] Skipped — run `flutterfire configure` and set '
        'DefaultFirebaseOptions.isConfigured = true.',
      );
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _analytics = FirebaseAnalytics.instance;
      await _analytics!.setAnalyticsCollectionEnabled(true);
      _ready = true;
      debugPrint('[Analytics] Ready');
    } catch (e, st) {
      debugPrint('[Analytics] Init failed: $e\n$st');
      _ready = false;
      _analytics = null;
    }
  }

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _log(
      () => _analytics!.logScreenView(
        screenName: _truncate(screenName, 36),
        screenClass: screenClass != null ? _truncate(screenClass, 36) : null,
      ),
    );
  }

  Future<void> logFeatureUsed({
    required String feature,
    Map<String, Object>? params,
  }) async {
    await _logEvent('feature_used', {
      'feature_name': _truncate(feature, 40),
      ...?_sanitize(params),
    });
  }

  Future<void> logConfigChange({
    required String setting,
    required String value,
  }) async {
    await _logEvent('config_change', {
      'setting_name': _truncate(setting, 40),
      'setting_value': _truncate(value, 100),
    });
  }

  /// Sets durable user properties so GA can segment by preferred config.
  Future<void> setUserConfig({
    String? language,
    String? script,
    String? theme,
    String? homeUiMode,
    bool? forceSanskritShloka,
    bool? showClassicalCommentaries,
    bool? reminderEnabled,
  }) async {
    if (!_ready || _analytics == null) return;
    try {
      if (language != null) {
        await _analytics!.setUserProperty(
          name: 'app_language',
          value: _truncate(language, 36),
        );
      }
      if (script != null) {
        await _analytics!.setUserProperty(
          name: 'app_script',
          value: _truncate(script, 36),
        );
      }
      if (theme != null) {
        await _analytics!.setUserProperty(
          name: 'theme_mode',
          value: _truncate(theme, 36),
        );
      }
      if (homeUiMode != null) {
        await _analytics!.setUserProperty(
          name: 'home_ui_mode',
          value: _truncate(homeUiMode, 36),
        );
      }
      if (forceSanskritShloka != null) {
        await _analytics!.setUserProperty(
          name: 'force_sanskrit',
          value: forceSanskritShloka ? 'true' : 'false',
        );
      }
      if (showClassicalCommentaries != null) {
        await _analytics!.setUserProperty(
          name: 'classical_commentary',
          value: showClassicalCommentaries ? 'true' : 'false',
        );
      }
      if (reminderEnabled != null) {
        await _analytics!.setUserProperty(
          name: 'reminder_enabled',
          value: reminderEnabled ? 'true' : 'false',
        );
      }
    } catch (e) {
      debugPrint('[Analytics] setUserConfig failed: $e');
    }
  }

  Future<void> logLinkOpen({
    required String url,
    required String source,
  }) async {
    await _logEvent('link_open', {
      'link_url': _truncate(url, 100),
      'link_source': _truncate(source, 40),
      'link_host': _truncate(Uri.tryParse(url)?.host ?? 'unknown', 40),
    });
  }

  Future<void> logSearch({
    required String query,
    required int resultCount,
    String mode = 'text',
  }) async {
    await _logEvent('search', {
      'search_term': _truncate(query, 100),
      'result_count': resultCount,
      'search_mode': _truncate(mode, 40),
    });
  }

  Future<void> logAskGita({
    required String query,
    required int referenceCount,
  }) async {
    await _logEvent('ask_gita', {
      'query_length': query.length,
      'reference_count': referenceCount,
    });
  }

  Future<void> logAudioPlay({
    required String shlokaId,
    required String mode,
    String playbackContext = 'shloka_card',
  }) async {
    await _logEvent('audio_play', {
      'shloka_id': _truncate(shlokaId, 40),
      'playback_mode': _truncate(mode, 40),
      'playback_context': _truncate(playbackContext, 40),
    });
  }

  Future<void> logAudioModeChange(String mode) async {
    await _logEvent('audio_mode_change', {
      'playback_mode': _truncate(mode, 40),
    });
  }

  Future<void> logShare({
    required String contentType,
    String? itemId,
  }) async {
    await _logEvent('share', {
      'content_type': _truncate(contentType, 40),
      if (itemId != null) 'item_id': _truncate(itemId, 40),
    });
  }

  Future<void> logBookmark({
    required String action,
    String? listName,
    String? shlokaId,
  }) async {
    await _logEvent('bookmark_action', {
      'action': _truncate(action, 40),
      if (listName != null) 'list_name': _truncate(listName, 40),
      if (shlokaId != null) 'shloka_id': _truncate(shlokaId, 40),
    });
  }

  Future<void> logDeepLink({
    required String source,
    String? shlokaId,
  }) async {
    await _logEvent('deep_link_open', {
      'source': _truncate(source, 40),
      if (shlokaId != null) 'shloka_id': _truncate(shlokaId, 40),
    });
  }

  Future<void> logAdReward({required String placement}) async {
    await _logEvent('ad_reward', {
      'placement': _truncate(placement, 40),
    });
  }

  Future<void> logChapterOpen({
    required int chapter,
    required String mode,
  }) async {
    await _logEvent('chapter_open', {
      'chapter_number': chapter,
      'read_mode': _truncate(mode, 40),
    });
  }

  Future<void> logEvent(String name, [Map<String, Object>? params]) =>
      _logEvent(name, params);

  Future<void> _logEvent(String name, Map<String, Object>? params) async {
    await _log(() => _analytics!.logEvent(
          name: _truncate(name, 40),
          parameters: _sanitize(params),
        ));
  }

  Future<void> _log(Future<void> Function() action) async {
    if (!_ready || _analytics == null) return;
    try {
      await action();
    } catch (e) {
      debugPrint('[Analytics] Event failed: $e');
    }
  }

  Map<String, Object>? _sanitize(Map<String, Object>? params) {
    if (params == null || params.isEmpty) return null;
    final out = <String, Object>{};
    for (final entry in params.entries) {
      final key = _truncate(entry.key, 40);
      final value = entry.value;
      if (value is String) {
        out[key] = _truncate(value, 100);
      } else if (value is num || value is bool) {
        out[key] = value;
      } else {
        out[key] = _truncate(value.toString(), 100);
      }
    }
    return out;
  }

  static String _truncate(String value, int max) =>
      value.length <= max ? value : value.substring(0, max);
}
