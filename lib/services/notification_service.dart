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
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

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
      initializationSettings,
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

  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      0, // ID
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
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
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Test method to show an immediate notification (for development/testing only)
  Future<void> showTestNotification() async {
    await _notificationsPlugin.show(
      999, // Test notification ID
      'Maintain your Spiritual Streak! 🙏',
      DailyMessageService.getTodaysMessage(),
      const NotificationDetails(
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
      997, // Test delayed notification ID
      'Maintain your Spiritual Streak! 🙏',
      DailyMessageService.getTodaysMessage(),
      scheduledTime,
      const NotificationDetails(
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
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Schedule a test notification exactly 1 minute from now (for testing)
  Future<void> scheduleTestNotificationInOneMinute() async {
    final tz.TZDateTime scheduledTime = tz.TZDateTime.now(
      tz.local,
    ).add(const Duration(minutes: 1));

    await _notificationsPlugin.zonedSchedule(
      998, // Test scheduled notification ID
      'Maintain your Spiritual Streak! 🙏',
      'Krishna is waiting for our daily chat. A quick shloka a day keeps Maya away. 😉',
      scheduledTime,
      const NotificationDetails(
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
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
