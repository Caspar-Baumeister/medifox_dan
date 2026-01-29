import 'package:flutter/material.dart';

/// A FloatingActionButton that tracks its position for expand animations.
/// Used to create hero-like transitions from FAB to dialog.
class ExpandingFab extends StatefulWidget {
  const ExpandingFab({super.key, required this.onShowDialog});

  /// Callback when the FAB is pressed, providing the FAB's screen rect.
  final void Function(Rect fabRect) onShowDialog;

  @override
  State<ExpandingFab> createState() => _ExpandingFabState();
}

class _ExpandingFabState extends State<ExpandingFab> {
  final GlobalKey _fabKey = GlobalKey();

  Rect _getFabRect() {
    final renderBox = _fabKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return Rect.zero;
    final position = renderBox.localToGlobal(Offset.zero);
    return Rect.fromLTWH(
      position.dx,
      position.dy,
      renderBox.size.width,
      renderBox.size.height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      key: _fabKey,
      onPressed: () => widget.onShowDialog(_getFabRect()),
      tooltip: 'Add Todo',
      child: const Icon(Icons.add),
    );
  }
}
