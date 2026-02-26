import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'daily_message_service.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    String timeZoneName = (await FlutterTimezone.getLocalTimezone()).identifier;

    // Safety check for common deprecated or missing timezone identifiers
    if (timeZoneName == 'Asia/Calcutta') {
      timeZoneName = 'Asia/Kolkata';
    }

    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      // Fallback to UTC if the identifier is still not recognized to prevent crash
      print(
        "[NotificationService] Warning: Could not find location $timeZoneName, falling back to UTC. error: $e",
      );
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: false, // Don't ask at launch
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap if needed
      },
    );
  }

  Future<bool> requestPermissions() async {
    // 1. First check with permission_handler for better state detection
    final status = await Permission.notification.request();

    if (status.isGranted) return true;

    // 2. Fallback to plugin's request for platform specifics (especially older iOS)
    final bool? result = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // Android 13+ permission request fallback
    final bool? androidResult = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    return status.isGranted || (result ?? false) || (androidResult ?? false);
  }

  /// Checks the current permission status using permission_handler.
  /// Returns [PermissionStatus.permanentlyDenied] if the user needs to enable it in settings.
  Future<PermissionStatus> checkPermissionStatus() async {
    return await Permission.notification.status;
  }

  /// Opens the system app settings page.
  Future<void> openNotificationSettings() async {
    await openAppSettings(); // This is the top-level function from permission_handler
  }

  // Pre-schedules reminders for the next 30 days to ensure a unique message each day.
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    // First, cancel previously scheduled daily reminders to avoid duplicates.
    // Assuming IDs 1-30 are used for daily reminders.
    for (int i = 1; i <= 30; i++) {
      await _notificationsPlugin.cancel(id: i);
    }

    final now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final targetDate = now.add(Duration(days: i));
      final dayIndex = targetDate.difference(DateTime(2025, 1, 1)).inDays;

      final titles = [
        'Divine Wisdom for Today 🙏',
        'Spirituality Awaits... 📿',
        'A Message from Krishna ✨',
        'Maintain your Spiritual Streak! 🌟',
        'Daily Gita Insight 📖',
        'Wisdom of the Gita 🕉️',
        'Krishna\'s Guidance Today 🌈',
        'Spiritual Growth Awaits 🧘',
      ];
      final title = titles[dayIndex % titles.length];
      final body = DailyMessageService.getMessageForDay(dayIndex % 365 + 1);

      var scheduledTime = tz.TZDateTime(
        tz.local,
        targetDate.year,
        targetDate.month,
        targetDate.day,
        hour,
        minute,
      );

      // If scheduled time in the past for today, skip it
      if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
        if (i == 0) continue;
      }

      await _notificationsPlugin.zonedSchedule(
        id: i + 1, // IDs 1 to 30
        title: title,
        body: body,
        scheduledDate: scheduledTime,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_wisdom_channel',
            'Daily Wisdom Reminders',
            channelDescription:
                'Witty reminders to read the Gita and maintain your streak.',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
    print(
      '🔔 30 diverse daily notifications scheduled starting around $hour:$minute',
    );
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Test method to show an immediate notification (for development/testing only)
  Future<void> showTestNotification() async {
    await _notificationsPlugin.show(
      id: 999, // Test notification ID
      title: 'Maintain your Spiritual Streak! 🙏',
      body: DailyMessageService.getTodaysMessage(),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_wisdom_channel',
          'Daily Wisdom Reminders',
          channelDescription:
              'Witty reminders to read the Gita and maintain your streak.',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Test method to show a notification after 5 seconds (gives time to background the app)
  Future<void> showTestNotificationAfterDelay() async {
    final tz.TZDateTime scheduledTime = tz.TZDateTime.now(
      tz.local,
    ).add(const Duration(seconds: 5));

    await _notificationsPlugin.zonedSchedule(
      id: 997, // Test delayed notification ID
      title: 'Maintain your Spiritual Streak! 🙏',
      body: DailyMessageService.getTodaysMessage(),
      scheduledDate: scheduledTime,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_wisdom_channel',
          'Daily Wisdom Reminders',
          channelDescription:
              'Witty reminders to read the Gita and maintain your streak.',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Schedule a test notification exactly 1 minute from now (for testing)
  Future<void> scheduleTestNotificationInOneMinute() async {
    final tz.TZDateTime scheduledTime = tz.TZDateTime.now(
      tz.local,
    ).add(const Duration(minutes: 1));

    await _notificationsPlugin.zonedSchedule(
      id: 998, // Test scheduled notification ID
      title: 'Maintain your Spiritual Streak! 🙏',
      body:
          'Krishna is waiting for our daily chat. A quick shloka a day keeps Maya away. 😉',
      scheduledDate: scheduledTime,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_wisdom_channel',
          'Daily Wisdom Reminders',
          channelDescription:
              'Witty reminders to read the Gita and maintain your streak.',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
