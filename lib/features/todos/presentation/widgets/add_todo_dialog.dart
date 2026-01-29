import 'package:flutter/material.dart';

/// The content of the Add Todo dialog.
/// Displays a text field for entering a new todo title with submit/cancel actions.
class AddTodoDialogContent extends StatefulWidget {
  const AddTodoDialogContent({
    super.key,
    required this.onAdd,
    required this.onCancel,
  });

  /// Callback when a todo is added with the given title.
  final void Function(String title) onAdd;

  /// Callback when the dialog is cancelled.
  final VoidCallback onCancel;

  @override
  State<AddTodoDialogContent> createState() => _AddTodoDialogContentState();
}

class _AddTodoDialogContentState extends State<AddTodoDialogContent> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus after animation completes
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _textController.text.trim();
    if (title.isNotEmpty) {
      widget.onAdd(title);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Add Todo', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            focusNode: _focusNode,
            decoration: const InputDecoration(
              hintText: 'What needs to be done?',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onCancel,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _submit, child: const Text('Add')),
            ],
          ),
        ],
      ),
    );
  }
}
