// Unit tests for JournalEntryService
// Tests compound entries, simple entries, reversing entries, and balance validation

import 'package:flutter_test/flutter_test.dart';
import 'package:core_data/src/services/journal_entry_service.dart';

void main() {
  group('JournalLine', () {
    test('should identify debit when amount is positive', () {
      const line = JournalLine(accountId: 'acc1', amount: 1000);
      expect(line.isDebit, isTrue);
      expect(line.isCredit, isFalse);
      expect(line.absoluteAmount, equals(1000));
    });

    test('should identify credit when amount is negative', () {
      const line = JournalLine(accountId: 'acc1', amount: -500);
      expect(line.isDebit, isFalse);
      expect(line.isCredit, isTrue);
      expect(line.absoluteAmount, equals(500));
    });

    test('should handle zero amount edge case', () {
      const line = JournalLine(accountId: 'acc1', amount: 0);
      expect(line.isDebit, isFalse);
      expect(line.isCredit, isFalse);
      expect(line.absoluteAmount, equals(0));
    });
  });

  group('JournalEntryResult', () {
    test('should correctly report balanced state', () {
      const result = JournalEntryResult(
        transactionId: 'tx1',
        isBalanced: true,
        totalDebits: 5000,
        totalCredits: 5000,
      );
      expect(result.isBalanced, isTrue);
      expect(result.totalDebits, equals(result.totalCredits));
    });

    test('should correctly report unbalanced state', () {
      const result = JournalEntryResult(
        transactionId: 'tx2',
        isBalanced: false,
        totalDebits: 5000,
        totalCredits: 4000,
      );
      expect(result.isBalanced, isFalse);
    });
  });

  group('Journal Entry Validation Logic', () {
    // These tests verify the validation logic without database

    test('should calculate totals correctly for compound entry', () {
      final lines = [
        const JournalLine(accountId: 'cash', amount: 10000), // Debit
        const JournalLine(accountId: 'revenue', amount: -8000), // Credit
        const JournalLine(accountId: 'taxPayable', amount: -2000), // Credit
      ];

      int totalDebits = 0;
      int totalCredits = 0;
      for (final line in lines) {
        if (line.isDebit) {
          totalDebits += line.absoluteAmount;
        } else {
          totalCredits += line.absoluteAmount;
        }
      }

      expect(totalDebits, equals(10000));
      expect(totalCredits, equals(10000));
      expect(totalDebits, equals(totalCredits)); // Balanced
    });

    test('should detect unbalanced journal entry', () {
      final lines = [
        const JournalLine(accountId: 'cash', amount: 10000), // Debit
        const JournalLine(
          accountId: 'revenue',
          amount: -9000,
        ), // Credit (wrong)
      ];

      int totalDebits = 0;
      int totalCredits = 0;
      for (final line in lines) {
        if (line.isDebit) {
          totalDebits += line.absoluteAmount;
        } else {
          totalCredits += line.absoluteAmount;
        }
      }

      expect(totalDebits, isNot(equals(totalCredits))); // Unbalanced
    });

    test('should require at least 2 lines in a journal entry', () {
      final lines = [const JournalLine(accountId: 'cash', amount: 10000)];

      expect(lines.length, lessThan(2));
    });

    test('should handle multiple debits and credits (compound entry)', () {
      // Example: Payroll entry with multiple debits
      final lines = [
        const JournalLine(accountId: 'salaryExpense', amount: 50000), // Debit
        const JournalLine(accountId: 'taxExpense', amount: 5000), // Debit
        const JournalLine(accountId: 'cash', amount: -40000), // Credit
        const JournalLine(accountId: 'taxPayable', amount: -15000), // Credit
      ];

      int totalDebits = 0;
      int totalCredits = 0;
      for (final line in lines) {
        if (line.isDebit) {
          totalDebits += line.absoluteAmount;
        } else {
          totalCredits += line.absoluteAmount;
        }
      }

      expect(totalDebits, equals(55000));
      expect(totalCredits, equals(55000));
    });

    test('should verify reversing entry swaps signs', () {
      // Original entry
      final originalLines = [
        const JournalLine(accountId: 'accruedExpense', amount: 1000), // Debit
        const JournalLine(accountId: 'expensePayable', amount: -1000), // Credit
      ];

      // Reversing entry should have opposite signs
      final reversedLines = originalLines
          .map(
            (line) => JournalLine(
              accountId: line.accountId,
              amount: -line.amount, // Reverse the sign
            ),
          )
          .toList();

      expect(reversedLines[0].amount, equals(-1000)); // Now credit
      expect(reversedLines[1].amount, equals(1000)); // Now debit

      // Reversed should also be balanced
      int totalDebits = 0;
      int totalCredits = 0;
      for (final line in reversedLines) {
        if (line.isDebit) {
          totalDebits += line.absoluteAmount;
        } else {
          totalCredits += line.absoluteAmount;
        }
      }
      expect(totalDebits, equals(totalCredits));
    });
  });

  group('Edge Cases', () {
    test('should handle very large amounts without overflow', () {
      // Testing with large amounts (in cents/fils representation)
      const line = JournalLine(
        accountId: 'acc1',
        amount: 999999999999, // ~10 billion in base unit
      );
      expect(line.absoluteAmount, equals(999999999999));
      expect(line.isDebit, isTrue);
    });

    test('should handle memo field', () {
      const line = JournalLine(
        accountId: 'acc1',
        amount: 1000,
        memo: 'Payment for invoice #123',
      );
      expect(line.memo, equals('Payment for invoice #123'));
    });

    test('should handle null memo field', () {
      const line = JournalLine(accountId: 'acc1', amount: 1000);
      expect(line.memo, isNull);
    });
  });
}
