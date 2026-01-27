import 'dart:ui';

import 'package:flowlytics/logic/controllers/security_controller.dart';
import 'package:flowlytics/ui/pages/calendar_page.dart';
import 'package:flowlytics/ui/widgets/comfort_overlay.dart';
import 'package:flutter/material.dart';
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
  // void _handleNotificationTap(String? payload) {
  //   if (payload == null) return;
  //   debugPrint("Notification Tapped with payload: $payload");

  //   // Use Future.delayed to ensure the Navigator is ready
  //   Future.delayed(const Duration(milliseconds: 200), () {
  //     final nav = Get.find<NavigationController>();

  //     if (payload == 'period_reminder') {
  //       nav.changeIndex(0); // Go to Home Tab
  //       Get.until((route) => route.isFirst); // Clear any open dialogs
  //       Get.to(() => const CalendarPage()); // Open Calendar
  //     } else if (payload == 'diagnostic_test') {
  //       nav.changeIndex(0); // Ensure we are on Home Tab
  //       Get.until((route) => route.isFirst);
  //       Get.to(() => const InsightsScreen()); // Open Insights
  //     }
  //   });
  // }

  void _handleNotificationTap(String? payload) {
    if (payload == null) return;

    Future.delayed(const Duration(milliseconds: 200), () {
      final nav = Get.find<NavigationController>();

      if (payload == 'period_reminder') {
        // 1. Prepare the background: Switch to Home Tab and clear the stack
        nav.changeIndex(0);
        Get.until((route) => route.isFirst);

        // 2. Navigate to the Calendar Page
        Get.to(() => const CalendarPage());

        // 3. Trigger the Comfort Overlay with Security Awareness
        _triggerComfortFlow();
      } else if (payload == 'diagnostic_test') {
        nav.changeIndex(0);
        Get.until((route) => route.isFirst);
        Get.to(() => const InsightsScreen());
      }
    });
  }

  void _triggerComfortFlow() {
    final security = Get.find<SecurityController>();

    if (!security.isLocked.value) {
      // Scenario: App is already open or has no lock
      _showComfortOverlay();
    } else {
      // Scenario: App is locked. We "listen" for the moment it unlocks.
      late Worker unlockWorker;
      unlockWorker = ever(security.isLocked, (bool isLocked) {
        if (!isLocked) {
          // Add a small delay so the lock screen fade animation finishes first
          Future.delayed(const Duration(milliseconds: 400), () {
            _showComfortOverlay();
          });
          unlockWorker
              .dispose(); // Cleanup: We only want this once per notification tap
        }
      });
    }
  }

  // void _showComfortOverlay() {
  //   Get.dialog(
  //     const ComfortOverlay(
  //       status: 'preparation',
  //     ), // Force prep message for notifications
  //     barrierDismissible: false,
  //     barrierColor: Colors.transparent,
  //     transitionDuration: const Duration(milliseconds: 500),
  //   );
  // }

  void _showComfortOverlay() {
    Get.generalDialog(
      pageBuilder: (context, anim1, anim2) =>
          const ComfortOverlay(status: 'preparation'),
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.05), // Very light dim
      transitionDuration: const Duration(
        milliseconds: 400,
      ), // Slower, elegant fade
      // transitionBuilder: (context, anim1, anim2, child) {
      //   // Create a smooth scale + fade effect
      //   return FadeTransition(
      //     opacity: CurvedAnimation(parent: anim1, curve: Curves.easeInOut),
      //     child: ScaleTransition(
      //       scale: CurvedAnimation(
      //         parent: anim1,
      //         curve: Curves.easeOutCubic, // Slight bounce for the "Cute" factor
      //       ),
      //       child: child,
      //     ),
      //   );
      // },
      transitionBuilder: (context, anim1, anim2, child) {
        final colorScheme = Theme.of(context).colorScheme;

        return Stack(
          children: [
            // LAYER 1: The Seamless Blur (Only Fades, never scales)
            FadeTransition(
              opacity: CurvedAnimation(
                parent: anim1,
                curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(color: colorScheme.surface.withOpacity(0.4)),
              ),
            ),

            // LAYER 2: The Content (Fades + Subtle Drift)
            FadeTransition(
              opacity: CurvedAnimation(
                parent: anim1,
                curve: const Interval(0.2, 1.0, curve: Curves.easeIn),
              ),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                  CurvedAnimation(
                    parent: anim1,
                    curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
                  ),
                ),
                child: child,
              ),
            ),
          ],
        );
      },
    );
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
