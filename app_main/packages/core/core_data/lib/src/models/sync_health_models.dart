enum SyncMutationState {
  localDraft,
  queued,
  processing,
  serverConfirmed,
  rejected,
  conflict,
  failed,
}

extension SyncMutationStateCodec on SyncMutationState {
  String get wireValue => switch (this) {
    SyncMutationState.localDraft => 'local_draft',
    SyncMutationState.queued => 'queued',
    SyncMutationState.processing => 'processing',
    SyncMutationState.serverConfirmed => 'server_confirmed',
    SyncMutationState.rejected => 'rejected',
    SyncMutationState.conflict => 'conflict',
    SyncMutationState.failed => 'failed',
  };

  static SyncMutationState parse(String? value) => switch (value) {
    'local_draft' => SyncMutationState.localDraft,
    'processing' => SyncMutationState.processing,
    'server_confirmed' => SyncMutationState.serverConfirmed,
    'rejected' => SyncMutationState.rejected,
    'conflict' => SyncMutationState.conflict,
    'failed' => SyncMutationState.failed,
    _ => SyncMutationState.queued,
  };
}

class SyncHealthSnapshot {
  const SyncHealthSnapshot({
    required this.serverPendingCount,
    required this.serverProcessingCount,
    required this.serverFailedCount,
    required this.openConflictCount,
    required this.serverSucceededCount,
    required this.observedAt,
  });

  final int serverPendingCount;
  final int serverProcessingCount;
  final int serverFailedCount;
  final int openConflictCount;
  final int serverSucceededCount;
  final DateTime observedAt;

  bool get needsAttention => serverFailedCount > 0 || openConflictCount > 0;

  int get activeCount => serverPendingCount + serverProcessingCount;

  factory SyncHealthSnapshot.fromServerRows({
    required List<Map<String, dynamic>> eventRows,
    required List<Map<String, dynamic>> conflictRows,
    DateTime? observedAt,
  }) {
    var pending = 0;
    var processing = 0;
    var failed = 0;
    var succeeded = 0;
    for (final row in eventRows) {
      switch (row['status']?.toString()) {
        case 'pending':
          pending++;
        case 'processing':
          processing++;
        case 'failed':
          failed++;
        case 'succeeded':
          succeeded++;
      }
    }
    final conflicts = conflictRows
        .where((row) => row['status']?.toString() == 'open')
        .length;
    return SyncHealthSnapshot(
      serverPendingCount: pending,
      serverProcessingCount: processing,
      serverFailedCount: failed,
      openConflictCount: conflicts,
      serverSucceededCount: succeeded,
      observedAt: (observedAt ?? DateTime.now()).toUtc(),
    );
  }
}
