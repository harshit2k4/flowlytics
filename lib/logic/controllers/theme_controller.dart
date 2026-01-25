import 'package:flowlytics/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

class ThemeController extends GetxController {
  final _box = Hive.box('settings_box');
  final String _key = 'theme_index';

  RxInt currentThemeIndex = 2.obs; // Default to Classic

  @override
  void onInit() {
    super.onInit();
    currentThemeIndex.value = _box.get(_key, defaultValue: 2);
  }

  void changeTheme(int index) {
    currentThemeIndex.value = index;
    _box.put(_key, index);
  }

  Color getSeedColor(int index) {
    return AppTheme.getSeedColor(index);
  }
}
