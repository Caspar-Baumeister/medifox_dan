import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/tables.dart';

// Re-export tables for external use
export 'tables/tables.dart';

part 'app_database.g.dart';

// =============================================================================
// DATA ACCESS OBJECTS
// =============================================================================

/// Data access object for todos operations.
@DriftAccessor(tables: [TodosTable])
class TodosDao extends DatabaseAccessor<AppDatabase> with _$TodosDaoMixin {
  TodosDao(super.db);

  // ---------------------------------------------------------------------------
  // READ OPERATIONS
  // ---------------------------------------------------------------------------

  /// Watches all non-deleted todos, ordered by created_at descending.
  /// Using createdAt keeps the list stable when items are updated.
  Stream<List<TodosTableData>> watchTodos() {
    return (select(todosTable)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// Gets all non-deleted todos.
  Future<List<TodosTableData>> getTodos() {
    return (select(todosTable)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// Gets a single todo by local ID.
  Future<TodosTableData?> getTodoById(String localId) {
    return (select(
      todosTable,
    )..where((t) => t.localId.equals(localId))).getSingleOrNull();
  }

  /// Gets a todo by its remote ID.
  Future<TodosTableData?> getTodoByRemoteId(int remoteId) {
    return (select(
      todosTable,
    )..where((t) => t.remoteId.equals(remoteId))).getSingleOrNull();
  }

  /// Counts all non-deleted todos.
  Future<int> countTodos() async {
    final count = todosTable.localId.count();
    final query = selectOnly(todosTable)
      ..where(todosTable.isDeleted.equals(false))
      ..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // ---------------------------------------------------------------------------
  // WRITE OPERATIONS
  // ---------------------------------------------------------------------------

  /// Inserts a new todo.
  Future<void> insertTodo(TodosTableCompanion todo) {
    return into(todosTable).insert(todo);
  }

  /// Upserts a todo (insert or update).
  Future<void> upsertTodo(TodosTableCompanion todo) {
    return into(todosTable).insertOnConflictUpdate(todo);
  }

  /// Updates an existing todo.
  Future<void> updateTodo(TodosTableCompanion todo) {
    return (update(
      todosTable,
    )..where((t) => t.localId.equals(todo.localId.value))).write(todo);
  }

  /// Soft deletes a todo and marks it pending.
  Future<void> softDeleteTodo(String localId) {
    return (update(todosTable)..where((t) => t.localId.equals(localId))).write(
      TodosTableCompanion(
        isDeleted: const Value(true),
        syncState: const Value('pending'),
        lastSyncError: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SYNC STATE OPERATIONS
  // ---------------------------------------------------------------------------

  /// Marks a todo as pending sync.
  Future<void> markTodoPending(String localId) {
    return (update(todosTable)..where((t) => t.localId.equals(localId))).write(
      TodosTableCompanion(
        syncState: const Value('pending'),
        lastSyncError: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Sets a todo as synced with optional remote ID.
  Future<void> setTodoSynced(String localId, {int? remoteId}) {
    return (update(todosTable)..where((t) => t.localId.equals(localId))).write(
      TodosTableCompanion(
        syncState: const Value('synced'),
        lastSyncError: const Value(null),
        remoteId: remoteId != null ? Value(remoteId) : const Value.absent(),
      ),
    );
  }

  /// Sets a todo as failed with error message.
  Future<void> setTodoFailed(String localId, String error) {
    return (update(todosTable)..where((t) => t.localId.equals(localId))).write(
      TodosTableCompanion(
        syncState: const Value('failed'),
        lastSyncError: Value(error),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // IMPORT OPERATIONS
  // ---------------------------------------------------------------------------

  /// Upserts an imported todo by remote ID (does not overwrite pending/failed local items).
  Future<void> upsertImportedTodo(
    TodosTableCompanion todo,
    int remoteId,
  ) async {
    final existing = await getTodoByRemoteId(remoteId);
    if (existing != null) {
      // Don't overwrite if local item is pending or failed
      if (existing.syncState == 'pending' || existing.syncState == 'failed') {
        return;
      }
      // Update existing synced item
      await (update(
        todosTable,
      )..where((t) => t.remoteId.equals(remoteId))).write(todo);
    } else {
      // Insert new imported item
      await into(todosTable).insert(todo);
    }
  }
}

/// Data access object for sync operations (outbox queue).
@DriftAccessor(tables: [SyncOperationsTable, TodosTable])
class SyncOpsDao extends DatabaseAccessor<AppDatabase> with _$SyncOpsDaoMixin {
  SyncOpsDao(super.db);

  // ---------------------------------------------------------------------------
  // QUEUE OPERATIONS
  // ---------------------------------------------------------------------------

  /// Fetches the next queued operations, ordered by created_at ascending.
  Future<List<SyncOperationsTableData>> fetchNextQueuedOps(int limit) {
    return (select(syncOperationsTable)
          ..where((o) => o.status.equals('queued'))
          ..orderBy([(o) => OrderingTerm.asc(o.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Gets all queued operations for a specific todo.
  Future<List<SyncOperationsTableData>> getOpsForTodo(String todoLocalId) {
    return (select(syncOperationsTable)
          ..where((o) => o.todoLocalId.equals(todoLocalId))
          ..where((o) => o.status.isIn(['queued', 'inProgress']))
          ..orderBy([(o) => OrderingTerm.asc(o.createdAt)]))
        .get();
  }

  /// Counts pending (queued) operations.
  Future<int> countPendingOps() async {
    final count = syncOperationsTable.opId.count();
    final query = selectOnly(syncOperationsTable)
      ..where(syncOperationsTable.status.equals('queued'))
      ..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // ---------------------------------------------------------------------------
  // STATUS UPDATES
  // ---------------------------------------------------------------------------

  /// Marks an operation as in progress.
  Future<void> markOpInProgress(String opId) {
    return (update(syncOperationsTable)..where((o) => o.opId.equals(opId)))
        .write(const SyncOperationsTableCompanion(status: Value('inProgress')));
  }

  /// Marks an operation as done.
  Future<void> markOpDone(String opId) {
    return (update(syncOperationsTable)..where((o) => o.opId.equals(opId)))
        .write(const SyncOperationsTableCompanion(status: Value('done')));
  }

  /// Marks an operation as failed with error and increments retry count.
  Future<void> markOpFailed(String opId, String error) async {
    final existing = await (select(
      syncOperationsTable,
    )..where((o) => o.opId.equals(opId))).getSingleOrNull();
    if (existing == null) return;
    await (update(
      syncOperationsTable,
    )..where((o) => o.opId.equals(opId))).write(
      SyncOperationsTableCompanion(
        status: const Value('queued'),
        retryCount: Value(existing.retryCount + 1),
        lastError: Value(error),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DELETE OPERATIONS
  // ---------------------------------------------------------------------------

  /// Deletes all operations for a specific todo.
  Future<void> deleteOpsForTodo(String todoLocalId) {
    return (delete(
      syncOperationsTable,
    )..where((o) => o.todoLocalId.equals(todoLocalId))).go();
  }

  /// Deletes a specific operation.
  Future<void> deleteOp(String opId) {
    return (delete(
      syncOperationsTable,
    )..where((o) => o.opId.equals(opId))).go();
  }

  // ---------------------------------------------------------------------------
  // COALESCING ENQUEUE
  // ---------------------------------------------------------------------------

  /// Enqueues a sync operation with coalescing logic.
  ///
  /// Coalescing rules:
  /// - CREATE + UPDATE → Merge UPDATE into CREATE payload
  /// - CREATE + DELETE → Remove CREATE, don't enqueue DELETE
  /// - UPDATE + UPDATE → Keep only latest UPDATE
  /// - DELETE → Remove any queued UPDATEs
  Future<void> enqueueOrCoalesce({
    required String opId,
    required String todoLocalId,
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    final existingOps = await getOpsForTodo(todoLocalId);
    final existingCreateOp = existingOps
        .where((op) => op.type == 'create' && op.status == 'queued')
        .firstOrNull;
    final existingUpdateOp = existingOps
        .where((op) => op.type == 'update' && op.status == 'queued')
        .firstOrNull;
    final hasQueuedCreate = existingCreateOp != null;

    // Rule A: If there's a queued CREATE for this todo
    if (hasQueuedCreate) {
      if (type == 'update') {
        // Merge UPDATE into CREATE payload
        final createPayload =
            jsonDecode(existingCreateOp.payloadJson) as Map<String, dynamic>;
        final mergedPayload = {...createPayload, ...payload};
        await (update(
          syncOperationsTable,
        )..where((o) => o.opId.equals(existingCreateOp.opId))).write(
          SyncOperationsTableCompanion(
            payloadJson: Value(jsonEncode(mergedPayload)),
          ),
        );
        return;
      }
      if (type == 'delete') {
        // Remove CREATE op entirely - item never existed remotely
        await deleteOp(existingCreateOp.opId);
        // Also remove any UPDATE ops
        for (final op in existingOps.where((o) => o.type == 'update')) {
          await deleteOp(op.opId);
        }
        return;
      }
    }

    // Rule B: If incoming is UPDATE and there's already a queued UPDATE
    if (type == 'update' && existingUpdateOp != null) {
      await (update(
        syncOperationsTable,
      )..where((o) => o.opId.equals(existingUpdateOp.opId))).write(
        SyncOperationsTableCompanion(payloadJson: Value(jsonEncode(payload))),
      );
      return;
    }

    // Rule C: If incoming is DELETE, remove any queued UPDATE ops
    if (type == 'delete') {
      for (final op in existingOps.where((o) => o.type == 'update')) {
        await deleteOp(op.opId);
      }
    }

    // Insert new operation
    await into(syncOperationsTable).insert(
      SyncOperationsTableCompanion(
        opId: Value(opId),
        todoLocalId: Value(todoLocalId),
        type: Value(type),
        payloadJson: Value(jsonEncode(payload)),
        createdAt: Value(DateTime.now()),
        retryCount: const Value(0),
        status: const Value('queued'),
      ),
    );
  }
}

// =============================================================================
// DATABASE
// =============================================================================

/// The main application database.
@DriftDatabase(
  tables: [TodosTable, SyncOperationsTable],
  daos: [TodosDao, SyncOpsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// For testing - allows injecting a custom executor.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) => m.createAll(),
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          // Migration v1 → v2: Add sync support
          await m.addColumn(todosTable, todosTable.remoteId);
          await m.addColumn(todosTable, todosTable.syncState);
          await m.addColumn(todosTable, todosTable.lastSyncError);
          await m.createTable(syncOperationsTable);
        }
      },
    );
  }
}

/// Opens a lazy database connection.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'medifox_dan.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
