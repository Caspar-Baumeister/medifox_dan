import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

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

  /// Soft delete flag for future sync support.
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {localId};
}

/// Data access object for todos operations.
@DriftAccessor(tables: [TodosTable])
class TodosDao extends DatabaseAccessor<AppDatabase> with _$TodosDaoMixin {
  TodosDao(super.db);

  /// Watches all non-deleted todos, ordered by updated_at descending.
  Stream<List<TodosTableData>> watchTodos() {
    return (select(todosTable)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([
            (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  /// Gets all non-deleted todos.
  Future<List<TodosTableData>> getTodos() {
    return (select(todosTable)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([
            (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  /// Gets a single todo by local ID.
  Future<TodosTableData?> getTodoById(String localId) {
    return (select(todosTable)..where((t) => t.localId.equals(localId)))
        .getSingleOrNull();
  }

  /// Inserts a new todo.
  Future<void> insertTodo(TodosTableCompanion todo) {
    return into(todosTable).insert(todo);
  }

  /// Updates an existing todo.
  Future<void> updateTodo(TodosTableCompanion todo) {
    return (update(todosTable)
          ..where((t) => t.localId.equals(todo.localId.value)))
        .write(todo);
  }

  /// Soft deletes a todo by setting is_deleted to true.
  Future<void> softDeleteTodo(String localId) {
    return (update(todosTable)..where((t) => t.localId.equals(localId))).write(
      TodosTableCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
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
}

/// The main application database.
@DriftDatabase(tables: [TodosTable], daos: [TodosDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'medifox_dan.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
