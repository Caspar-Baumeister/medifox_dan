import 'package:drift/drift.dart';

/// Table definition for todos.
class TodosTable extends Table {
  /// Local unique identifier (UUID).
  TextColumn get localId => text()();

  /// Title of the todo.
  TextColumn get title => text()();

  /// Whether the todo is completed.
  BoolColumn get completed => boolean().withDefault(const Constant(false))();

  /// Timestamp when the todo was created.
  DateTimeColumn get createdAt => dateTime()();

  /// Timestamp when the todo was last updated.
  DateTimeColumn get updatedAt => dateTime()();

  /// Soft delete flag for sync support.
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  /// Remote server ID (from JSONPlaceholder).
  IntColumn get remoteId => integer().nullable()();

  /// Sync state: 'synced', 'pending', 'failed'.
  TextColumn get syncState => text().withDefault(const Constant('pending'))();

  /// Last sync error message.
  TextColumn get lastSyncError => text().nullable()();

  @override
  Set<Column> get primaryKey => {localId};
}
