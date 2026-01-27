import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Filter options for the todos list.
enum TodoFilter {
  all('All'),
  active('Active'),
  completed('Completed');

  const TodoFilter(this.label);

  /// Display label for the filter.
  final String label;
}

/// Provider for the currently selected todo filter.
final todoFilterProvider = StateProvider<TodoFilter>((ref) {
  return TodoFilter.all;
});
