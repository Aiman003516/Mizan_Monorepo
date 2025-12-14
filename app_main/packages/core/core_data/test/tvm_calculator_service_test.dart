// FILE: packages/core/core_data/test/tvm_calculator_service_test.dart
// Purpose: Unit tests for Time Value of Money Calculator

import 'package:flutter_test/flutter_test.dart';
import 'package:core_data/src/services/tvm_calculator_service.dart';

void main() {
  group('Present Value Calculations', () {
    test('PV of single sum', () {
      // Example: FV = $10,000, rate = 10%, n = 5
      // PV = 10,000 / (1.10)^5 = $6,209.21
      final pv = TVMCalculatorService.presentValueSingle(
        futureValue: 10000,
        rate: 0.10,
        periods: 5,
      );
      expect(pv, closeTo(6209.21, 1.0));
    });

    test('PV of ordinary annuity', () {
      // Example: PMT = $1,000, rate = 8%, n = 10
      // PV = 1,000 × [(1 - (1.08)^-10) / 0.08] = $6,710.08
      final pv = TVMCalculatorService.presentValueOrdinaryAnnuity(
        payment: 1000,
        rate: 0.08,
        periods: 10,
      );
      expect(pv, closeTo(6710.08, 1.0));
    });

    test('PV of annuity due', () {
      // Example: PMT = $1,000, rate = 8%, n = 10
      // PV = PV of Ordinary × (1 + r) = 6,710.08 × 1.08 = $7,246.89
      final pv = TVMCalculatorService.presentValueAnnuityDue(
        payment: 1000,
        rate: 0.08,
        periods: 10,
      );
      expect(pv, closeTo(7246.89, 1.0));
    });

    test('PV with zero rate returns sum of payments', () {
      final pv = TVMCalculatorService.presentValueOrdinaryAnnuity(
        payment: 1000,
        rate: 0,
        periods: 5,
      );
      expect(pv, equals(5000));
    });
  });

  group('Future Value Calculations', () {
    test('FV of single sum', () {
      // Example: PV = $5,000, rate = 10%, n = 5
      // FV = 5,000 × (1.10)^5 = $8,052.55
      final fv = TVMCalculatorService.futureValueSingle(
        presentValue: 5000,
        rate: 0.10,
        periods: 5,
      );
      expect(fv, closeTo(8052.55, 1.0));
    });

    test('FV of ordinary annuity', () {
      // Example: PMT = $1,000, rate = 6%, n = 5
      // FV = 1,000 × [((1.06)^5 - 1) / 0.06] = $5,637.09
      final fv = TVMCalculatorService.futureValueOrdinaryAnnuity(
        payment: 1000,
        rate: 0.06,
        periods: 5,
      );
      expect(fv, closeTo(5637.09, 1.0));
    });

    test('FV of annuity due', () {
      // Example: PMT = $1,000, rate = 6%, n = 5
      // FV = FV of Ordinary × (1 + r) = 5,637.09 × 1.06 = $5,975.32
      final fv = TVMCalculatorService.futureValueAnnuityDue(
        payment: 1000,
        rate: 0.06,
        periods: 5,
      );
      expect(fv, closeTo(5975.32, 1.0));
    });
  });

  group('Loan Calculations', () {
    test('Calculate monthly payment', () {
      // Example: $200,000 loan, 6% annual rate, 30 years (360 months)
      // Expected payment ≈ $1,199.10
      final payment = TVMCalculatorService.calculatePayment(
        principal: 200000,
        rate: 0.06 / 12, // Monthly rate
        periods: 360,
      );
      expect(payment, closeTo(1199.10, 1.0));
    });

    test('Calculate total interest paid', () {
      // $200,000 loan, 6% annual, 30 years
      // Total payments = 1,199.10 × 360 = $431,676
      // Total interest = $431,676 - $200,000 = $231,676
      final totalInterest = TVMCalculatorService.calculateTotalInterest(
        principal: 200000,
        annualRate: 0.06,
        totalPeriods: 360,
      );
      expect(totalInterest, closeTo(231676, 100));
    });

    test('Generate amortization schedule', () {
      // Small loan for testing: $10,000, 12% annual, 12 months
      final schedule = TVMCalculatorService.generateAmortizationSchedule(
        principal: 10000,
        annualRate: 0.12,
        totalPeriods: 12,
      );

      expect(schedule.length, equals(12));

      // First payment
      expect(schedule[0].period, equals(1));
      expect(schedule[0].beginningBalance, equals(10000));
      expect(schedule[0].interestPortion, closeTo(100, 1)); // 10,000 × 0.01

      // Last payment should have ending balance near zero
      expect(schedule[11].endingBalance, closeTo(0, 1));
    });

    test('Payment with zero rate is simple division', () {
      final payment = TVMCalculatorService.calculatePayment(
        principal: 12000,
        rate: 0,
        periods: 12,
      );
      expect(payment, equals(1000));
    });
  });

  group('Rate Solving', () {
    test('Solve for rate given PV, FV, and periods', () {
      // Example: PV = $1,000, FV = $2,000, n = 7 years
      // Rate = (2000/1000)^(1/7) - 1 ≈ 10.41%
      final rate = TVMCalculatorService.solveForRate(
        presentValue: 1000,
        futureValue: 2000,
        periods: 7,
      );
      expect(rate, closeTo(0.1041, 0.001));
    });

    test('Solve for periods', () {
      // Example: PV = $1,000, FV = $2,000, rate = 10%
      // n = ln(2000/1000) / ln(1.10) ≈ 7.27 years
      final periods = TVMCalculatorService.solveForPeriods(
        presentValue: 1000,
        futureValue: 2000,
        rate: 0.10,
      );
      expect(periods, equals(8)); // Rounds up
    });
  });

  group('Effective Rate Conversions', () {
    test('Nominal to effective rate - monthly compounding', () {
      // Example: 12% nominal, compounded monthly
      // EAR = (1 + 0.12/12)^12 - 1 = 12.68%
      final ear = TVMCalculatorService.nominalToEffectiveRate(
        nominalRate: 0.12,
        compoundingPeriodsPerYear: 12,
      );
      expect(ear, closeTo(0.1268, 0.001));
    });

    test('Effective to nominal rate', () {
      // Example: 12.68% EAR to monthly nominal
      final nominal = TVMCalculatorService.effectiveToNominalRate(
        effectiveRate: 0.1268,
        compoundingPeriodsPerYear: 12,
      );
      expect(nominal, closeTo(0.12, 0.001));
    });

    test('Rate conversion between frequencies', () {
      // Convert semi-annual 10% to quarterly
      final quarterlyRate = TVMCalculatorService.convertRate(
        rate: 0.10,
        fromPeriodsPerYear: 2,
        toPeriodsPerYear: 4,
      );
      // Should be lower per period but more frequent
      expect(quarterlyRate, closeTo(0.0976, 0.001));
    });
  });

  group('Loan Summary', () {
    test('Loan summary calculation', () {
      final summary = LoanSummary.calculate(
        principal: 100000,
        annualRate: 0.05,
        years: 15,
      );

      expect(summary.totalPeriods, equals(180));
      expect(summary.monthlyPayment, closeTo(790.79, 1));
      expect(summary.totalPayments, closeTo(142342, 100));
      expect(summary.totalInterest, closeTo(42342, 100));
    });
  });
}
