import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/core_providers.dart';
import '../data/local/drift_todo_repository.dart';
import '../data/remote/jsonplaceholder_todos_api.dart';
import '../data/todo_repository.dart';
import '../domain/todo.dart';
import '../sync/todos_sync_engine.dart';

/// Provider for the todo repository implementation.
final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return DriftTodoRepository(database);
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

/// Stream provider for watching the list of todos from the database.
final todosStreamProvider = StreamProvider<List<Todo>>((ref) {
  final repository = ref.watch(todoRepositoryProvider);
  return repository.watchTodos();
});
