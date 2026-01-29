import 'package:flutter/material.dart';

/// Application theme configuration.
/// Provides consistent styling throughout the app for both light and dark modes.
class AppTheme {
  AppTheme._();

  // Brand colors (consistent across both themes)
  static const Color _primary = Color(0xFFD75F5A);
  static const Color _secondary = Color(0xFF4E8CF2);

  // Light theme colors
  static const Color _lightBackground = Color(0xFFFEFEFE);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightText = Color(0xFF222222);
  static const Color _lightTextSecondary = Color(0xFF727272);
  static const Color _lightDivider = Color(0xFFEDEDED);

  // Dark theme colors
  static const Color _darkBackground = Color(0xFF121212);
  static const Color _darkSurface = Color(0xFF1E1E1E);
  static const Color _darkSurfaceVariant = Color(0xFF2C2C2C);
  static const Color _darkText = Color(0xFFF5F5F5);
  static const Color _darkTextSecondary = Color(0xFFB0B0B0);
  static const Color _darkDivider = Color(0xFF3A3A3A);

  // Common colors
  static const Color _error = Color(0xFFE53935);
  static const Color _success = Color(0xFF43A047);
  static const Color _white = Color(0xFFFFFFFF);

  /// Light theme configuration.
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: _primary,
        secondary: _secondary,
        surface: _lightSurface,
        error: _error,
        onPrimary: _white,
        onSecondary: _white,
        onSurface: _lightText,
        onError: _white,
        outline: _lightDivider,
        surfaceContainerHighest: _lightBackground,
      ),
      scaffoldBackgroundColor: _lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: _primary,
        foregroundColor: _white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: _white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: _white),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _lightBackground,
        selectedColor: _primary.withValues(alpha: 0.15),
        labelStyle: const TextStyle(color: _lightText, fontSize: 14),
        secondaryLabelStyle: const TextStyle(
          color: _primary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _lightDivider),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: _lightDivider,
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: _lightText,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: _lightText,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: _lightText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: _lightText,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(color: _lightText, fontSize: 16),
        bodyMedium: TextStyle(color: _lightText, fontSize: 14),
        bodySmall: TextStyle(color: _lightTextSecondary, fontSize: 12),
        labelLarge: TextStyle(
          color: _lightText,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primary,
        foregroundColor: _white,
        elevation: 4,
      ),
      cardTheme: CardThemeData(
        color: _lightSurface,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: _lightText,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _success;
          }
          return _lightSurface;
        }),
        checkColor: WidgetStateProperty.all(_white),
        side: const BorderSide(color: _lightDivider, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _darkSurface,
        contentTextStyle: const TextStyle(color: _darkText),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _lightDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _lightDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: _lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Dark theme configuration.
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: _primary,
        secondary: _secondary,
        surface: _darkSurface,
        error: _error,
        onPrimary: _white,
        onSecondary: _white,
        onSurface: _darkText,
        onError: _white,
        outline: _darkDivider,
        surfaceContainerHighest: _darkSurfaceVariant,
      ),
      scaffoldBackgroundColor: _darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkSurface,
        foregroundColor: _darkText,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: _darkText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: _darkText),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _darkSurfaceVariant,
        selectedColor: _primary.withValues(alpha: 0.25),
        labelStyle: const TextStyle(color: _darkText, fontSize: 14),
        secondaryLabelStyle: TextStyle(
          color: _primary.withValues(alpha: 0.9),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _darkDivider),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: _darkDivider,
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: _darkText,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: _darkText,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: _darkText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: _darkText,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(color: _darkText, fontSize: 16),
        bodyMedium: TextStyle(color: _darkText, fontSize: 14),
        bodySmall: TextStyle(color: _darkTextSecondary, fontSize: 12),
        labelLarge: TextStyle(
          color: _darkText,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primary,
        foregroundColor: _white,
        elevation: 4,
      ),
      cardTheme: CardThemeData(
        color: _darkSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: _darkText,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _success;
          }
          return _darkSurfaceVariant;
        }),
        checkColor: WidgetStateProperty.all(_white),
        side: const BorderSide(color: _darkDivider, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _darkSurfaceVariant,
        contentTextStyle: const TextStyle(color: _darkText),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _darkDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: _darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
