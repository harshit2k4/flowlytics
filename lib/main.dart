import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/models/period_log.dart';
import 'core/theme/app_theme.dart';
import 'ui/nav_wrapper.dart';

void main() async {
  // Initialize Hive for Flutter
  await Hive.initFlutter();
  // Register the generated adapter
  Hive.registerAdapter(PeriodLogAdapter());
  // Open a Box to store logs
  await Hive.openBox<PeriodLog>('period_box');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flowlytics',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Switches based on phone settings
      home: const NavWrapper(),
    );
  }
}
