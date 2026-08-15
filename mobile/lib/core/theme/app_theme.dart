import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Neutral Ink palette (matches web design system)
  static const Color ink50 = Color(0xFFF8F8F8);
  static const Color ink100 = Color(0xFFF0F0F0);
  static const Color ink200 = Color(0xFFE2E2E2);
  static const Color ink300 = Color(0xFFC8C8C8);
  static const Color ink400 = Color(0xFFA0A0A0);
  static const Color ink500 = Color(0xFF7A7A7A);
  static const Color ink600 = Color(0xFF5A5A5A);
  static const Color ink700 = Color(0xFF3A3A3A);
  static const Color ink800 = Color(0xFF262626);
  static const Color ink900 = Color(0xFF171717);
  static const Color ink950 = Color(0xFF0D0D0D);

  // Warm Amber accent palette
  static const Color amber400 = Color(0xFFE6B02C);
  static const Color amber500 = Color(0xFFD9941C);
  static const Color amber600 = Color(0xFFBF7015);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.ink50,
      colorScheme: const ColorScheme.light(
        primary: AppColors.amber500,
        surface: Colors.white,
        onSurface: AppColors.ink900,
        outline: AppColors.ink200,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.ink800),
        titleTextStyle: TextStyle(
          color: AppColors.ink900,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.ink200, width: 1),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.ink950,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.amber400,
        surface: AppColors.ink900,
        onSurface: AppColors.ink100,
        outline: AppColors.ink800,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.ink950,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.ink200),
        titleTextStyle: TextStyle(
          color: AppColors.ink100,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.ink900,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.ink800, width: 1),
        ),
      ),
    );
  }
}
