import 'package:flutter/material.dart';

class RikiaTheme {
  // Rainbow colors
  static const Color red = Color(0xFFFF3B5C);
  static const Color orange = Color(0xFFFF8C00);
  static const Color yellow = Color(0xFFFFD700);
  static const Color green = Color(0xFF00C853);
  static const Color blue = Color(0xFF2979FF);
  static const Color indigo = Color(0xFF651FFF);
  static const Color violet = Color(0xFFD500F9);

  // App colors
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceLight = Color(0xFF2A2A2A);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color divider = Color(0xFF2A2A2A);

  // Rainbow gradient
  static const LinearGradient rainbowGradient = LinearGradient(
    colors: [red, orange, yellow, green, blue, indigo, violet],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Simpler gradient for buttons
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [violet, blue],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: violet,
      colorScheme: const ColorScheme.dark(
        primary: violet,
        secondary: blue,
        surface: surface,
        background: background,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: violet,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
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
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          fontSize: 14,
        ),
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
    );
  }
}
