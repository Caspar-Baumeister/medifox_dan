import 'package:flutter/material.dart';

/// Animated sync button that rotates while syncing.
class AnimatedSyncButton extends StatefulWidget {
  const AnimatedSyncButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  State<AnimatedSyncButton> createState() => _AnimatedSyncButtonState();
}

class _AnimatedSyncButtonState extends State<AnimatedSyncButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    if (widget.isLoading) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AnimatedSyncButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _controller.repeat();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      icon: RotationTransition(
        turns: _controller,
        child: Icon(
          Icons.sync,
          color: widget.isLoading
              ? theme.appBarTheme.foregroundColor?.withValues(alpha: 0.5)
              : null,
        ),
      ),
      tooltip: 'Sync now',
      onPressed: widget.isLoading ? null : widget.onPressed,
    );
  }
}
