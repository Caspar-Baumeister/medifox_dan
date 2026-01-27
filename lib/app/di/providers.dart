import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import '../../features/todos/data/local/drift_todo_repository.dart';
import '../../features/todos/data/todo_repository.dart';
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
