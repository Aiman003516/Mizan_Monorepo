import 'dart:convert';

import 'package:core_data/core_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes and validates supported accounting dimensions', () {
    final dimensions = DimensionSet.fromMap({
      ' Branch_Id ': 'branch-1',
      'cost_center_id': 'cost-1',
    });

    expect(dimensions['branch_id'], 'branch-1');
    expect(dimensions['cost_center_id'], 'cost-1');
    expect(dimensions.toJson(), {
      'branch_id': 'branch-1',
      'cost_center_id': 'cost-1',
    });
  });

  test('rejects unknown and empty accounting dimensions', () {
    expect(
      () => DimensionSet.fromMap({'department_id': 'dept-1'}),
      throwsFormatException,
    );
    expect(
      () => DimensionSet.fromMap({'project_id': ' '}),
      throwsFormatException,
    );
  });

  test('round-trips a tenant-scoped event envelope', () {
    final event = FinancialEventEnvelope(
      eventId: 'event-1',
      schemaVersion: 2,
      tenantId: 'tenant-1',
      aggregateType: 'journal_entry',
      aggregateId: 'entry-1',
      eventType: 'journal_entry.posted',
      occurredAt: DateTime.utc(2026, 8, 27, 12),
      payload: {'status': 'posted'},
    );

    final decoded = FinancialEventEnvelope.fromJson(
      Map<String, dynamic>.from(jsonDecode(event.encode()) as Map),
    );
    expect(decoded.schemaVersion, 2);
    expect(decoded.tenantId, 'tenant-1');
    expect(decoded.payload['status'], 'posted');
  });

  test('decodes integration jobs and reviewed extension descriptors', () {
    final job = IntegrationJob.fromJson({
      'id': 'job-1',
      'kind': 'export',
      'status': 'succeeded',
      'idempotency_key': 'idem-1',
      'created_at': '2026-08-27T12:00:00Z',
      'completed_at': '2026-08-27T12:01:00Z',
    });
    final extension = ExtensionDescriptor.fromJson({
      'id': 'extension-1',
      'name': 'Reviewed tax rule',
      'version': '1.0.0',
      'hook': 'pre_validate',
      'capabilities': ['tax.read'],
      'enabled': true,
    });

    expect(job.status, IntegrationJobStatus.succeeded);
    expect(job.completedAt == null, isFalse);
    expect(extension.hook, ExtensionHook.preValidate);
    expect(extension.capabilities, contains('tax.read'));
    expect(extension.enabled, isTrue);
  });
}
