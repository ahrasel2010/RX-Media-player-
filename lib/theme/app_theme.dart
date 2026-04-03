import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryOrange = Color(0xFFFF6B00);
  static const Color darkBg = Color(0xFF0D0D0D);
  static const Color cardBg = Color(0xFF1A1A1A);
  static const Color surfaceBg = Color(0xFF222222);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFAAAAAA);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      primaryColor: primaryOrange,
      colorScheme: const ColorScheme.dark(
        primary: primaryOrange,
        surface: cardBg,
        background: darkBg,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF111111),
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: primaryOrange,
        unselectedLabelColor: textSecondary,
        indicatorColor: primaryOrange,
        labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
      cardTheme: const CardThemeData(color: cardBg, elevation: 0),
      iconTheme: const IconThemeData(color: textPrimary),
      useMaterial3: true,
    );
  }
}
