import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF0B0E14);
  static const Color surface = Color(0xFF151B26);
  static const Color cardColor = Color(0xFF1F2937);
  static const Color primary = Color(0xFF00E676);
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF9CA3AF);

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    primaryColor: primary,
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      centerTitle: true,
    ),
  );
}
