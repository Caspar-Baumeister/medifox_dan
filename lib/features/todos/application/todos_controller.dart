import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/providers.dart';
import '../data/todo_repository.dart';
import '../domain/todo.dart';

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
    final todo = Todo.create(title: title);
    await _repository.create(todo);
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
