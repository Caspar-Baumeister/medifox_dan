import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/providers.dart';
import '../sync/todos_sync_engine.dart';
import 'todos_providers.dart';

/// Controller for managing sync operations.
/// Exposes methods to trigger sync and import, and tracks state.
class TodosSyncController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Initial state: not syncing
  }

  TodosSyncEngine get _syncEngine => ref.read(todosSyncEngineProvider);

  /// Triggers a sync operation to push local changes to the server.
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

  /// Imports todos from the API into the local database.
  /// 
  /// Fetches todos from JSONPlaceholder (filtered by userId=1) and
  /// upserts them into the local database with synced state.
  Future<SyncResult> importFromApi() async {
    state = const AsyncLoading();
    try {
      final result = await _syncEngine.importFromApi(userId: 1);
      // Invalidate todos stream to trigger refresh
      ref.invalidate(todosStreamProvider);
      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Returns whether a sync/import is currently in progress.
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
