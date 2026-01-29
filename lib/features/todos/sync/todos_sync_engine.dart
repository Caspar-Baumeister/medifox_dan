import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/errors/app_error.dart';
import '../data/remote/jsonplaceholder_todos_api.dart';

/// Summary of a sync operation.
class SyncSummary {
  const SyncSummary({
    required this.processed,
    required this.succeeded,
    required this.failed,
    required this.aborted,
    this.abortReason,
  });

  /// Number of operations processed.
  final int processed;

  /// Number of operations that succeeded.
  final int succeeded;

  /// Number of operations that failed.
  final int failed;

  /// Whether the sync was aborted early (e.g., offline).
  final bool aborted;

  /// Reason for abort, if aborted.
  final AppError? abortReason;

  /// Whether all processed operations succeeded.
  bool get isFullySuccessful => !aborted && failed == 0;

  /// Whether any operations were processed.
  bool get hasProcessedAny => processed > 0;

  @override
  String toString() =>
      'SyncSummary(processed: $processed, succeeded: $succeeded, failed: $failed, aborted: $aborted)';
}

/// Engine responsible for processing the sync outbox queue.
/// Handles CREATE, UPDATE, DELETE operations against JSONPlaceholder.
class TodosSyncEngine {
  TodosSyncEngine({
    required AppDatabase database,
    required JsonPlaceholderTodosApi api,
    required Connectivity connectivity,
  }) : _database = database,
       _api = api,
       _connectivity = connectivity;

  final AppDatabase _database;
  final JsonPlaceholderTodosApi _api;
  final Connectivity _connectivity;

  TodosDao get _todosDao => _database.todosDao;
  SyncOpsDao get _syncOpsDao => _database.syncOpsDao;

  /// Processes all queued sync operations.
  ///
  /// Returns a [SyncSummary] with the results.
  /// Throws [OfflineError] if no network connection.
  Future<SyncSummary> syncNow() async {
    // Check connectivity first
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return const SyncSummary(
        processed: 0,
        succeeded: 0,
        failed: 0,
        aborted: true,
        abortReason: OfflineError(),
      );
    }

    int processed = 0;
    int succeeded = 0;
    int failed = 0;

    // Process operations FIFO
    while (true) {
      final ops = await _syncOpsDao.fetchNextQueuedOps(1);
      if (ops.isEmpty) break;

      final op = ops.first;
      await _syncOpsDao.markOpInProgress(op.opId);
      processed++;

      try {
        await _processOperation(op);
        await _syncOpsDao.markOpDone(op.opId);
        succeeded++;
      } on AppError catch (e) {
        await _handleOperationFailure(op, e.userMessage);
        failed++;
      } catch (e) {
        await _handleOperationFailure(op, e.toString());
        failed++;
      }
    }

    return SyncSummary(
      processed: processed,
      succeeded: succeeded,
      failed: failed,
      aborted: false,
    );
  }

  Future<void> _processOperation(SyncOperationsTableData op) async {
    final payload = jsonDecode(op.payloadJson) as Map<String, dynamic>;
    final todo = await _todosDao.getTodoById(op.todoLocalId);

    switch (op.type) {
      case 'create':
        await _handleCreate(op.todoLocalId, payload);
      case 'update':
        await _handleUpdate(op.todoLocalId, payload, todo?.remoteId);
      case 'delete':
        await _handleDelete(op.todoLocalId, todo?.remoteId);
    }
  }

  Future<void> _handleCreate(
    String todoLocalId,
    Map<String, dynamic> payload,
  ) async {
    final remoteId = await _api.createTodo(
      title: payload['title'] as String,
      completed: payload['completed'] as bool,
      userId: payload['userId'] as int? ?? 1,
    );
    await _todosDao.setTodoSynced(todoLocalId, remoteId: remoteId);
  }

  Future<void> _handleUpdate(
    String todoLocalId,
    Map<String, dynamic> payload,
    int? existingRemoteId,
  ) async {
    if (existingRemoteId == null) {
      // Fallback: treat as CREATE if no remote ID exists
      final remoteId = await _api.createTodo(
        title: payload['title'] as String,
        completed: payload['completed'] as bool,
        userId: 1,
      );
      await _todosDao.setTodoSynced(todoLocalId, remoteId: remoteId);
    } else {
      await _api.patchTodo(
        remoteId: existingRemoteId,
        title: payload['title'] as String?,
        completed: payload['completed'] as bool?,
      );
      await _todosDao.setTodoSynced(todoLocalId);
    }
  }

  Future<void> _handleDelete(String todoLocalId, int? remoteId) async {
    if (remoteId != null) {
      await _api.deleteTodo(remoteId: remoteId);
    }
    // Mark as synced (deleted and synced)
    await _todosDao.setTodoSynced(todoLocalId);
  }

  Future<void> _handleOperationFailure(
    SyncOperationsTableData op,
    String error,
  ) async {
    await _syncOpsDao.markOpFailed(op.opId, error);
    await _todosDao.setTodoFailed(op.todoLocalId, error);
  }

  /// Returns the count of pending operations.
  Future<int> pendingOperationsCount() {
    return _syncOpsDao.countPendingOps();
  }

  /// Imports todos from the API into the local database.
  ///
  /// ASSUMPTION: We import todos filtered by userId=1 to get a manageable subset.
  /// JSONPlaceholder has 200 todos total across 10 users (20 per user).
  ///
  /// Returns a [SyncSummary] with the number of imported todos.
  /// Throws [OfflineError] if no network connection.
  Future<SyncSummary> importFromApi({int? limit, int userId = 1}) async {
    // Check connectivity first
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return const SyncSummary(
        processed: 0,
        succeeded: 0,
        failed: 0,
        aborted: true,
        abortReason: OfflineError(),
      );
    }

    try {
      final apiTodos = await _api.fetchTodos(limit: limit, userId: userId);
      int imported = 0;

      for (final apiTodo in apiTodos) {
        try {
          final localId = const Uuid().v4();
          final now = DateTime.now();

          final companion = TodosTableCompanion(
            localId: Value(localId),
            title: Value(apiTodo.title),
            completed: Value(apiTodo.completed),
            createdAt: Value(now),
            updatedAt: Value(now),
            isDeleted: const Value(false),
            remoteId: Value(apiTodo.id),
            syncState: const Value('synced'),
            lastSyncError: const Value(null),
          );

          await _todosDao.upsertImportedTodo(companion, apiTodo.id);
          imported++;
        } catch (_) {
          // Skip individual items that fail to import, continue with others
        }
      }

      return SyncSummary(
        processed: apiTodos.length,
        succeeded: imported,
        failed: apiTodos.length - imported,
        aborted: false,
      );
    } on AppError catch (e) {
      return SyncSummary(
        processed: 0,
        succeeded: 0,
        failed: 0,
        aborted: true,
        abortReason: e,
      );
    } catch (e) {
      return SyncSummary(
        processed: 0,
        succeeded: 0,
        failed: 0,
        aborted: true,
        abortReason: UnknownError(message: e.toString(), originalError: e),
      );
    }
  }
}
