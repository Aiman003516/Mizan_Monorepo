// FILE: packages/core/core_data/test/cvp_analysis_service_test.dart
// Purpose: Unit tests for CVP Analysis Service
// Reference: Accounting Principles 13e (Weygandt), Chapter 22

import 'package:flutter_test/flutter_test.dart';
import 'package:core_data/src/services/cvp_analysis_service.dart';

void main() {
  late CVPAnalysisService service;

  setUp(() {
    service = CVPAnalysisService();
  });

  group('Contribution Margin Calculations', () {
    test('should calculate contribution margin per unit', () {
      // Example: Selling Price = $50, Variable Cost = $30
      // Expected CM per Unit = $20
      final result = service.calculateContributionMarginPerUnit(
        unitSellingPrice: 5000, // $50.00
        variableCostPerUnit: 3000, // $30.00
      );
      expect(result, equals(2000)); // $20.00
    });

    test('should calculate total contribution margin', () {
      // Example: Price = $50, VC = $30, Units = 100
      // Expected Total CM = $20 × 100 = $2,000
      final result = service.calculateTotalContributionMargin(
        unitSellingPrice: 5000,
        variableCostPerUnit: 3000,
        unitsSold: 100,
      );
      expect(result, equals(200000)); // $2,000
    });

    test('should calculate contribution margin ratio', () {
      // Example: Price = $50, VC = $30
      // CM = $20, CM Ratio = 20/50 = 0.40 (40%)
      final result = service.calculateContributionMarginRatio(
        unitSellingPrice: 5000,
        variableCostPerUnit: 3000,
      );
      expect(result, equals(0.4));
    });

    test('should return 0 CM ratio when price is zero', () {
      final result = service.calculateContributionMarginRatio(
        unitSellingPrice: 0,
        variableCostPerUnit: 3000,
      );
      expect(result, equals(0));
    });

    test('should handle negative contribution margin', () {
      // Variable cost exceeds selling price
      final result = service.calculateContributionMarginPerUnit(
        unitSellingPrice: 2000, // $20
        variableCostPerUnit: 2500, // $25
      );
      expect(result, equals(-500)); // -$5
    });
  });

  group('Break-Even Analysis', () {
    test('should calculate break-even in units', () {
      // Textbook Example:
      // Fixed Costs = $100,000, Price = $50, VC = $30
      // CM per Unit = $20
      // Break-Even = $100,000 / $20 = 5,000 units
      final result = service.calculateBreakEvenUnits(
        fixedCosts: 10000000, // $100,000
        unitSellingPrice: 5000, // $50
        variableCostPerUnit: 3000, // $30
      );
      expect(result, equals(5000));
    });

    test('should calculate break-even in sales dollars', () {
      // Break-Even Sales = Fixed Costs / CM Ratio
      // $100,000 / 0.40 = $250,000
      final result = service.calculateBreakEvenSales(
        fixedCosts: 10000000, // $100,000
        unitSellingPrice: 5000, // $50
        variableCostPerUnit: 3000, // $30
      );
      expect(result, equals(25000000)); // $250,000
    });

    test('should return complete break-even analysis', () {
      final result = service.analyzeBreakEven(
        fixedCosts: 10000000,
        unitSellingPrice: 5000,
        variableCostPerUnit: 3000,
      );

      expect(result.breakEvenUnits, equals(5000));
      expect(result.breakEvenSales, equals(25000000));
      expect(result.contributionMarginPerUnit, equals(2000));
      expect(result.contributionMarginRatio, equals(0.4));
    });

    test('should return 0 when CM is zero or negative', () {
      final result = service.calculateBreakEvenUnits(
        fixedCosts: 10000000,
        unitSellingPrice: 3000, // Price = VC = $30
        variableCostPerUnit: 3000,
      );
      expect(result, equals(0));
    });

    test('should round up break-even units (cannot sell partial units)', () {
      // Fixed Costs = $10,000, CM = $30
      // Break-Even = 10,000 / 30 = 333.33... → 334 units
      final result = service.calculateBreakEvenUnits(
        fixedCosts: 1000000, // $10,000
        unitSellingPrice: 5000, // $50
        variableCostPerUnit: 2000, // $20 → CM = $30
      );
      expect(result, equals(334)); // Rounded up
    });
  });

  group('Target Profit Analysis', () {
    test('should calculate required units for target profit', () {
      // Fixed Costs = $100,000, Target Profit = $50,000
      // CM per Unit = $20
      // Required Units = ($100,000 + $50,000) / $20 = 7,500 units
      final result = service.calculateTargetProfitUnits(
        fixedCosts: 10000000,
        targetProfit: 5000000, // $50,000
        unitSellingPrice: 5000,
        variableCostPerUnit: 3000,
      );
      expect(result, equals(7500));
    });

    test('should calculate required sales for target profit', () {
      // Required Sales = ($100,000 + $50,000) / 0.40 = $375,000
      final result = service.calculateTargetProfitSales(
        fixedCosts: 10000000,
        targetProfit: 5000000,
        unitSellingPrice: 5000,
        variableCostPerUnit: 3000,
      );
      expect(result, equals(37500000)); // $375,000
    });

    test('should return complete target profit analysis', () {
      final result = service.analyzeTargetProfit(
        fixedCosts: 10000000,
        targetProfit: 5000000,
        unitSellingPrice: 5000,
        variableCostPerUnit: 3000,
      );

      expect(result.requiredUnits, equals(7500));
      expect(result.requiredSales, equals(37500000));
      expect(result.targetProfit, equals(5000000));
      expect(result.totalContributionMargin, equals(15000000)); // 7500 × $20
    });
  });

  group('Margin of Safety', () {
    test('should calculate margin of safety in dollars', () {
      // Actual Sales = $300,000, Break-Even Sales = $250,000
      // MOS = $50,000
      final result = service.calculateMarginOfSafetyDollars(
        actualSales: 30000000, // $300,000
        breakEvenSales: 25000000, // $250,000
      );
      expect(result, equals(5000000)); // $50,000
    });

    test('should calculate margin of safety in units', () {
      // Actual Units = 6,000, Break-Even Units = 5,000
      // MOS = 1,000 units
      final result = service.calculateMarginOfSafetyUnits(
        actualUnits: 6000,
        breakEvenUnits: 5000,
      );
      expect(result, equals(1000));
    });

    test('should calculate margin of safety ratio', () {
      // MOS = $50,000, Actual Sales = $300,000
      // MOS Ratio = 50,000 / 300,000 = 0.1667 (16.67%)
      final result = service.calculateMarginOfSafetyRatio(
        actualSales: 30000000,
        breakEvenSales: 25000000,
      );
      expect(result, closeTo(0.1667, 0.001));
    });

    test('should assess risk level based on MOS ratio', () {
      // Low Risk (MOS Ratio >= 30%)
      final lowRisk = service.analyzeMarginOfSafety(
        actualSales: 40000000, // $400,000
        actualUnits: 8000,
        fixedCosts: 10000000, // $100,000
        unitSellingPrice: 5000,
        variableCostPerUnit: 3000,
      );
      expect(lowRisk.riskLevel, equals('LOW'));

      // High Risk (MOS Ratio < 15%)
      final highRisk = service.analyzeMarginOfSafety(
        actualSales: 26000000, // $260,000 (just above break-even)
        actualUnits: 5200,
        fixedCosts: 10000000,
        unitSellingPrice: 5000,
        variableCostPerUnit: 3000,
      );
      expect(highRisk.riskLevel, equals('HIGH'));
    });

    test('should handle negative margin of safety', () {
      // Operating below break-even
      final result = service.calculateMarginOfSafetyDollars(
        actualSales: 20000000, // $200,000
        breakEvenSales: 25000000, // $250,000
      );
      expect(result, equals(-5000000)); // -$50,000 (loss position)
    });
  });

  group('Operating Leverage', () {
    test('should calculate degree of operating leverage', () {
      // CM = $120,000, Operating Income = $40,000
      // DOL = 120,000 / 40,000 = 3.0
      final result = service.calculateDegreeOfOperatingLeverage(
        contributionMargin: 12000000, // $120,000
        operatingIncome: 4000000, // $40,000
      );
      expect(result, equals(3.0));
    });

    test('should return infinity when operating income is zero', () {
      final result = service.calculateDegreeOfOperatingLeverage(
        contributionMargin: 12000000,
        operatingIncome: 0,
      );
      expect(result, equals(double.infinity));
    });

    test('should assess leverage level', () {
      // High leverage (DOL >= 5)
      final high = service.analyzeOperatingLeverage(
        actualSales: 30000000,
        variableCosts: 18000000,
        fixedCosts: 10000000, // High fixed costs
      );
      expect(high.leverageLevel, equals('HIGH'));

      // Low leverage (DOL < 2)
      final low = service.analyzeOperatingLeverage(
        actualSales: 30000000,
        variableCosts: 10000000,
        fixedCosts: 2000000, // Low fixed costs
      );
      expect(low.leverageLevel, equals('LOW'));
    });

    test('should explain impact multiplier correctly', () {
      // If DOL = 3, then 10% increase in sales = 30% increase in profit
      final result = service.analyzeOperatingLeverage(
        actualSales: 30000000,
        variableCosts: 18000000,
        fixedCosts: 8000000,
      );
      // CM = 12,000,000, OI = 4,000,000, DOL = 3.0
      expect(result.degreeOfOperatingLeverage, equals(3.0));
      expect(result.impactMultiplier, equals(3.0));
    });
  });

  group('Sensitivity Analysis', () {
    test('should generate price sensitivity scenarios', () {
      final result = service.performSensitivityAnalysis(
        fixedCosts: 10000000,
        unitSellingPrice: 5000,
        variableCostPerUnit: 3000,
        priceChangePercents: [-10, 0, 10],
      );

      expect(result.scenarios.length, equals(3));
      expect(result.baseBreakEvenUnits, equals(5000));

      // Price decrease should increase break-even
      final priceDecrease = result.scenarios.firstWhere(
        (s) => s.changePercent == -10,
      );
      expect(priceDecrease.breakEvenUnits, greaterThan(5000));

      // Price increase should decrease break-even
      final priceIncrease = result.scenarios.firstWhere(
        (s) => s.changePercent == 10,
      );
      expect(priceIncrease.breakEvenUnits, lessThan(5000));
    });

    test('should calculate change from base correctly', () {
      final result = service.performSensitivityAnalysis(
        fixedCosts: 10000000,
        unitSellingPrice: 5000,
        variableCostPerUnit: 3000,
        priceChangePercents: [0, 20],
      );

      final base = result.scenarios.firstWhere((s) => s.changePercent == 0);
      expect(base.changeFromBase, equals(0));

      final increased = result.scenarios.firstWhere(
        (s) => s.changePercent == 20,
      );
      expect(increased.changeFromBase, lessThan(0)); // Negative = improvement
    });
  });

  group('Multi-Product CVP Analysis', () {
    test('should calculate weighted break-even for multiple products', () {
      // Product A: Price = $100, VC = $60, Mix = 60%
      // Product B: Price = $80, VC = $50, Mix = 40%
      // CM A = $40, CM B = $30
      // Weighted CM = (40 × 0.6) + (30 × 0.4) = 24 + 12 = $36
      // Fixed Costs = $180,000
      // Break-Even = 180,000 / 36 = 5,000 total units
      final result = service.analyzeMultiProductCVP(
        totalFixedCosts: 18000000, // $180,000
        products: [
          const ProductCVPInput(
            productName: 'Product A',
            unitSellingPrice: 10000, // $100
            variableCostPerUnit: 6000, // $60
            salesMixPercent: 0.60,
          ),
          const ProductCVPInput(
            productName: 'Product B',
            unitSellingPrice: 8000, // $80
            variableCostPerUnit: 5000, // $50
            salesMixPercent: 0.40,
          ),
        ],
      );

      expect(result.weightedBreakEvenUnits, equals(5000));

      // Verify breakdown
      expect(result.productBreakdowns.length, equals(2));

      final productA = result.productBreakdowns.firstWhere(
        (p) => p.productName == 'Product A',
      );
      expect(productA.breakEvenUnits, equals(3000)); // 5000 × 0.60

      final productB = result.productBreakdowns.firstWhere(
        (p) => p.productName == 'Product B',
      );
      expect(productB.breakEvenUnits, equals(2000)); // 5000 × 0.40
    });

    test('should handle empty product list', () {
      final result = service.analyzeMultiProductCVP(
        totalFixedCosts: 18000000,
        products: [],
      );

      expect(result.weightedBreakEvenUnits, equals(0));
      expect(result.productBreakdowns, isEmpty);
    });

    test('should normalize sales mix if not adding to 100%', () {
      final result = service.analyzeMultiProductCVP(
        totalFixedCosts: 18000000,
        products: [
          const ProductCVPInput(
            productName: 'A',
            unitSellingPrice: 10000,
            variableCostPerUnit: 6000,
            salesMixPercent: 0.30, // Only 50% total
          ),
          const ProductCVPInput(
            productName: 'B',
            unitSellingPrice: 8000,
            variableCostPerUnit: 5000,
            salesMixPercent: 0.20,
          ),
        ],
      );

      // Should still calculate (may normalize internally)
      expect(result.weightedBreakEvenUnits, greaterThan(0));
    });
  });

  group('Profit Projection', () {
    test('should calculate projected profit at given volume', () {
      // 6,000 units at CM of $20 = $120,000 CM
      // Fixed Costs = $100,000
      // Profit = $20,000
      final result = service.calculateProjectedProfit(
        projectedUnits: 6000,
        unitSellingPrice: 5000,
        variableCostPerUnit: 3000,
        fixedCosts: 10000000,
      );
      expect(result, equals(2000000)); // $20,000 profit
    });

    test('should calculate loss when below break-even', () {
      // 4,000 units at CM of $20 = $80,000 CM
      // Fixed Costs = $100,000
      // Loss = -$20,000
      final result = service.calculateProjectedProfit(
        projectedUnits: 4000,
        unitSellingPrice: 5000,
        variableCostPerUnit: 3000,
        fixedCosts: 10000000,
      );
      expect(result, equals(-2000000)); // -$20,000 loss
    });

    test('should calculate zero profit at break-even', () {
      final result = service.calculateProjectedProfit(
        projectedUnits: 5000, // Break-even point
        unitSellingPrice: 5000,
        variableCostPerUnit: 3000,
        fixedCosts: 10000000,
      );
      expect(result, equals(0));
    });

    test('should calculate profit from sales dollars', () {
      // Sales = $300,000, CM Ratio = 40%
      // Total CM = $120,000
      // Fixed Costs = $100,000
      // Profit = $20,000
      final result = service.calculateProjectedProfitFromSales(
        projectedSales: 30000000, // $300,000
        contributionMarginRatio: 0.40,
        fixedCosts: 10000000,
      );
      expect(result, equals(2000000)); // $20,000
    });
  });

  group('Edge Cases', () {
    test('should handle very large numbers', () {
      final result = service.analyzeBreakEven(
        fixedCosts: 100000000000, // $1 billion
        unitSellingPrice: 100000, // $1,000
        variableCostPerUnit: 60000, // $600
      );

      expect(result.breakEvenUnits, equals(2500000)); // 2.5 million units
    });

    test('should handle very small margins', () {
      // CM = $1 (1 cent in cents)
      final result = service.calculateBreakEvenUnits(
        fixedCosts: 100000, // $1,000
        unitSellingPrice: 101, // $1.01
        variableCostPerUnit: 100, // $1.00
      );
      expect(result, equals(100000)); // 100,000 units
    });
  });
}
