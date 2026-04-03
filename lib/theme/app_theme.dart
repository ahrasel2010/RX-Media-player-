import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color primaryOrange = Color(0xFFFF6B00);
  static const Color darkBg = Color(0xFF0D0D0D);
  static const Color cardBg = Color(0xFF1A1A1A);
  static const Color surfaceBg = Color(0xFF222222);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFAAAAAA);

  // ================= DARK THEME =================
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
      cardTheme: const CardThemeData(
        color: cardBg,
        elevation: 0,
      ),
      iconTheme: const IconThemeData(color: textPrimary),
      useMaterial3: true,
    );
  }

  // ================= LIGHT THEME =================
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      primaryColor: primaryOrange,
      colorScheme: const ColorScheme.light(
        primary: primaryOrange,
        surface: Colors.white,
        background: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: primaryOrange,
        unselectedLabelColor: Colors.grey,
        indicatorColor: primaryOrange,
        labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
      ),
      iconTheme: const IconThemeData(color: Colors.black),
      useMaterial3: true,
    );
  }
}
