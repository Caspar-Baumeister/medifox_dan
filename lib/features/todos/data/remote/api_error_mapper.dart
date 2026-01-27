import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/errors/app_error.dart';

/// Maps Dio exceptions and other errors to typed [AppError] instances.
AppError mapToAppError(Object error, [StackTrace? stackTrace]) {
  if (error is AppError) return error;

  if (error is DioException) {
    return _mapDioException(error);
  }

  if (error is SocketException) {
    return const OfflineError(details: 'Socket exception');
  }

  if (error is FormatException) {
    return ParsingError(message: error.message, source: error.source?.toString());
  }

  if (error is TypeError) {
    return ParsingError(message: 'Type error during parsing: ${error.toString()}');
  }

  return UnknownError(message: error.toString(), originalError: error);
}

AppError _mapDioException(DioException e) {
  // Check for connection/timeout issues first
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
      return const TimeoutError(operation: 'Connection');
    case DioExceptionType.sendTimeout:
      return const TimeoutError(operation: 'Send');
    case DioExceptionType.receiveTimeout:
      return const TimeoutError(operation: 'Receive');
    case DioExceptionType.connectionError:
      // Check if it's a socket exception (no internet)
      if (e.error is SocketException) {
        return const OfflineError(details: 'Connection error');
      }
      return const OfflineError(details: 'Unable to connect to server');
    case DioExceptionType.badCertificate:
      return const UnknownError(message: 'SSL certificate error');
    case DioExceptionType.badResponse:
      return _mapHttpResponse(e.response);
    case DioExceptionType.cancel:
      return const UnknownError(message: 'Request was cancelled');
    case DioExceptionType.unknown:
      // Check for socket exceptions in the error
      if (e.error is SocketException) {
        return const OfflineError(details: 'Network unavailable');
      }
      return UnknownError(
        message: e.message ?? 'Unknown network error',
        originalError: e.error,
      );
  }
}

AppError _mapHttpResponse(Response<dynamic>? response) {
  if (response == null) {
    return const UnknownError(message: 'No response received');
  }

  final statusCode = response.statusCode ?? 0;
  final message = _extractErrorMessage(response);

  if (statusCode >= 500) {
    return ServerError(statusCode: statusCode, message: message);
  }

  if (statusCode >= 400) {
    return ClientError(statusCode: statusCode, message: message);
  }

  return UnknownError(message: 'Unexpected status code: $statusCode');
}

String? _extractErrorMessage(Response<dynamic> response) {
  final data = response.data;
  if (data is Map<String, dynamic>) {
    // Common error message fields
    return data['message'] as String? ??
        data['error'] as String? ??
        data['errors']?.toString();
  }
  if (data is String && data.isNotEmpty) {
    return data;
  }
  return response.statusMessage;
}
