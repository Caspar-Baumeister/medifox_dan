import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/theme/theme_mode_controller.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/todo_filter.dart';
import '../../application/todos_controller.dart';
import '../../application/todos_providers.dart';
import '../../application/todos_sync_controller.dart';
import '../../domain/todo.dart';
import '../../sync/todos_sync_engine.dart';
import '../widgets/widgets.dart';

/// The main page displaying the list of todos.
class TodosListPage extends ConsumerWidget {
  const TodosListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosAsync = ref.watch(todosStreamProvider);
    final filter = ref.watch(todoFilterProvider);
    final syncState = ref.watch(todosSyncControllerProvider);
    ref.watch(themeModeProvider);
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
        title: _buildAppBarTitle(theme),
        actions: [
          AnimatedSyncButton(
            isLoading: syncState.isLoading,
            onPressed: () => _performSync(context, ref),
          ),
          ThemeToggleButton(
            isDark: isDark,
            onToggle: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
          _OverflowMenu(
            isEnabled: !syncState.isLoading,
            onImport: () => _performImport(context, ref),
          ),
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
          data: (todos) => _TodosContent(
            key: ValueKey('data_${todos.length}'),
            todos: todos,
            filter: filter,
            onFilterChanged: (f) =>
                ref.read(todoFilterProvider.notifier).state = f,
            onToggle: (id) =>
                ref.read(todosControllerProvider.notifier).toggleCompleted(id),
            onEdit: (todo) => _showEditTodoDialog(context, ref, todo),
            onDelete: (id) =>
                ref.read(todosControllerProvider.notifier).deleteTodo(id),
          ),
        ),
      ),
      floatingActionButton: ExpandingFab(
        onShowDialog: (fabRect) => _showAddTodoDialog(context, ref, fabRect),
      ),
    );
  }

  Widget _buildAppBarTitle(ThemeData theme) {
    return Row(
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
    );
  }

  void _showAddTodoDialog(BuildContext context, WidgetRef ref, Rect fabRect) {
    Navigator.of(context).push(
      ExpandingDialogRoute(
        fabRect: fabRect,
        builder: (context) => AddTodoDialogContent(
          onAdd: (title) {
            ref.read(todosControllerProvider.notifier).addTodo(title);
            Navigator.of(context).pop();
          },
          onCancel: () => Navigator.of(context).pop(),
        ),
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

  Future<void> _performSync(BuildContext context, WidgetRef ref) async {
    try {
      final summary = await ref
          .read(todosSyncControllerProvider.notifier)
          .syncNow();

      if (!context.mounted) return;
      if (summary.aborted) return;

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
      if (summary.aborted) return;

      final message = summary.succeeded > 0
          ? 'Imported ${summary.succeeded} todo${summary.succeeded > 1 ? 's' : ''} from API'
          : 'No new todos to import';

      ToastService.success(context, message);
    } catch (_) {
      // Errors are handled via the listener
    }
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

// =============================================================================
// PRIVATE WIDGETS
// =============================================================================

class _OverflowMenu extends StatelessWidget {
  const _OverflowMenu({required this.isEnabled, required this.onImport});

  final bool isEnabled;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      enabled: isEnabled,
      onSelected: (value) {
        if (value == 'import') onImport();
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
}

class _TodosContent extends StatelessWidget {
  const _TodosContent({
    super.key,
    required this.todos,
    required this.filter,
    required this.onFilterChanged,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Todo> todos;
  final TodoFilter filter;
  final void Function(TodoFilter) onFilterChanged;
  final void Function(String id) onToggle;
  final void Function(Todo todo) onEdit;
  final void Function(String id) onDelete;

  List<Todo> get _filteredTodos {
    return switch (filter) {
      TodoFilter.all => todos,
      TodoFilter.active => todos.where((t) => !t.completed).toList(),
      TodoFilter.completed => todos.where((t) => t.completed).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final filteredTodos = _filteredTodos;
    final activeCount = todos.where((t) => !t.completed).length;
    final completedCount = todos.where((t) => t.completed).length;
    final pendingCount = todos
        .where((t) => t.syncState == SyncState.pending)
        .length;
    final failedCount = todos
        .where((t) => t.syncState == SyncState.failed)
        .length;

    return Column(
      children: [
        _FilterChips(selectedFilter: filter, onFilterChanged: onFilterChanged),
        _StatsBar(
          activeCount: activeCount,
          completedCount: completedCount,
          pendingCount: pendingCount,
          failedCount: failedCount,
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: filteredTodos.isEmpty
                ? _EmptyState(filter: filter)
                : _TodosList(
                    todos: filteredTodos,
                    onToggle: onToggle,
                    onEdit: onEdit,
                    onDelete: onDelete,
                  ),
          ),
        ),
      ],
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final TodoFilter selectedFilter;
  final void Function(TodoFilter) onFilterChanged;

  @override
  Widget build(BuildContext context) {
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
              onSelected: (_) => onFilterChanged(filter),
              selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              checkmarkColor: theme.colorScheme.primary,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatsBar extends StatelessWidget {
  const _StatsBar({
    required this.activeCount,
    required this.completedCount,
    required this.pendingCount,
    required this.failedCount,
  });

  final int activeCount;
  final int completedCount;
  final int pendingCount;
  final int failedCount;

  @override
  Widget build(BuildContext context) {
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
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});

  final TodoFilter filter;

  @override
  Widget build(BuildContext context) {
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
}

class _TodosList extends StatelessWidget {
  const _TodosList({
    required this.todos,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Todo> todos;
  final void Function(String id) onToggle;
  final void Function(Todo todo) onEdit;
  final void Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
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
          onToggle: () => onToggle(todo.id),
          onTap: () => onEdit(todo),
          onDismissed: () => onDelete(todo.id),
        );
      },
    );
  }
}
