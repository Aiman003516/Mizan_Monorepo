import 'package:core_data/core_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps a statement entry with running balance', () {
    final entry = PartyStatementEntry.fromJson({
      'entry_date': '2026-08-27',
      'source_type': 'invoice',
      'source_id': 'invoice-1',
      'reference': 'INV-001',
      'description': 'Invoice',
      'currency_code': 'SAR',
      'debit_minor': 12500,
      'credit_minor': 0,
      'balance_delta_minor': 12500,
      'running_balance_minor': 12500,
    });

    expect(entry.entryDate, DateTime(2026, 8, 27));
    expect(entry.sourceType, 'invoice');
    expect(entry.debitMinor, 12500);
    expect(entry.creditMinor, 0);
    expect(entry.runningBalanceMinor, 12500);
  });

  test('rejects an invalid statement date', () {
    expect(
      () => PartyStatementEntry.fromJson({'entry_date': 'not-a-date'}),
      throwsA(isA<FormatException>()),
    );
  });
}
