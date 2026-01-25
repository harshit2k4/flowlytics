import 'package:flutter/material.dart';

enum AppThemeType { skyBreeze, solarGlow, classicFlow, mintRevival }

class ThemeConfig {
  static Color getSeed(AppThemeType type) {
    switch (type) {
      case AppThemeType.skyBreeze:
        return const Color(0xFF98BAE7); // Periwinkle / Sky
      case AppThemeType.solarGlow:
        return const Color(0xFFFFD166); // Warm Honey / Gold
      case AppThemeType.mintRevival:
        return const Color(0xFFA8E6CF); // Fresh Mint Wellness
      case AppThemeType.classicFlow:
      default:
        return const Color(0xFFD81B60); // Classic
    }
  }

  static ColorScheme getColorScheme(AppThemeType type, Brightness brightness) {
    return ColorScheme.fromSeed(
      seedColor: getSeed(type),
      brightness: brightness,
      // 'tonalSpot' creates the soft, pastel container colors girls love
      dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
    );
  }
}
