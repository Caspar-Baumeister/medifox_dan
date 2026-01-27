import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../data/remote/jsonplaceholder_todos_api.dart';

/// Result of a sync operation.
sealed class SyncResult {
  const SyncResult();
}

/// Successful sync result.
final class SyncSuccess extends SyncResult {
  const SyncSuccess({required this.processedCount});

  final int processedCount;
}

/// Failed sync result.
final class SyncFailure extends SyncResult {
  const SyncFailure({required this.message});

  final String message;
}

/// Engine responsible for processing the sync outbox queue.
/// Handles CREATE, UPDATE, DELETE operations against JSONPlaceholder.
class TodosSyncEngine {
  TodosSyncEngine({
    required AppDatabase database,
    required JsonPlaceholderTodosApi api,
    required Connectivity connectivity,
  })  : _database = database,
        _api = api,
        _connectivity = connectivity;

  final AppDatabase _database;
  final JsonPlaceholderTodosApi _api;
  final Connectivity _connectivity;

  TodosDao get _todosDao => _database.todosDao;
  SyncOpsDao get _syncOpsDao => _database.syncOpsDao;

  /// Processes all queued sync operations.
  /// Returns a [SyncResult] indicating success or failure.
  Future<SyncResult> syncNow() async {
    // Check connectivity
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return const SyncFailure(message: 'No internet connection');
    }

    int processedCount = 0;
    String? lastError;

    // Process operations FIFO
    while (true) {
      final ops = await _syncOpsDao.fetchNextQueuedOps(1);
      if (ops.isEmpty) break;

      final op = ops.first;
      await _syncOpsDao.markOpInProgress(op.opId);

      try {
        await _processOperation(op);
        await _syncOpsDao.markOpDone(op.opId);
        processedCount++;
      } on DioException catch (e) {
        lastError = _extractErrorMessage(e);
        await _handleOperationFailure(op, lastError);
      } on ApiException catch (e) {
        lastError = e.message;
        await _handleOperationFailure(op, lastError);
      } catch (e) {
        lastError = e.toString();
        await _handleOperationFailure(op, lastError);
      }
    }

    if (lastError != null && processedCount == 0) {
      return SyncFailure(message: lastError);
    }

    return SyncSuccess(processedCount: processedCount);
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

  String _extractErrorMessage(DioException e) {
    if (e.response != null) {
      return 'HTTP ${e.response?.statusCode}: ${e.message}';
    }
    return switch (e.type) {
      DioExceptionType.connectionTimeout => 'Connection timeout',
      DioExceptionType.sendTimeout => 'Send timeout',
      DioExceptionType.receiveTimeout => 'Receive timeout',
      DioExceptionType.connectionError => 'Connection error',
      _ => e.message ?? 'Unknown network error',
    };
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
  /// Returns a [SyncResult] with the number of imported todos.
  Future<SyncResult> importFromApi({int? limit, int userId = 1}) async {
    // Check connectivity
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return const SyncFailure(message: 'No internet connection');
    }

    try {
      final apiTodos = await _api.fetchTodos(limit: limit, userId: userId);
      int importedCount = 0;

      for (final apiTodo in apiTodos) {
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
        importedCount++;
      }

      return SyncSuccess(processedCount: importedCount);
    } on DioException catch (e) {
      return SyncFailure(message: _extractErrorMessage(e));
    } on ApiException catch (e) {
      return SyncFailure(message: e.message);
    } catch (e) {
      return SyncFailure(message: e.toString());
    }
  }
}
