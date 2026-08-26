import 'package:core_data/core_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps a versioned ERP outbox event', () {
    final event = ErpOutboxEvent.fromJson({
      'id': 'event-1',
      'tenant_id': 'tenant-1',
      'event_name': 'invoice.created',
      'aggregate_type': 'invoice',
      'aggregate_id': 'invoice-1',
      'event_version': 2,
      'idempotency_key': 'invoice-1-created-v2',
      'payload': {'total_minor': 1200},
      'attempt_count': 1,
    });

    expect(event.eventName, 'invoice.created');
    expect(event.eventVersion, 2);
    expect(event.payload['total_minor'], 1200);
    expect(event.attemptCount, 1);
  });

  test('maps conflict fields and defaults malformed payloads safely', () {
    final conflict = SyncConflict.fromJson({
      'id': 'conflict-1',
      'client_mutation_id': 'mutation-123456',
      'entity_type': 'customer',
      'entity_id': 'customer-1',
      'local_payload': {'name': 'Local'},
      'server_payload': {'name': 'Server'},
      'conflict_fields': ['name'],
      'status': 'open',
    });
    final empty = SyncConflict.fromJson({});

    expect(conflict.conflictFields, ['name']);
    expect(conflict.localPayload['name'], 'Local');
    expect(conflict.status, 'open');
    expect(empty.conflictFields, isEmpty);
  });
}
