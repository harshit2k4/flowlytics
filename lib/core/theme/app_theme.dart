import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // A vibrant Pink-Red seed for better contrast
  static const Color _seedColor = Color(0xFFD81B60);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
      // Explicitly setting high contrast for text
      onSurface: Colors.black87,
    ),
    textTheme: GoogleFonts.lexendTextTheme(),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
      // Explicitly forcing contrast
      surface: const Color(0xFF1C1B1F), // Deep charcoal
      onSurface: const Color(0xFFE6E1E5), // Very light grey/white
    ),
    textTheme: GoogleFonts.lexendTextTheme(
      ThemeData.dark().textTheme, // Forces text to default to white
    ),
  );
}
