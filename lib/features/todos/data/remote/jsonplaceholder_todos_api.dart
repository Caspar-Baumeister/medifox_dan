import 'package:dio/dio.dart';

/// API client for JSONPlaceholder todos endpoints.
/// Base URL: https://jsonplaceholder.typicode.com
class JsonPlaceholderTodosApi {
  JsonPlaceholderTodosApi(this._dio);

  final Dio _dio;
  static const _baseUrl = 'https://jsonplaceholder.typicode.com';

  /// Fetches todos from the server.
  /// [limit] limits the number of todos returned.
  /// [userId] filters todos by user ID (JSONPlaceholder has userId 1-10).
  ///
  /// ASSUMPTION: We filter by userId=1 to get a manageable subset of todos
  /// for the initial import (JSONPlaceholder has 200 todos total).
  Future<List<ApiTodo>> fetchTodos({int? limit, int? userId}) async {
    final queryParams = <String, dynamic>{};
    if (userId != null) queryParams['userId'] = userId;
    if (limit != null) queryParams['_limit'] = limit;
    final response = await _dio.get<List<dynamic>>(
      '$_baseUrl/todos',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    return (response.data ?? [])
        .cast<Map<String, dynamic>>()
        .map(ApiTodo.fromJson)
        .toList();
  }

  /// Creates a new todo and returns the remote ID.
  Future<int> createTodo({
    required String title,
    required bool completed,
    int userId = 1,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_baseUrl/todos',
      data: {'title': title, 'completed': completed, 'userId': userId},
    );
    // JSONPlaceholder returns the created todo with an 'id' field
    final data = response.data;
    if (data == null || data['id'] == null) {
      throw ApiException('Failed to create todo: no ID returned');
    }
    return data['id'] as int;
  }

  /// Updates (patches) an existing todo.
  Future<void> patchTodo({
    required int remoteId,
    String? title,
    bool? completed,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (completed != null) data['completed'] = completed;
    await _dio.patch<Map<String, dynamic>>(
      '$_baseUrl/todos/$remoteId',
      data: data,
    );
  }

  /// Deletes a todo by remote ID.
  Future<void> deleteTodo({required int remoteId}) async {
    await _dio.delete<dynamic>('$_baseUrl/todos/$remoteId');
  }
}

/// Exception thrown by the API client.
class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => 'ApiException: $message';
}

/// Data transfer object for a todo from the API.
class ApiTodo {
  const ApiTodo({
    required this.id,
    required this.title,
    required this.completed,
    required this.userId,
  });

  factory ApiTodo.fromJson(Map<String, dynamic> json) {
    return ApiTodo(
      id: json['id'] as int,
      title: json['title'] as String,
      completed: json['completed'] as bool,
      userId: json['userId'] as int,
    );
  }

  final int id;
  final String title;
  final bool completed;
  final int userId;
}
