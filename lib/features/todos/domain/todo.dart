import 'package:uuid/uuid.dart';

/// Represents a todo item in the domain layer.
/// This is a pure model with no Flutter dependencies.
class Todo {
  const Todo({
    required this.id,
    required this.title,
    required this.completed,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a new todo with a generated UUID and current timestamps.
  factory Todo.create({required String title}) {
    final now = DateTime.now();
    return Todo(
      id: const Uuid().v4(),
      title: title,
      completed: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Unique identifier for the todo (UUID v4).
  final String id;

  /// Title of the todo.
  final String title;

  /// Whether the todo has been completed.
  final bool completed;

  /// Timestamp when the todo was created.
  final DateTime createdAt;

  /// Timestamp when the todo was last updated.
  final DateTime updatedAt;

  /// Creates a copy of this todo with the given fields replaced.
  /// Automatically updates updatedAt when relevant fields change.
  Todo copyWith({
    String? id,
    String? title,
    bool? completed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final hasRelevantChanges = title != null || completed != null;
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt:
          updatedAt ?? (hasRelevantChanges ? DateTime.now() : this.updatedAt),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Todo &&
        other.id == id &&
        other.title == title &&
        other.completed == completed &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, title, completed, createdAt, updatedAt);
  }

  @override
  String toString() {
    return 'Todo(id: $id, title: $title, completed: $completed)';
  }
}
