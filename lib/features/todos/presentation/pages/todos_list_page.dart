import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../app/theme/theme_mode_controller.dart';
import '../../../../core/errors/app_error.dart';
import '../../../../core/ui/toast/toast_service.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../application/todo_filter.dart';
import '../../application/todos_controller.dart';
import '../../application/todos_providers.dart';
import '../../application/todos_sync_controller.dart';
import '../../domain/todo.dart';
import '../../sync/todos_sync_engine.dart';
import '../widgets/todo_list_item.dart';

/// The main page displaying the list of todos.
class TodosListPage extends ConsumerWidget {
  const TodosListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosAsync = ref.watch(todosStreamProvider);
    final filter = ref.watch(todoFilterProvider);
    final syncState = ref.watch(todosSyncControllerProvider);
    ref.watch(themeModeProvider); // Watch to trigger rebuilds
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Listen for sync errors and show toast
    ref.listen<AsyncValue<SyncSummary?>>(todosSyncControllerProvider, (
      previous,
      next,
    ) {
      if (next.hasError && !next.isLoading) {
        final error = next.error;
        final message = error is AppError
            ? error.userMessage
            : 'An unexpected error occurred';
        ToastService.error(context, message);
      }
    });

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        centerTitle: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/white_transparent_logo.svg',
              height: 24,
              colorFilter: ColorFilter.mode(
                theme.appBarTheme.foregroundColor ?? Colors.white,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 10),
            const Text('DOFOX'),
          ],
        ),
        actions: [
          _AnimatedSyncButton(
            isLoading: syncState.isLoading,
            onPressed: () => _performSync(context, ref),
          ),
          _ThemeToggleButton(
            isDark: isDark,
            onToggle: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
          _buildOverflowMenu(context, ref, syncState),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: todosAsync.when(
          loading: () => const LoadingIndicator(key: ValueKey('loading')),
          error: (error, stack) => ErrorView(
            key: const ValueKey('error'),
            message: error is AppError
                ? error.userMessage
                : 'Failed to load todos',
            onRetry: () => ref.invalidate(todosStreamProvider),
          ),
          data: (todos) => _buildLoadedContent(
            key: ValueKey('data_${todos.length}'),
            context: context,
            ref: ref,
            todos: todos,
            filter: filter,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTodoDialog(context, ref),
        tooltip: 'Add Todo',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildOverflowMenu(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<SyncSummary?> syncState,
  ) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      enabled: !syncState.isLoading,
      onSelected: (value) {
        switch (value) {
          case 'import':
            _performImport(context, ref);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'import',
          child: Row(
            children: [
              Icon(
                Icons.cloud_download,
                size: 20,
                color: theme.colorScheme.onSurface,
              ),
              const SizedBox(width: 12),
              const Text('Import from API'),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _performSync(BuildContext context, WidgetRef ref) async {
    try {
      final summary = await ref
          .read(todosSyncControllerProvider.notifier)
          .syncNow();

      if (!context.mounted) return;

      // Handle aborted sync (offline, etc.)
      if (summary.aborted) {
        // Error is handled via the listener
        return;
      }

      // Show success toast
      final message = summary.succeeded > 0
          ? 'Synced ${summary.succeeded} item${summary.succeeded > 1 ? 's' : ''}'
          : 'Already up to date';

      if (summary.failed > 0) {
        ToastService.warning(context, '$message (${summary.failed} failed)');
      } else {
        ToastService.success(context, message);
      }
    } catch (_) {
      // Errors are handled via the listener
    }
  }

  Future<void> _performImport(BuildContext context, WidgetRef ref) async {
    try {
      final summary = await ref
          .read(todosSyncControllerProvider.notifier)
          .importFromApi();

      if (!context.mounted) return;

      // Handle aborted import (offline, etc.)
      if (summary.aborted) {
        // Error is handled via the listener
        return;
      }

      // Show success toast
      final message = summary.succeeded > 0
          ? 'Imported ${summary.succeeded} todo${summary.succeeded > 1 ? 's' : ''} from API'
          : 'No new todos to import';

      ToastService.success(context, message);
    } catch (_) {
      // Errors are handled via the listener
    }
  }

  Widget _buildLoadedContent({
    Key? key,
    required BuildContext context,
    required WidgetRef ref,
    required List<Todo> todos,
    required TodoFilter filter,
  }) {
    final filteredTodos = _filterTodos(todos, filter);
    final activeCount = todos.where((t) => !t.completed).length;
    final completedCount = todos.where((t) => t.completed).length;
    final pendingCount = todos
        .where((t) => t.syncState == SyncState.pending)
        .length;
    final failedCount = todos
        .where((t) => t.syncState == SyncState.failed)
        .length;

    return Column(
      key: key,
      children: [
        _buildFilterChips(context, ref, filter),
        _buildStatsBar(
          context,
          activeCount,
          completedCount,
          pendingCount,
          failedCount,
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: filteredTodos.isEmpty
                ? _buildEmptyState(context, filter)
                : _buildTodosList(context, ref, filteredTodos),
          ),
        ),
      ],
    );
  }

  List<Todo> _filterTodos(List<Todo> todos, TodoFilter filter) {
    return switch (filter) {
      TodoFilter.all => todos,
      TodoFilter.active => todos.where((t) => !t.completed).toList(),
      TodoFilter.completed => todos.where((t) => t.completed).toList(),
    };
  }

  Widget _buildFilterChips(
    BuildContext context,
    WidgetRef ref,
    TodoFilter selectedFilter,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: TodoFilter.values.map((filter) {
          final isSelected = selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter.label),
              selected: isSelected,
              onSelected: (_) =>
                  ref.read(todoFilterProvider.notifier).state = filter,
              selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              checkmarkColor: theme.colorScheme.primary,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsBar(
    BuildContext context,
    int activeCount,
    int completedCount,
    int pendingCount,
    int failedCount,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.colorScheme.outline)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$activeCount remaining', style: theme.textTheme.bodySmall),
          Row(
            children: [
              if (failedCount > 0) ...[
                Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 4),
                Text(
                  '$failedCount failed',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (pendingCount > 0) ...[
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '$pendingCount pending',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ],
          ),
          Text('$completedCount completed', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, TodoFilter filter) {
    final (message, icon) = switch (filter) {
      TodoFilter.all => (
        'No todos yet.\nTap + to add one!',
        Icons.inbox_outlined,
      ),
      TodoFilter.active => (
        'No active todos.\nGreat job!',
        Icons.check_circle_outline,
      ),
      TodoFilter.completed => ('No completed todos yet.', Icons.inbox_outlined),
    };
    return EmptyState(
      key: ValueKey('empty_$filter'),
      message: message,
      icon: icon,
    );
  }

  Widget _buildTodosList(
    BuildContext context,
    WidgetRef ref,
    List<Todo> todos,
  ) {
    return ListView.separated(
      key: const ValueKey('todos_list'),
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: todos.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final todo = todos[index];
        return TodoListItem(
          key: ValueKey(todo.id),
          todo: todo,
          onToggle: () => ref
              .read(todosControllerProvider.notifier)
              .toggleCompleted(todo.id),
          onTap: () => _showEditTodoDialog(context, ref, todo),
          onDismissed: () =>
              ref.read(todosControllerProvider.notifier).deleteTodo(todo.id),
        );
      },
    );
  }

  void _showAddTodoDialog(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Todo'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'What needs to be done?'),
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              ref.read(todosControllerProvider.notifier).addTodo(value.trim());
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final title = textController.text.trim();
              if (title.isNotEmpty) {
                ref.read(todosControllerProvider.notifier).addTodo(title);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditTodoDialog(BuildContext context, WidgetRef ref, Todo todo) {
    final textController = TextEditingController(text: todo.title);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Todo'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter new title'),
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (value) async {
            if (value.trim().isNotEmpty) {
              Navigator.of(dialogContext).pop();
              await _performRename(context, ref, todo, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final newTitle = textController.text.trim();
              if (newTitle.isNotEmpty) {
                Navigator.of(dialogContext).pop();
                await _performRename(context, ref, todo, newTitle);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _performRename(
    BuildContext context,
    WidgetRef ref,
    Todo todo,
    String newTitle,
  ) async {
    try {
      await ref
          .read(todosControllerProvider.notifier)
          .renameTodo(todo: todo, newTitle: newTitle);
    } catch (e) {
      if (!context.mounted) return;
      final message = e is AppError ? e.userMessage : 'Failed to rename';
      ToastService.error(context, message);
    }
  }
}

/// Animated sync button that rotates while syncing.
class _AnimatedSyncButton extends StatefulWidget {
  const _AnimatedSyncButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  State<_AnimatedSyncButton> createState() => _AnimatedSyncButtonState();
}

class _AnimatedSyncButtonState extends State<_AnimatedSyncButton>
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
  void didUpdateWidget(_AnimatedSyncButton oldWidget) {
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

/// Theme toggle button with animated icon transition.
class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton({required this.isDark, required this.onToggle});

  final bool isDark;
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
