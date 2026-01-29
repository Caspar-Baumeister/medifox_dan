import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/todo.dart';
import '../todo_repository.dart';

/// Drift-backed implementation of [TodoRepository].
/// Handles local SQLite database operations and enqueues sync operations.
class DriftTodoRepository implements TodoRepository {
  DriftTodoRepository(this._database);

  final AppDatabase _database;
  final _uuid = const Uuid();

  TodosDao get _todosDao => _database.todosDao;
  SyncOpsDao get _syncOpsDao => _database.syncOpsDao;

  @override
  Stream<List<Todo>> watchTodos() {
    return _todosDao.watchTodos().map(
      (rows) => rows.map(_mapRowToTodo).toList(),
    );
  }

  @override
  Future<void> create(Todo todo) async {
    // Insert todo with pending sync state
    final companion = TodosTableCompanion(
      localId: Value(todo.id),
      title: Value(todo.title),
      completed: Value(todo.completed),
      createdAt: Value(todo.createdAt),
      updatedAt: Value(todo.updatedAt),
      isDeleted: const Value(false),
      remoteId: const Value(null),
      syncState: const Value('pending'),
      lastSyncError: const Value(null),
    );
    await _todosDao.insertTodo(companion);

    // Enqueue CREATE sync operation
    await _syncOpsDao.enqueueOrCoalesce(
      opId: _uuid.v4(),
      todoLocalId: todo.id,
      type: 'create',
      payload: {'title': todo.title, 'completed': todo.completed, 'userId': 1},
    );
  }

  @override
  Future<void> update(Todo todo) async {
    // Update todo with pending sync state
    final companion = TodosTableCompanion(
      localId: Value(todo.id),
      title: Value(todo.title),
      completed: Value(todo.completed),
      createdAt: Value(todo.createdAt),
      updatedAt: Value(DateTime.now()),
      isDeleted: const Value(false),
      syncState: const Value('pending'),
      lastSyncError: const Value(null),
    );
    await _todosDao.updateTodo(companion);

    // Enqueue UPDATE sync operation
    await _syncOpsDao.enqueueOrCoalesce(
      opId: _uuid.v4(),
      todoLocalId: todo.id,
      type: 'update',
      payload: {'title': todo.title, 'completed': todo.completed},
    );
  }

  @override
  Future<void> toggleCompleted(String id) async {
    final existing = await _todosDao.getTodoById(id);
    if (existing == null) return;

    final newCompleted = !existing.completed;

    // Update todo with pending sync state
    await _todosDao.updateTodo(
      TodosTableCompanion(
        localId: Value(id),
        completed: Value(newCompleted),
        updatedAt: Value(DateTime.now()),
        syncState: const Value('pending'),
        lastSyncError: const Value(null),
      ),
    );

    // Enqueue UPDATE sync operation
    await _syncOpsDao.enqueueOrCoalesce(
      opId: _uuid.v4(),
      todoLocalId: id,
      type: 'update',
      payload: {'title': existing.title, 'completed': newCompleted},
    );
  }

  @override
  Future<void> delete(String id) async {
    final existing = await _todosDao.getTodoById(id);
    if (existing == null) return;

    // Check if there's a pending CREATE - if so, just remove without DELETE op
    final pendingOps = await _syncOpsDao.getOpsForTodo(id);
    final hasPendingCreate = pendingOps.any(
      (op) => op.type == 'create' && op.status == 'queued',
    );

    // Soft delete todo
    await _todosDao.softDeleteTodo(id);

    if (hasPendingCreate) {
      // Item never existed on server, just clean up local ops
      await _syncOpsDao.enqueueOrCoalesce(
        opId: _uuid.v4(),
        todoLocalId: id,
        type: 'delete',
        payload: {},
      );
    } else {
      // Enqueue DELETE sync operation
      await _syncOpsDao.enqueueOrCoalesce(
        opId: _uuid.v4(),
        todoLocalId: id,
        type: 'delete',
        payload: {},
      );
    }
  }

  @override
  Future<int> count() {
    return _todosDao.countTodos();
  }

  Todo _mapRowToTodo(TodosTableData row) {
    return Todo(
      id: row.localId,
      title: row.title,
      completed: row.completed,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      remoteId: row.remoteId,
      syncState: SyncState.fromDbString(row.syncState),
      lastSyncError: row.lastSyncError,
      isDeleted: row.isDeleted,
    );
  }
}
