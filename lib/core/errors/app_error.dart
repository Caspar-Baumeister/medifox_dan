/// Base class for all application errors.
sealed class AppError implements Exception {
  const AppError({required this.message, this.debugInfo});

  final String message;
  final String? debugInfo;

  @override
  String toString() => debugInfo ?? message;
}

/// Network-related errors (offline, timeout, HTTP errors).
class NetworkError extends AppError {
  const NetworkError({
    required super.message,
    super.debugInfo,
    this.isOffline = false,
  });

  final bool isOffline;

  /// Convenience constructors
  const NetworkError.offline()
    : isOffline = true,
      super(message: 'No internet connection');

  const NetworkError.timeout()
    : isOffline = false,
      super(message: 'Connection timed out. Please try again.');

  const NetworkError.server({int? statusCode})
    : isOffline = false,
      super(
        message: 'Server error. Please try again later.',
        debugInfo: statusCode != null ? 'HTTP $statusCode' : null,
      );
}

/// Validation errors (user input).
class ValidationError extends AppError {
  const ValidationError({required super.message, super.debugInfo});
}

/// Generic fallback error.
class AppException extends AppError {
  const AppException({required super.message, super.debugInfo, this.cause});

  final Object? cause;
}
