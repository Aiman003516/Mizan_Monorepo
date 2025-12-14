// FILE: packages/core/core_data/lib/src/services/standard_costing_service.dart
// Purpose: Standard costing and variance analysis calculations
// Reference: Accounting Principles 13e (Weygandt), Chapter 25 - Standard Costs

// ============================================================================
// DATA CLASSES
// ============================================================================

/// Standard cost card for a product
class StandardCostCard {
  final String productId;
  final String productName;

  // Direct Materials
  final double standardMaterialQuantity; // per unit
  final int standardMaterialPrice; // per unit of material (cents)

  // Direct Labor
  final double standardLaborHours; // per unit
  final int standardLaborRate; // per hour (cents)

  // Variable Overhead
  final double standardVOHHours; // activity base (usually labor hours)
  final int standardVOHRate; // per activity unit (cents)

  // Fixed Overhead
  final int budgetedFixedOverhead; // total budgeted (cents)
  final double normalCapacityHours; // denominator for rate

  const StandardCostCard({
    required this.productId,
    required this.productName,
    required this.standardMaterialQuantity,
    required this.standardMaterialPrice,
    required this.standardLaborHours,
    required this.standardLaborRate,
    required this.standardVOHHours,
    required this.standardVOHRate,
    this.budgetedFixedOverhead = 0,
    this.normalCapacityHours = 0,
  });

  /// Standard cost per unit
  int get standardCostPerUnit {
    final materials = (standardMaterialQuantity * standardMaterialPrice)
        .round();
    final labor = (standardLaborHours * standardLaborRate).round();
    final voh = (standardVOHHours * standardVOHRate).round();
    final foh = normalCapacityHours > 0
        ? (budgetedFixedOverhead / normalCapacityHours * standardLaborHours)
              .round()
        : 0;
    return materials + labor + voh + foh;
  }
}

/// Result of direct materials variance analysis
class MaterialVarianceResult {
  final int standardCost; // Should have cost
  final int actualCost; // Actually cost
  final int totalVariance; // Actual - Standard
  final int priceVariance; // (AP - SP) × AQ
  final int quantityVariance; // (AQ - SQ) × SP
  final bool priceVarianceFavorable;
  final bool quantityVarianceFavorable;

  const MaterialVarianceResult({
    required this.standardCost,
    required this.actualCost,
    required this.totalVariance,
    required this.priceVariance,
    required this.quantityVariance,
    required this.priceVarianceFavorable,
    required this.quantityVarianceFavorable,
  });
}

/// Result of direct labor variance analysis
class LaborVarianceResult {
  final int standardCost;
  final int actualCost;
  final int totalVariance;
  final int rateVariance; // (AR - SR) × AH
  final int efficiencyVariance; // (AH - SH) × SR
  final bool rateVarianceFavorable;
  final bool efficiencyVarianceFavorable;

  const LaborVarianceResult({
    required this.standardCost,
    required this.actualCost,
    required this.totalVariance,
    required this.rateVariance,
    required this.efficiencyVariance,
    required this.rateVarianceFavorable,
    required this.efficiencyVarianceFavorable,
  });
}

/// Result of overhead variance analysis
class OverheadVarianceResult {
  final int standardOverhead;
  final int actualOverhead;
  final int totalVariance;

  // Variable Overhead
  final int variableSpendingVariance; // (AH × AR) - (AH × SR)
  final int variableEfficiencyVariance; // (AH - SH) × SR

  // Fixed Overhead
  final int fixedBudgetVariance; // Actual FOH - Budgeted FOH
  final int fixedVolumeVariance; // Budgeted FOH - Applied FOH

  final bool isOverApplied;

  const OverheadVarianceResult({
    required this.standardOverhead,
    required this.actualOverhead,
    required this.totalVariance,
    required this.variableSpendingVariance,
    required this.variableEfficiencyVariance,
    required this.fixedBudgetVariance,
    required this.fixedVolumeVariance,
    required this.isOverApplied,
  });
}

/// Complete variance report for a production run
class ProductionVarianceReport {
  final String productId;
  final int unitsProduced;
  final MaterialVarianceResult materialVariance;
  final LaborVarianceResult laborVariance;
  final OverheadVarianceResult overheadVariance;
  final int totalVariance;
  final DateTime reportDate;

  const ProductionVarianceReport({
    required this.productId,
    required this.unitsProduced,
    required this.materialVariance,
    required this.laborVariance,
    required this.overheadVariance,
    required this.totalVariance,
    required this.reportDate,
  });

  bool get isNetFavorable => totalVariance < 0;
}

// ============================================================================
// SERVICE - STATIC VARIANCE CALCULATIONS
// ============================================================================

/// Standard Costing Service - All methods are static for testability
///
/// Reference: Accounting Principles 13e (Weygandt), Chapter 25
///
/// Key Formulas:
/// - Material Price Variance = (AP - SP) × AQ
/// - Material Quantity Variance = (AQ - SQ) × SP
/// - Labor Rate Variance = (AR - SR) × AH
/// - Labor Efficiency Variance = (AH - SH) × SR
class StandardCostingService {
  StandardCostingService._(); // Private constructor - use static methods

  // ==========================================================================
  // DIRECT MATERIALS VARIANCE
  // ==========================================================================

  /// Calculate direct materials variance
  ///
  /// Inputs (all in cents or actual units):
  /// - actualQuantity: Actual quantity of materials used
  /// - actualPrice: Actual price per unit of material
  /// - standardQuantity: Standard quantity allowed for actual production
  /// - standardPrice: Standard price per unit of material
  ///
  /// Returns MaterialVarianceResult with:
  /// - Price Variance = (AP - SP) × AQ
  /// - Quantity Variance = (AQ - SQ) × SP
  static MaterialVarianceResult calculateMaterialVariance({
    required double actualQuantity,
    required int actualPrice,
    required double standardQuantity,
    required int standardPrice,
  }) {
    final actualCost = (actualQuantity * actualPrice).round();
    final standardCost = (standardQuantity * standardPrice).round();
    final totalVariance = actualCost - standardCost;

    // Price Variance = (AP - SP) × AQ
    // Favorable if AP < SP (paid less than standard)
    final priceVariance = ((actualPrice - standardPrice) * actualQuantity)
        .round();
    final priceVarianceFavorable = priceVariance < 0;

    // Quantity Variance = (AQ - SQ) × SP
    // Favorable if AQ < SQ (used less than standard)
    final quantityVariance =
        ((actualQuantity - standardQuantity) * standardPrice).round();
    final quantityVarianceFavorable = quantityVariance < 0;

    return MaterialVarianceResult(
      standardCost: standardCost,
      actualCost: actualCost,
      totalVariance: totalVariance,
      priceVariance: priceVariance,
      quantityVariance: quantityVariance,
      priceVarianceFavorable: priceVarianceFavorable,
      quantityVarianceFavorable: quantityVarianceFavorable,
    );
  }

  /// Calculate standard quantity allowed for actual output
  static double calculateStandardQuantityAllowed({
    required double standardQuantityPerUnit,
    required int unitsProduced,
  }) {
    return standardQuantityPerUnit * unitsProduced;
  }

  // ==========================================================================
  // DIRECT LABOR VARIANCE
  // ==========================================================================

  /// Calculate direct labor variance
  ///
  /// Inputs:
  /// - actualHours: Actual hours worked
  /// - actualRate: Actual hourly rate (cents)
  /// - standardHours: Standard hours allowed for actual production
  /// - standardRate: Standard hourly rate (cents)
  ///
  /// Returns LaborVarianceResult with:
  /// - Rate Variance = (AR - SR) × AH
  /// - Efficiency Variance = (AH - SH) × SR
  static LaborVarianceResult calculateLaborVariance({
    required double actualHours,
    required int actualRate,
    required double standardHours,
    required int standardRate,
  }) {
    final actualCost = (actualHours * actualRate).round();
    final standardCost = (standardHours * standardRate).round();
    final totalVariance = actualCost - standardCost;

    // Rate Variance = (AR - SR) × AH
    // Favorable if AR < SR (paid lower rate than standard)
    final rateVariance = ((actualRate - standardRate) * actualHours).round();
    final rateVarianceFavorable = rateVariance < 0;

    // Efficiency Variance = (AH - SH) × SR
    // Favorable if AH < SH (worked fewer hours than standard)
    final efficiencyVariance = ((actualHours - standardHours) * standardRate)
        .round();
    final efficiencyVarianceFavorable = efficiencyVariance < 0;

    return LaborVarianceResult(
      standardCost: standardCost,
      actualCost: actualCost,
      totalVariance: totalVariance,
      rateVariance: rateVariance,
      efficiencyVariance: efficiencyVariance,
      rateVarianceFavorable: rateVarianceFavorable,
      efficiencyVarianceFavorable: efficiencyVarianceFavorable,
    );
  }

  /// Calculate standard hours allowed for actual output
  static double calculateStandardHoursAllowed({
    required double standardHoursPerUnit,
    required int unitsProduced,
  }) {
    return standardHoursPerUnit * unitsProduced;
  }

  // ==========================================================================
  // MANUFACTURING OVERHEAD VARIANCE
  // ==========================================================================

  /// Calculate manufacturing overhead variance (4-variance method)
  ///
  /// Variable Overhead:
  /// - Spending Variance = Actual VOH - (AH × SR)
  /// - Efficiency Variance = (AH - SH) × SR
  ///
  /// Fixed Overhead:
  /// - Budget Variance = Actual FOH - Budgeted FOH
  /// - Volume Variance = Budgeted FOH - Applied FOH
  static OverheadVarianceResult calculateOverheadVariance({
    required int actualVariableOverhead,
    required int actualFixedOverhead,
    required double actualHours,
    required double standardHours,
    required int standardVariableRate, // per hour
    required int budgetedFixedOverhead,
    required double normalCapacityHours,
  }) {
    final actualOverhead = actualVariableOverhead + actualFixedOverhead;

    // Calculate standard fixed rate
    final standardFixedRate = normalCapacityHours > 0
        ? (budgetedFixedOverhead / normalCapacityHours).round()
        : 0;

    // Standard overhead applied
    final appliedVariable = (standardHours * standardVariableRate).round();
    final appliedFixed = (standardHours * standardFixedRate).round();
    final standardOverhead = appliedVariable + appliedFixed;

    // Total Variance
    final totalVariance = actualOverhead - standardOverhead;

    // Variable Overhead Variances
    // Spending = Actual VOH - (AH × SR)
    final variableSpendingVariance =
        actualVariableOverhead - (actualHours * standardVariableRate).round();

    // Efficiency = (AH - SH) × SR
    final variableEfficiencyVariance =
        ((actualHours - standardHours) * standardVariableRate).round();

    // Fixed Overhead Variances
    // Budget Variance = Actual FOH - Budgeted FOH
    final fixedBudgetVariance = actualFixedOverhead - budgetedFixedOverhead;

    // Volume Variance = Budgeted FOH - Applied FOH
    final fixedVolumeVariance = budgetedFixedOverhead - appliedFixed;

    // Over/Under applied
    final isOverApplied = totalVariance < 0;

    return OverheadVarianceResult(
      standardOverhead: standardOverhead,
      actualOverhead: actualOverhead,
      totalVariance: totalVariance,
      variableSpendingVariance: variableSpendingVariance,
      variableEfficiencyVariance: variableEfficiencyVariance,
      fixedBudgetVariance: fixedBudgetVariance,
      fixedVolumeVariance: fixedVolumeVariance,
      isOverApplied: isOverApplied,
    );
  }

  // ==========================================================================
  // COMPLETE PRODUCTION VARIANCE REPORT
  // ==========================================================================

  /// Generate a complete variance report for a production run
  static ProductionVarianceReport generateVarianceReport({
    required StandardCostCard standardCost,
    required int unitsProduced,
    required double actualMaterialQuantity,
    required int actualMaterialPrice,
    required double actualLaborHours,
    required int actualLaborRate,
    required int actualVariableOverhead,
    required int actualFixedOverhead,
  }) {
    // Calculate standard quantities allowed
    final standardQuantityAllowed = calculateStandardQuantityAllowed(
      standardQuantityPerUnit: standardCost.standardMaterialQuantity,
      unitsProduced: unitsProduced,
    );

    final standardHoursAllowed = calculateStandardHoursAllowed(
      standardHoursPerUnit: standardCost.standardLaborHours,
      unitsProduced: unitsProduced,
    );

    // Calculate variances
    final materialVariance = calculateMaterialVariance(
      actualQuantity: actualMaterialQuantity,
      actualPrice: actualMaterialPrice,
      standardQuantity: standardQuantityAllowed,
      standardPrice: standardCost.standardMaterialPrice,
    );

    final laborVariance = calculateLaborVariance(
      actualHours: actualLaborHours,
      actualRate: actualLaborRate,
      standardHours: standardHoursAllowed,
      standardRate: standardCost.standardLaborRate,
    );

    final overheadVariance = calculateOverheadVariance(
      actualVariableOverhead: actualVariableOverhead,
      actualFixedOverhead: actualFixedOverhead,
      actualHours: actualLaborHours,
      standardHours: standardHoursAllowed,
      standardVariableRate: standardCost.standardVOHRate,
      budgetedFixedOverhead: standardCost.budgetedFixedOverhead,
      normalCapacityHours: standardCost.normalCapacityHours,
    );

    final totalVariance =
        materialVariance.totalVariance +
        laborVariance.totalVariance +
        overheadVariance.totalVariance;

    return ProductionVarianceReport(
      productId: standardCost.productId,
      unitsProduced: unitsProduced,
      materialVariance: materialVariance,
      laborVariance: laborVariance,
      overheadVariance: overheadVariance,
      totalVariance: totalVariance,
      reportDate: DateTime.now(),
    );
  }

  // ==========================================================================
  // HELPER: VARIANCE ANALYSIS INTERPRETATION
  // ==========================================================================

  /// Get text interpretation of a variance
  static String interpretVariance(int variance, bool isFavorable) {
    if (variance == 0) return 'No variance';
    final direction = isFavorable ? 'Favorable' : 'Unfavorable';
    return '$direction variance of \$${(variance.abs() / 100).toStringAsFixed(2)}';
  }

  /// Calculate variance percentage
  static double calculateVariancePercent(int standard, int variance) {
    if (standard == 0) return 0;
    return variance / standard;
  }
}
