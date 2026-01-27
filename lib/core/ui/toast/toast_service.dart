import 'dart:async';

import 'package:flutter/material.dart';

/// Type of toast message.
enum ToastType {
  success,
  error,
  warning,
  info,
}

/// In-app toast service using Overlay.
/// Shows toast messages at the top of the screen without affecting layout.
class ToastService {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  /// Shows a toast message.
  /// Only one toast is visible at a time; new toasts replace old ones.
  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Dismiss any existing toast
    dismiss();

    final overlay = Overlay.of(context);

    _currentEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        type: type,
        onDismiss: dismiss,
      ),
    );

    overlay.insert(_currentEntry!);

    // Auto dismiss after duration
    _dismissTimer = Timer(duration, dismiss);
  }

  /// Dismisses the current toast if any.
  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }

  /// Shows a success toast.
  static void success(BuildContext context, String message) {
    show(context, message, type: ToastType.success);
  }

  /// Shows an error toast.
  static void error(BuildContext context, String message) {
    show(context, message, type: ToastType.error, duration: const Duration(seconds: 4));
  }

  /// Shows a warning toast.
  static void warning(BuildContext context, String message) {
    show(context, message, type: ToastType.warning);
  }

  /// Shows an info toast.
  static void info(BuildContext context, String message) {
    show(context, message, type: ToastType.info);
  }
}

class _ToastWidget extends StatefulWidget {
  const _ToastWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  final String message;
  final ToastType type;
  final VoidCallback onDismiss;

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _backgroundColor {
    return switch (widget.type) {
      ToastType.success => const Color(0xFF43A047),
      ToastType.error => const Color(0xFFE53935),
      ToastType.warning => const Color(0xFFFFA726),
      ToastType.info => const Color(0xFF1976D2),
    };
  }

  IconData get _icon {
    return switch (widget.type) {
      ToastType.success => Icons.check_circle_outline,
      ToastType.error => Icons.error_outline,
      ToastType.warning => Icons.warning_amber_rounded,
      ToastType.info => Icons.info_outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;

    return Positioned(
      bottom: bottomPadding + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: widget.onDismiss,
              onVerticalDragEnd: (details) {
                // Swipe down to dismiss (since toast is at bottom)
                if (details.velocity.pixelsPerSecond.dy > 0) {
                  widget.onDismiss();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      _icon,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.close,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
