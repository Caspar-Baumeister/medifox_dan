import '../../../core/errors/app_error.dart';

/// Summary of a sync operation.
class SyncSummary {
  const SyncSummary({
    required this.processed,
    required this.succeeded,
    required this.failed,
    required this.aborted,
    this.abortReason,
  });

  /// Number of operations processed.
  final int processed;

  /// Number of operations that succeeded.
  final int succeeded;

  /// Number of operations that failed.
  final int failed;

  /// Whether the sync was aborted early (e.g., offline).
  final bool aborted;

  /// Reason for abort, if aborted.
  final AppError? abortReason;

  /// Whether all processed operations succeeded.
  bool get isFullySuccessful => !aborted && failed == 0;

  /// Whether any operations were processed.
  bool get hasProcessedAny => processed > 0;

  @override
  String toString() =>
      'SyncSummary(processed: $processed, succeeded: $succeeded, failed: $failed, aborted: $aborted)';
}
