import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/providers.dart';
import '../domain/todo.dart';

/// Stream provider for watching the list of todos from the database.
/// Automatically updates when the database changes.
final todosStreamProvider = StreamProvider<List<Todo>>((ref) {
  final repository = ref.watch(todoRepositoryProvider);
  return repository.watchTodos();
});
