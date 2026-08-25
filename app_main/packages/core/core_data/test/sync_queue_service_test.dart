import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core_data/core_data.dart';

void main() {
  test('outbox persists tenant-scoped mutation and retry metadata', () async {
    final db = AppDatabase.connect(NativeDatabase.memory());
    addTearDown(db.close);
    final queue = SyncQueueService(db);

    await queue.enqueue(
      tenantId: 'tenant-1',
      tableName: 'customers',
      recordId: 'customer-1',
      operation: 'insert',
      payload: {
        'id': 'customer-1',
        'tenant_id': 'tenant-1',
        'name': 'Example Customer',
      },
    );

    final pending = await queue.pending('tenant-1');
    expect(pending, hasLength(1));
    expect(pending.single.entityTable, 'customers');
    expect(queue.decodePayload(pending.single)['tenant_id'], 'tenant-1');

    await queue.markFailed(
      pending.single.id,
      Exception('temporary network failure'),
    );
    final retry = await queue.pending('tenant-1');
    expect(retry.single.attemptCount, 1);
    expect(retry.single.status, 'retry');
  });
}
