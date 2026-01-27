import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/providers.dart';
import '../sync/todos_sync_engine.dart';
import 'todos_providers.dart';

/// Controller for managing sync operations.
/// Exposes methods to trigger sync and tracks sync state.
class TodosSyncController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Initial state: not syncing
  }

  TodosSyncEngine get _syncEngine => ref.read(todosSyncEngineProvider);

  /// Triggers a sync operation.
  /// Sets loading state during sync, then refreshes the todos list.
  Future<SyncResult> syncNow() async {
    state = const AsyncLoading();
    try {
      final result = await _syncEngine.syncNow();
      // Invalidate todos stream to trigger refresh
      ref.invalidate(todosStreamProvider);
      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Returns whether a sync is currently in progress.
  bool get isSyncing => state.isLoading;
}

/// Provider for the sync controller.
final todosSyncControllerProvider =
    AsyncNotifierProvider<TodosSyncController, void>(
  TodosSyncController.new,
);

/// Provider for the count of pending sync operations.
final pendingSyncCountProvider = FutureProvider<int>((ref) async {
  final syncEngine = ref.watch(todosSyncEngineProvider);
  return syncEngine.pendingOperationsCount();
});
