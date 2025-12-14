// FILE: packages/core/core_data/test/financial_analysis_service_test.dart
// Purpose: Unit tests for Financial Analysis Service ratio calculations

import 'package:flutter_test/flutter_test.dart';
import 'package:core_data/src/services/financial_analysis_service.dart';

void main() {
  // Tests use FinancialAnalysisService directly with null database
  // since we're only testing pure calculation methods

  group('Liquidity Ratios', () {
    test('Current Ratio calculation', () {
      // Example: Current Assets = $500,000, Current Liabilities = $200,000
      // Expected: 2.5
      final result = FinancialAnalysisService(null as dynamic)
          .calculateCurrentRatio(
            currentAssets: 500000,
            currentLiabilities: 200000,
          );
      expect(result, equals(2.5));
    });

    test('Current Ratio with zero liabilities returns 0', () {
      final result = FinancialAnalysisService(
        null as dynamic,
      ).calculateCurrentRatio(currentAssets: 500000, currentLiabilities: 0);
      expect(result, equals(0));
    });

    test('Quick Ratio calculation', () {
      // Example: Cash = $100,000, Receivables = $200,000, Current Liabilities = $150,000
      // Expected: 2.0
      final result = FinancialAnalysisService(null as dynamic)
          .calculateQuickRatio(
            cash: 100000,
            receivables: 200000,
            currentLiabilities: 150000,
          );
      expect(result, equals(2.0));
    });

    test('Cash Ratio calculation', () {
      // Example: Cash = $50,000, Current Liabilities = $100,000
      // Expected: 0.5
      final result = FinancialAnalysisService(
        null as dynamic,
      ).calculateCashRatio(cash: 50000, currentLiabilities: 100000);
      expect(result, equals(0.5));
    });

    test('Working Capital calculation', () {
      // Example: Current Assets = $300,000, Current Liabilities = $150,000
      // Expected: $150,000
      final result = FinancialAnalysisService(null as dynamic)
          .calculateWorkingCapital(
            currentAssets: 300000,
            currentLiabilities: 150000,
          );
      expect(result, equals(150000));
    });
  });

  group('Activity Ratios', () {
    test('Inventory Turnover calculation', () {
      // Example: COGS = $600,000, Average Inventory = $100,000
      // Expected: 6.0 times
      final result = FinancialAnalysisService(null as dynamic)
          .calculateInventoryTurnover(
            costOfGoodsSold: 600000,
            averageInventory: 100000,
          );
      expect(result, equals(6.0));
    });

    test('Days Sales in Inventory calculation', () {
      // Example: Inventory Turnover = 6.0
      // Expected: 365 / 6 = 61 days (rounded)
      final result = FinancialAnalysisService(
        null as dynamic,
      ).calculateDaysSalesInInventory(inventoryTurnover: 6.0);
      expect(result, equals(61));
    });

    test('Receivables Turnover calculation', () {
      // Example: Net Credit Sales = $1,000,000, Average Receivables = $200,000
      // Expected: 5.0 times
      final result = FinancialAnalysisService(null as dynamic)
          .calculateReceivablesTurnover(
            netCreditSales: 1000000,
            averageReceivables: 200000,
          );
      expect(result, equals(5.0));
    });

    test('Days Sales Outstanding calculation', () {
      // Example: Receivables Turnover = 5.0
      // Expected: 365 / 5 = 73 days
      final result = FinancialAnalysisService(
        null as dynamic,
      ).calculateDaysSalesOutstanding(receivablesTurnover: 5.0);
      expect(result, equals(73));
    });

    test('Cash Conversion Cycle calculation', () {
      // Example: DSI = 60, DSO = 45, DPO = 30
      // Expected: 60 + 45 - 30 = 75 days
      final result = FinancialAnalysisService(null as dynamic)
          .calculateCashConversionCycle(
            daysSalesInInventory: 60,
            daysSalesOutstanding: 45,
            daysPayablesOutstanding: 30,
          );
      expect(result, equals(75));
    });

    test('Asset Turnover calculation', () {
      // Example: Net Sales = $2,000,000, Average Total Assets = $1,000,000
      // Expected: 2.0
      final result = FinancialAnalysisService(
        null as dynamic,
      ).calculateAssetTurnover(netSales: 2000000, averageTotalAssets: 1000000);
      expect(result, equals(2.0));
    });
  });

  group('Profitability Ratios', () {
    test('Gross Profit Margin calculation', () {
      // Example: Revenue = $1,000,000, COGS = $600,000
      // Expected: 40% (0.4)
      final result = FinancialAnalysisService(
        null as dynamic,
      ).calculateGrossProfitMargin(revenue: 1000000, costOfGoodsSold: 600000);
      expect(result, equals(0.4));
    });

    test('Operating Profit Margin calculation', () {
      // Example: Operating Income = $200,000, Revenue = $1,000,000
      // Expected: 20% (0.2)
      final result = FinancialAnalysisService(null as dynamic)
          .calculateOperatingProfitMargin(
            operatingIncome: 200000,
            revenue: 1000000,
          );
      expect(result, equals(0.2));
    });

    test('Net Profit Margin calculation', () {
      // Example: Net Income = $150,000, Revenue = $1,000,000
      // Expected: 15% (0.15)
      final result = FinancialAnalysisService(
        null as dynamic,
      ).calculateNetProfitMargin(netIncome: 150000, revenue: 1000000);
      expect(result, equals(0.15));
    });

    test('Return on Assets calculation', () {
      // Example: Net Income = $100,000, Average Total Assets = $500,000
      // Expected: 20% (0.2)
      final result = FinancialAnalysisService(
        null as dynamic,
      ).calculateReturnOnAssets(netIncome: 100000, averageTotalAssets: 500000);
      expect(result, equals(0.2));
    });

    test('Return on Equity calculation', () {
      // Example: Net Income = $100,000, Average Shareholders Equity = $250,000
      // Expected: 40% (0.4)
      final result = FinancialAnalysisService(null as dynamic)
          .calculateReturnOnEquity(
            netIncome: 100000,
            averageShareholdersEquity: 250000,
          );
      expect(result, equals(0.4));
    });
  });

  group('Leverage Ratios', () {
    test('Debt-to-Equity Ratio calculation', () {
      // Example: Total Liabilities = $300,000, Shareholders Equity = $200,000
      // Expected: 1.5
      final result = FinancialAnalysisService(null as dynamic)
          .calculateDebtToEquityRatio(
            totalLiabilities: 300000,
            shareholdersEquity: 200000,
          );
      expect(result, equals(1.5));
    });

    test('Debt-to-Assets Ratio calculation', () {
      // Example: Total Liabilities = $300,000, Total Assets = $500,000
      // Expected: 60% (0.6)
      final result = FinancialAnalysisService(null as dynamic)
          .calculateDebtToAssetsRatio(
            totalLiabilities: 300000,
            totalAssets: 500000,
          );
      expect(result, equals(0.6));
    });

    test('Equity Multiplier calculation', () {
      // Example: Total Assets = $500,000, Shareholders Equity = $200,000
      // Expected: 2.5
      final result = FinancialAnalysisService(null as dynamic)
          .calculateEquityMultiplier(
            totalAssets: 500000,
            shareholdersEquity: 200000,
          );
      expect(result, equals(2.5));
    });

    test('Interest Coverage Ratio calculation', () {
      // Example: EBIT = $200,000, Interest Expense = $40,000
      // Expected: 5.0
      final result = FinancialAnalysisService(
        null as dynamic,
      ).calculateInterestCoverageRatio(ebit: 200000, interestExpense: 40000);
      expect(result, equals(5.0));
    });

    test('Interest Coverage with zero interest returns infinity', () {
      final result = FinancialAnalysisService(
        null as dynamic,
      ).calculateInterestCoverageRatio(ebit: 200000, interestExpense: 0);
      expect(result, equals(double.infinity));
    });

    test('Times Interest Earned calculation', () {
      // Example: Net Income = $100,000, Interest = $20,000, Tax = $30,000
      // Expected: (100,000 + 20,000 + 30,000) / 20,000 = 7.5
      final result = FinancialAnalysisService(null as dynamic)
          .calculateTimesInterestEarned(
            netIncome: 100000,
            interestExpense: 20000,
            incomeTaxExpense: 30000,
          );
      expect(result, equals(7.5));
    });
  });

  group('Du Pont Analysis', () {
    test('3-Part Du Pont ROE calculation', () {
      // Example from textbook:
      // Net Income = $150,000, Revenue = $1,000,000 -> NPM = 15%
      // Revenue = $1,000,000, Avg Assets = $500,000 -> AT = 2.0
      // Avg Assets = $500,000, Avg Equity = $250,000 -> EM = 2.0
      // ROE = 0.15 * 2.0 * 2.0 = 0.60 (60%)
      final result = FinancialAnalysisService(null as dynamic)
          .calculateDuPont3Part(
            netIncome: 150000,
            revenue: 1000000,
            averageTotalAssets: 500000,
            averageShareholdersEquity: 250000,
          );

      expect(result.netProfitMargin, equals(0.15));
      expect(result.assetTurnover, equals(2.0));
      expect(result.equityMultiplier, equals(2.0));
      expect(result.roe3Part, closeTo(0.60, 0.001));
    });
  });

  group('Cash Flow Quality', () {
    test('Cash Flow Quality Metrics calculation', () {
      // Example:
      // OCF = $150,000, Net Income = $100,000 -> OCF/NI = 1.5
      // OCF = $150,000, CapEx = $50,000 -> FCF = $100,000
      final result = FinancialAnalysisService(null as dynamic)
          .calculateCashFlowQuality(
            operatingCashFlow: 150000,
            netIncome: 100000,
            capitalExpenditures: 50000,
            interestExpense: 10000,
            netBorrowing: 20000,
            totalAssets: 500000,
            incomeTaxExpense: 25000,
          );

      expect(result.ocfToNetIncome, equals(1.5));
      expect(result.freeCashFlow, equals(100000));
      expect(result.isHighQuality, isTrue); // OCF/NI >= 1.0
    });

    test('Low quality earnings detection', () {
      // Example: OCF = $80,000, Net Income = $100,000 -> OCF/NI = 0.8
      final result = FinancialAnalysisService(null as dynamic)
          .calculateCashFlowQuality(
            operatingCashFlow: 80000,
            netIncome: 100000,
            capitalExpenditures: 30000,
            interestExpense: 5000,
            netBorrowing: 0,
            totalAssets: 400000,
            incomeTaxExpense: 20000,
          );

      expect(result.ocfToNetIncome, equals(0.8));
      expect(result.isHighQuality, isFalse); // OCF/NI < 1.0
    });
  });
}
