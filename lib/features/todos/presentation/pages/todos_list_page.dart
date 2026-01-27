import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Todos'),
        actions: [
          _buildSyncButton(context, ref, syncState),
          _buildOverflowMenu(context, ref, syncState),
        ],
      ),
      body: todosAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                error.toString(),
                style: const TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(todosStreamProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (todos) => _buildLoadedContent(context, ref, todos, filter),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTodoDialog(context, ref),
        tooltip: 'Add Todo',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSyncButton(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<void> syncState,
  ) {
    if (syncState.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.white,
          ),
        ),
      );
    }
    return IconButton(
      icon: const Icon(Icons.sync),
      tooltip: 'Sync now',
      onPressed: () => _performSync(context, ref),
    );
  }

  Widget _buildOverflowMenu(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<void> syncState,
  ) {
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
        const PopupMenuItem(
          value: 'import',
          child: Row(
            children: [
              Icon(Icons.cloud_download, size: 20),
              SizedBox(width: 12),
              Text('Import from API'),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _performSync(BuildContext context, WidgetRef ref) async {
    try {
      final result =
          await ref.read(todosSyncControllerProvider.notifier).syncNow();
      if (!context.mounted) return;
      switch (result) {
        case SyncSuccess(processedCount: final count):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(count > 0
                  ? 'Synced $count item${count > 1 ? 's' : ''}'
                  : 'Already up to date'),
              duration: const Duration(seconds: 2),
              backgroundColor: AppColors.success,
            ),
          );
        case SyncFailure(message: final message):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sync failed: $message'),
              duration: const Duration(seconds: 3),
              backgroundColor: AppColors.error,
            ),
          );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync error: $e'),
          duration: const Duration(seconds: 3),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _performImport(BuildContext context, WidgetRef ref) async {
    try {
      final result =
          await ref.read(todosSyncControllerProvider.notifier).importFromApi();
      if (!context.mounted) return;
      switch (result) {
        case SyncSuccess(processedCount: final count):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(count > 0
                  ? 'Imported $count todo${count > 1 ? 's' : ''} from API'
                  : 'No new todos to import'),
              duration: const Duration(seconds: 2),
              backgroundColor: AppColors.success,
            ),
          );
        case SyncFailure(message: final message):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Import failed: $message'),
              duration: const Duration(seconds: 3),
              backgroundColor: AppColors.error,
            ),
          );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import error: $e'),
          duration: const Duration(seconds: 3),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildLoadedContent(
    BuildContext context,
    WidgetRef ref,
    List<Todo> todos,
    TodoFilter filter,
  ) {
    final filteredTodos = _filterTodos(todos, filter);
    final activeCount = todos.where((t) => !t.completed).length;
    final completedCount = todos.where((t) => t.completed).length;
    final pendingCount = todos.where((t) => t.syncState == SyncState.pending).length;
    return Column(
      children: [
        _buildFilterChips(ref, filter),
        _buildStatsBar(activeCount, completedCount, pendingCount),
        Expanded(
          child: filteredTodos.isEmpty
              ? _buildEmptyState(filter)
              : _buildTodosList(ref, filteredTodos),
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

  Widget _buildFilterChips(WidgetRef ref, TodoFilter selectedFilter) {
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
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primary,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsBar(int activeCount, int completedCount, int pendingCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$activeCount remaining',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          if (pendingCount > 0)
            Row(
              children: [
                const Icon(
                  Icons.schedule,
                  size: 14,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '$pendingCount pending',
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          Text(
            '$completedCount completed',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(TodoFilter filter) {
    final message = switch (filter) {
      TodoFilter.all => 'No todos yet.\nTap + to add one!',
      TodoFilter.active => 'No active todos.\nGreat job!',
      TodoFilter.completed => 'No completed todos yet.',
    };
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            filter == TodoFilter.active
                ? Icons.check_circle_outline
                : Icons.inbox_outlined,
            size: 64,
            color: AppColors.divider,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodosList(WidgetRef ref, List<Todo> todos) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: todos.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final todo = todos[index];
        return TodoListItem(
          todo: todo,
          onToggle: () =>
              ref.read(todosControllerProvider.notifier).toggleCompleted(todo.id),
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
          decoration: const InputDecoration(
            hintText: 'What needs to be done?',
            border: OutlineInputBorder(),
          ),
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
}
