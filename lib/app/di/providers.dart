import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import '../../features/todos/data/local/drift_todo_repository.dart';
import '../../features/todos/data/remote/jsonplaceholder_todos_api.dart';
import '../../features/todos/data/todo_repository.dart';
import '../../features/todos/sync/todos_sync_engine.dart';
import '../router/app_router.dart';

/// Provider for the GoRouter instance.
/// Use this provider to access the router throughout the app.
final goRouterProvider = Provider<GoRouter>((ref) {
  return AppRouter.router;
});

/// Provider for the application database.
/// Properly disposes the database when no longer needed.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(() => database.close());
  return database;
});

/// Provider for the todo repository implementation.
/// Uses Drift-backed local storage.
final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return DriftTodoRepository(database);
});

/// Provider for Dio HTTP client.
final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );
});

/// Provider for Connectivity service.
final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

/// Provider for the JSONPlaceholder API client.
final todosApiProvider = Provider<JsonPlaceholderTodosApi>((ref) {
  final dio = ref.watch(dioProvider);
  return JsonPlaceholderTodosApi(dio);
});

/// Provider for the sync engine.
final todosSyncEngineProvider = Provider<TodosSyncEngine>((ref) {
  final database = ref.watch(appDatabaseProvider);
  final api = ref.watch(todosApiProvider);
  final connectivity = ref.watch(connectivityProvider);
  return TodosSyncEngine(
    database: database,
    api: api,
    connectivity: connectivity,
  );
});
