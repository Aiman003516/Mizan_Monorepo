import 'package:flutter_test/flutter_test.dart';

import 'package:core_data/core_data.dart';

void main() {
  group('ApprovalRequestType', () {
    test('round-trips database values', () {
      for (final type in ApprovalRequestType.values) {
        expect(
          ApprovalRequestType.fromDatabase(type.databaseValue),
          equals(type),
        );
      }
    });

    test('rejects unknown database values', () {
      expect(
        () => ApprovalRequestType.fromDatabase('unknown'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  test('maps an approval request with branch and decision fields', () {
    final request = ApprovalRequest.fromJson({
      'id': 'request-1',
      'tenant_id': 'tenant-1',
      'requester_id': 'user-1',
      'request_type': 'balance_adjustment',
      'target_id': 'customer-1',
      'payload': {'source': 'customer_balance'},
      'amount_minor': 12500,
      'currency_code': 'YER',
      'reason': 'Correct opening balance',
      'status': 'approved',
      'branch_id': 'branch-1',
      'idempotency_key': 'approval-key-1',
      'created_at': '2026-08-27T00:00:00Z',
      'decided_by': 'manager-1',
      'decided_at': '2026-08-27T00:05:00Z',
      'updated_at': '2026-08-27T00:05:00Z',
    });

    expect(request.requestType, ApprovalRequestType.balanceAdjustment);
    expect(request.status, ApprovalStatus.approved);
    expect(request.amountMinor, 12500);
    expect(request.branchId, 'branch-1');
    expect(request.payload['source'], 'customer_balance');
    expect(request.decidedBy, 'manager-1');
  });

  test('maps the initial pending event without a previous status', () {
    final event = ApprovalRequestEvent.fromJson({
      'id': 1,
      'tenant_id': 'tenant-1',
      'approval_request_id': 'request-1',
      'actor_id': 'user-1',
      'from_status': null,
      'to_status': 'pending',
      'decision_reason': 'Requires owner review',
      'created_at': '2026-08-27T00:00:00Z',
    });

    expect(event.fromStatus, equals(null));
    expect(event.toStatus, ApprovalStatus.pending);
    expect(event.decisionReason, 'Requires owner review');
  });
}
