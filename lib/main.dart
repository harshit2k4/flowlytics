import 'dart:io';

import 'package:flowlytics/data/models/daily_log.dart';
import 'package:flowlytics/logic/controllers/diagnostic_controller.dart';
import 'package:flowlytics/logic/controllers/period_controller.dart';
import 'package:flowlytics/logic/controllers/security_controller.dart';
import 'package:flowlytics/logic/services/notification_service.dart';
import 'package:flowlytics/ui/onboarding/onboarding_screen.dart';
import 'package:flowlytics/logic/controllers/navigation_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/models/period_log.dart';
import 'core/theme/app_theme.dart';
import 'ui/nav_wrapper.dart';

void main() async {
  // init native bridge
  WidgetsFlutterBinding.ensureInitialized();

  // init notification service for mobile devices only
  if (Platform.isAndroid || Platform.isIOS) {
    await NotificationService().init();
  }

  // init hive
  await Hive.initFlutter();
  // Register period log model adapter
  Hive.registerAdapter(PeriodLogAdapter());
  // Register daily log model adapter
  Hive.registerAdapter(DailyLogAdapter());
  // Open box of daily log
  await Hive.openBox<DailyLog>('daily_box');
  // Open the box to store logs
  await Hive.openBox<PeriodLog>('period_box');
  // Open the box to store settings (Name, Onboarding status, etc.)
  await Hive.openBox('settings_box');

  // Initialize the controller
  final controller = Get.put(PeriodController());

  // Register all controllers globally on app start
  Get.put(NavigationController());
  Get.put(PeriodController());
  Get.put(DiagnosticController());
  Get.put(SecurityController());

  // init NotificationService
  if (Platform.isAndroid || Platform.isIOS) {
    await NotificationService().init();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PeriodController>();

    return GetMaterialApp(
      title: 'Flowlytics',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: Obx(() {
        if (controller.isFirstRun.value) {
          return const OnboardingScreen();
        } else {
          return const NavWrapper();
        }
      }),
    );
  }
}
