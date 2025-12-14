// FILE: packages/core/core_data/test/budgeting_service_test.dart
// Purpose: Unit tests for Budgeting Service variance calculations
// Reference: Accounting Principles 13e (Weygandt), Chapters 23-24

import 'package:flutter_test/flutter_test.dart';
import 'package:core_data/src/services/budgeting_service.dart';

void main() {
  // All variance calculation tests use static methods, no database needed

  group('Variance Calculation - Expenses', () {
    test('should identify favorable variance when under budget (expenses)', () {
      // Example: Budgeted $10,000, Actual $8,000
      // Variance = -$2,000 (favorable for expenses)
      final result = BudgetingService.calculateVariance(
        accountId: 'exp1',
        accountName: 'Office Supplies',
        accountType: 'expense',
        budgetedAmount: 1000000, // $10,000
        actualAmount: 800000, // $8,000
      );

      expect(result.variance, equals(-200000)); // -$2,000
      expect(result.isFavorable, isTrue);
      expect(result.variancePercent, closeTo(-0.20, 0.001)); // -20%
    });

    test(
      'should identify unfavorable variance when over budget (expenses)',
      () {
        // Example: Budgeted $10,000, Actual $12,000
        // Variance = +$2,000 (unfavorable for expenses)
        final result = BudgetingService.calculateVariance(
          accountId: 'exp1',
          accountName: 'Travel',
          accountType: 'expense',
          budgetedAmount: 1000000,
          actualAmount: 1200000,
        );

        expect(result.variance, equals(200000)); // +$2,000
        expect(result.isFavorable, isFalse);
        expect(result.variancePercent, closeTo(0.20, 0.001)); // +20%
      },
    );

    test('should handle zero budget (avoid division by zero)', () {
      final result = BudgetingService.calculateVariance(
        accountId: 'exp1',
        accountName: 'New Category',
        accountType: 'expense',
        budgetedAmount: 0,
        actualAmount: 500000,
      );

      expect(result.variance, equals(500000));
      expect(result.variancePercent, equals(0)); // Avoid infinity
    });
  });

  group('Variance Calculation - Revenue', () {
    test('should identify favorable variance when over budget (revenue)', () {
      // Example: Budgeted $100,000, Actual $120,000
      // Variance = +$20,000 (favorable for revenue)
      final result = BudgetingService.calculateVariance(
        accountId: 'rev1',
        accountName: 'Sales Revenue',
        accountType: 'revenue',
        budgetedAmount: 10000000, // $100,000
        actualAmount: 12000000, // $120,000
      );

      expect(result.variance, equals(2000000)); // +$20,000
      expect(result.isFavorable, isTrue);
      expect(result.variancePercent, closeTo(0.20, 0.001)); // +20%
    });

    test(
      'should identify unfavorable variance when under budget (revenue)',
      () {
        // Example: Budgeted $100,000, Actual $80,000
        // Variance = -$20,000 (unfavorable for revenue)
        final result = BudgetingService.calculateVariance(
          accountId: 'rev1',
          accountName: 'Service Revenue',
          accountType: 'revenue',
          budgetedAmount: 10000000,
          actualAmount: 8000000,
        );

        expect(result.variance, equals(-2000000)); // -$20,000
        expect(result.isFavorable, isFalse);
        expect(result.variancePercent, closeTo(-0.20, 0.001)); // -20%
      },
    );
  });

  group('Flexible Budget Analysis', () {
    test('should calculate flexible budget correctly', () {
      // Textbook Example:
      // Fixed Costs = $10,000
      // Variable Rate = $5 per unit
      // Planned Activity = 10,000 units
      // Actual Activity = 12,000 units
      // Actual Cost = $75,000
      //
      // Static Budget = $10,000 + ($5 × 10,000) = $60,000
      // Flexible Budget = $10,000 + ($5 × 12,000) = $70,000
      // Volume Variance = $70,000 - $60,000 = $10,000 (U - more activity)
      // Spending Variance = $75,000 - $70,000 = $5,000 (U - overspent)
      // Total Variance = $75,000 - $60,000 = $15,000 (U)

      final result = BudgetingService.calculateFlexibleBudget(
        fixedPortion: 1000000, // $10,000
        variableRate: 500, // $5 per unit
        plannedActivity: 10000,
        actualActivity: 12000,
        actualAmount: 7500000, // $75,000
      );

      expect(result.staticBudget, equals(6000000)); // $60,000
      expect(result.flexibleBudget, equals(7000000)); // $70,000
      expect(result.volumeVariance, equals(1000000)); // $10,000
      expect(result.spendingVariance, equals(500000)); // $5,000
      expect(result.totalVariance, equals(1500000)); // $15,000
    });

    test('should calculate favorable volume variance (less activity)', () {
      // Planned 10,000 units, Actual 8,000 units
      // Fixed = $10,000, Variable = $5/unit
      // Static = $60,000, Flexible = $50,000
      // Volume Variance = $50,000 - $60,000 = -$10,000 (F for costs)

      final result = BudgetingService.calculateFlexibleBudget(
        fixedPortion: 1000000,
        variableRate: 500,
        plannedActivity: 10000,
        actualActivity: 8000,
        actualAmount: 4800000, // $48,000
      );

      expect(result.flexibleBudget, equals(5000000)); // $50,000
      expect(result.volumeVariance, equals(-1000000)); // -$10,000
      expect(result.spendingVariance, equals(-200000)); // -$2,000 (favorable)
    });

    test('should handle zero variable rate (fixed costs only)', () {
      final result = BudgetingService.calculateFlexibleBudget(
        fixedPortion: 1000000,
        variableRate: 0, // All fixed
        plannedActivity: 10000,
        actualActivity: 15000,
        actualAmount: 1100000,
      );

      expect(result.staticBudget, equals(1000000));
      expect(result.flexibleBudget, equals(1000000)); // Same - no variable
      expect(result.volumeVariance, equals(0)); // No volume impact
      expect(result.spendingVariance, equals(100000)); // All due to spending
    });

    test('should handle zero fixed costs (all variable)', () {
      final result = BudgetingService.calculateFlexibleBudget(
        fixedPortion: 0,
        variableRate: 1000, // $10/unit
        plannedActivity: 1000,
        actualActivity: 1200,
        actualAmount: 1150000, // $11,500
      );

      expect(result.staticBudget, equals(1000000)); // $10,000
      expect(result.flexibleBudget, equals(1200000)); // $12,000
      expect(result.volumeVariance, equals(200000)); // $2,000
      expect(result.spendingVariance, equals(-50000)); // -$500 (favorable)
    });
  });

  group('Variance Percent Calculation', () {
    test('should calculate positive variance percent', () {
      final result = BudgetingService.calculateVariancePercent(10000, 12000);
      expect(result, closeTo(0.20, 0.001)); // 20%
    });

    test('should calculate negative variance percent', () {
      final result = BudgetingService.calculateVariancePercent(10000, 8000);
      expect(result, closeTo(-0.20, 0.001)); // -20%
    });

    test('should handle zero budget', () {
      final result = BudgetingService.calculateVariancePercent(0, 5000);
      expect(result, equals(0));
    });

    test('should handle exact budget match', () {
      final result = BudgetingService.calculateVariancePercent(10000, 10000);
      expect(result, equals(0));
    });
  });

  group('Budget Summary Calculations', () {
    test('BudgetSummary should correctly calculate variances', () {
      final summary = BudgetSummary(
        budgetId: 'test',
        budgetName: 'Q1 2024',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 3, 31),
        totalBudgetedRevenue: 10000000, // $100,000
        totalActualRevenue: 12000000, // $120,000
        totalBudgetedExpenses: 7000000, // $70,000
        totalActualExpenses: 6500000, // $65,000
        budgetedNetIncome: 3000000, // $30,000
        actualNetIncome: 5500000, // $55,000
        lineItems: [],
      );

      expect(summary.revenueVariance, equals(2000000)); // +$20,000
      expect(summary.expenseVariance, equals(-500000)); // -$5,000 (favorable)
      expect(summary.netIncomeVariance, equals(2500000)); // +$25,000
      expect(summary.revenueVariancePercent, closeTo(0.20, 0.001));
      expect(summary.expenseVariancePercent, closeTo(-0.0714, 0.001));
    });
  });

  group('FlexibleBudgetResult Properties', () {
    test('should maintain correct relationships', () {
      final result = FlexibleBudgetResult(
        staticBudget: 6000000,
        flexibleBudget: 7000000,
        actualAmount: 7500000,
        volumeVariance: 1000000,
        spendingVariance: 500000,
        totalVariance: 1500000,
        plannedActivity: 10000,
        actualActivity: 12000,
      );

      // Total Variance = Volume + Spending
      expect(
        result.totalVariance,
        equals(result.volumeVariance + result.spendingVariance),
      );

      // Total Variance = Actual - Static
      expect(
        result.totalVariance,
        equals(result.actualAmount - result.staticBudget),
      );
    });
  });

  group('Edge Cases', () {
    test('should handle large numbers', () {
      final result = BudgetingService.calculateVariance(
        accountId: 'exp1',
        accountName: 'Capital Expenditure',
        accountType: 'expense',
        budgetedAmount: 100000000000, // $1 billion
        actualAmount: 95000000000, // $950 million
      );

      expect(result.variance, equals(-5000000000)); // -$50 million
      expect(result.isFavorable, isTrue);
    });

    test('should handle negative actual (credits)', () {
      final result = BudgetingService.calculateVariance(
        accountId: 'exp1',
        accountName: 'Refunds',
        accountType: 'expense',
        budgetedAmount: 0,
        actualAmount: -50000, // Credit
      );

      expect(result.variance, equals(-50000));
    });
  });
}
