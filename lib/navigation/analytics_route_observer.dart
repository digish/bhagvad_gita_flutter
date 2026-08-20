/* 
*  © 2025 Digish Pandya. All rights reserved.
*
*  This mobile application, "Shrimad Bhagavad Gita," including its code, design, and original content, is released under the [MIT License] unless otherwise noted.
*/

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../services/analytics_service.dart';

/// Attaches GA screen_view logging to [GoRouter] location changes.
class AnalyticsRouterListener {
  AnalyticsRouterListener._();

  static String? _lastScreen;
  static String? _lastLocation;
  static VoidCallback? _listener;

  static void attach(GoRouter router) {
    void logCurrent() {
      final uri = router.routerDelegate.currentConfiguration.uri;
      final location = uri.path;
      if (location == _lastLocation) return;
      _lastLocation = location;

      final screen = normalizePath(location);
      if (screen != _lastScreen) {
        _lastScreen = screen;
        AnalyticsService.instance.logScreenView(screenName: screen);
      }

      _logFeatureFromPath(location);
    }

    if (_listener != null) {
      router.routerDelegate.removeListener(_listener!);
    }
    _listener = logCurrent;
    router.routerDelegate.addListener(logCurrent);
    WidgetsBinding.instance.addPostFrameCallback((_) => logCurrent());
  }

  static void _logFeatureFromPath(String path) {
    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return;

    if (parts.first == 'shloka-list' && parts.length >= 2) {
      final chapter = int.tryParse(parts[1]);
      if (chapter != null) {
        AnalyticsService.instance.logChapterOpen(
          chapter: chapter,
          mode: 'list',
        );
      }
    } else if (parts.first == 'book-reading' && parts.length >= 2) {
      final chapter = int.tryParse(parts[1]);
      if (chapter != null) {
        AnalyticsService.instance.logChapterOpen(
          chapter: chapter,
          mode: 'book',
        );
      }
    } else if (parts.first == 'shloka-detail' && parts.length >= 2) {
      AnalyticsService.instance.logFeatureUsed(
        feature: 'shloka_detail',
        params: {'shloka_id': parts[1]},
      );
    } else if (parts.first == 'parayan') {
      AnalyticsService.instance.logFeatureUsed(feature: 'parayan');
    } else if (parts.first == 'ask-gita') {
      AnalyticsService.instance.logFeatureUsed(feature: 'ask_gita_screen');
    } else if (parts.first == 'image-creator') {
      AnalyticsService.instance.logFeatureUsed(feature: 'image_creator');
    } else if (parts.first == 'audio-management') {
      AnalyticsService.instance.logFeatureUsed(feature: 'audio_management');
    }
  }

  /// `/` → search, `/shloka-detail/2.7` → shloka_detail, etc.
  static String normalizePath(String path) {
    if (path == '/' || path.isEmpty) return 'search';
    final segment = path.startsWith('/')
        ? path.substring(1).split('/').first
        : path.split('/').first;
    return segment.replaceAll('-', '_').replaceAll(':', '');
  }
}
