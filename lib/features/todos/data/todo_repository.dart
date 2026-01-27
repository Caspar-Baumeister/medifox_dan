import '../domain/todo.dart';

/// Repository interface for todo data operations.
/// Implementation will be provided in future steps.
abstract interface class TodoRepository {
  /// Retrieves all todos.
  Future<List<Todo>> getTodos();

  /// Retrieves a single todo by its id.
  Future<Todo?> getTodoById(String id);

  /// Creates a new todo and returns the created todo.
  Future<Todo> createTodo(Todo todo);

  /// Updates an existing todo and returns the updated todo.
  Future<Todo> updateTodo(Todo todo);

  /// Deletes a todo by its id.
  Future<void> deleteTodo(String id);

  /// Toggles the completion status of a todo.
  Future<Todo> toggleTodoCompletion(String id);
}
