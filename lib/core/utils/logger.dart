import 'dart:developer' as developer;

/// Application logger for consistent logging throughout the app.
/// Provides methods for different log levels.
class AppLogger {
  AppLogger._();

  static const String _tag = 'MedifoxDan';

  /// Logs a debug message.
  static void debug(String message, {String? tag}) {
    developer.log(
      message,
      name: tag ?? _tag,
      level: 500,
    );
  }

  /// Logs an info message.
  static void info(String message, {String? tag}) {
    developer.log(
      message,
      name: tag ?? _tag,
      level: 800,
    );
  }

  /// Logs a warning message.
  static void warning(String message, {String? tag}) {
    developer.log(
      message,
      name: tag ?? _tag,
      level: 900,
    );
  }

  /// Logs an error message with optional error object and stack trace.
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: tag ?? _tag,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
