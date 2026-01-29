import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/errors/app_error.dart';

/// Maps exceptions to [AppError] instances.
AppError mapToAppError(Object error, [StackTrace? stackTrace]) {
  if (error is AppError) return error;

  if (error is DioException) {
    return _mapDioException(error);
  }

  if (error is SocketException) {
    return const NetworkError.offline();
  }

  return AppException(message: error.toString(), cause: error);
}

AppError _mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const NetworkError.timeout();

    case DioExceptionType.connectionError:
      return const NetworkError.offline();

    case DioExceptionType.badResponse:
      final statusCode = e.response?.statusCode ?? 0;
      if (statusCode >= 500) {
        return NetworkError.server(statusCode: statusCode);
      }
      return NetworkError(
        message: 'Request failed',
        debugInfo: 'HTTP $statusCode',
      );

    case DioExceptionType.badCertificate:
    case DioExceptionType.cancel:
    case DioExceptionType.unknown:
      if (e.error is SocketException) {
        return const NetworkError.offline();
      }
      return AppException(message: e.message ?? 'Network error', cause: e.error);
  }
}
