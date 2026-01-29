import '../domain/todo.dart';

/// Repository interface for todo data operations.
/// Defines the contract for data access without implementation details.
abstract class TodoRepository {
  /// Watches all non-deleted todos as a stream.
  Stream<List<Todo>> watchTodos();

  /// Gets a single todo by ID.
  Future<Todo?> getById(String id);

  /// Creates a new todo.
  Future<void> create(Todo todo);

  /// Updates an existing todo.
  Future<void> update(Todo todo);

  /// Toggles the completed status of a todo.
  Future<void> toggleCompleted(String id);

  /// Soft deletes a todo (marks as deleted).
  Future<void> delete(String id);

  /// Returns the count of non-deleted todos.
  Future<int> count();
}
