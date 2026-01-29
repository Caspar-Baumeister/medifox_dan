import 'package:flutter/material.dart';

/// Theme toggle button with animated icon transition.
/// Switches between light and dark mode icons with a rotation effect.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({
    super.key,
    required this.isDark,
    required this.onToggle,
  });

  /// Whether the current theme is dark mode.
  final bool isDark;

  /// Callback when the button is pressed.
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return RotationTransition(
            turns: Tween(begin: 0.5, end: 1.0).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: Icon(
          isDark ? Icons.light_mode : Icons.dark_mode,
          key: ValueKey(isDark),
        ),
      ),
      tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
      onPressed: onToggle,
    );
  }
}
