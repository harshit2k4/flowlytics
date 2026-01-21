import 'package:flowlytics/ui/pages/calendar_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart'; // for navigation to different screens
import '../controllers/navigation_controller.dart';
import '../../ui/insights/insights_screen.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // Use consistent settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        _handleNotificationTap(details.payload);
      },
    );

    // Check if the app was launched by tapping a notification
    final NotificationAppLaunchDetails? launchDetails = await _notifications
        .getNotificationAppLaunchDetails();

    if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
      // Delay slightly to wait for GetMaterialApp to be ready
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationTap(launchDetails.notificationResponse?.payload);
      });
    }

    _setupAndroidChannels();
  }

  // Logic that decides where to go
  void _handleNotificationTap(String? payload) {
    if (payload == null) return;
    debugPrint("Notification Tapped with payload: $payload");

    // Use Future.delayed to ensure the Navigator is ready
    Future.delayed(const Duration(milliseconds: 200), () {
      final nav = Get.find<NavigationController>();

      if (payload == 'period_reminder') {
        nav.changeIndex(0); // Go to Home Tab
        Get.until((route) => route.isFirst); // Clear any open dialogs
        Get.to(() => const CalendarPage()); // Open Calendar
      } else if (payload == 'diagnostic_test') {
        nav.changeIndex(0); // Ensure we are on Home Tab
        Get.until((route) => route.isFirst);
        Get.to(() => const InsightsScreen()); // Open Insights
      }
    });
  }

  void _setupAndroidChannels() async {
    const channel = AndroidNotificationChannel(
      'cycle_alerts',
      'Cycle Predictions',
      description: 'Notifications for your period cycle and fertility.',
      importance: Importance.max,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<bool> requestPermissions() async {
    PermissionStatus status = await Permission.notification.request();
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      debugPrint("Notification permissions are permanently denied.");
    }
    return false;
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload, // decides which notification will be tapped
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
        ),
      ),
      payload: payload, // Make sure this is passed
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
