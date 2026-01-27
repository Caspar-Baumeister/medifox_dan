import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../application/todos_controller.dart';
import '../../application/todos_state.dart';
import '../widgets/todo_list_item.dart';

/// The main page displaying the list of todos.
class TodosListPage extends ConsumerStatefulWidget {
  const TodosListPage({super.key});

  @override
  ConsumerState<TodosListPage> createState() => _TodosListPageState();
}

class _TodosListPageState extends ConsumerState<TodosListPage> {
  @override
  void initState() {
    super.initState();
    // Load todos when the page is first displayed
    Future.microtask(
      () => ref.read(todosControllerProvider.notifier).loadTodos(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(todosControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Todos'),
      ),
      body: _buildBody(state),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddTodoPressed,
        tooltip: 'Add Todo',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(TodosState state) {
    return switch (state) {
      TodosInitial() => const Center(
          child: Text('Welcome! Loading your todos...'),
        ),
      TodosLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
      TodosError(message: final message) => Center(
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
                message,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(todosControllerProvider.notifier).loadTodos(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      TodosLoaded() => _buildLoadedContent(state),
    };
  }

  Widget _buildLoadedContent(TodosLoaded state) {
    return Column(
      children: [
        _buildFilterChips(state),
        _buildStatsBar(state),
        Expanded(
          child: state.filteredTodos.isEmpty
              ? _buildEmptyState(state.selectedFilter)
              : _buildTodosList(state.filteredTodos),
        ),
      ],
    );
  }

  Widget _buildFilterChips(TodosLoaded state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: TodoFilter.values.map((filter) {
          final isSelected = state.selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter.label),
              selected: isSelected,
              onSelected: (_) =>
                  ref.read(todosControllerProvider.notifier).setFilter(filter),
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primary,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsBar(TodosLoaded state) {
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
            '${state.activeCount} remaining',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            '${state.completedCount} completed',
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

  Widget _buildTodosList(List todos) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: todos.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final todo = todos[index];
        return TodoListItem(
          todo: todo,
          onToggle: () => ref
              .read(todosControllerProvider.notifier)
              .toggleTodoCompletion(todo.id),
          onDismissed: () =>
              ref.read(todosControllerProvider.notifier).removeTodo(todo.id),
        );
      },
    );
  }

  void _onAddTodoPressed() {
    // TODO: Implement add todo dialog/page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add todo feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
