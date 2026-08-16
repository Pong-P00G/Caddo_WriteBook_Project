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
  static const Color amber50 = Color(0xFFFDF8EC);
  static const Color amber100 = Color(0xFFFAEFC9);
  static const Color amber200 = Color(0xFFF4DC8E);
  static const Color amber300 = Color(0xFFEDC654);
  static const Color amber400 = Color(0xFFE6B02C);
  static const Color amber500 = Color(0xFFD9941C);
  static const Color amber600 = Color(0xFFBF7015);
  static const Color amber700 = Color(0xFF9B5214);

  // Semantic colors
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerLight = Color(0xFFFEF2F2);
  static const Color dangerBorder = Color(0xFFFECACA);
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFF0FDF4);

  // Parchment
  static const Color parchment = Color(0xFFFDF9F0);
}

class AppTheme {
  // ── Shared Input Decoration ────────────────────────────────────────────────
  static InputDecorationTheme _inputDecorationTheme(bool isDark) {
    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? AppColors.ink900 : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? AppColors.ink700 : AppColors.ink200,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? AppColors.ink700 : AppColors.ink200,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.amber500,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger, width: 2),
      ),
      labelStyle: TextStyle(
        color: isDark ? AppColors.ink400 : AppColors.ink500,
        fontSize: 14,
      ),
      hintStyle: TextStyle(
        color: isDark ? AppColors.ink600 : AppColors.ink300,
        fontSize: 14,
      ),
      prefixIconColor: isDark ? AppColors.ink400 : AppColors.ink500,
      suffixIconColor: isDark ? AppColors.ink400 : AppColors.ink500,
    );
  }

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: AppColors.amber500,
      primaryContainer: AppColors.amber100,
      onPrimaryContainer: AppColors.amber700,
      secondary: AppColors.ink700,
      secondaryContainer: AppColors.ink100,
      surface: Colors.white,
      onSurface: AppColors.ink900,
      onSurfaceVariant: AppColors.ink600,
      outline: AppColors.ink200,
      outlineVariant: AppColors.ink100,
      error: AppColors.danger,
      errorContainer: AppColors.dangerLight,
      onErrorContainer: AppColors.danger,
      surfaceContainerHighest: AppColors.ink100,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.ink50,
      colorScheme: colorScheme,
      textTheme: GoogleFonts.interTextTheme(),
      inputDecorationTheme: _inputDecorationTheme(false),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: AppColors.ink200,
        iconTheme: IconThemeData(color: AppColors.ink800),
        actionsIconTheme: IconThemeData(color: AppColors.ink700),
        titleTextStyle: TextStyle(
          color: AppColors.ink900,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.ink200, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.amber500,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.ink200,
          disabledForegroundColor: AppColors.ink400,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.amber600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink800,
          side: const BorderSide(color: AppColors.ink200),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.ink100,
        selectedColor: AppColors.amber500,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.ink200),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        shadowColor: AppColors.ink900.withAlpha(30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.ink900,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: AppColors.ink600,
          height: 1.5,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink900,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        minVerticalPadding: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        selectedColor: AppColors.amber600,
        selectedTileColor: AppColors.amber50,
        iconColor: AppColors.ink600,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.ink100,
        thickness: 1,
        space: 1,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(0),
            bottomRight: Radius.circular(0),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.amber500,
        foregroundColor: Colors.white,
        elevation: 3,
        highlightElevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.amber500,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.amber500;
          return AppColors.ink300;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.amber200;
          return AppColors.ink200;
        }),
      ),
    );
  }

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.amber400,
      primaryContainer: AppColors.amber700,
      onPrimaryContainer: AppColors.amber200,
      secondary: AppColors.ink300,
      secondaryContainer: AppColors.ink800,
      surface: AppColors.ink900,
      onSurface: AppColors.ink100,
      onSurfaceVariant: AppColors.ink400,
      outline: AppColors.ink700,
      outlineVariant: AppColors.ink800,
      error: Color(0xFFF87171),
      errorContainer: Color(0xFF7F1D1D),
      onErrorContainer: Color(0xFFFCA5A5),
      surfaceContainerHighest: AppColors.ink800,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.ink950,
      colorScheme: colorScheme,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      inputDecorationTheme: _inputDecorationTheme(true),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.ink950,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: AppColors.ink800,
        iconTheme: IconThemeData(color: AppColors.ink200),
        actionsIconTheme: IconThemeData(color: AppColors.ink300),
        titleTextStyle: TextStyle(
          color: AppColors.ink100,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.ink900,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.ink800, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.amber400,
          foregroundColor: AppColors.ink950,
          disabledBackgroundColor: AppColors.ink800,
          disabledForegroundColor: AppColors.ink600,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.amber400,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink200,
          side: const BorderSide(color: AppColors.ink700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.ink800,
        selectedColor: AppColors.amber500,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.ink200,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.ink700),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.ink900,
        elevation: 8,
        shadowColor: Colors.black.withAlpha(80),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.ink800),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.ink100,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: AppColors.ink400,
          height: 1.5,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink800,
        contentTextStyle: const TextStyle(
          color: AppColors.ink100,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        minVerticalPadding: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        selectedColor: AppColors.amber400,
        selectedTileColor: Color(0x22D9941C), // amber500 at ~13% opacity
        iconColor: AppColors.ink400,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.ink800,
        thickness: 1,
        space: 1,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.ink950,
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.amber500,
        foregroundColor: Colors.white,
        elevation: 3,
        highlightElevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.amber400,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.amber400;
          return AppColors.ink600;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.amber700;
          return AppColors.ink800;
        }),
      ),
    );
  }
}
