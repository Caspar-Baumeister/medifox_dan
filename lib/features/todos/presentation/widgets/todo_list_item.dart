import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/todo.dart';

/// A widget that displays a single todo item in the list.
/// Includes animations for completed state and sync status changes.
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
    return TweenAnimationBuilder<double>(
      key: ValueKey('appear_${todo.id}'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Dismissible(
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
          title: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 16,
              decoration: todo.completed ? TextDecoration.lineThrough : null,
              color: todo.completed ? AppColors.textSecondary : AppColors.text,
            ),
            child: Text(todo.title),
          ),
          subtitle: _buildSubtitle(),
          trailing: _buildSyncStatusIndicator(),
        ),
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

  Widget? _buildSyncStatusIndicator() {
    final icon = switch (todo.syncState) {
      SyncState.pending => _AnimatedSyncIcon(
          key: ValueKey('pending_${todo.id}'),
          icon: Icons.schedule,
          color: AppColors.secondary.withValues(alpha: 0.7),
          tooltip: 'Pending sync',
        ),
      SyncState.failed => _AnimatedSyncIcon(
          key: ValueKey('failed_${todo.id}'),
          icon: Icons.warning_amber_rounded,
          color: AppColors.error,
          tooltip: todo.lastSyncError ?? 'Sync failed',
        ),
      SyncState.synced => null,
    };

    return icon;
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

/// Animated sync status icon that fades in smoothly.
class _AnimatedSyncIcon extends StatelessWidget {
  const _AnimatedSyncIcon({
    super.key,
    required this.icon,
    required this.color,
    required this.tooltip,
  });

  final IconData icon;
  final Color color;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.5 + (0.5 * value),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Tooltip(
        message: tooltip,
        child: Icon(
          icon,
          size: 18,
          color: color,
        ),
      ),
    );
  }
}
