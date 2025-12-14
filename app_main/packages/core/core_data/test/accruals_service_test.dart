// Unit tests for AccrualsService
// Tests prepaid expenses, accrued expenses, unearned revenue, and amortization

import 'package:flutter_test/flutter_test.dart';
import 'package:core_data/src/services/accruals_service.dart';

void main() {
  group('AccrualType', () {
    test('should have all expected types', () {
      expect(AccrualType.values, contains(AccrualType.accruedExpense));
      expect(AccrualType.values, contains(AccrualType.accruedRevenue));
      expect(AccrualType.values, contains(AccrualType.prepaidExpense));
      expect(AccrualType.values, contains(AccrualType.unearnedRevenue));
    });
  });

  group('AccrualSchedule', () {
    test('should calculate amount per period correctly', () {
      final schedule = AccrualSchedule(
        description: 'Annual Insurance',
        type: AccrualType.prepaidExpense,
        debitAccountId: 'insuranceExpense',
        creditAccountId: 'prepaidInsurance',
        amount: 1200000, // $12,000
        startDate: DateTime(2024, 1, 1),
        frequency: 'monthly',
        totalPeriods: 12,
      );

      expect(schedule.amountPerPeriod, equals(100000)); // $1,000/month
    });

    test('should calculate remaining amount correctly', () {
      final schedule = AccrualSchedule(
        description: 'Quarterly Subscription',
        type: AccrualType.unearnedRevenue,
        debitAccountId: 'unearnedRevenue',
        creditAccountId: 'serviceRevenue',
        amount: 120000, // $1,200
        startDate: DateTime(2024, 1, 1),
        frequency: 'monthly',
        totalPeriods: 12,
        periodsCompleted: 4, // 4 months done
      );

      // Remaining = $1,200 - (4 * $100) = $800
      expect(schedule.remainingAmount, equals(80000));
    });

    test('should detect schedule completion', () {
      final completed = AccrualSchedule(
        description: 'Completed',
        type: AccrualType.prepaidExpense,
        debitAccountId: 'exp',
        creditAccountId: 'prepaid',
        amount: 12000,
        startDate: DateTime(2024, 1, 1),
        frequency: 'monthly',
        totalPeriods: 12,
        periodsCompleted: 12,
      );

      final incomplete = AccrualSchedule(
        description: 'Incomplete',
        type: AccrualType.prepaidExpense,
        debitAccountId: 'exp',
        creditAccountId: 'prepaid',
        amount: 12000,
        startDate: DateTime(2024, 1, 1),
        frequency: 'monthly',
        totalPeriods: 12,
        periodsCompleted: 6,
      );

      expect(completed.isComplete, isTrue);
      expect(incomplete.isComplete, isFalse);
    });

    test('should calculate next date for monthly frequency', () {
      final schedule = AccrualSchedule(
        description: 'Monthly',
        type: AccrualType.prepaidExpense,
        debitAccountId: 'exp',
        creditAccountId: 'prepaid',
        amount: 12000,
        startDate: DateTime(2024, 1, 15),
        frequency: 'monthly',
        totalPeriods: 12,
        periodsCompleted: 3,
      );

      // Start Jan 15, 3 periods completed = next is April 15
      expect(schedule.nextDate.month, equals(4));
      expect(schedule.nextDate.day, equals(15));
    });

    test('should calculate next date for quarterly frequency', () {
      final schedule = AccrualSchedule(
        description: 'Quarterly',
        type: AccrualType.prepaidExpense,
        debitAccountId: 'exp',
        creditAccountId: 'prepaid',
        amount: 4000,
        startDate: DateTime(2024, 1, 1),
        frequency: 'quarterly',
        totalPeriods: 4,
        periodsCompleted: 1,
      );

      // Start Jan 1, 1 period completed = next is April 1
      expect(schedule.nextDate.month, equals(4));
    });

    test('should calculate next date for annual frequency', () {
      final schedule = AccrualSchedule(
        description: 'Annual',
        type: AccrualType.prepaidExpense,
        debitAccountId: 'exp',
        creditAccountId: 'prepaid',
        amount: 5000,
        startDate: DateTime(2024, 1, 1),
        frequency: 'annually',
        totalPeriods: 5,
        periodsCompleted: 2,
      );

      // Start 2024, 2 periods completed = next is 2026
      expect(schedule.nextDate.year, equals(2026));
    });
  });

  group('Prepaid Expense Scenarios', () {
    test('should amortize 12-month insurance correctly', () {
      // Pay $12,000 for annual insurance on Jan 1
      // Monthly amortization = $1,000
      const totalPaid = 1200000; // $12,000 in cents
      const periods = 12;
      final monthlyExpense = totalPaid ~/ periods;

      expect(monthlyExpense, equals(100000)); // $1,000

      // After 6 months: $6,000 expensed, $6,000 remaining prepaid
      final expensedAfter6 = monthlyExpense * 6;
      final remainingPrepaid = totalPaid - expensedAfter6;

      expect(expensedAfter6, equals(600000));
      expect(remainingPrepaid, equals(600000));
    });

    test('should handle uneven division in amortization', () {
      // $1,000 over 3 months = $333.33...
      const totalPaid = 100000; // $1,000
      const periods = 3;
      final perPeriod = totalPaid ~/ periods; // 33333

      // After 3 periods: 33333 * 3 = 99999
      // Remaining: 100000 - 99999 = 1 cent (ghost money)
      final allocated = perPeriod * periods;
      final ghost = totalPaid - allocated;

      expect(ghost, equals(1));
    });
  });

  group('Accrued Expense Scenarios', () {
    test('should calculate month-end salary accrual', () {
      // Scenario: Bi-weekly pay, month ends mid-pay-period
      // 5 working days accrued at end of month
      const dailyRate = 20000; // $200/day
      const dayAccrued = 5;
      final accruedAmount = dailyRate * dayAccrued;

      expect(accruedAmount, equals(100000)); // $1,000 accrued
    });

    test('should handle interest accrual', () {
      // $100,000 loan at 6% annual = $6,000/year = $500/month
      const principal = 10000000; // $100,000
      const annualRate = 0.06;
      final annualInterest = (principal * annualRate).round();
      final monthlyInterest = annualInterest ~/ 12;

      expect(monthlyInterest, equals(50000)); // $500
    });
  });

  group('Unearned Revenue Scenarios', () {
    test('should recognize revenue over service period', () {
      // Annual subscription: $120 received upfront, recognized over 12 months
      const receivedUpfront = 12000; // $120
      const servicePeriods = 12;
      final monthlyRevenue = receivedUpfront ~/ servicePeriods;

      expect(monthlyRevenue, equals(1000)); // $10/month

      // After 4 months: $40 recognized, $80 still unearned
      final recognized = monthlyRevenue * 4;
      final stillUnearned = receivedUpfront - recognized;

      expect(recognized, equals(4000));
      expect(stillUnearned, equals(8000));
    });

    test('should handle quarterly recognition', () {
      // $1,200 recognized quarterly = $300/quarter
      const totalAmount = 120000;
      const quarters = 4;
      final perQuarter = totalAmount ~/ quarters;

      expect(perQuarter, equals(30000)); // $300
    });
  });

  group('Schedule JSON Serialization', () {
    test('should serialize to JSON correctly', () {
      final schedule = AccrualSchedule(
        description: 'Test',
        type: AccrualType.prepaidExpense,
        debitAccountId: 'debit',
        creditAccountId: 'credit',
        amount: 10000,
        startDate: DateTime(2024, 1, 1),
        frequency: 'monthly',
        totalPeriods: 12,
        periodsCompleted: 3,
      );

      final json = schedule.toJson();

      expect(json['description'], equals('Test'));
      expect(json['type'], equals('prepaidExpense'));
      expect(json['amount'], equals(10000));
      expect(json['frequency'], equals('monthly'));
      expect(json['totalPeriods'], equals(12));
      expect(json['periodsCompleted'], equals(3));
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'description': 'Test',
        'type': 'unearnedRevenue',
        'debitAccountId': 'debit',
        'creditAccountId': 'credit',
        'amount': 5000,
        'startDate': '2024-06-01T00:00:00.000',
        'frequency': 'quarterly',
        'totalPeriods': 4,
        'periodsCompleted': 1,
      };

      final schedule = AccrualSchedule.fromJson(json);

      expect(schedule.type, equals(AccrualType.unearnedRevenue));
      expect(schedule.amount, equals(5000));
      expect(schedule.startDate.month, equals(6));
    });
  });

  group('Edge Cases', () {
    test('should handle null end date', () {
      final schedule = AccrualSchedule(
        description: 'No End',
        type: AccrualType.prepaidExpense,
        debitAccountId: 'exp',
        creditAccountId: 'prepaid',
        amount: 12000,
        startDate: DateTime(2024, 1, 1),
        endDate: null,
        frequency: 'monthly',
        totalPeriods: 12,
      );

      expect(schedule.endDate, isNull);
    });

    test('should handle over-completion gracefully', () {
      final schedule = AccrualSchedule(
        description: 'Over',
        type: AccrualType.prepaidExpense,
        debitAccountId: 'exp',
        creditAccountId: 'prepaid',
        amount: 12000,
        startDate: DateTime(2024, 1, 1),
        frequency: 'monthly',
        totalPeriods: 12,
        periodsCompleted: 15, // More than total
      );

      expect(schedule.isComplete, isTrue);
      // Remaining might be negative, but isComplete should be true
    });
  });
}
