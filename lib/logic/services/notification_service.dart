import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();

    // Map the device's actual location to the timezone database
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // Debug: Confirm timezone is ready
    try {
      debugPrint(
        "Notification System: Timezone initialized as ${tz.local.name}",
      );
    } catch (e) {
      debugPrint(
        "Notification System: Timezone default error, using UTC fallback",
      );
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // Use 'Darwin' settings for iOS/macOS configuration
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // Strict compliance: Don't ask on boot
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint("Notification Tapped: ${details.payload}");
      },
    );

    _setupAndroidChannels();
  }

  void _setupAndroidChannels() async {
    const periodChannel = AndroidNotificationChannel(
      'cycle_alerts',
      'Cycle Predictions',
      description: 'Alerts you 2 days before your predicted cycle.',
      importance: Importance.max,
    );

    const checkInChannel = AndroidNotificationChannel(
      'daily_care',
      'Daily Check-ins',
      description: 'Gentle nudges to log your health data.',
      importance: Importance.low,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(periodChannel);
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(checkInChannel);
  }

  // uses 'permission_handler' to manage the dialogs cleanly.
  Future<bool> requestPermissions() async {
    // Unified call handles Android 13+ and iOS automatically.
    // It will show the system dialog if not yet asked.
    final status = await Permission.notification.request();

    if (status.isGranted) {
      return true;
    }

    // If the user previously clicked "Don't Allow",
    // standard requests fail silently. This check lets us know if we need
    // to show a custom "Please go to settings" dialog in your UI later.
    if (status.isPermanentlyDenied) {
      debugPrint("Notification permissions are permanently denied.");
      // Optional: openAppSettings();
    }

    return false;
  }

  // Schedules a notification for a specific date and time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'cycle_alerts',
          'Cycle Predictions',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      // UPDATE THIS LINE:
      // From: androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // To:
      // androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,

      // uiLocalNotificationDateInterpretation:
      //     UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
