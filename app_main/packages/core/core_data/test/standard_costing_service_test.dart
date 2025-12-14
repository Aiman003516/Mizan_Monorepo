// FILE: packages/core/core_data/test/standard_costing_service_test.dart
// Purpose: Unit tests for Standard Costing Service variance calculations
// Reference: Accounting Principles 13e (Weygandt), Chapter 25

import 'package:flutter_test/flutter_test.dart';
import 'package:core_data/src/services/standard_costing_service.dart';

void main() {
  group('Direct Materials Variance', () {
    test('should calculate favorable price variance (paid less)', () {
      // Standard: 2 lbs @ $5/lb = $10
      // Actual: 2 lbs @ $4/lb = $8
      // Price Variance = ($4 - $5) × 2 = -$2 (Favorable)

      final result = StandardCostingService.calculateMaterialVariance(
        actualQuantity: 2.0,
        actualPrice: 400, // $4.00
        standardQuantity: 2.0,
        standardPrice: 500, // $5.00
      );

      expect(result.priceVariance, equals(-200)); // -$2.00
      expect(result.priceVarianceFavorable, isTrue);
      expect(result.quantityVariance, equals(0)); // No quantity variance
    });

    test('should calculate unfavorable price variance (paid more)', () {
      // Standard: 100 units @ $10 = $1,000
      // Actual: 100 units @ $12 = $1,200
      // Price Variance = ($12 - $10) × 100 = $200 (Unfavorable)

      final result = StandardCostingService.calculateMaterialVariance(
        actualQuantity: 100.0,
        actualPrice: 1200, // $12.00
        standardQuantity: 100.0,
        standardPrice: 1000, // $10.00
      );

      expect(result.priceVariance, equals(20000)); // $200.00
      expect(result.priceVarianceFavorable, isFalse);
    });

    test('should calculate favorable quantity variance (used less)', () {
      // Standard: 100 units allowed @ $5
      // Actual: 90 units used @ $5
      // Quantity Variance = (90 - 100) × $5 = -$50 (Favorable)

      final result = StandardCostingService.calculateMaterialVariance(
        actualQuantity: 90.0,
        actualPrice: 500,
        standardQuantity: 100.0,
        standardPrice: 500,
      );

      expect(result.quantityVariance, equals(-5000)); // -$50.00
      expect(result.quantityVarianceFavorable, isTrue);
    });

    test('should calculate unfavorable quantity variance (used more)', () {
      // Standard: 100 units @ $5 = $500
      // Actual: 120 units @ $5 = $600
      // Quantity Variance = (120 - 100) × $5 = $100 (Unfavorable)

      final result = StandardCostingService.calculateMaterialVariance(
        actualQuantity: 120.0,
        actualPrice: 500,
        standardQuantity: 100.0,
        standardPrice: 500,
      );

      expect(result.quantityVariance, equals(10000)); // $100.00
      expect(result.quantityVarianceFavorable, isFalse);
    });

    test('should calculate total variance correctly', () {
      // Textbook Example:
      // Standard: 1,000 lbs @ $3/lb = $3,000
      // Actual: 1,050 lbs @ $2.90/lb = $3,045
      // Total Variance = $3,045 - $3,000 = $45 (U)
      // Price Variance = ($2.90 - $3.00) × 1,050 = -$105 (F)
      // Quantity Variance = (1,050 - 1,000) × $3.00 = $150 (U)

      final result = StandardCostingService.calculateMaterialVariance(
        actualQuantity: 1050.0,
        actualPrice: 290, // $2.90
        standardQuantity: 1000.0,
        standardPrice: 300, // $3.00
      );

      expect(result.actualCost, equals(304500)); // $3,045
      expect(result.standardCost, equals(300000)); // $3,000
      expect(result.totalVariance, equals(4500)); // $45
      expect(result.priceVariance, equals(-10500)); // -$105 (F)
      expect(result.quantityVariance, equals(15000)); // $150 (U)
      // Verify: Price + Quantity = Total
      expect(
        result.priceVariance + result.quantityVariance,
        equals(result.totalVariance),
      );
    });
  });

  group('Direct Labor Variance', () {
    test('should calculate favorable rate variance (lower rate)', () {
      // Standard: 100 hours @ $20/hr = $2,000
      // Actual: 100 hours @ $18/hr = $1,800
      // Rate Variance = ($18 - $20) × 100 = -$200 (Favorable)

      final result = StandardCostingService.calculateLaborVariance(
        actualHours: 100.0,
        actualRate: 1800, // $18.00
        standardHours: 100.0,
        standardRate: 2000, // $20.00
      );

      expect(result.rateVariance, equals(-20000)); // -$200.00
      expect(result.rateVarianceFavorable, isTrue);
      expect(result.efficiencyVariance, equals(0));
    });

    test('should calculate unfavorable rate variance (higher rate)', () {
      final result = StandardCostingService.calculateLaborVariance(
        actualHours: 100.0,
        actualRate: 2500, // $25.00
        standardHours: 100.0,
        standardRate: 2000, // $20.00
      );

      expect(result.rateVariance, equals(50000)); // $500.00
      expect(result.rateVarianceFavorable, isFalse);
    });

    test('should calculate favorable efficiency variance (fewer hours)', () {
      // Standard: 100 hours @ $20/hr
      // Actual: 90 hours @ $20/hr
      // Efficiency Variance = (90 - 100) × $20 = -$200 (Favorable)

      final result = StandardCostingService.calculateLaborVariance(
        actualHours: 90.0,
        actualRate: 2000,
        standardHours: 100.0,
        standardRate: 2000,
      );

      expect(result.efficiencyVariance, equals(-20000)); // -$200.00
      expect(result.efficiencyVarianceFavorable, isTrue);
    });

    test('should calculate unfavorable efficiency variance (more hours)', () {
      final result = StandardCostingService.calculateLaborVariance(
        actualHours: 110.0,
        actualRate: 2000,
        standardHours: 100.0,
        standardRate: 2000,
      );

      expect(result.efficiencyVariance, equals(20000)); // $200.00
      expect(result.efficiencyVarianceFavorable, isFalse);
    });

    test('should verify total = rate + efficiency', () {
      // Textbook Example:
      // Standard: 5,000 hrs @ $12/hr = $60,000
      // Actual: 4,900 hrs @ $12.30/hr = $60,270
      // Total = $270 (U)
      // Rate = ($12.30 - $12.00) × 4,900 = $1,470 (U)
      // Efficiency = (4,900 - 5,000) × $12 = -$1,200 (F)

      final result = StandardCostingService.calculateLaborVariance(
        actualHours: 4900.0,
        actualRate: 1230, // $12.30
        standardHours: 5000.0,
        standardRate: 1200, // $12.00
      );

      expect(result.rateVariance, equals(147000)); // $1,470
      expect(result.efficiencyVariance, equals(-120000)); // -$1,200
      expect(
        result.rateVariance + result.efficiencyVariance,
        equals(result.totalVariance),
      );
    });
  });

  group('Manufacturing Overhead Variance', () {
    test('should calculate variable overhead spending variance', () {
      // Actual VOH = $5,500, Actual hours = 1,000, Standard rate = $5/hr
      // Expected at actual hours = 1,000 × $5 = $5,000
      // Spending Variance = $5,500 - $5,000 = $500 (U)

      final result = StandardCostingService.calculateOverheadVariance(
        actualVariableOverhead: 550000, // $5,500
        actualFixedOverhead: 0,
        actualHours: 1000.0,
        standardHours: 1000.0,
        standardVariableRate: 500, // $5.00/hr
        budgetedFixedOverhead: 0,
        normalCapacityHours: 1000.0,
      );

      expect(result.variableSpendingVariance, equals(50000)); // $500
    });

    test('should calculate variable overhead efficiency variance', () {
      // Actual hours = 1,100, Standard hours = 1,000, Rate = $5/hr
      // Efficiency = (1,100 - 1,000) × $5 = $500 (U)

      final result = StandardCostingService.calculateOverheadVariance(
        actualVariableOverhead: 550000,
        actualFixedOverhead: 0,
        actualHours: 1100.0,
        standardHours: 1000.0,
        standardVariableRate: 500,
        budgetedFixedOverhead: 0,
        normalCapacityHours: 1000.0,
      );

      expect(result.variableEfficiencyVariance, equals(50000)); // $500
    });

    test('should calculate fixed overhead budget variance', () {
      // Budgeted FOH = $10,000, Actual FOH = $10,500
      // Budget Variance = $10,500 - $10,000 = $500 (U)

      final result = StandardCostingService.calculateOverheadVariance(
        actualVariableOverhead: 0,
        actualFixedOverhead: 1050000, // $10,500
        actualHours: 1000.0,
        standardHours: 1000.0,
        standardVariableRate: 0,
        budgetedFixedOverhead: 1000000, // $10,000
        normalCapacityHours: 1000.0,
      );

      expect(result.fixedBudgetVariance, equals(50000)); // $500
    });

    test('should calculate fixed overhead volume variance', () {
      // Budgeted FOH = $10,000, Normal capacity = 1,000 hrs
      // Standard hours allowed = 900 hrs
      // Applied FOH = 900 × ($10,000/1,000) = $9,000
      // Volume Variance = $10,000 - $9,000 = $1,000 (U - underapplied)

      final result = StandardCostingService.calculateOverheadVariance(
        actualVariableOverhead: 0,
        actualFixedOverhead: 1000000,
        actualHours: 900.0,
        standardHours: 900.0,
        standardVariableRate: 0,
        budgetedFixedOverhead: 1000000, // $10,000
        normalCapacityHours: 1000.0,
      );

      expect(result.fixedVolumeVariance, equals(100000)); // $1,000
    });

    test('should identify overapplied overhead', () {
      // Standard hours > Normal = Overapplied
      final result = StandardCostingService.calculateOverheadVariance(
        actualVariableOverhead: 500000,
        actualFixedOverhead: 1000000,
        actualHours: 1100.0,
        standardHours: 1100.0,
        standardVariableRate: 500,
        budgetedFixedOverhead: 1000000,
        normalCapacityHours: 1000.0,
      );

      expect(result.isOverApplied, isTrue);
    });
  });

  group('Standard Quantity/Hours Allowed', () {
    test('should calculate standard quantity allowed', () {
      // 2 lbs per unit × 500 units = 1,000 lbs allowed
      final sqa = StandardCostingService.calculateStandardQuantityAllowed(
        standardQuantityPerUnit: 2.0,
        unitsProduced: 500,
      );

      expect(sqa, equals(1000.0));
    });

    test('should calculate standard hours allowed', () {
      // 0.5 hours per unit × 1,000 units = 500 hours allowed
      final sha = StandardCostingService.calculateStandardHoursAllowed(
        standardHoursPerUnit: 0.5,
        unitsProduced: 1000,
      );

      expect(sha, equals(500.0));
    });
  });

  group('StandardCostCard', () {
    test('should calculate standard cost per unit', () {
      final card = StandardCostCard(
        productId: 'PROD001',
        productName: 'Widget A',
        standardMaterialQuantity: 2.0,
        standardMaterialPrice: 500, // $5.00
        standardLaborHours: 0.5,
        standardLaborRate: 2000, // $20.00/hr
        standardVOHHours: 0.5,
        standardVOHRate: 400, // $4.00/hr
        budgetedFixedOverhead: 1000000, // $10,000
        normalCapacityHours: 1000.0,
      );

      // Materials: 2 × $5 = $10
      // Labor: 0.5 × $20 = $10
      // VOH: 0.5 × $4 = $2
      // FOH: 0.5 × ($10,000/1,000) = 0.5 × $10 = $5
      // Total: $27

      expect(card.standardCostPerUnit, equals(2700)); // $27.00
    });
  });

  group('Complete Variance Report', () {
    test('should generate comprehensive variance report', () {
      final standardCost = StandardCostCard(
        productId: 'PROD001',
        productName: 'Widget',
        standardMaterialQuantity: 2.0,
        standardMaterialPrice: 500,
        standardLaborHours: 1.0,
        standardLaborRate: 1500,
        standardVOHHours: 1.0,
        standardVOHRate: 300,
        budgetedFixedOverhead: 500000,
        normalCapacityHours: 500.0,
      );

      final report = StandardCostingService.generateVarianceReport(
        standardCost: standardCost,
        unitsProduced: 100,
        actualMaterialQuantity: 210.0, // 5% more
        actualMaterialPrice: 520, // 4% higher
        actualLaborHours: 105.0, // 5% more
        actualLaborRate: 1550, // 3.3% higher
        actualVariableOverhead: 32000, // Slightly higher
        actualFixedOverhead: 100000,
      );

      expect(report.unitsProduced, equals(100));
      expect(report.productId, equals('PROD001'));

      // Material variance populated
      expect(report.materialVariance.totalVariance, isNot(0));

      // Labor variance populated
      expect(report.laborVariance.totalVariance, isNot(0));

      // Overhead variance populated
      expect(report.overheadVariance.actualOverhead, equals(132000));

      // Total variance is sum of all
      expect(
        report.totalVariance,
        equals(
          report.materialVariance.totalVariance +
              report.laborVariance.totalVariance +
              report.overheadVariance.totalVariance,
        ),
      );
    });
  });

  group('Variance Interpretation', () {
    test('should interpret favorable variance', () {
      final text = StandardCostingService.interpretVariance(-10000, true);
      expect(text, contains('Favorable'));
      expect(text, contains('100.00'));
    });

    test('should interpret unfavorable variance', () {
      final text = StandardCostingService.interpretVariance(5000, false);
      expect(text, contains('Unfavorable'));
      expect(text, contains('50.00'));
    });

    test('should handle zero variance', () {
      final text = StandardCostingService.interpretVariance(0, true);
      expect(text, equals('No variance'));
    });
  });

  group('Variance Percentage', () {
    test('should calculate variance percent', () {
      final percent = StandardCostingService.calculateVariancePercent(
        100000, // Standard $1,000
        10000, // Variance $100
      );
      expect(percent, closeTo(0.10, 0.001)); // 10%
    });

    test('should handle zero standard', () {
      final percent = StandardCostingService.calculateVariancePercent(0, 100);
      expect(percent, equals(0));
    });
  });
}
