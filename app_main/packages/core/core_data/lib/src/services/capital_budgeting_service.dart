// FILE: packages/core/core_data/lib/src/services/capital_budgeting_service.dart
// Purpose: Capital budgeting decision tools (NPV, IRR, Payback, PI)
// Reference: Accounting Principles 13e (Weygandt), Chapter 26 - Capital Budgeting

import 'tvm_calculator_service.dart';

/// Capital Budgeting Service
/// Provides investment analysis tools for evaluating capital projects
class CapitalBudgetingService {
  // ============================================================================
  // NET PRESENT VALUE (NPV)
  // ============================================================================

  /// Calculate Net Present Value
  /// NPV = Σ [Cash Flow_t / (1 + r)^t] - Initial Investment
  ///
  /// Decision Rule: Accept if NPV > 0
  ///
  /// [initialInvestment] - Initial cash outflow (positive number)
  /// [cashFlows] - List of expected cash inflows for each period
  /// [discountRate] - Required rate of return (e.g., 0.10 for 10%)
  static NPVResult calculateNPV({
    required double initialInvestment,
    required List<double> cashFlows,
    required double discountRate,
  }) {
    double pvOfCashFlows = 0;

    for (int t = 0; t < cashFlows.length; t++) {
      final period = t + 1;
      pvOfCashFlows += TVMCalculatorService.presentValueSingle(
        futureValue: cashFlows[t],
        rate: discountRate,
        periods: period,
      );
    }

    final npv = pvOfCashFlows - initialInvestment;

    return NPVResult(
      npv: npv,
      pvOfCashFlows: pvOfCashFlows,
      initialInvestment: initialInvestment,
      discountRate: discountRate,
      isAcceptable: npv > 0,
      recommendation: npv > 0
          ? 'Accept - Project adds value'
          : npv == 0
          ? 'Indifferent - Project breaks even'
          : 'Reject - Project destroys value',
    );
  }

  // ============================================================================
  // INTERNAL RATE OF RETURN (IRR)
  // ============================================================================

  /// Calculate Internal Rate of Return
  /// IRR is the discount rate that makes NPV = 0
  /// Uses Newton-Raphson iterative method
  ///
  /// Decision Rule: Accept if IRR > Required Return
  ///
  /// [initialInvestment] - Initial cash outflow (positive number)
  /// [cashFlows] - List of expected cash inflows for each period
  /// [guess] - Initial guess for IRR (default 0.10)
  static IRRResult calculateIRR({
    required double initialInvestment,
    required List<double> cashFlows,
    double guess = 0.10,
    double tolerance = 0.0001,
    int maxIterations = 100,
  }) {
    // All cash flows including initial investment (negative)
    final allCashFlows = [-initialInvestment, ...cashFlows];

    double rate = guess;

    for (int iteration = 0; iteration < maxIterations; iteration++) {
      double npv = 0;
      double derivative = 0;

      for (int t = 0; t < allCashFlows.length; t++) {
        final cf = allCashFlows[t];
        npv += cf / _pow(1 + rate, t);
        if (t > 0) {
          derivative -= t * cf / _pow(1 + rate, t + 1);
        }
      }

      if (derivative == 0) break;

      final newRate = rate - npv / derivative;

      if ((newRate - rate).abs() < tolerance) {
        return IRRResult(
          irr: newRate,
          iterations: iteration + 1,
          converged: true,
        );
      }

      rate = newRate;
    }

    return IRRResult(irr: rate, iterations: maxIterations, converged: false);
  }

  // ============================================================================
  // PAYBACK PERIOD
  // ============================================================================

  /// Calculate Simple Payback Period
  /// Time required to recover the initial investment
  ///
  /// [initialInvestment] - Initial cash outflow (positive number)
  /// [cashFlows] - List of expected cash inflows for each period
  static PaybackResult calculatePaybackPeriod({
    required double initialInvestment,
    required List<double> cashFlows,
  }) {
    double cumulativeCashFlow = 0;

    for (int t = 0; t < cashFlows.length; t++) {
      final previousCumulative = cumulativeCashFlow;
      cumulativeCashFlow += cashFlows[t];

      if (cumulativeCashFlow >= initialInvestment) {
        // Interpolate for partial year
        final remainingToRecover = initialInvestment - previousCumulative;
        final fractionOfYear = remainingToRecover / cashFlows[t];
        final paybackYears = t + fractionOfYear;

        return PaybackResult(
          years: paybackYears,
          recoversInvestment: true,
          cumulativeCashFlows: _buildCumulativeList(cashFlows),
        );
      }
    }

    return PaybackResult(
      years: double.infinity,
      recoversInvestment: false,
      cumulativeCashFlows: _buildCumulativeList(cashFlows),
    );
  }

  /// Calculate Discounted Payback Period
  /// Time required to recover initial investment using discounted cash flows
  static PaybackResult calculateDiscountedPaybackPeriod({
    required double initialInvestment,
    required List<double> cashFlows,
    required double discountRate,
  }) {
    // First, discount all cash flows
    final discountedCashFlows = <double>[];
    for (int t = 0; t < cashFlows.length; t++) {
      discountedCashFlows.add(
        TVMCalculatorService.presentValueSingle(
          futureValue: cashFlows[t],
          rate: discountRate,
          periods: t + 1,
        ),
      );
    }

    // Then calculate payback on discounted flows
    return calculatePaybackPeriod(
      initialInvestment: initialInvestment,
      cashFlows: discountedCashFlows,
    );
  }

  // ============================================================================
  // PROFITABILITY INDEX (PI)
  // ============================================================================

  /// Calculate Profitability Index
  /// PI = PV of Cash Inflows / Initial Investment
  ///
  /// Decision Rule: Accept if PI > 1.0
  static PIResult calculateProfitabilityIndex({
    required double initialInvestment,
    required List<double> cashFlows,
    required double discountRate,
  }) {
    double pvOfCashFlows = 0;

    for (int t = 0; t < cashFlows.length; t++) {
      pvOfCashFlows += TVMCalculatorService.presentValueSingle(
        futureValue: cashFlows[t],
        rate: discountRate,
        periods: t + 1,
      );
    }

    final pi = pvOfCashFlows / initialInvestment;

    return PIResult(
      profitabilityIndex: pi,
      pvOfCashFlows: pvOfCashFlows,
      initialInvestment: initialInvestment,
      isAcceptable: pi > 1.0,
      recommendation: pi > 1.0
          ? 'Accept - Project returns more than cost'
          : pi == 1.0
          ? 'Indifferent - Project breaks even'
          : 'Reject - Project returns less than cost',
    );
  }

  // ============================================================================
  // ANNUAL RATE OF RETURN (ARR)
  // ============================================================================

  /// Calculate Accounting Rate of Return (Simple)
  /// ARR = Expected Annual Net Income / Average Investment
  /// Average Investment = (Initial Investment + Residual Value) / 2
  static ARRResult calculateARR({
    required double expectedAnnualNetIncome,
    required double initialInvestment,
    required double residualValue,
  }) {
    final averageInvestment = (initialInvestment + residualValue) / 2;
    final arr = expectedAnnualNetIncome / averageInvestment;

    return ARRResult(
      arr: arr,
      averageInvestment: averageInvestment,
      expectedAnnualNetIncome: expectedAnnualNetIncome,
    );
  }

  // ============================================================================
  // SENSITIVITY ANALYSIS
  // ============================================================================

  /// Perform sensitivity analysis on NPV
  /// Calculates NPV across a range of discount rates
  static List<SensitivityPoint> npvSensitivityAnalysis({
    required double initialInvestment,
    required List<double> cashFlows,
    required double minRate,
    required double maxRate,
    required double step,
  }) {
    final points = <SensitivityPoint>[];

    for (double rate = minRate; rate <= maxRate; rate += step) {
      final npvResult = calculateNPV(
        initialInvestment: initialInvestment,
        cashFlows: cashFlows,
        discountRate: rate,
      );

      points.add(SensitivityPoint(discountRate: rate, npv: npvResult.npv));
    }

    return points;
  }

  /// Compare multiple projects
  static ProjectComparison compareProjects({
    required List<ProjectInput> projects,
    required double discountRate,
  }) {
    final results = <ProjectAnalysis>[];

    for (final project in projects) {
      final npv = calculateNPV(
        initialInvestment: project.initialInvestment,
        cashFlows: project.cashFlows,
        discountRate: discountRate,
      );

      final irr = calculateIRR(
        initialInvestment: project.initialInvestment,
        cashFlows: project.cashFlows,
      );

      final pi = calculateProfitabilityIndex(
        initialInvestment: project.initialInvestment,
        cashFlows: project.cashFlows,
        discountRate: discountRate,
      );

      final payback = calculatePaybackPeriod(
        initialInvestment: project.initialInvestment,
        cashFlows: project.cashFlows,
      );

      results.add(
        ProjectAnalysis(
          name: project.name,
          npv: npv.npv,
          irr: irr.irr,
          pi: pi.profitabilityIndex,
          paybackYears: payback.years,
        ),
      );
    }

    // Rank by NPV
    results.sort((a, b) => b.npv.compareTo(a.npv));

    return ProjectComparison(
      analyses: results,
      discountRate: discountRate,
      recommendedProject: results.isNotEmpty ? results.first.name : null,
    );
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  static List<double> _buildCumulativeList(List<double> cashFlows) {
    final cumulative = <double>[];
    double running = 0;
    for (final cf in cashFlows) {
      running += cf;
      cumulative.add(running);
    }
    return cumulative;
  }

  static double _pow(double base, num exponent) {
    if (exponent == 0) return 1.0;
    if (exponent is int && exponent < 0) return 1.0 / _pow(base, -exponent);

    double result = 1.0;
    int exp = exponent.toInt();
    double b = base;

    if (exp < 0) {
      b = 1 / base;
      exp = -exp;
    }

    while (exp > 0) {
      if (exp & 1 == 1) result *= b;
      b *= b;
      exp >>= 1;
    }

    // Handle fractional exponent
    if (exponent != exponent.toInt()) {
      final fraction = (exponent - exponent.toInt()).toDouble();
      // Use logarithms for fractional part
      result *= _expFraction(base, fraction);
    }

    return result;
  }

  static double _expFraction(double base, double fraction) {
    if (base <= 0) return 0;
    // x^f = e^(f * ln(x))
    final lnBase = _ln(base);
    return _exp(fraction * lnBase);
  }

  static double _ln(double x) {
    if (x <= 0) return double.negativeInfinity;
    double y = (x - 1) / (x + 1);
    double y2 = y * y;
    double result = 0;
    double term = y;
    for (int i = 1; i <= 50; i += 2) {
      result += term / i;
      term *= y2;
    }
    return 2 * result;
  }

  static double _exp(double x) {
    double result = 1;
    double term = 1;
    for (int n = 1; n <= 50; n++) {
      term *= x / n;
      result += term;
    }
    return result;
  }
}

// ============================================================================
// DATA CLASSES
// ============================================================================

/// Result of NPV calculation
class NPVResult {
  final double npv;
  final double pvOfCashFlows;
  final double initialInvestment;
  final double discountRate;
  final bool isAcceptable;
  final String recommendation;

  const NPVResult({
    required this.npv,
    required this.pvOfCashFlows,
    required this.initialInvestment,
    required this.discountRate,
    required this.isAcceptable,
    required this.recommendation,
  });
}

/// Result of IRR calculation
class IRRResult {
  final double irr;
  final int iterations;
  final bool converged;

  const IRRResult({
    required this.irr,
    required this.iterations,
    required this.converged,
  });

  /// Compare IRR to required return
  bool isAcceptable(double requiredReturn) => irr > requiredReturn;

  String getRecommendation(double requiredReturn) {
    if (irr > requiredReturn) {
      return 'Accept - IRR (${(irr * 100).toStringAsFixed(2)}%) > Required Return (${(requiredReturn * 100).toStringAsFixed(2)}%)';
    } else if (irr == requiredReturn) {
      return 'Indifferent - IRR equals Required Return';
    } else {
      return 'Reject - IRR (${(irr * 100).toStringAsFixed(2)}%) < Required Return (${(requiredReturn * 100).toStringAsFixed(2)}%)';
    }
  }
}

/// Result of Payback Period calculation
class PaybackResult {
  final double years;
  final bool recoversInvestment;
  final List<double> cumulativeCashFlows;

  const PaybackResult({
    required this.years,
    required this.recoversInvestment,
    required this.cumulativeCashFlows,
  });

  String get formattedPayback {
    if (!recoversInvestment) return 'Never';
    final wholeYears = years.floor();
    final months = ((years - wholeYears) * 12).round();
    if (months == 0) return '$wholeYears years';
    return '$wholeYears years, $months months';
  }
}

/// Result of Profitability Index calculation
class PIResult {
  final double profitabilityIndex;
  final double pvOfCashFlows;
  final double initialInvestment;
  final bool isAcceptable;
  final String recommendation;

  const PIResult({
    required this.profitabilityIndex,
    required this.pvOfCashFlows,
    required this.initialInvestment,
    required this.isAcceptable,
    required this.recommendation,
  });
}

/// Result of ARR calculation
class ARRResult {
  final double arr;
  final double averageInvestment;
  final double expectedAnnualNetIncome;

  const ARRResult({
    required this.arr,
    required this.averageInvestment,
    required this.expectedAnnualNetIncome,
  });

  String get formattedARR => '${(arr * 100).toStringAsFixed(2)}%';
}

/// Point in sensitivity analysis
class SensitivityPoint {
  final double discountRate;
  final double npv;

  const SensitivityPoint({required this.discountRate, required this.npv});
}

/// Input for project comparison
class ProjectInput {
  final String name;
  final double initialInvestment;
  final List<double> cashFlows;

  const ProjectInput({
    required this.name,
    required this.initialInvestment,
    required this.cashFlows,
  });
}

/// Analysis result for a single project
class ProjectAnalysis {
  final String name;
  final double npv;
  final double irr;
  final double pi;
  final double paybackYears;

  const ProjectAnalysis({
    required this.name,
    required this.npv,
    required this.irr,
    required this.pi,
    required this.paybackYears,
  });
}

/// Result of comparing multiple projects
class ProjectComparison {
  final List<ProjectAnalysis> analyses;
  final double discountRate;
  final String? recommendedProject;

  const ProjectComparison({
    required this.analyses,
    required this.discountRate,
    this.recommendedProject,
  });
}
