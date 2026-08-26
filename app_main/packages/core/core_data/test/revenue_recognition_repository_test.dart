import 'package:core_data/core_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps a planned revenue schedule line and marks it ready', () {
    final line = RevenueScheduleLine.fromJson({
      'id': 'line-1',
      'contract_id': 'contract-1',
      'contract_number': 'SUB-001',
      'recognition_on': '2026-09-01',
      'amount_minor': 12500,
      'currency_code': 'SAR',
      'status': 'planned',
      'journal_entry_id': null,
    });

    expect(line.id, 'line-1');
    expect(line.contractNumber, 'SUB-001');
    expect(line.amountMinor, 12500);
    expect(line.currencyCode, 'SAR');
    expect(line.isReady, isTrue);
    expect(line.journalEntryId, null);
  });

  test('does not expose a draft-created or recognized line as ready', () {
    final draft = RevenueScheduleLine.fromJson({
      'id': 'line-2',
      'contract_id': 'contract-1',
      'contract_number': 'SUB-001',
      'recognition_on': '2026-10-01',
      'amount_minor': 12500,
      'currency_code': 'SAR',
      'status': 'draft_created',
      'journal_entry_id': 'journal-1',
    });
    final recognized = RevenueScheduleLine.fromJson({
      'id': 'line-3',
      'contract_id': 'contract-1',
      'contract_number': 'SUB-001',
      'recognition_on': '2026-11-01',
      'amount_minor': 12500,
      'currency_code': 'SAR',
      'status': 'recognized',
      'journal_entry_id': 'journal-2',
    });

    expect(draft.isReady, isFalse);
    expect(recognized.isReady, isFalse);
  });
}
