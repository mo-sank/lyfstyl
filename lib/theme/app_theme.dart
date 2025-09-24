import 'package:flutter/material.dart';

class AppColors {
  static const deepNavy = Color(0xFF1A1F36);
  static const cleanWhite = Color(0xFFFFFFFF);
  static const electricTeal = Color(0xFF00C2A8);
  static const vibrantCoral = Color(0xFFFF6F61);
  static const goldenYellow = Color(0xFFFFC857);
  static const lavender = Color(0xFF9B5DE5);
  static const softBackground = Color(0xFFF6F7FB); // subtle light gray
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.electricTeal,
      primary: AppColors.deepNavy,
      secondary: AppColors.electricTeal,
      surface: AppColors.cleanWhite,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.softBackground,
    fontFamily: 'Roboto',
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.cleanWhite,
      foregroundColor: AppColors.deepNavy,
      elevation: 0.5,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.deepNavy,
        foregroundColor: AppColors.cleanWhite,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: AppColors.cleanWhite,
    ),
    chipTheme: base.chipTheme.copyWith(
      labelStyle: const TextStyle(color: AppColors.deepNavy),
      backgroundColor: const Color(0xFFE9EEF7),
    ),
  );
}
