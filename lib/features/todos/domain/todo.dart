/// Represents a todo item in the domain layer.
/// This is a pure model with no Flutter dependencies.
class Todo {
  const Todo({
    required this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.createdAt,
    this.dueDate,
  });

  /// Unique identifier for the todo.
  final String id;

  /// Title of the todo.
  final String title;

  /// Optional description with additional details.
  final String? description;

  /// Whether the todo has been completed.
  final bool isCompleted;

  /// Timestamp when the todo was created.
  final DateTime? createdAt;

  /// Optional due date for the todo.
  final DateTime? dueDate;

  /// Creates a copy of this todo with the given fields replaced.
  Todo copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? dueDate,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Todo &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.isCompleted == isCompleted &&
        other.createdAt == createdAt &&
        other.dueDate == dueDate;
  }

  @override
  int get hashCode {
    return Object.hash(id, title, description, isCompleted, createdAt, dueDate);
  }

  @override
  String toString() {
    return 'Todo(id: $id, title: $title, isCompleted: $isCompleted)';
  }
}
