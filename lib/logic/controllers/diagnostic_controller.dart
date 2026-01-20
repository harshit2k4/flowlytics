import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Required for persistence
import 'package:permission_handler/permission_handler.dart';
import '../services/notification_service.dart';

class DiagnosticController extends GetxController with WidgetsBindingObserver {
  // Observables
  final isTesting = false.obs;
  final progress = 0.0.obs;
  final secondsRemaining = 15.obs;
  final lastChecked = "Never".obs;
  final notificationsEnabled = true.obs;

  Timer? _progressTimer;
  Timer? _countdownTimer;
  Timer? _statusPollingTimer; // For instant UI updates while on page

  final _settingsBox = Hive.box('settings_box');

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);

    // Load persisted verification time
    lastChecked.value = _settingsBox.get(
      'last_verified',
      defaultValue: "Never",
    );

    checkPermission();

    // Poll for permission changes every second for instant response
    _statusPollingTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => checkPermission(),
    );
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _progressTimer?.cancel();
    _countdownTimer?.cancel();
    _statusPollingTimer?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkPermission();
    }
  }

  Future<void> checkPermission() async {
    // Permission handler only works on Android, iOS, and limited Web.
    if (!GetPlatform.isMobile) {
      notificationsEnabled.value =
          true; // Default to true for unsupported platforms
      return;
    }

    try {
      final status = await Permission.notification.status;
      if (notificationsEnabled.value != status.isGranted) {
        notificationsEnabled.value = status.isGranted;
      }
    } catch (e) {
      debugPrint("Permission check failed: $e");
      notificationsEnabled.value = true;
    }
  }

  void startDiagnostic(String userName) {
    if (isTesting.value) return;

    // Prevent notification system check on Linux, mac and Windows
    if (!GetPlatform.isMobile) {
      Get.snackbar(
        "Platform Not Supported",
        "Notification diagnostics are only available on Android and iOS.",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isTesting.value = true;
    progress.value = 0.0;
    secondsRemaining.value = 15;

    NotificationService().scheduleNotification(
      id: 999,
      title: "System checks complete",
      body:
          "Hi ${userName.split(" ")[0]}! Your notification engine is running perfectly.",
      scheduledDate: DateTime.now().add(const Duration(seconds: 15)),
    );

    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      progress.value += 0.1 / 15;
      if (progress.value >= 1.0) {
        progress.value = 1.0;
        isTesting.value = false;

        // Save and persist the verification time
        final timeString = DateFormat('HH:mm').format(DateTime.now());
        lastChecked.value = timeString;
        _settingsBox.put('last_verified', timeString);

        timer.cancel();
      }
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining.value > 0) {
        secondsRemaining.value--;
      } else {
        timer.cancel();
      }
    });
  }
}
