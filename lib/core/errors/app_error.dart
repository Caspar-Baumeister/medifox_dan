/// Base class for all application errors.
/// Provides user-friendly and debug messages.
sealed class AppError implements Exception {
  const AppError();

  /// User-friendly message to display in the UI.
  String get userMessage;

  /// Detailed message for debugging purposes.
  String get debugMessage;

  @override
  String toString() => debugMessage;
}

/// Error when the device is offline.
class OfflineError extends AppError {
  const OfflineError({this.details});

  final String? details;

  @override
  String get userMessage => 'No internet connection';

  @override
  String get debugMessage =>
      'OfflineError: No network connectivity${details != null ? ' ($details)' : ''}';
}

/// Error when a network request times out.
class TimeoutError extends AppError {
  const TimeoutError({this.operation});

  final String? operation;

  @override
  String get userMessage => 'Connection timed out. Please try again.';

  @override
  String get debugMessage =>
      'TimeoutError: ${operation ?? 'Request'} timed out';
}

/// Error from the server (5xx status codes).
class ServerError extends AppError {
  const ServerError({required this.statusCode, this.message});

  final int statusCode;
  final String? message;

  @override
  String get userMessage => 'Server error. Please try again later.';

  @override
  String get debugMessage =>
      'ServerError: HTTP $statusCode${message != null ? ' - $message' : ''}';
}

/// Error from client request (4xx status codes).
class ClientError extends AppError {
  const ClientError({required this.statusCode, this.message});

  final int statusCode;
  final String? message;

  @override
  String get userMessage {
    return switch (statusCode) {
      400 => 'Invalid request',
      401 => 'Authentication required',
      403 => 'Access denied',
      404 => 'Resource not found',
      409 => 'Conflict with existing data',
      422 => 'Invalid data provided',
      429 => 'Too many requests. Please wait.',
      _ => 'Request failed',
    };
  }

  @override
  String get debugMessage =>
      'ClientError: HTTP $statusCode${message != null ? ' - $message' : ''}';
}

/// Error when parsing data fails.
class ParsingError extends AppError {
  const ParsingError({required this.message, this.source});

  final String message;
  final String? source;

  @override
  String get userMessage => 'Failed to process server response';

  @override
  String get debugMessage =>
      'ParsingError: $message${source != null ? ' (source: $source)' : ''}';
}

/// Error from database operations.
class DatabaseError extends AppError {
  const DatabaseError({required this.message, this.operation});

  final String message;
  final String? operation;

  @override
  String get userMessage => 'Failed to save data locally';

  @override
  String get debugMessage =>
      'DatabaseError: ${operation ?? 'Operation'} failed - $message';
}

/// Fallback error for unexpected cases.
class UnknownError extends AppError {
  const UnknownError({required this.message, this.originalError});

  final String message;
  final Object? originalError;

  @override
  String get userMessage => 'Something went wrong. Please try again.';

  @override
  String get debugMessage =>
      'UnknownError: $message${originalError != null ? ' (original: $originalError)' : ''}';
}
