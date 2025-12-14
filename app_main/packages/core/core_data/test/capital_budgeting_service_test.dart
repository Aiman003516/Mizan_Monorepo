// FILE: packages/core/core_data/test/capital_budgeting_service_test.dart
// Purpose: Unit tests for Capital Budgeting Service

import 'package:flutter_test/flutter_test.dart';
import 'package:core_data/src/services/capital_budgeting_service.dart';

void main() {
  group('Net Present Value (NPV)', () {
    test('NPV calculation - positive NPV project', () {
      // Example: Initial investment = $100,000
      // Cash flows: Year 1 = $30,000, Year 2 = $40,000, Year 3 = $50,000
      // Discount rate = 10%
      // PV of cash flows:
      //   30,000 / 1.10 = 27,273
      //   40,000 / 1.21 = 33,058
      //   50,000 / 1.331 = 37,566
      //   Total PV = 97,897
      // NPV = 97,897 - 100,000 = -2,103 (reject)
      final result = CapitalBudgetingService.calculateNPV(
        initialInvestment: 100000,
        cashFlows: [30000, 40000, 50000],
        discountRate: 0.10,
      );

      expect(result.npv, closeTo(-2103, 50));
      expect(result.isAcceptable, isFalse);
    });

    test('NPV calculation - accept project with positive NPV', () {
      // Same project with higher cash flows
      final result = CapitalBudgetingService.calculateNPV(
        initialInvestment: 100000,
        cashFlows: [40000, 50000, 60000],
        discountRate: 0.10,
      );

      expect(result.npv, greaterThan(0));
      expect(result.isAcceptable, isTrue);
      expect(result.recommendation, contains('Accept'));
    });

    test('NPV with zero discount rate', () {
      final result = CapitalBudgetingService.calculateNPV(
        initialInvestment: 100000,
        cashFlows: [40000, 40000, 40000],
        discountRate: 0,
      );

      // NPV = 120,000 - 100,000 = 20,000
      expect(result.npv, equals(20000));
    });
  });

  group('Internal Rate of Return (IRR)', () {
    test('IRR calculation', () {
      // Example: Investment = $100,000, Cash flows = $50,000 for 3 years
      // IRR should be approximately 23.4%
      final result = CapitalBudgetingService.calculateIRR(
        initialInvestment: 100000,
        cashFlows: [50000, 50000, 50000],
      );

      expect(result.converged, isTrue);
      expect(result.irr, closeTo(0.234, 0.01));
    });

    test('IRR decision - accept when IRR > required return', () {
      final result = CapitalBudgetingService.calculateIRR(
        initialInvestment: 100000,
        cashFlows: [50000, 50000, 50000],
      );

      expect(result.isAcceptable(0.10), isTrue); // 23% > 10%
      expect(result.isAcceptable(0.30), isFalse); // 23% < 30%
    });

    test('IRR with even cash flows', () {
      // Annuity-like investment: $10,000 investment, $2,638 for 5 years
      // This should give approximately 10% IRR
      final result = CapitalBudgetingService.calculateIRR(
        initialInvestment: 10000,
        cashFlows: [2638, 2638, 2638, 2638, 2638],
      );

      expect(result.irr, closeTo(0.10, 0.01));
    });
  });

  group('Payback Period', () {
    test('Simple payback period - even cash flows', () {
      // Investment = $100,000, Annual cash flow = $25,000
      // Payback = 100,000 / 25,000 = 4 years
      final result = CapitalBudgetingService.calculatePaybackPeriod(
        initialInvestment: 100000,
        cashFlows: [25000, 25000, 25000, 25000, 25000],
      );

      expect(result.years, equals(4.0));
      expect(result.recoversInvestment, isTrue);
    });

    test('Payback period - uneven cash flows', () {
      // Investment = $100,000
      // Year 1: $30,000, Year 2: $40,000, Year 3: $50,000
      // Cumulative: 30k, 70k, 120k
      // Payback between year 2 and 3: 2 + (30,000/50,000) = 2.6 years
      final result = CapitalBudgetingService.calculatePaybackPeriod(
        initialInvestment: 100000,
        cashFlows: [30000, 40000, 50000, 20000],
      );

      expect(result.years, closeTo(2.6, 0.1));
      expect(result.formattedPayback, contains('years'));
    });

    test('Never recovers investment', () {
      final result = CapitalBudgetingService.calculatePaybackPeriod(
        initialInvestment: 100000,
        cashFlows: [10000, 10000, 10000],
      );

      expect(result.recoversInvestment, isFalse);
      expect(result.years, equals(double.infinity));
      expect(result.formattedPayback, equals('Never'));
    });

    test('Discounted payback period', () {
      // Investment = $100,000, Cash flows = $40,000 per year, rate = 10%
      // Discounted: 36,364 + 33,058 + 30,053 = 99,475 (still short after 3 years)
      final result = CapitalBudgetingService.calculateDiscountedPaybackPeriod(
        initialInvestment: 100000,
        cashFlows: [40000, 40000, 40000, 40000],
        discountRate: 0.10,
      );

      // Should take longer than simple payback (2.5 years)
      expect(result.years, greaterThan(2.5));
      expect(result.recoversInvestment, isTrue);
    });
  });

  group('Profitability Index (PI)', () {
    test('Profitability Index calculation', () {
      // Investment = $100,000, PV of cash flows = $120,000
      // PI = 120,000 / 100,000 = 1.20
      final result = CapitalBudgetingService.calculateProfitabilityIndex(
        initialInvestment: 100000,
        cashFlows: [40000, 50000, 60000],
        discountRate: 0.10,
      );

      expect(result.profitabilityIndex, greaterThan(1.0));
      expect(result.isAcceptable, isTrue);
      expect(result.recommendation, contains('Accept'));
    });

    test('PI less than 1.0 - reject', () {
      final result = CapitalBudgetingService.calculateProfitabilityIndex(
        initialInvestment: 100000,
        cashFlows: [20000, 30000, 30000],
        discountRate: 0.10,
      );

      expect(result.profitabilityIndex, lessThan(1.0));
      expect(result.isAcceptable, isFalse);
      expect(result.recommendation, contains('Reject'));
    });
  });

  group('Annual Rate of Return (ARR)', () {
    test('ARR calculation', () {
      // Expected annual net income = $20,000
      // Initial investment = $100,000, Residual value = $20,000
      // Average investment = (100,000 + 20,000) / 2 = $60,000
      // ARR = 20,000 / 60,000 = 33.33%
      final result = CapitalBudgetingService.calculateARR(
        expectedAnnualNetIncome: 20000,
        initialInvestment: 100000,
        residualValue: 20000,
      );

      expect(result.arr, closeTo(0.3333, 0.001));
      expect(result.formattedARR, equals('33.33%'));
      expect(result.averageInvestment, equals(60000));
    });
  });

  group('Sensitivity Analysis', () {
    test('NPV sensitivity to discount rate', () {
      final points = CapitalBudgetingService.npvSensitivityAnalysis(
        initialInvestment: 100000,
        cashFlows: [40000, 50000, 60000],
        minRate: 0.05,
        maxRate: 0.20,
        step: 0.05,
      );

      expect(points.length, equals(4)); // 5%, 10%, 15%, 20%

      // NPV should decrease as discount rate increases
      expect(points[0].npv, greaterThan(points[1].npv));
      expect(points[1].npv, greaterThan(points[2].npv));
    });
  });

  group('Project Comparison', () {
    test('Compare multiple projects', () {
      final comparison = CapitalBudgetingService.compareProjects(
        projects: [
          ProjectInput(
            name: 'Project A',
            initialInvestment: 100000,
            cashFlows: [40000, 50000, 60000],
          ),
          ProjectInput(
            name: 'Project B',
            initialInvestment: 80000,
            cashFlows: [30000, 35000, 40000],
          ),
          ProjectInput(
            name: 'Project C',
            initialInvestment: 120000,
            cashFlows: [50000, 60000, 80000],
          ),
        ],
        discountRate: 0.10,
      );

      expect(comparison.analyses.length, equals(3));
      expect(comparison.discountRate, equals(0.10));

      // Should be ranked by NPV
      expect(
        comparison.analyses[0].npv,
        greaterThanOrEqualTo(comparison.analyses[1].npv),
      );

      // Recommended project should be the one with highest NPV
      expect(comparison.recommendedProject, isNotNull);
    });
  });
}
