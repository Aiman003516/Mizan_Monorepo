// FILE: packages/core/core_data/lib/src/services/cvp_analysis_service.dart
// Purpose: Cost-Volume-Profit Analysis for managerial decision-making
// Reference: Accounting Principles 13e (Weygandt), Chapter 22 - Cost-Volume-Profit Analysis

import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================================================
// DATA CLASSES
// ============================================================================

/// Result of break-even analysis
class BreakEvenResult {
  final int breakEvenUnits;
  final int breakEvenSales; // In cents/smallest currency unit
  final int contributionMarginPerUnit;
  final double contributionMarginRatio;

  const BreakEvenResult({
    required this.breakEvenUnits,
    required this.breakEvenSales,
    required this.contributionMarginPerUnit,
    required this.contributionMarginRatio,
  });

  @override
  String toString() =>
      'BreakEvenResult(units: $breakEvenUnits, sales: $breakEvenSales, '
      'cmPerUnit: $contributionMarginPerUnit, cmRatio: ${(contributionMarginRatio * 100).toStringAsFixed(1)}%)';
}

/// Result of target profit analysis
class TargetProfitResult {
  final int requiredUnits;
  final int requiredSales; // In cents
  final int targetProfit;
  final int totalContributionMargin;

  const TargetProfitResult({
    required this.requiredUnits,
    required this.requiredSales,
    required this.targetProfit,
    required this.totalContributionMargin,
  });
}

/// Margin of safety analysis
class MarginOfSafetyResult {
  final int marginOfSafetyDollars; // In cents
  final int marginOfSafetyUnits;
  final double marginOfSafetyRatio;
  final String riskLevel; // 'LOW', 'MODERATE', 'HIGH'

  const MarginOfSafetyResult({
    required this.marginOfSafetyDollars,
    required this.marginOfSafetyUnits,
    required this.marginOfSafetyRatio,
    required this.riskLevel,
  });
}

/// Operating leverage analysis
class OperatingLeverageResult {
  final double degreeOfOperatingLeverage;
  final String leverageLevel; // 'LOW', 'MODERATE', 'HIGH'
  final double impactMultiplier; // % change in income per 1% change in sales

  const OperatingLeverageResult({
    required this.degreeOfOperatingLeverage,
    required this.leverageLevel,
    required this.impactMultiplier,
  });
}

/// Sensitivity analysis result
class SensitivityAnalysisResult {
  final List<SensitivityScenario> scenarios;
  final int baseBreakEvenUnits;
  final int baseBreakEvenSales;

  const SensitivityAnalysisResult({
    required this.scenarios,
    required this.baseBreakEvenUnits,
    required this.baseBreakEvenSales,
  });
}

/// Individual scenario in sensitivity analysis
class SensitivityScenario {
  final String name;
  final double changePercent;
  final int breakEvenUnits;
  final int breakEvenSales;
  final int changeFromBase;

  const SensitivityScenario({
    required this.name,
    required this.changePercent,
    required this.breakEvenUnits,
    required this.breakEvenSales,
    required this.changeFromBase,
  });
}

/// Multi-product CVP analysis result
class MultiProductCVPResult {
  final int weightedBreakEvenUnits;
  final int weightedBreakEvenSales;
  final double weightedCMRatio;
  final List<ProductBreakdown> productBreakdowns;

  const MultiProductCVPResult({
    required this.weightedBreakEvenUnits,
    required this.weightedBreakEvenSales,
    required this.weightedCMRatio,
    required this.productBreakdowns,
  });
}

/// Product breakdown for multi-product CVP
class ProductBreakdown {
  final String productName;
  final int breakEvenUnits;
  final double salesMixPercent;
  final int contributionMarginPerUnit;

  const ProductBreakdown({
    required this.productName,
    required this.breakEvenUnits,
    required this.salesMixPercent,
    required this.contributionMarginPerUnit,
  });
}

/// Input for multi-product CVP analysis
class ProductCVPInput {
  final String productName;
  final int unitSellingPrice; // In cents
  final int variableCostPerUnit; // In cents
  final double salesMixPercent; // 0.0 to 1.0

  const ProductCVPInput({
    required this.productName,
    required this.unitSellingPrice,
    required this.variableCostPerUnit,
    required this.salesMixPercent,
  });

  int get contributionMarginPerUnit => unitSellingPrice - variableCostPerUnit;
}

// ============================================================================
// SERVICE
// ============================================================================

/// Service for Cost-Volume-Profit (CVP) Analysis
/// Provides break-even, target profit, and operating leverage calculations
///
/// Reference: Accounting Principles 13e (Weygandt), Chapter 22
class CVPAnalysisService {
  // ========================================================================
  // CONTRIBUTION MARGIN CALCULATIONS
  // ========================================================================

  /// Calculate Contribution Margin per Unit
  /// CM per Unit = Unit Selling Price - Variable Cost per Unit
  int calculateContributionMarginPerUnit({
    required int unitSellingPrice,
    required int variableCostPerUnit,
  }) {
    return unitSellingPrice - variableCostPerUnit;
  }

  /// Calculate Total Contribution Margin
  /// Total CM = (Unit Selling Price - Variable Cost) × Units Sold
  int calculateTotalContributionMargin({
    required int unitSellingPrice,
    required int variableCostPerUnit,
    required int unitsSold,
  }) {
    final cmPerUnit = unitSellingPrice - variableCostPerUnit;
    return cmPerUnit * unitsSold;
  }

  /// Calculate Contribution Margin Ratio
  /// CM Ratio = Contribution Margin / Sales (or CM per Unit / Price)
  ///
  /// Returns value between 0.0 and 1.0
  double calculateContributionMarginRatio({
    required int unitSellingPrice,
    required int variableCostPerUnit,
  }) {
    if (unitSellingPrice == 0) return 0;
    final cmPerUnit = unitSellingPrice - variableCostPerUnit;
    return cmPerUnit / unitSellingPrice;
  }

  // ========================================================================
  // BREAK-EVEN ANALYSIS
  // ========================================================================

  /// Calculate Break-Even Point in Units
  /// Break-Even Units = Fixed Costs / Contribution Margin per Unit
  ///
  /// Returns the number of units that must be sold to break even
  int calculateBreakEvenUnits({
    required int fixedCosts,
    required int unitSellingPrice,
    required int variableCostPerUnit,
  }) {
    final cmPerUnit = unitSellingPrice - variableCostPerUnit;
    if (cmPerUnit <= 0) return 0; // Cannot break even with negative/zero CM
    // Round up - you can't sell partial units
    return (fixedCosts / cmPerUnit).ceil();
  }

  /// Calculate Break-Even Point in Sales Dollars
  /// Break-Even Sales = Fixed Costs / Contribution Margin Ratio
  ///
  /// Returns the sales revenue needed to break even (in cents)
  int calculateBreakEvenSales({
    required int fixedCosts,
    required int unitSellingPrice,
    required int variableCostPerUnit,
  }) {
    final cmRatio = calculateContributionMarginRatio(
      unitSellingPrice: unitSellingPrice,
      variableCostPerUnit: variableCostPerUnit,
    );
    if (cmRatio <= 0) return 0;
    return (fixedCosts / cmRatio).round();
  }

  /// Complete Break-Even Analysis
  /// Returns all break-even metrics in one result
  BreakEvenResult analyzeBreakEven({
    required int fixedCosts,
    required int unitSellingPrice,
    required int variableCostPerUnit,
  }) {
    final cmPerUnit = unitSellingPrice - variableCostPerUnit;
    final cmRatio = calculateContributionMarginRatio(
      unitSellingPrice: unitSellingPrice,
      variableCostPerUnit: variableCostPerUnit,
    );
    final breakEvenUnits = calculateBreakEvenUnits(
      fixedCosts: fixedCosts,
      unitSellingPrice: unitSellingPrice,
      variableCostPerUnit: variableCostPerUnit,
    );
    final breakEvenSales = calculateBreakEvenSales(
      fixedCosts: fixedCosts,
      unitSellingPrice: unitSellingPrice,
      variableCostPerUnit: variableCostPerUnit,
    );

    return BreakEvenResult(
      breakEvenUnits: breakEvenUnits,
      breakEvenSales: breakEvenSales,
      contributionMarginPerUnit: cmPerUnit,
      contributionMarginRatio: cmRatio,
    );
  }

  // ========================================================================
  // TARGET PROFIT ANALYSIS
  // ========================================================================

  /// Calculate Required Units for Target Profit
  /// Required Units = (Fixed Costs + Target Profit) / CM per Unit
  int calculateTargetProfitUnits({
    required int fixedCosts,
    required int targetProfit,
    required int unitSellingPrice,
    required int variableCostPerUnit,
  }) {
    final cmPerUnit = unitSellingPrice - variableCostPerUnit;
    if (cmPerUnit <= 0) return 0;
    return ((fixedCosts + targetProfit) / cmPerUnit).ceil();
  }

  /// Calculate Required Sales for Target Profit
  /// Required Sales = (Fixed Costs + Target Profit) / CM Ratio
  int calculateTargetProfitSales({
    required int fixedCosts,
    required int targetProfit,
    required int unitSellingPrice,
    required int variableCostPerUnit,
  }) {
    final cmRatio = calculateContributionMarginRatio(
      unitSellingPrice: unitSellingPrice,
      variableCostPerUnit: variableCostPerUnit,
    );
    if (cmRatio <= 0) return 0;
    return ((fixedCosts + targetProfit) / cmRatio).round();
  }

  /// Complete Target Profit Analysis
  TargetProfitResult analyzeTargetProfit({
    required int fixedCosts,
    required int targetProfit,
    required int unitSellingPrice,
    required int variableCostPerUnit,
  }) {
    final requiredUnits = calculateTargetProfitUnits(
      fixedCosts: fixedCosts,
      targetProfit: targetProfit,
      unitSellingPrice: unitSellingPrice,
      variableCostPerUnit: variableCostPerUnit,
    );
    final requiredSales = calculateTargetProfitSales(
      fixedCosts: fixedCosts,
      targetProfit: targetProfit,
      unitSellingPrice: unitSellingPrice,
      variableCostPerUnit: variableCostPerUnit,
    );
    final cmPerUnit = unitSellingPrice - variableCostPerUnit;
    final totalCM = cmPerUnit * requiredUnits;

    return TargetProfitResult(
      requiredUnits: requiredUnits,
      requiredSales: requiredSales,
      targetProfit: targetProfit,
      totalContributionMargin: totalCM,
    );
  }

  // ========================================================================
  // MARGIN OF SAFETY
  // ========================================================================

  /// Calculate Margin of Safety in Dollars
  /// MOS ($) = Actual (or Expected) Sales - Break-Even Sales
  int calculateMarginOfSafetyDollars({
    required int actualSales,
    required int breakEvenSales,
  }) {
    return actualSales - breakEvenSales;
  }

  /// Calculate Margin of Safety in Units
  /// MOS (Units) = Actual Units - Break-Even Units
  int calculateMarginOfSafetyUnits({
    required int actualUnits,
    required int breakEvenUnits,
  }) {
    return actualUnits - breakEvenUnits;
  }

  /// Calculate Margin of Safety Ratio
  /// MOS Ratio = Margin of Safety / Actual (or Expected) Sales
  ///
  /// A higher ratio indicates lower risk
  double calculateMarginOfSafetyRatio({
    required int actualSales,
    required int breakEvenSales,
  }) {
    if (actualSales == 0) return 0;
    final mos = actualSales - breakEvenSales;
    return mos / actualSales;
  }

  /// Complete Margin of Safety Analysis
  MarginOfSafetyResult analyzeMarginOfSafety({
    required int actualSales,
    required int actualUnits,
    required int fixedCosts,
    required int unitSellingPrice,
    required int variableCostPerUnit,
  }) {
    final breakEvenUnits = calculateBreakEvenUnits(
      fixedCosts: fixedCosts,
      unitSellingPrice: unitSellingPrice,
      variableCostPerUnit: variableCostPerUnit,
    );
    final breakEvenSales = calculateBreakEvenSales(
      fixedCosts: fixedCosts,
      unitSellingPrice: unitSellingPrice,
      variableCostPerUnit: variableCostPerUnit,
    );

    final mosDollars = actualSales - breakEvenSales;
    final mosUnits = actualUnits - breakEvenUnits;
    final mosRatio = actualSales > 0
        ? (actualSales - breakEvenSales) / actualSales
        : 0.0;

    // Risk assessment based on MOS ratio
    final String riskLevel;
    if (mosRatio >= 0.30) {
      riskLevel = 'LOW';
    } else if (mosRatio >= 0.15) {
      riskLevel = 'MODERATE';
    } else {
      riskLevel = 'HIGH';
    }

    return MarginOfSafetyResult(
      marginOfSafetyDollars: mosDollars,
      marginOfSafetyUnits: mosUnits,
      marginOfSafetyRatio: mosRatio,
      riskLevel: riskLevel,
    );
  }

  // ========================================================================
  // OPERATING LEVERAGE
  // ========================================================================

  /// Calculate Degree of Operating Leverage
  /// DOL = Contribution Margin / Operating Income
  ///
  /// Higher DOL means greater sensitivity to sales changes
  double calculateDegreeOfOperatingLeverage({
    required int contributionMargin,
    required int operatingIncome,
  }) {
    if (operatingIncome == 0) return double.infinity;
    return contributionMargin / operatingIncome;
  }

  /// Calculate Operating Leverage from inputs
  OperatingLeverageResult analyzeOperatingLeverage({
    required int actualSales,
    required int variableCosts,
    required int fixedCosts,
  }) {
    final contributionMargin = actualSales - variableCosts;
    final operatingIncome = contributionMargin - fixedCosts;

    final dol = operatingIncome > 0
        ? contributionMargin / operatingIncome
        : 0.0;

    // Leverage level assessment
    final String leverageLevel;
    if (dol >= 5.0) {
      leverageLevel = 'HIGH';
    } else if (dol >= 2.0) {
      leverageLevel = 'MODERATE';
    } else {
      leverageLevel = 'LOW';
    }

    return OperatingLeverageResult(
      degreeOfOperatingLeverage: dol,
      leverageLevel: leverageLevel,
      impactMultiplier: dol, // 1% sales change = DOL% income change
    );
  }

  // ========================================================================
  // SENSITIVITY ANALYSIS (WHAT-IF)
  // ========================================================================

  /// Perform sensitivity analysis on break-even
  /// Calculates how break-even changes with variable adjustments
  SensitivityAnalysisResult performSensitivityAnalysis({
    required int fixedCosts,
    required int unitSellingPrice,
    required int variableCostPerUnit,
    List<double> priceChangePercents = const [-10, -5, 0, 5, 10],
  }) {
    final baseBreakEven = analyzeBreakEven(
      fixedCosts: fixedCosts,
      unitSellingPrice: unitSellingPrice,
      variableCostPerUnit: variableCostPerUnit,
    );

    final scenarios = <SensitivityScenario>[];

    for (final changePercent in priceChangePercents) {
      final adjustedPrice = (unitSellingPrice * (1 + changePercent / 100))
          .round();
      final newBreakEven = calculateBreakEvenUnits(
        fixedCosts: fixedCosts,
        unitSellingPrice: adjustedPrice,
        variableCostPerUnit: variableCostPerUnit,
      );
      final newBreakEvenSales = calculateBreakEvenSales(
        fixedCosts: fixedCosts,
        unitSellingPrice: adjustedPrice,
        variableCostPerUnit: variableCostPerUnit,
      );

      scenarios.add(
        SensitivityScenario(
          name: changePercent >= 0
              ? 'Price +${changePercent.toStringAsFixed(0)}%'
              : 'Price ${changePercent.toStringAsFixed(0)}%',
          changePercent: changePercent,
          breakEvenUnits: newBreakEven,
          breakEvenSales: newBreakEvenSales,
          changeFromBase: newBreakEven - baseBreakEven.breakEvenUnits,
        ),
      );
    }

    return SensitivityAnalysisResult(
      scenarios: scenarios,
      baseBreakEvenUnits: baseBreakEven.breakEvenUnits,
      baseBreakEvenSales: baseBreakEven.breakEvenSales,
    );
  }

  // ========================================================================
  // MULTI-PRODUCT CVP ANALYSIS
  // ========================================================================

  /// Calculate weighted-average break-even for multiple products
  /// Uses sales mix to weight contribution margins
  MultiProductCVPResult analyzeMultiProductCVP({
    required int totalFixedCosts,
    required List<ProductCVPInput> products,
  }) {
    if (products.isEmpty) {
      return const MultiProductCVPResult(
        weightedBreakEvenUnits: 0,
        weightedBreakEvenSales: 0,
        weightedCMRatio: 0,
        productBreakdowns: [],
      );
    }

    // Validate sales mix adds up to 100%
    final totalMix = products.fold<double>(
      0,
      (sum, p) => sum + p.salesMixPercent,
    );
    if ((totalMix - 1.0).abs() > 0.01) {
      // Normalize the mix if it doesn't add up to 1.0
      for (var i = 0; i < products.length; i++) {
        products = [
          ...products.sublist(0, i),
          ProductCVPInput(
            productName: products[i].productName,
            unitSellingPrice: products[i].unitSellingPrice,
            variableCostPerUnit: products[i].variableCostPerUnit,
            salesMixPercent: products[i].salesMixPercent / totalMix,
          ),
          ...products.sublist(i + 1),
        ];
      }
    }

    // Calculate weighted-average CM per unit
    var weightedCMPerUnit = 0.0;
    var weightedPrice = 0.0;
    for (final product in products) {
      weightedCMPerUnit +=
          product.contributionMarginPerUnit * product.salesMixPercent;
      weightedPrice += product.unitSellingPrice * product.salesMixPercent;
    }

    final weightedCMRatio = weightedPrice > 0
        ? weightedCMPerUnit / weightedPrice
        : 0.0;

    // Calculate total break-even units
    final totalBreakEvenUnits = weightedCMPerUnit > 0
        ? (totalFixedCosts / weightedCMPerUnit).ceil()
        : 0;

    // Calculate break-even sales
    final totalBreakEvenSales = weightedCMRatio > 0
        ? (totalFixedCosts / weightedCMRatio).round()
        : 0;

    // Break down by product
    final breakdowns = <ProductBreakdown>[];
    for (final product in products) {
      final productBreakEvenUnits =
          (totalBreakEvenUnits * product.salesMixPercent).round();
      breakdowns.add(
        ProductBreakdown(
          productName: product.productName,
          breakEvenUnits: productBreakEvenUnits,
          salesMixPercent: product.salesMixPercent,
          contributionMarginPerUnit: product.contributionMarginPerUnit,
        ),
      );
    }

    return MultiProductCVPResult(
      weightedBreakEvenUnits: totalBreakEvenUnits,
      weightedBreakEvenSales: totalBreakEvenSales,
      weightedCMRatio: weightedCMRatio,
      productBreakdowns: breakdowns,
    );
  }

  // ========================================================================
  // PROFIT PROJECTION
  // ========================================================================

  /// Calculate projected profit at given sales level
  /// Profit = (Units × CM per Unit) - Fixed Costs
  int calculateProjectedProfit({
    required int projectedUnits,
    required int unitSellingPrice,
    required int variableCostPerUnit,
    required int fixedCosts,
  }) {
    final cmPerUnit = unitSellingPrice - variableCostPerUnit;
    final totalCM = cmPerUnit * projectedUnits;
    return totalCM - fixedCosts;
  }

  /// Calculate projected profit from sales dollars
  /// Profit = (Sales × CM Ratio) - Fixed Costs
  int calculateProjectedProfitFromSales({
    required int projectedSales,
    required double contributionMarginRatio,
    required int fixedCosts,
  }) {
    final totalCM = (projectedSales * contributionMarginRatio).round();
    return totalCM - fixedCosts;
  }
}

// ============================================================================
// PROVIDER
// ============================================================================

/// Provider for CVPAnalysisService
final cvpAnalysisServiceProvider = Provider<CVPAnalysisService>((ref) {
  return CVPAnalysisService();
});
