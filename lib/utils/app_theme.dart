import 'package:flutter/material.dart';
import 'constants.dart';

class AppTheme {
  static ThemeData theme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(Constants.primaryBlack),
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(Constants.primaryBlack),
      secondary: const Color(Constants.secondaryGreen),
      tertiary: const Color(Constants.accentBlue),
      error: const Color(Constants.errorRed),
      surface: Colors.white,
      background: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.background,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.background,
        foregroundColor: colorScheme.onBackground,
        elevation: 0,
        centerTitle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.primary,
        contentTextStyle: TextStyle(color: colorScheme.onPrimary),
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }
}
