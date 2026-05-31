import 'package:flutter/material.dart';

class RikiaTheme {
  // Core gradient colors (matching the logo)
  static const Color blue = Color(0xFF4A90D9);
  static const Color purple = Color(0xFF9B6DD6);
  static const Color pink = Color(0xFFE066A0);
  static const Color orange = Color(0xFFFF6B35);
  static const Color yellow = Color(0xFFFFB830);
  static const Color green = Color(0xFF4CAF7D);

  // App colors - light theme
  static const Color background = Color(0xFFF8F9FE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF0F2F8);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color divider = Color(0xFFE5E7EB);

  // Main gradient (logo colors)
  static const LinearGradient mainGradient = LinearGradient(
    colors: [blue, purple, pink, orange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Button gradient
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [blue, purple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Rainbow gradient for accents
  static const LinearGradient rainbowGradient = LinearGradient(
    colors: [blue, purple, pink, orange, yellow],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: purple,
      colorScheme: const ColorScheme.light(
        primary: purple,
        secondary: blue,
        surface: surface,
        background: background,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: purple,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
