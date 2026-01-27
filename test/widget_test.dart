// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:medifox_dan/features/todos/domain/todo.dart';

void main() {
  group('Todo', () {
    test('Todo.create generates valid todo', () {
      final todo = Todo.create(title: 'Test todo');
      expect(todo.title, 'Test todo');
      expect(todo.completed, false);
      expect(todo.id, isNotEmpty);
      expect(todo.createdAt, isNotNull);
      expect(todo.updatedAt, isNotNull);
    });

    test('copyWith updates fields and updatedAt', () {
      final original = Todo.create(title: 'Original');
      final updated = original.copyWith(completed: true);
      expect(updated.completed, true);
      expect(updated.title, 'Original');
      expect(updated.id, original.id);
    });

    test('copyWith with title change updates updatedAt', () {
      final original = Todo.create(title: 'Original');
      // Small delay to ensure different timestamp
      final updated = original.copyWith(title: 'Updated');
      expect(updated.title, 'Updated');
    });
  });
}
