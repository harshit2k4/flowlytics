// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class AppTheme {
//   // A vibrant Pink-Red seed for better contrast
//   static const Color _seedColor = Color(0xFFD81B60);

//   static ThemeData get lightTheme => ThemeData(
//     useMaterial3: true,
//     colorScheme: ColorScheme.fromSeed(
//       seedColor: _seedColor,
//       brightness: Brightness.light,
//       // Explicitly setting high contrast for text
//       onSurface: Colors.black87,
//     ),
//     textTheme: GoogleFonts.lexendTextTheme(),
//   );

//   static ThemeData get darkTheme => ThemeData(
//     useMaterial3: true,
//     colorScheme: ColorScheme.fromSeed(
//       seedColor: _seedColor,
//       brightness: Brightness.dark,
//       // Explicitly forcing contrast
//       surface: const Color(0xFF1C1B1F), // Deep charcoal
//       onSurface: const Color(0xFFE6E1E5), // Very light grey/white
//     ),
//     textTheme: GoogleFonts.lexendTextTheme(
//       ThemeData.dark().textTheme, // Forces text to default to white
//     ),
//   );
// }

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Logic to get seed colors that are vibrant and appealing
  static Color getSeedColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFF2196F3); // Clear Blue
      case 1:
        return const Color(0xFFFFB300); // Amber
      case 3:
        return const Color(0xFF00BFA5); // Teal/Mint
      case 2:
      default:
        return const Color(0xFFD81B60); // Classic
    }
  }

  static ThemeData getTheme(int index, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final seed = getSeedColor(index);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: brightness)
          .copyWith(
            // High-contrast text
            onSurface: isDark ? const Color(0xFFE6E1E5) : Colors.black87,
            surface: isDark ? const Color(0xFF1C1B1F) : null,
          ),
      textTheme: GoogleFonts.lexendTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ),
    );
  }
}
