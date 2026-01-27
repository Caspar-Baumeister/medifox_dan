import 'package:drift/drift.dart';

/// Table definition for sync operations (outbox queue).
/// Stores pending operations to be synced with the remote server.
class SyncOperationsTable extends Table {
  /// Operation unique identifier (UUID).
  TextColumn get opId => text()();

  /// Local ID of the associated todo.
  TextColumn get todoLocalId => text()();

  /// Operation type: 'create', 'update', 'delete'.
  TextColumn get type => text()();

  /// JSON payload for the operation.
  TextColumn get payloadJson => text()();

  /// Timestamp when the operation was created.
  DateTimeColumn get createdAt => dateTime()();

  /// Number of retry attempts.
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  /// Operation status: 'queued', 'inProgress', 'failed', 'done'.
  TextColumn get status => text().withDefault(const Constant('queued'))();

  /// Last error message.
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {opId};
}
