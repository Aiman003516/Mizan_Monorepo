// FILE: packages/core/core_data/lib/src/services/tvm_calculator_service.dart
// Purpose: Time Value of Money calculations for financial analysis
// Reference: Accounting Principles 13e (Weygandt), Appendix C - Time Value of Money

/// Time Value of Money Calculator Service
/// Provides present value, future value, and loan amortization calculations
class TVMCalculatorService {
  // ============================================================================
  // PRESENT VALUE CALCULATIONS
  // ============================================================================

  /// Present Value of a Single Sum
  /// PV = FV / (1 + r)^n
  ///
  /// [futureValue] - Future amount to be received
  /// [rate] - Interest rate per period (e.g., 0.10 for 10%)
  /// [periods] - Number of compounding periods
  static double presentValueSingle({
    required double futureValue,
    required double rate,
    required int periods,
  }) {
    if (rate == 0) return futureValue;
    return futureValue / _pow(1 + rate, periods);
  }

  /// Present Value of an Ordinary Annuity
  /// PV = PMT × [(1 - (1 + r)^-n) / r]
  /// Payments at END of each period
  ///
  /// [payment] - Payment amount per period
  /// [rate] - Interest rate per period
  /// [periods] - Number of periods
  static double presentValueOrdinaryAnnuity({
    required double payment,
    required double rate,
    required int periods,
  }) {
    if (rate == 0) return payment * periods;
    final pvFactor = (1 - _pow(1 + rate, -periods)) / rate;
    return payment * pvFactor;
  }

  /// Present Value of an Annuity Due
  /// PV = PV of Ordinary Annuity × (1 + r)
  /// Payments at BEGINNING of each period
  static double presentValueAnnuityDue({
    required double payment,
    required double rate,
    required int periods,
  }) {
    final pvOrdinary = presentValueOrdinaryAnnuity(
      payment: payment,
      rate: rate,
      periods: periods,
    );
    return pvOrdinary * (1 + rate);
  }

  // ============================================================================
  // FUTURE VALUE CALCULATIONS
  // ============================================================================

  /// Future Value of a Single Sum
  /// FV = PV × (1 + r)^n
  static double futureValueSingle({
    required double presentValue,
    required double rate,
    required int periods,
  }) {
    return presentValue * _pow(1 + rate, periods);
  }

  /// Future Value of an Ordinary Annuity
  /// FV = PMT × [((1 + r)^n - 1) / r]
  /// Payments at END of each period
  static double futureValueOrdinaryAnnuity({
    required double payment,
    required double rate,
    required int periods,
  }) {
    if (rate == 0) return payment * periods;
    final fvFactor = (_pow(1 + rate, periods) - 1) / rate;
    return payment * fvFactor;
  }

  /// Future Value of an Annuity Due
  /// FV = FV of Ordinary Annuity × (1 + r)
  /// Payments at BEGINNING of each period
  static double futureValueAnnuityDue({
    required double payment,
    required double rate,
    required int periods,
  }) {
    final fvOrdinary = futureValueOrdinaryAnnuity(
      payment: payment,
      rate: rate,
      periods: periods,
    );
    return fvOrdinary * (1 + rate);
  }

  // ============================================================================
  // LOAN CALCULATIONS
  // ============================================================================

  /// Calculate periodic payment for a loan
  /// PMT = PV × [r / (1 - (1 + r)^-n)]
  ///
  /// [principal] - Loan amount
  /// [rate] - Interest rate per period
  /// [periods] - Number of payment periods
  static double calculatePayment({
    required double principal,
    required double rate,
    required int periods,
  }) {
    if (rate == 0) return principal / periods;
    final paymentFactor = rate / (1 - _pow(1 + rate, -periods));
    return principal * paymentFactor;
  }

  /// Generate a complete loan amortization schedule
  /// Returns a list of AmortizationRow for each payment period
  static List<AmortizationRow> generateAmortizationSchedule({
    required double principal,
    required double annualRate,
    required int totalPeriods,
    int periodsPerYear = 12,
  }) {
    final periodicRate = annualRate / periodsPerYear;
    final payment = calculatePayment(
      principal: principal,
      rate: periodicRate,
      periods: totalPeriods,
    );

    final schedule = <AmortizationRow>[];
    double balance = principal;

    for (int period = 1; period <= totalPeriods; period++) {
      final interestPortion = balance * periodicRate;
      final principalPortion = payment - interestPortion;
      final endingBalance = balance - principalPortion;

      schedule.add(
        AmortizationRow(
          period: period,
          beginningBalance: balance,
          payment: payment,
          interestPortion: interestPortion,
          principalPortion: principalPortion,
          endingBalance: endingBalance < 0.01 ? 0 : endingBalance,
        ),
      );

      balance = endingBalance;
    }

    return schedule;
  }

  /// Calculate total interest paid over the life of a loan
  static double calculateTotalInterest({
    required double principal,
    required double annualRate,
    required int totalPeriods,
    int periodsPerYear = 12,
  }) {
    final periodicRate = annualRate / periodsPerYear;
    final payment = calculatePayment(
      principal: principal,
      rate: periodicRate,
      periods: totalPeriods,
    );
    return (payment * totalPeriods) - principal;
  }

  // ============================================================================
  // RATE SOLVING
  // ============================================================================

  /// Solve for the interest rate given PV, FV, and periods
  /// Uses Newton-Raphson iterative method
  static double solveForRate({
    required double presentValue,
    required double futureValue,
    required int periods,
    double tolerance = 0.0001,
    int maxIterations = 100,
  }) {
    // Initial guess: (FV/PV)^(1/n) - 1
    double rate = _pow(futureValue / presentValue, 1 / periods) - 1;

    for (int i = 0; i < maxIterations; i++) {
      final calculatedFV = presentValue * _pow(1 + rate, periods);
      final derivative = presentValue * periods * _pow(1 + rate, periods - 1);

      final newRate = rate - (calculatedFV - futureValue) / derivative;

      if ((newRate - rate).abs() < tolerance) {
        return newRate;
      }
      rate = newRate;
    }

    return rate;
  }

  /// Solve for the number of periods given PV, FV, and rate
  static int solveForPeriods({
    required double presentValue,
    required double futureValue,
    required double rate,
  }) {
    if (rate == 0) return 0;
    // n = ln(FV/PV) / ln(1+r)
    final n = _log(futureValue / presentValue) / _log(1 + rate);
    return n.ceil();
  }

  // ============================================================================
  // EFFECTIVE RATE CONVERSIONS
  // ============================================================================

  /// Convert nominal annual rate to effective annual rate
  /// EAR = (1 + r/m)^m - 1
  static double nominalToEffectiveRate({
    required double nominalRate,
    required int compoundingPeriodsPerYear,
  }) {
    return _pow(
          1 + nominalRate / compoundingPeriodsPerYear,
          compoundingPeriodsPerYear,
        ) -
        1;
  }

  /// Convert effective annual rate to nominal rate
  static double effectiveToNominalRate({
    required double effectiveRate,
    required int compoundingPeriodsPerYear,
  }) {
    return compoundingPeriodsPerYear *
        (_pow(1 + effectiveRate, 1 / compoundingPeriodsPerYear) - 1);
  }

  /// Convert rate between different compounding frequencies
  static double convertRate({
    required double rate,
    required int fromPeriodsPerYear,
    required int toPeriodsPerYear,
  }) {
    // First convert to effective annual rate
    final ear = nominalToEffectiveRate(
      nominalRate: rate,
      compoundingPeriodsPerYear: fromPeriodsPerYear,
    );
    // Then convert to target frequency
    return effectiveToNominalRate(
      effectiveRate: ear,
      compoundingPeriodsPerYear: toPeriodsPerYear,
    );
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Power function that handles negative exponents correctly
  static double _pow(double base, num exponent) {
    if (exponent is int) {
      return _intPow(base, exponent);
    }
    return _doublePow(base, exponent.toDouble());
  }

  static double _intPow(double base, int exponent) {
    if (exponent == 0) return 1.0;
    if (exponent < 0) return 1.0 / _intPow(base, -exponent);

    double result = 1.0;
    double current = base;
    int exp = exponent;

    while (exp > 0) {
      if (exp & 1 == 1) {
        result *= current;
      }
      current *= current;
      exp >>= 1;
    }
    return result;
  }

  static double _doublePow(double base, double exponent) {
    // Use natural log for non-integer exponents
    if (base <= 0) return 0;
    return _exp(exponent * _log(base));
  }

  static double _log(double x) {
    // Natural logarithm using Taylor series for accuracy
    if (x <= 0) return double.negativeInfinity;
    if (x == 1) return 0;

    // Use identity: ln(x) = 2 * arctanh((x-1)/(x+1)) for better convergence
    double y = (x - 1) / (x + 1);
    double y2 = y * y;
    double result = 0;
    double term = y;

    for (int i = 1; i <= 100; i += 2) {
      result += term / i;
      term *= y2;
      if (term.abs() < 1e-15) break;
    }

    return 2 * result;
  }

  static double _exp(double x) {
    // e^x using Taylor series
    double result = 1;
    double term = 1;

    for (int n = 1; n <= 100; n++) {
      term *= x / n;
      result += term;
      if (term.abs() < 1e-15) break;
    }

    return result;
  }
}

// ============================================================================
// DATA CLASSES
// ============================================================================

/// Single row in an amortization schedule
class AmortizationRow {
  final int period;
  final double beginningBalance;
  final double payment;
  final double interestPortion;
  final double principalPortion;
  final double endingBalance;

  const AmortizationRow({
    required this.period,
    required this.beginningBalance,
    required this.payment,
    required this.interestPortion,
    required this.principalPortion,
    required this.endingBalance,
  });

  @override
  String toString() {
    return 'Period $period: Payment \$${payment.toStringAsFixed(2)}, '
        'Interest \$${interestPortion.toStringAsFixed(2)}, '
        'Principal \$${principalPortion.toStringAsFixed(2)}, '
        'Balance \$${endingBalance.toStringAsFixed(2)}';
  }
}

/// Summary of a loan
class LoanSummary {
  final double principal;
  final double annualRate;
  final int totalPeriods;
  final double monthlyPayment;
  final double totalPayments;
  final double totalInterest;

  const LoanSummary({
    required this.principal,
    required this.annualRate,
    required this.totalPeriods,
    required this.monthlyPayment,
    required this.totalPayments,
    required this.totalInterest,
  });

  factory LoanSummary.calculate({
    required double principal,
    required double annualRate,
    required int years,
  }) {
    final totalPeriods = years * 12;
    final monthlyPayment = TVMCalculatorService.calculatePayment(
      principal: principal,
      rate: annualRate / 12,
      periods: totalPeriods,
    );
    final totalPayments = monthlyPayment * totalPeriods;
    final totalInterest = totalPayments - principal;

    return LoanSummary(
      principal: principal,
      annualRate: annualRate,
      totalPeriods: totalPeriods,
      monthlyPayment: monthlyPayment,
      totalPayments: totalPayments,
      totalInterest: totalInterest,
    );
  }
}
