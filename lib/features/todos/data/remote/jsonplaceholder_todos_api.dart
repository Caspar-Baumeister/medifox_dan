import 'package:dio/dio.dart';

/// API client for JSONPlaceholder todos endpoints.
/// Base URL: https://jsonplaceholder.typicode.com
class JsonPlaceholderTodosApi {
  JsonPlaceholderTodosApi(this._dio);

  final Dio _dio;
  static const _baseUrl = 'https://jsonplaceholder.typicode.com';

  /// Fetches all todos from the server.
  Future<List<Map<String, dynamic>>> fetchTodos() async {
    final response = await _dio.get<List<dynamic>>('$_baseUrl/todos');
    return (response.data ?? []).cast<Map<String, dynamic>>();
  }

  /// Creates a new todo and returns the remote ID.
  Future<int> createTodo({
    required String title,
    required bool completed,
    int userId = 1,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_baseUrl/todos',
      data: {
        'title': title,
        'completed': completed,
        'userId': userId,
      },
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
