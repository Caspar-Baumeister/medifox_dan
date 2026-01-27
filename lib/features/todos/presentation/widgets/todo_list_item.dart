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
          value: todo.isCompleted,
          onChanged: (_) => onToggle(),
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
            color: todo.isCompleted ? AppColors.textSecondary : AppColors.text,
          ),
        ),
        subtitle: todo.description != null
            ? Text(
                todo.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  decoration:
                      todo.isCompleted ? TextDecoration.lineThrough : null,
                  color: AppColors.textSecondary,
                ),
              )
            : null,
        trailing: _buildDueDateBadge(),
      ),
    );
  }

  Widget? _buildDueDateBadge() {
    if (todo.dueDate == null || todo.isCompleted) return null;
    final now = DateTime.now();
    final isOverdue = todo.dueDate!.isBefore(now);
    final isDueSoon = todo.dueDate!.difference(now).inDays <= 1;
    Color badgeColor;
    if (isOverdue) {
      badgeColor = AppColors.error;
    } else if (isDueSoon) {
      badgeColor = Colors.orange;
    } else {
      badgeColor = AppColors.secondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _formatDueDate(todo.dueDate!),
        style: TextStyle(
          fontSize: 12,
          color: badgeColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(date.year, date.month, date.day);
    final difference = dueDay.difference(today).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference == -1) return 'Yesterday';
    if (difference < -1) return '${-difference}d overdue';
    if (difference <= 7) return 'In ${difference}d';
    return '${date.day}/${date.month}';
  }
}
