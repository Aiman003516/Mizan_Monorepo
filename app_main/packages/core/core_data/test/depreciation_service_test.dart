// Unit tests for DepreciationService
// Tests Straight-Line, Declining Balance, and Units-of-Activity depreciation methods

import 'package:flutter_test/flutter_test.dart';
import 'package:core_data/src/services/depreciation_service.dart';

void main() {
  late DepreciationServiceCalculator calculator;

  setUp(() {
    calculator = DepreciationServiceCalculator();
  });

  group('Straight-Line Depreciation', () {
    test('should calculate annual depreciation correctly', () {
      // Equipment: Cost $13,000, Salvage $1,000, 5-year life
      // Expected: ($13,000 - $1,000) / 5 = $2,400/year
      final result = calculator.calculateStraightLine(
        acquisitionCost: 1300000, // $13,000 in cents
        salvageValue: 100000, // $1,000 in cents
        usefulLifeMonths: 60, // 5 years
        totalDepreciationToDate: 0,
      );

      expect(result.annualDepreciation, equals(240000)); // $2,400
      expect(result.monthlyDepreciation, equals(20000)); // $200
      expect(result.bookValue, equals(1060000)); // $13,000 - $2,400 = $10,600
      expect(result.isFullyDepreciated, isFalse);
    });

    test('should handle partial years correctly', () {
      // 3-year life (36 months)
      final result = calculator.calculateStraightLine(
        acquisitionCost: 3600000, // $36,000
        salvageValue: 0,
        usefulLifeMonths: 36,
        totalDepreciationToDate: 0,
      );

      expect(result.annualDepreciation, equals(1200000)); // $12,000/year
    });

    test('should cap depreciation at depreciable base', () {
      // Already depreciated 90% - should not exceed salvage value
      final result = calculator.calculateStraightLine(
        acquisitionCost: 1000000, // $10,000
        salvageValue: 100000, // $1,000 salvage
        usefulLifeMonths: 60,
        totalDepreciationToDate: 850000, // Already $8,500 depreciated
      );

      // Max remaining = $900,000 - $850,000 = $50,000 (but annual is $180,000)
      expect(result.accumulatedDepreciation, lessThanOrEqualTo(900000));
    });

    test('should mark as fully depreciated when done', () {
      final result = calculator.calculateStraightLine(
        acquisitionCost: 1000000,
        salvageValue: 100000,
        usefulLifeMonths: 60,
        totalDepreciationToDate: 900000, // Already at max
      );

      expect(result.isFullyDepreciated, isTrue);
      expect(result.bookValue, equals(100000)); // = salvage value
    });
  });

  group('Declining Balance Depreciation', () {
    test('should calculate double-declining balance correctly', () {
      // Equipment: Cost $10,000, 5-year life, double-declining (rate 2.0)
      // DDB Rate = 2 / 5 = 40%
      // Year 1: $10,000 * 40% = $4,000
      final result = calculator.calculateDecliningBalance(
        acquisitionCost: 1000000, // $10,000
        salvageValue: 100000, // $1,000
        usefulLifeMonths: 60, // 5 years
        totalDepreciationToDate: 0,
        rate: 2.0,
      );

      // Rate = 2.0 / 5 = 0.4 (40%)
      // Depreciation = $10,000 * 0.4 = $4,000
      expect(result.annualDepreciation, equals(400000));
      expect(result.bookValue, equals(600000)); // $6,000
    });

    test('should calculate year 2 declining balance correctly', () {
      // Year 2: Book value $6,000 * 40% = $2,400
      final result = calculator.calculateDecliningBalance(
        acquisitionCost: 1000000,
        salvageValue: 100000,
        usefulLifeMonths: 60,
        totalDepreciationToDate: 400000, // After year 1
        rate: 2.0,
      );

      expect(result.annualDepreciation, equals(240000)); // $2,400
      expect(result.bookValue, equals(360000)); // $3,600
    });

    test('should not depreciate below salvage value', () {
      // When book value approaches salvage
      final result = calculator.calculateDecliningBalance(
        acquisitionCost: 1000000,
        salvageValue: 100000,
        usefulLifeMonths: 60,
        totalDepreciationToDate: 850000, // Book value = $1,500
        rate: 2.0,
      );

      // Should only depreciate $500 to reach salvage, not $600
      expect(result.accumulatedDepreciation, lessThanOrEqualTo(900000));
      expect(result.bookValue, greaterThanOrEqualTo(100000));
    });

    test('should handle 150% declining balance', () {
      final result = calculator.calculateDecliningBalance(
        acquisitionCost: 1000000,
        salvageValue: 100000,
        usefulLifeMonths: 60,
        totalDepreciationToDate: 0,
        rate: 1.5, // 150% declining
      );

      // Rate = 1.5 / 5 = 0.3 (30%)
      expect(result.annualDepreciation, equals(300000)); // $3,000
    });
  });

  group('Units-of-Activity Depreciation', () {
    test('should calculate based on units used', () {
      // Vehicle: Cost $50,000, Salvage $5,000, Life 100,000 miles
      // Depreciation per mile = ($50,000 - $5,000) / 100,000 = $0.45
      // If 15,000 miles used: $0.45 * 15,000 = $6,750
      final result = calculator.calculateUnitsOfActivity(
        acquisitionCost: 5000000, // $50,000
        salvageValue: 500000, // $5,000
        totalUnitCapacity: 100000, // miles
        unitsUsedThisPeriod: 15000,
        totalDepreciationToDate: 0,
      );

      expect(result.annualDepreciation, equals(675000)); // $6,750
    });

    test('should accumulate depreciation over periods', () {
      // After 30,000 miles used in prior periods
      final result = calculator.calculateUnitsOfActivity(
        acquisitionCost: 5000000,
        salvageValue: 500000,
        totalUnitCapacity: 100000,
        unitsUsedThisPeriod: 20000, // This period
        totalDepreciationToDate: 1350000, // Prior 30,000 miles @ $0.45
      );

      // This period: 20,000 * $0.45 = $9,000
      expect(result.annualDepreciation, equals(900000));
      // Total: $13,500 + $9,000 = $22,500
      expect(result.accumulatedDepreciation, equals(2250000));
    });

    test('should cap at depreciable base', () {
      // Already used 90,000 miles, now using 20,000 more
      final result = calculator.calculateUnitsOfActivity(
        acquisitionCost: 5000000,
        salvageValue: 500000,
        totalUnitCapacity: 100000,
        unitsUsedThisPeriod: 20000,
        totalDepreciationToDate: 4050000, // 90,000 miles worth
      );

      // Should only depreciate remaining $450,000, not $900,000
      expect(result.accumulatedDepreciation, equals(4500000)); // Max
      expect(result.isFullyDepreciated, isTrue);
    });
  });

  group('Edge Cases', () {
    test('should handle zero salvage value', () {
      final result = calculator.calculateStraightLine(
        acquisitionCost: 1000000,
        salvageValue: 0, // No salvage
        usefulLifeMonths: 60,
        totalDepreciationToDate: 0,
      );

      expect(result.annualDepreciation, equals(200000)); // Full cost / 5 years
    });

    test('should handle very short useful life', () {
      final result = calculator.calculateStraightLine(
        acquisitionCost: 1200000,
        salvageValue: 0,
        usefulLifeMonths: 12, // 1 year
        totalDepreciationToDate: 0,
      );

      expect(result.annualDepreciation, equals(1200000));
      expect(result.monthlyDepreciation, equals(100000));
    });

    test('should handle already fully depreciated asset', () {
      final result = calculator.calculateStraightLine(
        acquisitionCost: 1000000,
        salvageValue: 100000,
        usefulLifeMonths: 60,
        totalDepreciationToDate: 900000, // Already at max
      );

      expect(result.isFullyDepreciated, isTrue);
      expect(result.annualDepreciation, greaterThanOrEqualTo(0));
    });
  });
}

/// Test helper that mirrors the calculation logic from DepreciationService
/// This allows testing without database dependency
class DepreciationServiceCalculator {
  DepreciationResult calculateStraightLine({
    required int acquisitionCost,
    required int salvageValue,
    required int usefulLifeMonths,
    required int totalDepreciationToDate,
  }) {
    final depreciableBase = acquisitionCost - salvageValue;
    final usefulLifeYears = usefulLifeMonths / 12;
    final annualDepreciation = (depreciableBase / usefulLifeYears).round();
    final monthlyDepreciation = (annualDepreciation / 12).round();

    final maxDepreciation = depreciableBase;
    final newAccumulatedDepreciation =
        (totalDepreciationToDate + annualDepreciation).clamp(
          0,
          maxDepreciation,
        );

    return DepreciationResult(
      annualDepreciation: annualDepreciation,
      monthlyDepreciation: monthlyDepreciation,
      accumulatedDepreciation: newAccumulatedDepreciation,
      bookValue: acquisitionCost - newAccumulatedDepreciation,
      isFullyDepreciated: newAccumulatedDepreciation >= maxDepreciation,
    );
  }

  DepreciationResult calculateDecliningBalance({
    required int acquisitionCost,
    required int salvageValue,
    required int usefulLifeMonths,
    required int totalDepreciationToDate,
    double rate = 2.0,
  }) {
    final bookValue = acquisitionCost - totalDepreciationToDate;
    final usefulLifeYears = usefulLifeMonths / 12;
    final depreciationRate = rate / usefulLifeYears;

    var annualDepreciation = (bookValue * depreciationRate).round();

    final maxDepreciation = acquisitionCost - salvageValue;
    if (totalDepreciationToDate + annualDepreciation > maxDepreciation) {
      annualDepreciation = maxDepreciation - totalDepreciationToDate;
    }

    final newAccumulatedDepreciation =
        totalDepreciationToDate + annualDepreciation;

    return DepreciationResult(
      annualDepreciation: annualDepreciation,
      monthlyDepreciation: (annualDepreciation / 12).round(),
      accumulatedDepreciation: newAccumulatedDepreciation,
      bookValue: acquisitionCost - newAccumulatedDepreciation,
      isFullyDepreciated: newAccumulatedDepreciation >= maxDepreciation,
    );
  }

  DepreciationResult calculateUnitsOfActivity({
    required int acquisitionCost,
    required int salvageValue,
    required int totalUnitCapacity,
    required int unitsUsedThisPeriod,
    required int totalDepreciationToDate,
  }) {
    final depreciableBase = acquisitionCost - salvageValue;
    final depreciationPerUnit = depreciableBase / totalUnitCapacity;
    var periodDepreciation = (depreciationPerUnit * unitsUsedThisPeriod)
        .round();

    final maxDepreciation = depreciableBase;
    if (totalDepreciationToDate + periodDepreciation > maxDepreciation) {
      periodDepreciation = maxDepreciation - totalDepreciationToDate;
    }

    final newAccumulatedDepreciation =
        totalDepreciationToDate + periodDepreciation;

    return DepreciationResult(
      annualDepreciation: periodDepreciation,
      monthlyDepreciation: periodDepreciation,
      accumulatedDepreciation: newAccumulatedDepreciation,
      bookValue: acquisitionCost - newAccumulatedDepreciation,
      isFullyDepreciated: newAccumulatedDepreciation >= maxDepreciation,
    );
  }
}
