import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/todo.dart';
import '../todo_repository.dart';

/// Drift-backed implementation of [TodoRepository].
/// Handles local SQLite database operations.
class DriftTodoRepository implements TodoRepository {
  DriftTodoRepository(this._database);

  final AppDatabase _database;

  TodosDao get _dao => _database.todosDao;

  @override
  Stream<List<Todo>> watchTodos() {
    return _dao.watchTodos().map(
          (rows) => rows.map(_mapRowToTodo).toList(),
        );
  }

  @override
  Future<void> create(Todo todo) async {
    final companion = TodosTableCompanion(
      localId: Value(todo.id),
      title: Value(todo.title),
      completed: Value(todo.completed),
      createdAt: Value(todo.createdAt),
      updatedAt: Value(todo.updatedAt),
      isDeleted: const Value(false),
    );
    await _dao.insertTodo(companion);
  }

  @override
  Future<void> update(Todo todo) async {
    final companion = TodosTableCompanion(
      localId: Value(todo.id),
      title: Value(todo.title),
      completed: Value(todo.completed),
      createdAt: Value(todo.createdAt),
      updatedAt: Value(DateTime.now()),
      isDeleted: const Value(false),
    );
    await _dao.updateTodo(companion);
  }

  @override
  Future<void> toggleCompleted(String id) async {
    final existing = await _dao.getTodoById(id);
    if (existing == null) return;
    final companion = TodosTableCompanion(
      localId: Value(id),
      completed: Value(!existing.completed),
      updatedAt: Value(DateTime.now()),
    );
    await _dao.updateTodo(companion);
  }

  @override
  Future<void> delete(String id) async {
    await _dao.softDeleteTodo(id);
  }

  @override
  Future<int> count() {
    return _dao.countTodos();
  }

  Todo _mapRowToTodo(TodosTableData row) {
    return Todo(
      id: row.localId,
      title: row.title,
      completed: row.completed,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
