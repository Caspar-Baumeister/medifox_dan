import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../data/todo_repository.dart';
import '../domain/todo.dart';
import 'todos_providers.dart';

/// Controller for managing todo write operations.
/// Uses Riverpod for dependency access but holds no state itself.
class TodosController {
  TodosController(this._repository);

  final TodoRepository _repository;

  /// Adds a new todo with the given title.
  /// Throws [ValidationError] if the title is empty.
  Future<void> addTodo(String title) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw const ValidationError(
        message: 'Title cannot be empty',
        field: 'title',
      );
    }
    final todo = Todo.create(title: trimmedTitle);
    await _repository.create(todo);
  }

  /// Renames an existing todo.
  /// Throws [ValidationError] if the new title is empty.
  Future<void> renameTodo({
    required Todo todo,
    required String newTitle,
  }) async {
    final trimmedTitle = newTitle.trim();
    if (trimmedTitle.isEmpty) {
      throw const ValidationError(
        message: 'Title cannot be empty',
        field: 'title',
      );
    }
    // No-op if title unchanged
    if (trimmedTitle == todo.title) return;

    final updatedTodo = todo.copyWith(title: trimmedTitle);
    await _repository.update(updatedTodo);
  }

  /// Toggles the completed status of a todo.
  Future<void> toggleCompleted(String id) async {
    await _repository.toggleCompleted(id);
  }

  /// Deletes a todo (soft delete).
  Future<void> deleteTodo(String id) async {
    await _repository.delete(id);
  }
}

/// Provider for the TodosController.
final todosControllerProvider = Provider<TodosController>((ref) {
  return TodosController(ref.watch(todoRepositoryProvider));
});
