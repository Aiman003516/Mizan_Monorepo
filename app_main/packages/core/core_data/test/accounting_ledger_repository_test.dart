import 'package:core_data/core_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('period exposes locked and closed states as immutable', () {
    final locked = AccountingPeriod.fromJson({
      'id': 'period-1',
      'name': 'FY 2026',
      'starts_on': '2026-01-01',
      'ends_on': '2026-12-31',
      'status': 'locked',
    });
    final open = AccountingPeriod.fromJson({
      'id': 'period-2',
      'name': 'FY 2027',
      'starts_on': '2027-01-01',
      'ends_on': '2027-12-31',
      'status': 'open',
    });

    expect(locked.isLocked, isTrue);
    expect(open.isLocked, isFalse);
    expect(locked.startsOn.year, 2026);
  });

  test('parses tax and chart-of-account responses', () {
    final tax = TaxCode.fromJson({
      'id': 'tax-1',
      'code': 'VAT15',
      'name': 'VAT 15%',
      'rate_percent': 15,
      'is_inclusive': true,
      'is_active': true,
    });
    final account = ChartAccount.fromJson({
      'id': 'account-1',
      'code': '1100',
      'name': 'Cash',
      'account_type': 'asset',
      'normal_balance': 'debit',
      'currency_code': 'SAR',
      'is_active': true,
    });

    expect(tax.ratePercent, 15);
    expect(tax.isInclusive, isTrue);
    expect(account.code, '1100');
    expect(account.currencyCode, 'SAR');
  });

  test('parses accounting books and dimensions', () {
    final book = AccountingBook.fromJson({
      'id': 'book-1',
      'code': 'LEADING',
      'name': 'Leading book',
      'book_type': 'leading',
      'status': 'active',
    });
    final dimension = AccountingDimension.fromJson({
      'id': 'dimension-1',
      'dimension_type': 'cost_center',
      'code': 'OPS',
      'name': 'Operations',
      'is_active': true,
    });

    expect(book.bookType, LedgerBookType.leading);
    expect(book.isActive, isTrue);
    expect(dimension.dimensionType, 'cost_center');
    expect(dimension.name, 'Operations');
  });

  test('serializes a journal line without leaking blank optional fields', () {
    const line = JournalLineInput(
      accountId: 'account-1',
      debitMinor: 1000,
      creditMinor: 0,
      currencyCode: 'sar',
      description: 'Cash receipt',
      lineNumber: 1,
    );
    final json = line.toJson();

    expect(json['account_id'], 'account-1');
    expect(json['debit_minor'], 1000);
    expect(json['currency_code'], 'SAR');
    expect(json['line_number'], 1);
    expect(json.containsKey('tax_code_id'), isFalse);
  });

  test('maps server draft and trial-balance responses', () {
    final draft = JournalDraftResult.fromJson({
      'id': 'entry-1',
      'entry_number': 'JE-0001',
      'status': 'draft',
      'line_count': 2,
    });
    final balance = TrialBalanceLine.fromJson({
      'account_id': 'account-1',
      'account_code': '1100',
      'account_name': 'Cash',
      'account_type': 'asset',
      'debit_minor': 1000,
      'credit_minor': 0,
      'balance_minor': 1000,
    });

    expect(draft.status, 'draft');
    expect(draft.lineCount, 2);
    expect(balance.accountCode, '1100');
    expect(balance.balanceMinor, 1000);
  });
}
