import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controller for managing the application's theme mode.
/// Default: ThemeMode.light
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Default to light mode
    return ThemeMode.light;
  }

  /// Toggles between light and dark mode.
  void toggle() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }

  /// Sets the theme mode explicitly.
  void setMode(ThemeMode mode) {
    state = mode;
  }

  /// Returns true if currently in dark mode.
  bool get isDarkMode => state == ThemeMode.dark;
}

/// Provider for the theme mode controller.
final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
