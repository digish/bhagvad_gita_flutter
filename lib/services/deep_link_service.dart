import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../navigation/app_router.dart';
import 'deep_link_parser.dart';

/// Handles opens from home widget taps and local notification taps,
/// navigating to a specific shloka when an id is present.
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  static const String uriScheme = DeepLinkParser.uriScheme;
  static const String shlokaHost = DeepLinkParser.shlokaHost;

  bool _handling = false;

  static Uri uriForShloka(String shlokaId) =>
      DeepLinkParser.uriForShloka(shlokaId);

  static String? extractShlokaId({Uri? uri, String? payload}) =>
      DeepLinkParser.extractShlokaId(uri: uri, payload: payload);

  Future<void> handleUri(Uri? uri) async {
    final id = extractShlokaId(uri: uri);
    if (id == null) return;
    await openShloka(id);
  }

  Future<void> handlePayload(String? payload) async {
    final id = extractShlokaId(payload: payload);
    if (id == null) {
      debugPrint('DeepLinkService: notification had no shloka payload');
      return;
    }
    await openShloka(id);
  }

  Future<void> openShloka(String shlokaId) async {
    if (_handling) return;
    _handling = true;
    try {
      final target = AppRoutes.shlokaDetailPath(shlokaId);
      final current = router.routerDelegate.currentConfiguration.uri.toString();
      if (current.contains('shloka-detail') && current.contains(shlokaId)) {
        return;
      }
      debugPrint('DeepLinkService: opening shloka $shlokaId');
      router.go(target);
    } catch (e) {
      debugPrint('DeepLinkService: navigation failed: $e');
    } finally {
      _handling = false;
    }
  }

  /// Cold-start: widget launch URI and/or notification that opened the app.
  Future<void> handleInitialLinks({
    FlutterLocalNotificationsPlugin? notificationsPlugin,
  }) async {
    try {
      final widgetUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (widgetUri != null) {
        await handleUri(widgetUri);
        return;
      }
    } catch (e) {
      debugPrint('DeepLinkService: widget launch check failed: $e');
    }

    try {
      final plugin =
          notificationsPlugin ?? FlutterLocalNotificationsPlugin();
      final details = await plugin.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp == true) {
        await handlePayload(details!.notificationResponse?.payload);
      }
    } catch (e) {
      debugPrint('DeepLinkService: notification launch check failed: $e');
    }
  }
}
