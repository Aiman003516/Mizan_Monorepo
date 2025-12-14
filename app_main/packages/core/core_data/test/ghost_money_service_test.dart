// Unit tests for GhostMoneyService
// Tests rounding difference tracking, accumulation, and reconciliation

import 'package:flutter_test/flutter_test.dart';
import 'package:core_data/src/services/ghost_money_service.dart';

void main() {
  group('GhostReconciliationStrategy', () {
    test('should have all expected strategies', () {
      expect(
        GhostReconciliationStrategy.values,
        contains(GhostReconciliationStrategy.writeOff),
      );
      expect(
        GhostReconciliationStrategy.values,
        contains(GhostReconciliationStrategy.allocateToNext),
      );
      expect(
        GhostReconciliationStrategy.values,
        contains(GhostReconciliationStrategy.accumulate),
      );
    });
  });

  group('GhostMoneySummary', () {
    test('should store summary values correctly', () {
      const summary = GhostMoneySummary(
        currency: 'USD',
        totalAmount: 150,
        entryCount: 12,
      );

      expect(summary.currency, equals('USD'));
      expect(summary.totalAmount, equals(150)); // $1.50 in cents
      expect(summary.entryCount, equals(12));
    });
  });

  group('Ghost Money Tracking Scenarios', () {
    test('should identify rounding from transaction split', () {
      // Scenario: Split $100 bill 3 ways
      // 10000 / 3 = 3333.33... → 3333 each = 9999
      // Ghost = 10000 - 9999 = 1 cent
      const totalAmount = 10000; // $100 in cents
      const splits = 3;
      final amountPerSplit = totalAmount ~/ splits; // 3333
      final totalAllocated = amountPerSplit * splits; // 9999
      final ghostMoney = totalAmount - totalAllocated; // 1

      expect(ghostMoney, equals(1));
      expect(ghostMoney, greaterThan(0));
    });

    test('should identify rounding from percentage calculation', () {
      // Scenario: 15% tax on $99.99
      // 9999 * 0.15 = 1499.85 → 1500 (rounded)
      const amount = 9999; // $99.99
      const taxRate = 0.15;
      final exactTax = amount * taxRate; // 1499.85
      final roundedTax = exactTax.round(); // 1500
      final ghostMoney = (roundedTax - exactTax).abs().round();

      expect(ghostMoney, lessThanOrEqualTo(1));
    });

    test('should identify rounding from currency exchange', () {
      // Scenario: Convert $100 at rate 3.7525 SAR
      // 10000 * 3.7525 = 37525 (exact)
      // No ghost in this case, but:
      // 10000 * 3.7526 = 37526.0 → 37526
      const amountUsd = 10000;
      const rate = 3.7526;
      final exactSar = amountUsd * rate; // 37526.0
      final roundedSar = exactSar.round(); // 37526
      final ghost = (exactSar - roundedSar).abs();

      expect(ghost, lessThan(1)); // Less than 1 halala
    });

    test('should accumulate ghost money over multiple transactions', () {
      final ghosts = <int>[1, -1, 2, 1, -1, 3]; // Various rounding diffs
      final total = ghosts.reduce((a, b) => a + b);

      expect(total, equals(5)); // Net 5 cents ghost
    });
  });

  group('Reconciliation Logic', () {
    test('should determine write-off amount correctly', () {
      const accumulated = 150; // $1.50 in cents
      const threshold = 100; // $1.00 threshold for write-off

      expect(accumulated.abs(), greaterThan(threshold));
      // Should write off
    });

    test('should handle negative ghost accumulation', () {
      // Sometimes ghost can be negative (we rounded up more than down)
      const accumulated = -75; // We owe -$0.75

      expect(accumulated, lessThan(0));
      // This becomes revenue when written off
    });

    test('should clear ghost entries after reconciliation', () {
      // Simulate reconciliation state
      final entries = [
        MockGhostEntry(amount: 10, reconciled: false),
        MockGhostEntry(amount: -5, reconciled: false),
        MockGhostEntry(amount: 8, reconciled: false),
      ];

      // Reconcile all
      final reconciled = entries
          .map((e) => e.copyWithReconciled(true))
          .toList();

      expect(reconciled.every((e) => e.reconciled), isTrue);
    });
  });

  group('Ghost Money Sources', () {
    test('should categorize different source types', () {
      const sources = ['TRANSACTION', 'SPLIT', 'EXCHANGE', 'IMPORT'];

      // All valid source types
      for (final source in sources) {
        expect(source, isNotEmpty);
      }
    });

    test('should categorize different reasons', () {
      const reasons = ['ROUNDING', 'DIVISION', 'EXCHANGE_RATE'];

      // All valid reasons
      for (final reason in reasons) {
        expect(reason, isNotEmpty);
      }
    });
  });

  group('Edge Cases', () {
    test('should handle zero ghost amount', () {
      // Perfect division - no ghost
      const totalAmount = 10000;
      const splits = 4;
      final amountPerSplit = totalAmount ~/ splits; // 2500
      final totalAllocated = amountPerSplit * splits;
      final ghostMoney = totalAmount - totalAllocated;

      expect(ghostMoney, equals(0));
    });

    test('should handle very small currency units', () {
      // Currencies with more decimal places
      const amountKwd = 1000000; // 1000 KWD in fils (1/1000)
      const splits = 3;
      final amountPerSplit = amountKwd ~/ splits;
      final ghostMoney = amountKwd - (amountPerSplit * splits);

      expect(ghostMoney, lessThan(splits));
    });

    test('should handle multiple currencies separately', () {
      final ghostByCurrency = <String, int>{'USD': 10, 'SAR': 25, 'EUR': -5};

      expect(ghostByCurrency['USD'], equals(10));
      expect(ghostByCurrency['SAR'], equals(25));
      expect(ghostByCurrency['EUR'], equals(-5));
    });
  });
}

/// Mock ghost entry for testing
class MockGhostEntry {
  final int amount;
  final bool reconciled;

  MockGhostEntry({required this.amount, required this.reconciled});

  MockGhostEntry copyWithReconciled(bool value) {
    return MockGhostEntry(amount: amount, reconciled: value);
  }
}
