import 'package:core_data/core_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses mutation states safely', () {
    expect(
      SyncMutationStateCodec.parse('processing'),
      SyncMutationState.processing,
    );
    expect(SyncMutationStateCodec.parse('unknown'), SyncMutationState.queued);
    expect(SyncMutationState.failed.wireValue, 'failed');
  });

  test('aggregates server event and conflict states', () {
    final snapshot = SyncHealthSnapshot.fromServerRows(
      eventRows: const [
        {'status': 'pending'},
        {'status': 'processing'},
        {'status': 'failed'},
        {'status': 'succeeded'},
        {'status': 'succeeded'},
      ],
      conflictRows: const [
        {'status': 'open'},
        {'status': 'resolved'},
      ],
      observedAt: DateTime.utc(2026, 8, 27),
    );

    expect(snapshot.activeCount, 2);
    expect(snapshot.serverFailedCount, 1);
    expect(snapshot.serverSucceededCount, 2);
    expect(snapshot.openConflictCount, 1);
    expect(snapshot.needsAttention, isTrue);
    expect(snapshot.observedAt, DateTime.utc(2026, 8, 27));
  });
}
