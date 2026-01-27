import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/todo.dart';

/// A widget that displays a single todo item in the list.
class TodoListItem extends StatelessWidget {
  const TodoListItem({
    super.key,
    required this.todo,
    required this.onToggle,
    this.onTap,
    this.onDismissed,
  });

  /// The todo to display.
  final Todo todo;

  /// Callback when the checkbox is toggled.
  final VoidCallback onToggle;

  /// Callback when the item is tapped.
  final VoidCallback? onTap;

  /// Callback when the item is dismissed (swiped away).
  final VoidCallback? onDismissed;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(todo.id),
      direction: DismissDirection.endToStart,
      onDismissed: onDismissed != null ? (_) => onDismissed!() : null,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(
          Icons.delete_outline,
          color: AppColors.white,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Checkbox(
          value: todo.completed,
          onChanged: (_) => onToggle(),
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: todo.completed ? TextDecoration.lineThrough : null,
            color: todo.completed ? AppColors.textSecondary : AppColors.text,
          ),
        ),
        subtitle: _buildSubtitle(),
      ),
    );
  }

  Widget? _buildSubtitle() {
    final formattedDate = _formatRelativeDate(todo.updatedAt);
    return Text(
      formattedDate,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
      ),
    );
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);
    final difference = today.difference(dateDay).inDays;
    if (difference == 0) return 'Updated today';
    if (difference == 1) return 'Updated yesterday';
    if (difference < 7) return 'Updated $difference days ago';
    return 'Updated ${date.day}/${date.month}/${date.year}';
  }
}
