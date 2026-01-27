import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/providers.dart';
import '../data/todo_repository.dart';
import '../domain/todo.dart';

/// Exception thrown when todo validation fails.
class TodoValidationException implements Exception {
  const TodoValidationException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Controller for managing todo write operations.
/// Does not store state; delegates to repository.
class TodosController extends Notifier<void> {
  @override
  void build() {
    // No state to initialize
  }

  TodoRepository get _repository => ref.read(todoRepositoryProvider);

  /// Adds a new todo with the given title.
  Future<void> addTodo(String title) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw const TodoValidationException('Title cannot be empty');
    }
    final todo = Todo.create(title: trimmedTitle);
    await _repository.create(todo);
  }

  /// Renames an existing todo.
  /// Throws [TodoValidationException] if the new title is empty.
  Future<void> renameTodo({
    required Todo todo,
    required String newTitle,
  }) async {
    final trimmedTitle = newTitle.trim();
    if (trimmedTitle.isEmpty) {
      throw const TodoValidationException('Title cannot be empty');
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
final todosControllerProvider = NotifierProvider<TodosController, void>(
  TodosController.new,
);
