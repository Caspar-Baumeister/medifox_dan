import 'package:uuid/uuid.dart';

/// Sync state for a todo item.
enum SyncState {
  synced,
  pending,
  failed;

  /// Converts sync state to string for database storage.
  String toDbString() => name;

  /// Creates sync state from database string.
  static SyncState fromDbString(String value) {
    return SyncState.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SyncState.pending,
    );
  }
}

/// Represents a todo item in the domain layer.
/// This is a pure model with no Flutter dependencies.
class Todo {
  const Todo({
    required this.id,
    required this.title,
    required this.completed,
    required this.createdAt,
    required this.updatedAt,
    this.remoteId,
    this.syncState = SyncState.pending,
    this.lastSyncError,
    this.isDeleted = false,
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
      remoteId: null,
      syncState: SyncState.pending,
      lastSyncError: null,
      isDeleted: false,
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

  /// Remote server ID (from JSONPlaceholder).
  final int? remoteId;

  /// Current sync state of the todo.
  final SyncState syncState;

  /// Last sync error message, if any.
  final String? lastSyncError;

  /// Whether the todo is soft deleted.
  final bool isDeleted;

  /// Creates a copy of this todo with the given fields replaced.
  /// Automatically updates updatedAt when relevant fields change.
  Todo copyWith({
    String? id,
    String? title,
    bool? completed,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? remoteId,
    SyncState? syncState,
    String? lastSyncError,
    bool? isDeleted,
    bool clearRemoteId = false,
    bool clearLastSyncError = false,
  }) {
    final hasRelevantChanges = title != null || completed != null;
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt:
          updatedAt ?? (hasRelevantChanges ? DateTime.now() : this.updatedAt),
      remoteId: clearRemoteId ? null : (remoteId ?? this.remoteId),
      syncState: syncState ?? this.syncState,
      lastSyncError: clearLastSyncError
          ? null
          : (lastSyncError ?? this.lastSyncError),
      isDeleted: isDeleted ?? this.isDeleted,
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
        other.updatedAt == updatedAt &&
        other.remoteId == remoteId &&
        other.syncState == syncState &&
        other.lastSyncError == lastSyncError &&
        other.isDeleted == isDeleted;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      completed,
      createdAt,
      updatedAt,
      remoteId,
      syncState,
      lastSyncError,
      isDeleted,
    );
  }

  @override
  String toString() {
    return 'Todo(id: $id, title: $title, completed: $completed, syncState: $syncState)';
  }
}
