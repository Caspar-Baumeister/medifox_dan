import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../domain/sync_summary.dart';
import '../sync/todos_sync_engine.dart';
import 'todos_providers.dart';

/// Controller for managing sync operations.
/// Exposes methods to trigger sync and import, and tracks state.
class TodosSyncController extends AsyncNotifier<SyncSummary?> {
  @override
  FutureOr<SyncSummary?> build() {
    // Initial state: no sync has been performed yet
    return null;
  }

  TodosSyncEngine get _syncEngine => ref.read(todosSyncEngineProvider);

  /// Triggers a sync operation to push local changes to the server.
  /// Sets loading state during sync, then refreshes the todos list.
  ///
  /// Returns the [SyncSummary] result.
  /// On error, sets the state to [AsyncError] with an [AppError].
  Future<SyncSummary> syncNow() async {
    state = const AsyncLoading();
    try {
      final summary = await _syncEngine.syncNow();

      // If aborted due to offline/error, expose the error
      if (summary.aborted && summary.abortReason != null) {
        state = AsyncError(summary.abortReason!, StackTrace.current);
        return summary;
      }

      // Invalidate todos stream to trigger refresh
      ref.invalidate(todosStreamProvider);
      state = AsyncData(summary);
      return summary;
    } on AppError catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    } catch (e, st) {
      final appError = AppException(message: e.toString(), cause: e);
      state = AsyncError(appError, st);
      throw appError;
    }
  }

  /// Imports todos from the API into the local database.
  ///
  /// Fetches todos from JSONPlaceholder (filtered by userId=1) and
  /// upserts them into the local database with synced state.
  ///
  /// Returns the [SyncSummary] result.
  /// On error, sets the state to [AsyncError] with an [AppError].
  Future<SyncSummary> importFromApi() async {
    state = const AsyncLoading();
    try {
      final summary = await _syncEngine.importFromApi(userId: 1);

      // If aborted due to offline/error, expose the error
      if (summary.aborted && summary.abortReason != null) {
        state = AsyncError(summary.abortReason!, StackTrace.current);
        return summary;
      }

      // Invalidate todos stream to trigger refresh
      ref.invalidate(todosStreamProvider);
      state = AsyncData(summary);
      return summary;
    } on AppError catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    } catch (e, st) {
      final appError = AppException(message: e.toString(), cause: e);
      state = AsyncError(appError, st);
      throw appError;
    }
  }

  /// Returns whether a sync/import is currently in progress.
  bool get isSyncing => state.isLoading;

  /// Returns the last sync summary, if available.
  SyncSummary? get lastSummary => state.valueOrNull;

  /// Clears any error state and resets to the last successful summary.
  void clearError() {
    if (state.hasError) {
      state = AsyncData(state.valueOrNull);
    }
  }
}

/// Provider for the sync controller.
final todosSyncControllerProvider =
    AsyncNotifierProvider<TodosSyncController, SyncSummary?>(
      TodosSyncController.new,
    );
