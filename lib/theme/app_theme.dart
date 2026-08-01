import 'package:flutter/material.dart';

class AppInfo {
  static const version = 'v1.3.0';
}

class AppColors {
  static const darkBg = Color(0xFF0A0A0F);
  static const darkCard = Color(0xFF1A1A2E);
  static const darkNav = Color(0xFF0F0F1A);
  static const accent = Color(0xFF00D4FF);
  static const accentPurple = Color(0xFF7C3AED);
  static const accentPink = Color(0xFFFF2D78);
  static const textPrimary = Color(0xFFF1F1F6);
  static const textSecondary = Color(0xFF9E9EB8);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);

  static const lightBg = Color(0xFFF8FAFC);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightNav = Color(0xFFF1F5F9);
  static const lightTextPrimary = Color(0xFF0F172A);
  static const lightTextSecondary = Color(0xFF64748B);
}

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      secondary: AppColors.accentPurple,
      surface: AppColors.darkCard,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkNav,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF2A2A3E),
    ),
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBg,
    colorScheme: const ColorScheme.light(
      primary: AppColors.accentPurple,
      secondary: AppColors.accent,
      surface: AppColors.lightCard,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightNav,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AppColors.lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE2E8F0),
    ),
  );
}
