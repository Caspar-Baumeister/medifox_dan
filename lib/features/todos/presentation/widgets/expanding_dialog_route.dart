import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Custom page route that expands from the FAB position to show a dialog.
/// Creates a smooth morphing animation from FAB to centered dialog.
class ExpandingDialogRoute extends PageRoute<void> {
  ExpandingDialogRoute({required this.fabRect, required this.builder});

  /// The initial rect of the FAB to expand from.
  final Rect fabRect;

  /// Builder for the dialog content.
  final WidgetBuilder builder;

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  Color get barrierColor => Colors.black54;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 350);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 280);

  @override
  bool get maintainState => true;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;

    // Calculate the dialog's final position (centered)
    const dialogWidth = 320.0;
    const dialogHeight = 220.0;
    final dialogRect = Rect.fromCenter(
      center: Offset(screenSize.width / 2, screenSize.height / 2),
      width: dialogWidth,
      height: dialogHeight,
    );

    // Animation curves
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    // Interpolate between FAB rect and dialog rect
    final rectTween = RectTween(begin: fabRect, end: dialogRect);
    final currentRect = rectTween.evaluate(curvedAnimation) ?? dialogRect;

    // Interpolate border radius (FAB is circular, dialog has rounded corners)
    final borderRadius = BorderRadius.circular(
      lerpDouble(fabRect.width / 2, 16, curvedAnimation.value)!,
    );

    // Fade animation for content
    final fadeAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );

    // Scale for the icon (shrinks as dialog expands)
    final iconScale = 1.0 - curvedAnimation.value;

    // Rotation for the + icon
    final iconRotation = curvedAnimation.value * 0.125; // 45 degrees

    return Stack(
      children: [
        // Animated container that morphs from FAB to dialog
        Positioned(
          left: currentRect.left,
          top: currentRect.top,
          width: currentRect.width,
          height: currentRect.height,
          child: Material(
            color: theme.colorScheme.primary,
            borderRadius: borderRadius,
            elevation: 8 + (16 * curvedAnimation.value),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // The + icon that fades and rotates out
                if (iconScale > 0.01)
                  Positioned.fill(
                    child: Center(
                      child: Transform.rotate(
                        angle: iconRotation * 3.14159,
                        child: Opacity(
                          opacity: iconScale,
                          child: Transform.scale(
                            scale: iconScale,
                            child: Icon(
                              Icons.add,
                              color: theme.colorScheme.onPrimary,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Dialog content that fades in
                Positioned.fill(
                  child: FadeTransition(
                    opacity: fadeAnimation,
                    child: Container(
                      color: theme.dialogTheme.backgroundColor ??
                          theme.colorScheme.surface,
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
