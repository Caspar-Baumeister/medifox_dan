import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/todo.dart';
import 'todos_state.dart';

/// Controller for managing the todos list state.
/// Handles all business logic related to todos.
class TodosController extends StateNotifier<TodosState> {
  TodosController() : super(const TodosInitial());

  /// Loads the initial list of todos.
  /// For now, this uses mock data. Repository will be injected later.
  Future<void> loadTodos() async {
    state = const TodosLoading();
    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 500));
    // Mock data for initial setup
    final mockTodos = [
      Todo(
        id: '1',
        title: 'Set up project structure',
        description: 'Create feature-first folder layout',
        isCompleted: true,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Todo(
        id: '2',
        title: 'Configure Riverpod',
        description: 'Add state management with flutter_riverpod',
        isCompleted: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Todo(
        id: '3',
        title: 'Implement GoRouter',
        description: 'Set up navigation with go_router',
        isCompleted: false,
        createdAt: DateTime.now(),
      ),
      Todo(
        id: '4',
        title: 'Add database layer',
        description: 'Implement local storage with SQLite or Hive',
        isCompleted: false,
        createdAt: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(days: 3)),
      ),
    ];
    state = TodosLoaded(todos: mockTodos);
  }

  /// Toggles the completion status of a todo.
  void toggleTodoCompletion(String todoId) {
    final currentState = state;
    if (currentState is! TodosLoaded) return;
    final updatedTodos = currentState.todos.map((todo) {
      if (todo.id == todoId) {
        return todo.copyWith(isCompleted: !todo.isCompleted);
      }
      return todo;
    }).toList();
    state = currentState.copyWith(todos: updatedTodos);
  }

  /// Changes the current filter.
  void setFilter(TodoFilter filter) {
    final currentState = state;
    if (currentState is! TodosLoaded) return;
    state = currentState.copyWith(selectedFilter: filter);
  }

  /// Adds a new todo to the list.
  void addTodo(Todo todo) {
    final currentState = state;
    if (currentState is! TodosLoaded) return;
    state = currentState.copyWith(
      todos: [...currentState.todos, todo],
    );
  }

  /// Removes a todo from the list.
  void removeTodo(String todoId) {
    final currentState = state;
    if (currentState is! TodosLoaded) return;
    state = currentState.copyWith(
      todos: currentState.todos.where((todo) => todo.id != todoId).toList(),
    );
  }
}

/// Provider for the TodosController.
final todosControllerProvider =
    StateNotifierProvider<TodosController, TodosState>((ref) {
  return TodosController();
});
