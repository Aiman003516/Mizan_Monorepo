// FILE: packages/core/core_data/test/beneish_mscore_test.dart
// Purpose: Unit tests for Beneish M-Score fraud detection
// Reference: Messod D. Beneish, "The Detection of Earnings Manipulation" (1999)

import 'package:flutter_test/flutter_test.dart';
import 'package:core_data/src/services/financial_analysis_service.dart';

void main() {
  group('Beneish M-Score Individual Indices', () {
    test('DSRI - should calculate Days Sales in Receivables Index', () {
      // If receivables grow faster than sales, DSRI > 1
      final dsri = BeneishMScore.calculateDSRI(
        currentReceivables: 120000,
        currentRevenue: 1000000,
        priorReceivables: 100000,
        priorRevenue: 1000000,
      );

      expect(dsri, closeTo(1.2, 0.001)); // 20% increase in DSR
    });

    test('DSRI - should detect receivables outpacing sales', () {
      // Current: Receivables grew 50%, Sales grew 20%
      final dsri = BeneishMScore.calculateDSRI(
        currentReceivables: 150000, // +50%
        currentRevenue: 1200000, // +20%
        priorReceivables: 100000,
        priorRevenue: 1000000,
      );

      // (150/1200) / (100/1000) = 0.125 / 0.100 = 1.25
      expect(dsri, closeTo(1.25, 0.001));
    });

    test('GMI - should calculate Gross Margin Index', () {
      // Prior GM = 40%, Current GM = 35%
      // GMI = 0.40 / 0.35 = 1.14 (declining margins)
      final gmi = BeneishMScore.calculateGMI(
        currentRevenue: 1000000,
        currentGrossProfit: 350000, // 35%
        priorRevenue: 1000000,
        priorGrossProfit: 400000, // 40%
      );

      expect(gmi, closeTo(1.143, 0.001));
    });

    test('AQI - should calculate Asset Quality Index', () {
      // Increase in non-current, non-PPE assets
      final aqi = BeneishMScore.calculateAQI(
        currentTotalAssets: 1000000,
        currentCurrentAssets: 300000,
        currentPPE: 500000, // 20% other (non-quality) assets
        priorTotalAssets: 900000,
        priorCurrentAssets: 270000,
        priorPPE: 540000, // 10% other assets
      );

      // Current AQ = 1 - (300+500)/1000 = 0.20
      // Prior AQ = 1 - (270+540)/900 = 0.10
      // AQI = 0.20 / 0.10 = 2.0
      expect(aqi, closeTo(2.0, 0.001));
    });

    test('SGI - should calculate Sales Growth Index', () {
      final sgi = BeneishMScore.calculateSGI(
        currentRevenue: 1200000,
        priorRevenue: 1000000,
      );

      expect(sgi, closeTo(1.2, 0.001)); // 20% growth
    });

    test('DEPI - should calculate Depreciation Index', () {
      // Prior rate = 100/(100+900) = 10%
      // Current rate = 80/(80+920) = 8%
      // DEPI = 0.10 / 0.08 = 1.25 (slowing depreciation)
      final depi = BeneishMScore.calculateDEPI(
        currentDepreciation: 80000,
        currentPPE: 920000,
        priorDepreciation: 100000,
        priorPPE: 900000,
      );

      expect(depi, closeTo(1.25, 0.01));
    });

    test('SGAI - should calculate SG&A Index', () {
      // Current ratio = 200/1000 = 20%
      // Prior ratio = 180/1000 = 18%
      // SGAI = 0.20 / 0.18 = 1.11
      final sgai = BeneishMScore.calculateSGAI(
        currentSGA: 200000,
        currentRevenue: 1000000,
        priorSGA: 180000,
        priorRevenue: 1000000,
      );

      expect(sgai, closeTo(1.111, 0.001));
    });

    test('TATA - should calculate Total Accruals to Total Assets', () {
      // TATA = (Net Income - CFO) / Total Assets
      // High positive means earnings are from accruals, not cash
      final tata = BeneishMScore.calculateTATA(
        currentNetIncome: 100000,
        currentCFO: 50000, // Only 50% cash backing
        currentTotalAssets: 1000000,
      );

      expect(tata, closeTo(0.05, 0.001)); // 5%
    });

    test('TATA - should be negative when CFO exceeds net income', () {
      // Quality earnings - more cash than accounting income
      final tata = BeneishMScore.calculateTATA(
        currentNetIncome: 100000,
        currentCFO: 150000,
        currentTotalAssets: 1000000,
      );

      expect(tata, closeTo(-0.05, 0.001)); // -5% (favorable)
    });

    test('LVGI - should calculate Leverage Index', () {
      // Increasing leverage
      final lvgi = BeneishMScore.calculateLVGI(
        currentLongTermDebt: 400000,
        currentCurrentLiabilities: 200000,
        currentTotalAssets: 1000000, // 60% leverage
        priorLongTermDebt: 350000,
        priorCurrentLiabilities: 150000,
        priorTotalAssets: 1000000, // 50% leverage
      );

      expect(lvgi, closeTo(1.2, 0.001)); // 20% increase in leverage
    });
  });

  group('Beneish M-Score Complete Calculation', () {
    test('should identify LOW risk for healthy company', () {
      // Normal company with proportional metrics
      final result = BeneishMScore.calculate(
        MScoreInput(
          currentRevenue: 1000000,
          currentReceivables: 100000,
          currentGrossProfit: 400000,
          currentTotalAssets: 1000000,
          currentCurrentAssets: 400000,
          currentPPE: 500000,
          currentDepreciation: 50000,
          currentSGA: 200000,
          currentNetIncome: 100000,
          currentCFO: 120000, // Cash > Net Income (quality)
          currentLongTermDebt: 200000,
          currentCurrentLiabilities: 100000,
          priorRevenue: 950000, // 5% growth
          priorReceivables: 95000,
          priorGrossProfit: 380000,
          priorTotalAssets: 950000,
          priorCurrentAssets: 380000,
          priorPPE: 475000,
          priorDepreciation: 47500,
          priorSGA: 190000,
          priorLongTermDebt: 190000,
          priorCurrentLiabilities: 95000,
        ),
      );

      expect(result.riskLevel, equals('LOW'));
      expect(result.isProbableManipulator, isFalse);
      expect(result.mScore, lessThan(-2.22));
    });

    test('should identify HIGH risk for Enron-like company', () {
      // Aggressive metrics that mirror manipulation patterns
      final result = BeneishMScore.calculate(
        MScoreInput(
          currentRevenue: 1500000, // 50% revenue jump
          currentReceivables: 300000, // Receivables tripled
          currentGrossProfit: 300000, // 20% margin (down from 40%)
          currentTotalAssets: 2000000, // Assets doubled
          currentCurrentAssets: 400000,
          currentPPE: 800000, // 40% is "other" (high AQI)
          currentDepreciation: 30000, // Low depreciation
          currentSGA: 350000,
          currentNetIncome: 200000,
          currentCFO: 50000, // Very low cash backing
          currentLongTermDebt: 800000, // High debt
          currentCurrentLiabilities: 400000,
          priorRevenue: 1000000,
          priorReceivables: 100000,
          priorGrossProfit: 400000, // Was 40%
          priorTotalAssets: 1000000,
          priorCurrentAssets: 400000,
          priorPPE: 500000,
          priorDepreciation: 50000,
          priorSGA: 200000,
          priorLongTermDebt: 300000,
          priorCurrentLiabilities: 200000,
        ),
      );

      expect(result.riskLevel, equals('HIGH'));
      expect(result.isProbableManipulator, isTrue);
      expect(result.mScore, greaterThan(-1.78));
      expect(result.redFlags, isNotEmpty);
    });

    test('should generate appropriate red flags', () {
      final result = BeneishMScore.calculate(
        MScoreInput(
          currentRevenue: 1500000,
          currentReceivables: 250000, // High receivables
          currentGrossProfit: 300000, // Declining margin
          currentTotalAssets: 1500000,
          currentCurrentAssets: 400000,
          currentPPE: 600000,
          currentDepreciation: 30000,
          currentSGA: 250000,
          currentNetIncome: 150000,
          currentCFO: 50000, // Low cash
          currentLongTermDebt: 500000,
          currentCurrentLiabilities: 300000,
          priorRevenue: 1000000,
          priorReceivables: 100000,
          priorGrossProfit: 400000,
          priorTotalAssets: 1000000,
          priorCurrentAssets: 400000,
          priorPPE: 500000,
          priorDepreciation: 50000,
          priorSGA: 180000,
          priorLongTermDebt: 300000,
          priorCurrentLiabilities: 200000,
        ),
      );

      // Should have DSRI flag (receivables growing faster than sales)
      expect(result.redFlags.any((f) => f.contains('DSRI')), isTrue);
      // Should have TATA flag (low cash backing)
      expect(result.redFlags.any((f) => f.contains('TATA')), isTrue);
      // Should have SGI flag (50% growth)
      expect(result.redFlags.any((f) => f.contains('SGI')), isTrue);
    });
  });

  group('M-Score Edge Cases', () {
    test('should handle zero values gracefully', () {
      final result = BeneishMScore.calculate(
        MScoreInput(
          currentRevenue: 0,
          currentReceivables: 0,
          currentGrossProfit: 0,
          currentTotalAssets: 1000000,
          currentCurrentAssets: 0,
          currentPPE: 0,
          currentDepreciation: 0,
          currentSGA: 0,
          currentNetIncome: 0,
          currentCFO: 0,
          currentLongTermDebt: 0,
          currentCurrentLiabilities: 0,
          priorRevenue: 0,
          priorReceivables: 0,
          priorGrossProfit: 0,
          priorTotalAssets: 1000000,
          priorCurrentAssets: 0,
          priorPPE: 0,
          priorDepreciation: 0,
          priorSGA: 0,
          priorLongTermDebt: 0,
          priorCurrentLiabilities: 0,
        ),
      );

      // Should not throw and should return neutral indices
      expect(result.dsri, equals(1.0));
      expect(result.gmi, equals(1.0));
      expect(result.sgi, equals(1.0));
      expect(result.mScore.isFinite, isTrue);
    });

    test('should handle identical periods (no change)', () {
      final result = BeneishMScore.calculate(
        MScoreInput(
          currentRevenue: 1000000,
          currentReceivables: 100000,
          currentGrossProfit: 400000,
          currentTotalAssets: 1000000,
          currentCurrentAssets: 400000,
          currentPPE: 500000,
          currentDepreciation: 50000,
          currentSGA: 200000,
          currentNetIncome: 100000,
          currentCFO: 100000,
          currentLongTermDebt: 300000,
          currentCurrentLiabilities: 200000,
          priorRevenue: 1000000,
          priorReceivables: 100000,
          priorGrossProfit: 400000,
          priorTotalAssets: 1000000,
          priorCurrentAssets: 400000,
          priorPPE: 500000,
          priorDepreciation: 50000,
          priorSGA: 200000,
          priorLongTermDebt: 300000,
          priorCurrentLiabilities: 200000,
        ),
      );

      // All indices should be 1.0 (neutral)
      expect(result.dsri, closeTo(1.0, 0.001));
      expect(result.gmi, closeTo(1.0, 0.001));
      expect(result.aqi, closeTo(1.0, 0.001));
      expect(result.sgi, closeTo(1.0, 0.001));
      expect(result.depi, closeTo(1.0, 0.001));
      expect(result.sgai, closeTo(1.0, 0.001));
      expect(result.lvgi, closeTo(1.0, 0.001));
      expect(result.tata, closeTo(0.0, 0.001)); // No accruals
    });
  });

  group('Simplified M-Score', () {
    test('should calculate 5-variable model', () {
      final simplifiedScore = BeneishMScore.calculateSimplifiedMScore(
        dsri: 1.0,
        gmi: 1.0,
        aqi: 1.0,
        sgi: 1.0,
        tata: 0.0,
      );

      // With all neutral values:
      // -6.065 + 0.823 + 0.906 + 0.593 + 0.717 + 0 = -3.026
      expect(simplifiedScore, closeTo(-3.026, 0.01));
    });
  });

  group('M-Score Threshold Constants', () {
    test('manipulation threshold should be -1.78', () {
      expect(BeneishMScoreResult.manipulationThreshold, equals(-1.78));
    });
  });
}
