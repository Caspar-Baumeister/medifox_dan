import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/todo.dart';

/// A widget that displays a single todo item in the list.
/// Includes animations for completed state and sync status changes.
/// Shows a success animation when todo transitions from incomplete to completed.
class TodoListItem extends StatefulWidget {
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
  State<TodoListItem> createState() => _TodoListItemState();
}

class _TodoListItemState extends State<TodoListItem>
    with TickerProviderStateMixin {
  late AnimationController _successController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _ringAnimation;

  bool _showSuccessAnimation = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _successController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.3,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.3,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
    ]).animate(_successController);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_successController);

    _ringAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.easeOut),
    );

    _successController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _showSuccessAnimation = false);
      }
    });
  }

  @override
  void didUpdateWidget(TodoListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Detect completion transition: false -> true
    if (!oldWidget.todo.completed && widget.todo.completed) {
      _triggerSuccessAnimation();
    }
  }

  void _triggerSuccessAnimation() {
    setState(() => _showSuccessAnimation = true);
    _successController.forward(from: 0);
  }

  @override
  void dispose() {
    _successController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TweenAnimationBuilder<double>(
      key: ValueKey('appear_${widget.todo.id}'),
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
        key: Key(widget.todo.id),
        direction: DismissDirection.endToStart,
        onDismissed: widget.onDismissed != null
            ? (_) => widget.onDismissed!()
            : null,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: theme.colorScheme.error,
          child: Icon(Icons.delete_outline, color: theme.colorScheme.onError),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: ListTile(
            onTap: widget.onTap,
            leading: _buildLeading(theme),
            title: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 16,
                decoration: widget.todo.completed
                    ? TextDecoration.lineThrough
                    : null,
                color: widget.todo.completed
                    ? theme.textTheme.bodySmall?.color
                    : theme.textTheme.bodyLarge?.color,
              ),
              child: Text(widget.todo.title),
            ),
            subtitle: _buildSubtitle(theme),
            trailing: _buildSyncStatusIndicator(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildLeading(ThemeData theme) {
    const successColor = Color(0xFF43A047);

    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Success animation layers (behind checkbox)
          if (_showSuccessAnimation) ...[
            // Expanding ring
            AnimatedBuilder(
              animation: _ringAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1 + (_ringAnimation.value * 0.8),
                  child: Opacity(
                    opacity: (1 - _ringAnimation.value).clamp(0.0, 1.0),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: successColor, width: 2),
                      ),
                    ),
                  ),
                );
              },
            ),
            // Sparkle particles
            ..._buildSparkles(theme),
          ],
          // Checkbox with scale animation
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _showSuccessAnimation ? _scaleAnimation.value : 1.0,
                child: child,
              );
            },
            child: Checkbox(
              value: widget.todo.completed,
              onChanged: (_) => widget.onToggle(),
            ),
          ),
          // Success checkmark overlay
          if (_showSuccessAnimation)
            AnimatedBuilder(
              animation: _opacityAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: const Icon(
                      Icons.check_circle,
                      color: successColor,
                      size: 32,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  List<Widget> _buildSparkles(ThemeData theme) {
    final random = Random(widget.todo.id.hashCode);
    return List.generate(6, (index) {
      final angle = (index * 60.0) + random.nextDouble() * 30;
      final distance = 16.0 + random.nextDouble() * 8;

      return AnimatedBuilder(
        animation: _ringAnimation,
        builder: (context, child) {
          final progress = _ringAnimation.value;
          final radians = angle * (pi / 180);
          final currentDistance = distance * progress;

          return Transform.translate(
            offset: Offset(
              cos(radians) * currentDistance,
              sin(radians) * currentDistance,
            ),
            child: Opacity(
              opacity: (1 - progress).clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 1 - (progress * 0.5),
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _getSparkleColor(index, theme),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Color _getSparkleColor(int index, ThemeData theme) {
    final colors = [
      const Color(0xFF43A047), // Success green
      theme.colorScheme.secondary,
      theme.colorScheme.primary,
      const Color(0xFFFFD700), // Gold
      const Color(0xFF43A047), // Success green
      const Color(0xFF9C27B0), // Purple
    ];
    return colors[index % colors.length];
  }

  Widget? _buildSubtitle(ThemeData theme) {
    final formattedDate = _formatRelativeDate(widget.todo.updatedAt);
    return Text(formattedDate, style: theme.textTheme.bodySmall);
  }

  Widget? _buildSyncStatusIndicator(ThemeData theme) {
    // Reserve fixed space for the indicator to prevent layout shifts
    return SizedBox(
      width: 24,
      height: 24,
      child: Center(
        child: switch (widget.todo.syncState) {
          SyncState.pending => _AnimatedSyncIcon(
            key: ValueKey('pending_${widget.todo.id}'),
            icon: Icons.schedule,
            color: theme.colorScheme.secondary.withValues(alpha: 0.7),
            tooltip: 'Pending sync',
          ),
          SyncState.failed => _AnimatedSyncIcon(
            key: ValueKey('failed_${widget.todo.id}'),
            icon: Icons.warning_amber_rounded,
            color: theme.colorScheme.error,
            tooltip: widget.todo.lastSyncError ?? 'Sync failed',
          ),
          SyncState.synced => null,
        },
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
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Tooltip(
        message: tooltip,
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
