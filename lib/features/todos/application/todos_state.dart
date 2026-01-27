import '../domain/todo.dart';

/// Represents the different states of the todos list.
sealed class TodosState {
  const TodosState();
}

/// Initial state before any data is loaded.
final class TodosInitial extends TodosState {
  const TodosInitial();
}

/// Loading state while fetching todos.
final class TodosLoading extends TodosState {
  const TodosLoading();
}

/// Loaded state with the list of todos.
final class TodosLoaded extends TodosState {
  const TodosLoaded({
    required this.todos,
    this.selectedFilter = TodoFilter.all,
  });

  /// The list of todos.
  final List<Todo> todos;

  /// The currently selected filter.
  final TodoFilter selectedFilter;

  /// Returns the todos filtered by the selected filter.
  List<Todo> get filteredTodos {
    return switch (selectedFilter) {
      TodoFilter.all => todos,
      TodoFilter.active => todos.where((todo) => !todo.isCompleted).toList(),
      TodoFilter.completed => todos.where((todo) => todo.isCompleted).toList(),
    };
  }

  /// Returns the count of active (incomplete) todos.
  int get activeCount => todos.where((todo) => !todo.isCompleted).length;

  /// Returns the count of completed todos.
  int get completedCount => todos.where((todo) => todo.isCompleted).length;

  /// Creates a copy of this state with the given fields replaced.
  TodosLoaded copyWith({
    List<Todo>? todos,
    TodoFilter? selectedFilter,
  }) {
    return TodosLoaded(
      todos: todos ?? this.todos,
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }
}

/// Error state when loading or manipulating todos fails.
final class TodosError extends TodosState {
  const TodosError({required this.message});

  /// The error message.
  final String message;
}

/// Filter options for the todos list.
enum TodoFilter {
  all('All'),
  active('Active'),
  completed('Completed');

  const TodoFilter(this.label);

  /// Display label for the filter.
  final String label;
}
