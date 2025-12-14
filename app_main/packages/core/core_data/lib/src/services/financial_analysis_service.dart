// FILE: packages/core/core_data/lib/src/services/financial_analysis_service.dart
// Purpose: Comprehensive financial ratio calculations for analysis dashboard
// Reference: Accounting Principles 13e (Weygandt), Financial Statement Analysis (Fridson)

import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:drift/drift.dart';

// ============================================================================
// DATA CLASSES
// ============================================================================

/// Complete set of financial ratios
class FinancialRatiosResult {
  // Liquidity Ratios
  final double currentRatio;
  final double quickRatio;
  final double cashRatio;
  final int workingCapital;
  final double operatingCashFlowRatio;

  // Activity/Efficiency Ratios
  final double inventoryTurnover;
  final int daysSalesInInventory;
  final double receivablesTurnover;
  final int daysSalesOutstanding;
  final double payablesTurnover;
  final int daysPayablesOutstanding;
  final int cashConversionCycle;
  final double assetTurnover;
  final double fixedAssetTurnover;

  // Profitability Ratios
  final double grossProfitMargin;
  final double operatingProfitMargin;
  final double netProfitMargin;
  final double returnOnAssets;
  final double returnOnEquity;
  final double ebitdaMargin;

  // Leverage/Solvency Ratios
  final double debtToEquityRatio;
  final double debtToAssetsRatio;
  final double equityMultiplier;
  final double interestCoverageRatio;
  final double timesInterestEarned;

  const FinancialRatiosResult({
    // Liquidity
    required this.currentRatio,
    required this.quickRatio,
    required this.cashRatio,
    required this.workingCapital,
    required this.operatingCashFlowRatio,
    // Activity
    required this.inventoryTurnover,
    required this.daysSalesInInventory,
    required this.receivablesTurnover,
    required this.daysSalesOutstanding,
    required this.payablesTurnover,
    required this.daysPayablesOutstanding,
    required this.cashConversionCycle,
    required this.assetTurnover,
    required this.fixedAssetTurnover,
    // Profitability
    required this.grossProfitMargin,
    required this.operatingProfitMargin,
    required this.netProfitMargin,
    required this.returnOnAssets,
    required this.returnOnEquity,
    required this.ebitdaMargin,
    // Leverage
    required this.debtToEquityRatio,
    required this.debtToAssetsRatio,
    required this.equityMultiplier,
    required this.interestCoverageRatio,
    required this.timesInterestEarned,
  });

  factory FinancialRatiosResult.empty() => const FinancialRatiosResult(
    currentRatio: 0,
    quickRatio: 0,
    cashRatio: 0,
    workingCapital: 0,
    operatingCashFlowRatio: 0,
    inventoryTurnover: 0,
    daysSalesInInventory: 0,
    receivablesTurnover: 0,
    daysSalesOutstanding: 0,
    payablesTurnover: 0,
    daysPayablesOutstanding: 0,
    cashConversionCycle: 0,
    assetTurnover: 0,
    fixedAssetTurnover: 0,
    grossProfitMargin: 0,
    operatingProfitMargin: 0,
    netProfitMargin: 0,
    returnOnAssets: 0,
    returnOnEquity: 0,
    ebitdaMargin: 0,
    debtToEquityRatio: 0,
    debtToAssetsRatio: 0,
    equityMultiplier: 0,
    interestCoverageRatio: 0,
    timesInterestEarned: 0,
  );
}

/// Du Pont Analysis decomposition (3-part and 5-part)
class DuPontAnalysis {
  // 3-Part Du Pont
  final double netProfitMargin;
  final double assetTurnover;
  final double equityMultiplier;
  final double roe3Part; // NPM × Asset Turnover × Equity Multiplier

  // 5-Part Du Pont (extended)
  final double? taxBurden; // Net Income / EBT
  final double? interestBurden; // EBT / EBIT
  final double? ebitMargin; // EBIT / Revenue
  final double? roe5Part;

  const DuPontAnalysis({
    required this.netProfitMargin,
    required this.assetTurnover,
    required this.equityMultiplier,
    required this.roe3Part,
    this.taxBurden,
    this.interestBurden,
    this.ebitMargin,
    this.roe5Part,
  });

  factory DuPontAnalysis.empty() => const DuPontAnalysis(
    netProfitMargin: 0,
    assetTurnover: 0,
    equityMultiplier: 0,
    roe3Part: 0,
  );
}

/// Cash Flow Quality Metrics
class CashFlowQualityMetrics {
  final double ocfToNetIncome; // Should be >= 1.0 for quality earnings
  final int freeCashFlow; // OCF - CapEx
  final int fcfToEquity; // FCF - Interest*(1-Tax) + Net Borrowing
  final double cashReturnOnAssets; // OCF / Total Assets
  final double coroa; // (OCF + Interest + Tax) / Assets
  final bool isHighQuality;

  const CashFlowQualityMetrics({
    required this.ocfToNetIncome,
    required this.freeCashFlow,
    required this.fcfToEquity,
    required this.cashReturnOnAssets,
    required this.coroa,
    required this.isHighQuality,
  });

  factory CashFlowQualityMetrics.empty() => const CashFlowQualityMetrics(
    ocfToNetIncome: 0,
    freeCashFlow: 0,
    fcfToEquity: 0,
    cashReturnOnAssets: 0,
    coroa: 0,
    isHighQuality: false,
  );
}

/// Balance sheet snapshot for ratio calculations
class BalanceSheetSnapshot {
  final int totalAssets;
  final int currentAssets;
  final int cash;
  final int accountsReceivable;
  final int inventory;
  final int fixedAssets;
  final int totalLiabilities;
  final int currentLiabilities;
  final int longTermDebt;
  final int shareholdersEquity;

  const BalanceSheetSnapshot({
    required this.totalAssets,
    required this.currentAssets,
    required this.cash,
    required this.accountsReceivable,
    required this.inventory,
    required this.fixedAssets,
    required this.totalLiabilities,
    required this.currentLiabilities,
    required this.longTermDebt,
    required this.shareholdersEquity,
  });

  factory BalanceSheetSnapshot.empty() => const BalanceSheetSnapshot(
    totalAssets: 0,
    currentAssets: 0,
    cash: 0,
    accountsReceivable: 0,
    inventory: 0,
    fixedAssets: 0,
    totalLiabilities: 0,
    currentLiabilities: 0,
    longTermDebt: 0,
    shareholdersEquity: 0,
  );
}

/// Income statement snapshot for ratio calculations
class IncomeStatementSnapshot {
  final int revenue;
  final int costOfGoodsSold;
  final int grossProfit;
  final int operatingExpenses;
  final int operatingIncome;
  final int interestExpense;
  final int incomeBeforeTax;
  final int incomeTaxExpense;
  final int netIncome;
  final int depreciation;
  final int amortization;

  const IncomeStatementSnapshot({
    required this.revenue,
    required this.costOfGoodsSold,
    required this.grossProfit,
    required this.operatingExpenses,
    required this.operatingIncome,
    required this.interestExpense,
    required this.incomeBeforeTax,
    required this.incomeTaxExpense,
    required this.netIncome,
    required this.depreciation,
    required this.amortization,
  });

  int get ebitda => operatingIncome + depreciation + amortization;
  int get ebit => operatingIncome;

  factory IncomeStatementSnapshot.empty() => const IncomeStatementSnapshot(
    revenue: 0,
    costOfGoodsSold: 0,
    grossProfit: 0,
    operatingExpenses: 0,
    operatingIncome: 0,
    interestExpense: 0,
    incomeBeforeTax: 0,
    incomeTaxExpense: 0,
    netIncome: 0,
    depreciation: 0,
    amortization: 0,
  );
}

// ============================================================================
// SERVICE
// ============================================================================

/// Service for comprehensive financial ratio analysis
class FinancialAnalysisService {
  final AppDatabase _db;

  FinancialAnalysisService(this._db);

  // --------------------------------------------------------------------------
  // LIQUIDITY RATIOS
  // --------------------------------------------------------------------------

  /// Current Ratio = Current Assets / Current Liabilities
  /// Measures short-term debt-paying ability
  double calculateCurrentRatio({
    required int currentAssets,
    required int currentLiabilities,
  }) {
    if (currentLiabilities == 0) return 0;
    return currentAssets / currentLiabilities;
  }

  /// Quick (Acid-Test) Ratio = (Cash + Receivables + Marketable Securities) / Current Liabilities
  /// More stringent test of liquidity
  double calculateQuickRatio({
    required int cash,
    required int receivables,
    required int currentLiabilities,
    int marketableSecurities = 0,
  }) {
    if (currentLiabilities == 0) return 0;
    return (cash + receivables + marketableSecurities) / currentLiabilities;
  }

  /// Cash Ratio = Cash / Current Liabilities
  /// Most conservative liquidity measure
  double calculateCashRatio({
    required int cash,
    required int currentLiabilities,
  }) {
    if (currentLiabilities == 0) return 0;
    return cash / currentLiabilities;
  }

  /// Working Capital = Current Assets - Current Liabilities
  int calculateWorkingCapital({
    required int currentAssets,
    required int currentLiabilities,
  }) {
    return currentAssets - currentLiabilities;
  }

  /// Operating Cash Flow Ratio = Operating Cash Flow / Current Liabilities
  double calculateOperatingCashFlowRatio({
    required int operatingCashFlow,
    required int currentLiabilities,
  }) {
    if (currentLiabilities == 0) return 0;
    return operatingCashFlow / currentLiabilities;
  }

  // --------------------------------------------------------------------------
  // ACTIVITY (EFFICIENCY) RATIOS
  // --------------------------------------------------------------------------

  /// Inventory Turnover = Cost of Goods Sold / Average Inventory
  /// Measures how quickly inventory sells
  double calculateInventoryTurnover({
    required int costOfGoodsSold,
    required int averageInventory,
  }) {
    if (averageInventory == 0) return 0;
    return costOfGoodsSold / averageInventory;
  }

  /// Days Sales in Inventory = 365 / Inventory Turnover
  int calculateDaysSalesInInventory({required double inventoryTurnover}) {
    if (inventoryTurnover == 0) return 0;
    return (365 / inventoryTurnover).round();
  }

  /// Receivables Turnover = Net Credit Sales / Average Accounts Receivable
  double calculateReceivablesTurnover({
    required int netCreditSales,
    required int averageReceivables,
  }) {
    if (averageReceivables == 0) return 0;
    return netCreditSales / averageReceivables;
  }

  /// Days Sales Outstanding = 365 / Receivables Turnover
  int calculateDaysSalesOutstanding({required double receivablesTurnover}) {
    if (receivablesTurnover == 0) return 0;
    return (365 / receivablesTurnover).round();
  }

  /// Payables Turnover = Purchases / Average Accounts Payable
  double calculatePayablesTurnover({
    required int purchases,
    required int averagePayables,
  }) {
    if (averagePayables == 0) return 0;
    return purchases / averagePayables;
  }

  /// Days Payables Outstanding = 365 / Payables Turnover
  int calculateDaysPayablesOutstanding({required double payablesTurnover}) {
    if (payablesTurnover == 0) return 0;
    return (365 / payablesTurnover).round();
  }

  /// Cash Conversion Cycle = DSI + DSO - DPO
  /// Measures days to convert inventory investment to cash
  int calculateCashConversionCycle({
    required int daysSalesInInventory,
    required int daysSalesOutstanding,
    required int daysPayablesOutstanding,
  }) {
    return daysSalesInInventory +
        daysSalesOutstanding -
        daysPayablesOutstanding;
  }

  /// Asset Turnover = Net Sales / Average Total Assets
  double calculateAssetTurnover({
    required int netSales,
    required int averageTotalAssets,
  }) {
    if (averageTotalAssets == 0) return 0;
    return netSales / averageTotalAssets;
  }

  /// Fixed Asset Turnover = Net Sales / Average Net Fixed Assets
  double calculateFixedAssetTurnover({
    required int netSales,
    required int averageNetFixedAssets,
  }) {
    if (averageNetFixedAssets == 0) return 0;
    return netSales / averageNetFixedAssets;
  }

  // --------------------------------------------------------------------------
  // PROFITABILITY RATIOS
  // --------------------------------------------------------------------------

  /// Gross Profit Margin = (Revenue - COGS) / Revenue
  double calculateGrossProfitMargin({
    required int revenue,
    required int costOfGoodsSold,
  }) {
    if (revenue == 0) return 0;
    return (revenue - costOfGoodsSold) / revenue;
  }

  /// Operating Profit Margin = Operating Income / Revenue
  double calculateOperatingProfitMargin({
    required int operatingIncome,
    required int revenue,
  }) {
    if (revenue == 0) return 0;
    return operatingIncome / revenue;
  }

  /// Net Profit Margin = Net Income / Revenue
  double calculateNetProfitMargin({
    required int netIncome,
    required int revenue,
  }) {
    if (revenue == 0) return 0;
    return netIncome / revenue;
  }

  /// Return on Assets (ROA) = Net Income / Average Total Assets
  double calculateReturnOnAssets({
    required int netIncome,
    required int averageTotalAssets,
  }) {
    if (averageTotalAssets == 0) return 0;
    return netIncome / averageTotalAssets;
  }

  /// Return on Equity (ROE) = Net Income / Average Shareholders' Equity
  double calculateReturnOnEquity({
    required int netIncome,
    required int averageShareholdersEquity,
  }) {
    if (averageShareholdersEquity == 0) return 0;
    return netIncome / averageShareholdersEquity;
  }

  /// EBITDA Margin = EBITDA / Revenue
  double calculateEBITDAMargin({required int ebitda, required int revenue}) {
    if (revenue == 0) return 0;
    return ebitda / revenue;
  }

  // --------------------------------------------------------------------------
  // LEVERAGE (SOLVENCY) RATIOS
  // --------------------------------------------------------------------------

  /// Debt-to-Equity Ratio = Total Liabilities / Shareholders' Equity
  double calculateDebtToEquityRatio({
    required int totalLiabilities,
    required int shareholdersEquity,
  }) {
    if (shareholdersEquity == 0) return 0;
    return totalLiabilities / shareholdersEquity;
  }

  /// Debt-to-Assets Ratio = Total Liabilities / Total Assets
  double calculateDebtToAssetsRatio({
    required int totalLiabilities,
    required int totalAssets,
  }) {
    if (totalAssets == 0) return 0;
    return totalLiabilities / totalAssets;
  }

  /// Equity Multiplier = Total Assets / Shareholders' Equity
  double calculateEquityMultiplier({
    required int totalAssets,
    required int shareholdersEquity,
  }) {
    if (shareholdersEquity == 0) return 0;
    return totalAssets / shareholdersEquity;
  }

  /// Interest Coverage Ratio = EBIT / Interest Expense
  double calculateInterestCoverageRatio({
    required int ebit,
    required int interestExpense,
  }) {
    if (interestExpense == 0) return double.infinity;
    return ebit / interestExpense;
  }

  /// Times Interest Earned = (Net Income + Interest + Tax) / Interest Expense
  double calculateTimesInterestEarned({
    required int netIncome,
    required int interestExpense,
    required int incomeTaxExpense,
  }) {
    if (interestExpense == 0) return double.infinity;
    return (netIncome + interestExpense + incomeTaxExpense) / interestExpense;
  }

  // --------------------------------------------------------------------------
  // DU PONT ANALYSIS
  // --------------------------------------------------------------------------

  /// 3-Part Du Pont: ROE = NPM × Asset Turnover × Equity Multiplier
  DuPontAnalysis calculateDuPont3Part({
    required int netIncome,
    required int revenue,
    required int averageTotalAssets,
    required int averageShareholdersEquity,
  }) {
    final npm = calculateNetProfitMargin(
      netIncome: netIncome,
      revenue: revenue,
    );
    final at = calculateAssetTurnover(
      netSales: revenue,
      averageTotalAssets: averageTotalAssets,
    );
    final em = calculateEquityMultiplier(
      totalAssets: averageTotalAssets,
      shareholdersEquity: averageShareholdersEquity,
    );

    return DuPontAnalysis(
      netProfitMargin: npm,
      assetTurnover: at,
      equityMultiplier: em,
      roe3Part: npm * at * em,
    );
  }

  /// 5-Part Du Pont: ROE = Tax Burden × Interest Burden × EBIT Margin × Asset Turnover × Leverage
  DuPontAnalysis calculateDuPont5Part({
    required int netIncome,
    required int incomeBeforeTax,
    required int ebit,
    required int revenue,
    required int averageTotalAssets,
    required int averageShareholdersEquity,
  }) {
    // Tax Burden = Net Income / EBT
    final taxBurden = incomeBeforeTax == 0 ? 0.0 : netIncome / incomeBeforeTax;

    // Interest Burden = EBT / EBIT
    final interestBurden = ebit == 0 ? 0.0 : incomeBeforeTax / ebit;

    // EBIT Margin = EBIT / Revenue
    final ebitMargin = revenue == 0 ? 0.0 : ebit / revenue;

    // Asset Turnover = Revenue / Assets
    final at = averageTotalAssets == 0 ? 0.0 : revenue / averageTotalAssets;

    // Leverage = Assets / Equity
    final leverage = averageShareholdersEquity == 0
        ? 0.0
        : averageTotalAssets / averageShareholdersEquity;

    final roe5Part = taxBurden * interestBurden * ebitMargin * at * leverage;

    return DuPontAnalysis(
      netProfitMargin: calculateNetProfitMargin(
        netIncome: netIncome,
        revenue: revenue,
      ),
      assetTurnover: at,
      equityMultiplier: leverage,
      roe3Part: roe5Part, // Same end result
      taxBurden: taxBurden,
      interestBurden: interestBurden,
      ebitMargin: ebitMargin,
      roe5Part: roe5Part,
    );
  }

  // --------------------------------------------------------------------------
  // CASH FLOW QUALITY
  // --------------------------------------------------------------------------

  /// Calculate comprehensive cash flow quality metrics
  CashFlowQualityMetrics calculateCashFlowQuality({
    required int operatingCashFlow,
    required int netIncome,
    required int capitalExpenditures,
    required int interestExpense,
    required int netBorrowing,
    required int totalAssets,
    required int incomeTaxExpense,
    double taxRate = 0.25,
  }) {
    // OCF / Net Income - should be >= 1.0
    final ocfToNI = netIncome == 0 ? 0.0 : operatingCashFlow / netIncome;

    // Free Cash Flow = OCF - CapEx
    final fcf = operatingCashFlow - capitalExpenditures;

    // FCF to Equity = FCF - Interest*(1-Tax) + Net Borrowing
    final afterTaxInterest = (interestExpense * (1 - taxRate)).round();
    final fcfToEquity = fcf - afterTaxInterest + netBorrowing;

    // Cash Return on Assets = OCF / Total Assets
    final croa = totalAssets == 0 ? 0.0 : operatingCashFlow / totalAssets;

    // COROA = (OCF + Interest + Tax) / Assets
    final coroa = totalAssets == 0
        ? 0.0
        : (operatingCashFlow + interestExpense + incomeTaxExpense) /
              totalAssets;

    return CashFlowQualityMetrics(
      ocfToNetIncome: ocfToNI,
      freeCashFlow: fcf,
      fcfToEquity: fcfToEquity,
      cashReturnOnAssets: croa,
      coroa: coroa,
      isHighQuality: ocfToNI >= 1.0,
    );
  }

  // --------------------------------------------------------------------------
  // COMPREHENSIVE ANALYSIS FROM DATABASE
  // --------------------------------------------------------------------------

  /// Get balance sheet snapshot from database
  Future<BalanceSheetSnapshot> getBalanceSheetSnapshot({
    required DateTime asOfDate,
  }) async {
    // Get all accounts with their balances
    final accounts = await _db.select(_db.accounts).get();

    int totalAssets = 0;
    int currentAssets = 0;
    int cash = 0;
    int receivables = 0;
    int inventory = 0;
    int fixedAssets = 0;
    int totalLiabilities = 0;
    int currentLiabilities = 0;
    int longTermDebt = 0;
    int equity = 0;

    for (final account in accounts) {
      // Get balance for this account
      final entries = await (_db.select(
        _db.transactionEntries,
      )..where((t) => t.accountId.equals(account.id))).get();

      int balance = 0;
      for (final entry in entries) {
        balance += entry.amount;
      }

      // Classify by account type
      switch (account.type.toLowerCase()) {
        case 'asset':
          totalAssets += balance;
          // Check if current asset (simplified - could use account codes)
          if (account.name.toLowerCase().contains('cash')) {
            cash += balance;
            currentAssets += balance;
          } else if (account.name.toLowerCase().contains('receivable')) {
            receivables += balance;
            currentAssets += balance;
          } else if (account.name.toLowerCase().contains('inventory')) {
            inventory += balance;
            currentAssets += balance;
          } else if (account.name.toLowerCase().contains('fixed') ||
              account.name.toLowerCase().contains('equipment') ||
              account.name.toLowerCase().contains('building')) {
            fixedAssets += balance;
          } else {
            currentAssets += balance; // Default to current
          }
          break;
        case 'liability':
          totalLiabilities += balance.abs();
          if (account.name.toLowerCase().contains('long') ||
              account.name.toLowerCase().contains('bond') ||
              account.name.toLowerCase().contains('mortgage')) {
            longTermDebt += balance.abs();
          } else {
            currentLiabilities += balance.abs();
          }
          break;
        case 'equity':
          equity += balance.abs();
          break;
      }
    }

    return BalanceSheetSnapshot(
      totalAssets: totalAssets,
      currentAssets: currentAssets,
      cash: cash,
      accountsReceivable: receivables,
      inventory: inventory,
      fixedAssets: fixedAssets,
      totalLiabilities: totalLiabilities,
      currentLiabilities: currentLiabilities,
      longTermDebt: longTermDebt,
      shareholdersEquity: equity,
    );
  }

  /// Get income statement snapshot from database
  Future<IncomeStatementSnapshot> getIncomeStatementSnapshot({
    required DateTimeRange period,
  }) async {
    final accounts = await _db.select(_db.accounts).get();

    int revenue = 0;
    int cogs = 0;
    int operatingExpenses = 0;
    int interestExpense = 0;
    int depreciation = 0;

    for (final account in accounts) {
      // Get entries within the period
      final entries =
          await (_db.select(_db.transactionEntries).join([
                  innerJoin(
                    _db.transactions,
                    _db.transactions.id.equalsExp(
                      _db.transactionEntries.transactionId,
                    ),
                  ),
                ])
                ..where(_db.transactionEntries.accountId.equals(account.id))
                ..where(
                  _db.transactions.transactionDate.isBetweenValues(
                    period.start,
                    period.end,
                  ),
                ))
              .get();

      int periodBalance = 0;
      for (final row in entries) {
        final entry = row.readTable(_db.transactionEntries);
        periodBalance += entry.amount;
      }

      switch (account.type.toLowerCase()) {
        case 'revenue':
          revenue += periodBalance.abs();
          break;
        case 'expense':
          if (account.name.toLowerCase().contains('cost of') ||
              account.name.toLowerCase().contains('cogs')) {
            cogs += periodBalance;
          } else if (account.name.toLowerCase().contains('interest')) {
            interestExpense += periodBalance;
          } else if (account.name.toLowerCase().contains('depreciation')) {
            depreciation += periodBalance;
          } else {
            operatingExpenses += periodBalance;
          }
          break;
      }
    }

    final grossProfit = revenue - cogs;
    final operatingIncome = grossProfit - operatingExpenses;
    final incomeBeforeTax = operatingIncome - interestExpense;
    // Estimate tax at 25% if positive
    final taxExpense = incomeBeforeTax > 0
        ? (incomeBeforeTax * 0.25).round()
        : 0;
    final netIncome = incomeBeforeTax - taxExpense;

    return IncomeStatementSnapshot(
      revenue: revenue,
      costOfGoodsSold: cogs,
      grossProfit: grossProfit,
      operatingExpenses: operatingExpenses,
      operatingIncome: operatingIncome,
      interestExpense: interestExpense,
      incomeBeforeTax: incomeBeforeTax,
      incomeTaxExpense: taxExpense,
      netIncome: netIncome,
      depreciation: depreciation,
      amortization: 0,
    );
  }

  /// Calculate all financial ratios for a period
  Future<FinancialRatiosResult> calculateAllRatios({
    required DateTimeRange period,
  }) async {
    final bs = await getBalanceSheetSnapshot(asOfDate: period.end);
    final is_ = await getIncomeStatementSnapshot(period: period);

    // Activity ratio calculations
    final invTurnover = calculateInventoryTurnover(
      costOfGoodsSold: is_.costOfGoodsSold,
      averageInventory: bs.inventory, // Simplified - would need prior period
    );
    final dsi = calculateDaysSalesInInventory(inventoryTurnover: invTurnover);

    final recTurnover = calculateReceivablesTurnover(
      netCreditSales: is_.revenue,
      averageReceivables: bs.accountsReceivable,
    );
    final dso = calculateDaysSalesOutstanding(receivablesTurnover: recTurnover);

    // Estimate purchases as COGS (simplified)
    final payTurnover = calculatePayablesTurnover(
      purchases: is_.costOfGoodsSold,
      averagePayables: bs.currentLiabilities,
    );
    final dpo = calculateDaysPayablesOutstanding(payablesTurnover: payTurnover);

    return FinancialRatiosResult(
      // Liquidity
      currentRatio: calculateCurrentRatio(
        currentAssets: bs.currentAssets,
        currentLiabilities: bs.currentLiabilities,
      ),
      quickRatio: calculateQuickRatio(
        cash: bs.cash,
        receivables: bs.accountsReceivable,
        currentLiabilities: bs.currentLiabilities,
      ),
      cashRatio: calculateCashRatio(
        cash: bs.cash,
        currentLiabilities: bs.currentLiabilities,
      ),
      workingCapital: calculateWorkingCapital(
        currentAssets: bs.currentAssets,
        currentLiabilities: bs.currentLiabilities,
      ),
      operatingCashFlowRatio: 0, // Would need cash flow statement
      // Activity
      inventoryTurnover: invTurnover,
      daysSalesInInventory: dsi,
      receivablesTurnover: recTurnover,
      daysSalesOutstanding: dso,
      payablesTurnover: payTurnover,
      daysPayablesOutstanding: dpo,
      cashConversionCycle: calculateCashConversionCycle(
        daysSalesInInventory: dsi,
        daysSalesOutstanding: dso,
        daysPayablesOutstanding: dpo,
      ),
      assetTurnover: calculateAssetTurnover(
        netSales: is_.revenue,
        averageTotalAssets: bs.totalAssets,
      ),
      fixedAssetTurnover: calculateFixedAssetTurnover(
        netSales: is_.revenue,
        averageNetFixedAssets: bs.fixedAssets,
      ),

      // Profitability
      grossProfitMargin: calculateGrossProfitMargin(
        revenue: is_.revenue,
        costOfGoodsSold: is_.costOfGoodsSold,
      ),
      operatingProfitMargin: calculateOperatingProfitMargin(
        operatingIncome: is_.operatingIncome,
        revenue: is_.revenue,
      ),
      netProfitMargin: calculateNetProfitMargin(
        netIncome: is_.netIncome,
        revenue: is_.revenue,
      ),
      returnOnAssets: calculateReturnOnAssets(
        netIncome: is_.netIncome,
        averageTotalAssets: bs.totalAssets,
      ),
      returnOnEquity: calculateReturnOnEquity(
        netIncome: is_.netIncome,
        averageShareholdersEquity: bs.shareholdersEquity,
      ),
      ebitdaMargin: calculateEBITDAMargin(
        ebitda: is_.ebitda,
        revenue: is_.revenue,
      ),

      // Leverage
      debtToEquityRatio: calculateDebtToEquityRatio(
        totalLiabilities: bs.totalLiabilities,
        shareholdersEquity: bs.shareholdersEquity,
      ),
      debtToAssetsRatio: calculateDebtToAssetsRatio(
        totalLiabilities: bs.totalLiabilities,
        totalAssets: bs.totalAssets,
      ),
      equityMultiplier: calculateEquityMultiplier(
        totalAssets: bs.totalAssets,
        shareholdersEquity: bs.shareholdersEquity,
      ),
      interestCoverageRatio: calculateInterestCoverageRatio(
        ebit: is_.ebit,
        interestExpense: is_.interestExpense,
      ),
      timesInterestEarned: calculateTimesInterestEarned(
        netIncome: is_.netIncome,
        interestExpense: is_.interestExpense,
        incomeTaxExpense: is_.incomeTaxExpense,
      ),
    );
  }
}

// ============================================================================
// BENEISH M-SCORE DATA CLASS
// ============================================================================

/// Beneish M-Score Result for earnings manipulation detection
/// Reference: Messod D. Beneish, "The Detection of Earnings Manipulation" (1999)
class BeneishMScoreResult {
  final double dsri; // Days Sales in Receivables Index
  final double gmi; // Gross Margin Index
  final double aqi; // Asset Quality Index
  final double sgi; // Sales Growth Index
  final double depi; // Depreciation Index
  final double sgai; // SG&A Index
  final double tata; // Total Accruals to Total Assets
  final double lvgi; // Leverage Index
  final double mScore;
  final String riskLevel; // 'LOW', 'MODERATE', 'HIGH'
  final bool isProbableManipulator;
  final List<String> redFlags;

  const BeneishMScoreResult({
    required this.dsri,
    required this.gmi,
    required this.aqi,
    required this.sgi,
    required this.depi,
    required this.sgai,
    required this.tata,
    required this.lvgi,
    required this.mScore,
    required this.riskLevel,
    required this.isProbableManipulator,
    required this.redFlags,
  });

  /// M-Score > -1.78 indicates probable manipulation
  static const double manipulationThreshold = -1.78;
}

/// Input data for M-Score calculation (requires 2 periods)
class MScoreInput {
  // Current Period
  final int currentRevenue;
  final int currentReceivables;
  final int currentGrossProfit;
  final int currentTotalAssets;
  final int currentCurrentAssets;
  final int currentPPE; // Property, Plant & Equipment
  final int currentDepreciation;
  final int currentSGA; // Selling, General & Administrative
  final int currentNetIncome;
  final int currentCFO; // Cash Flow from Operations
  final int currentLongTermDebt;
  final int currentCurrentLiabilities;

  // Prior Period
  final int priorRevenue;
  final int priorReceivables;
  final int priorGrossProfit;
  final int priorTotalAssets;
  final int priorCurrentAssets;
  final int priorPPE;
  final int priorDepreciation;
  final int priorSGA;
  final int priorLongTermDebt;
  final int priorCurrentLiabilities;

  const MScoreInput({
    required this.currentRevenue,
    required this.currentReceivables,
    required this.currentGrossProfit,
    required this.currentTotalAssets,
    required this.currentCurrentAssets,
    required this.currentPPE,
    required this.currentDepreciation,
    required this.currentSGA,
    required this.currentNetIncome,
    required this.currentCFO,
    required this.currentLongTermDebt,
    required this.currentCurrentLiabilities,
    required this.priorRevenue,
    required this.priorReceivables,
    required this.priorGrossProfit,
    required this.priorTotalAssets,
    required this.priorCurrentAssets,
    required this.priorPPE,
    required this.priorDepreciation,
    required this.priorSGA,
    required this.priorLongTermDebt,
    required this.priorCurrentLiabilities,
  });
}

// ============================================================================
// BENEISH M-SCORE CALCULATIONS (STATIC)
// ============================================================================

/// Static methods for Beneish M-Score fraud detection
///
/// The M-Score is an 8-variable model that identifies earnings manipulators.
/// M-Score > -1.78 indicates a HIGH probability of manipulation.
///
/// Formula:
/// M = -4.84 + 0.92×DSRI + 0.528×GMI + 0.404×AQI + 0.892×SGI
///     + 0.115×DEPI - 0.172×SGAI + 4.679×TATA - 0.327×LVGI
class BeneishMScore {
  BeneishMScore._(); // Private constructor - all methods are static

  // --------------------------------------------------------------------------
  // INDIVIDUAL INDICES
  // --------------------------------------------------------------------------

  /// Days Sales in Receivables Index (DSRI)
  /// Measures if receivables grew disproportionately to sales
  /// High DSRI (> 1.0) may indicate revenue inflation
  static double calculateDSRI({
    required int currentReceivables,
    required int currentRevenue,
    required int priorReceivables,
    required int priorRevenue,
  }) {
    if (priorRevenue == 0 || priorReceivables == 0 || currentRevenue == 0) {
      return 1.0; // Neutral
    }
    final currentDSR = currentReceivables / currentRevenue;
    final priorDSR = priorReceivables / priorRevenue;
    if (priorDSR == 0) return 1.0;
    return currentDSR / priorDSR;
  }

  /// Gross Margin Index (GMI)
  /// Measures deterioration in gross margins
  /// High GMI (> 1.0) indicates declining margins - motive to manipulate
  static double calculateGMI({
    required int currentRevenue,
    required int currentGrossProfit,
    required int priorRevenue,
    required int priorGrossProfit,
  }) {
    if (currentRevenue == 0 || priorRevenue == 0) return 1.0;
    final currentGM = currentGrossProfit / currentRevenue;
    final priorGM = priorGrossProfit / priorRevenue;
    if (currentGM == 0) return 1.0;
    return priorGM / currentGM;
  }

  /// Asset Quality Index (AQI)
  /// Measures change in non-current, non-PPE assets
  /// High AQI may indicate expense capitalization
  static double calculateAQI({
    required int currentTotalAssets,
    required int currentCurrentAssets,
    required int currentPPE,
    required int priorTotalAssets,
    required int priorCurrentAssets,
    required int priorPPE,
  }) {
    if (currentTotalAssets == 0 || priorTotalAssets == 0) return 1.0;

    final currentAQ =
        1 - (currentCurrentAssets + currentPPE) / currentTotalAssets;
    final priorAQ = 1 - (priorCurrentAssets + priorPPE) / priorTotalAssets;

    if (priorAQ == 0) return 1.0;
    return currentAQ / priorAQ;
  }

  /// Sales Growth Index (SGI)
  /// High growth increases pressure to meet targets
  static double calculateSGI({
    required int currentRevenue,
    required int priorRevenue,
  }) {
    if (priorRevenue == 0) return 1.0;
    return currentRevenue / priorRevenue;
  }

  /// Depreciation Index (DEPI)
  /// Measures if depreciation is slowing down
  /// High DEPI may indicate estimate manipulation
  static double calculateDEPI({
    required int currentDepreciation,
    required int currentPPE,
    required int priorDepreciation,
    required int priorPPE,
  }) {
    if (currentPPE == 0 || priorPPE == 0) return 1.0;

    final currentRate =
        currentDepreciation / (currentDepreciation + currentPPE);
    final priorRate = priorDepreciation / (priorDepreciation + priorPPE);

    if (currentRate == 0) return 1.0;
    return priorRate / currentRate;
  }

  /// SG&A Index (SGAI)
  /// Disproportionate increase may signal declining efficiency
  static double calculateSGAI({
    required int currentSGA,
    required int currentRevenue,
    required int priorSGA,
    required int priorRevenue,
  }) {
    if (currentRevenue == 0 || priorRevenue == 0) return 1.0;

    final currentRatio = currentSGA / currentRevenue;
    final priorRatio = priorSGA / priorRevenue;

    if (priorRatio == 0) return 1.0;
    return currentRatio / priorRatio;
  }

  /// Total Accruals to Total Assets (TATA)
  /// Higher accruals (vs cash) indicate lower earnings quality
  /// TATA = (Net Income - CFO) / Total Assets
  static double calculateTATA({
    required int currentNetIncome,
    required int currentCFO,
    required int currentTotalAssets,
  }) {
    if (currentTotalAssets == 0) return 0;
    return (currentNetIncome - currentCFO) / currentTotalAssets;
  }

  /// Leverage Index (LVGI)
  /// Increase in leverage increases covenant pressure
  static double calculateLVGI({
    required int currentLongTermDebt,
    required int currentCurrentLiabilities,
    required int currentTotalAssets,
    required int priorLongTermDebt,
    required int priorCurrentLiabilities,
    required int priorTotalAssets,
  }) {
    if (currentTotalAssets == 0 || priorTotalAssets == 0) return 1.0;

    final currentLev =
        (currentLongTermDebt + currentCurrentLiabilities) / currentTotalAssets;
    final priorLev =
        (priorLongTermDebt + priorCurrentLiabilities) / priorTotalAssets;

    if (priorLev == 0) return 1.0;
    return currentLev / priorLev;
  }

  // --------------------------------------------------------------------------
  // COMPLETE M-SCORE CALCULATION
  // --------------------------------------------------------------------------

  /// Calculate the complete Beneish M-Score
  ///
  /// M = -4.84 + 0.92×DSRI + 0.528×GMI + 0.404×AQI + 0.892×SGI
  ///     + 0.115×DEPI - 0.172×SGAI + 4.679×TATA - 0.327×LVGI
  ///
  /// Interpretation:
  /// - M-Score > -1.78: HIGH probability of manipulation
  /// - M-Score between -2.22 and -1.78: MODERATE risk
  /// - M-Score < -2.22: LOW probability of manipulation
  static BeneishMScoreResult calculate(MScoreInput input) {
    // Calculate all indices
    final dsri = calculateDSRI(
      currentReceivables: input.currentReceivables,
      currentRevenue: input.currentRevenue,
      priorReceivables: input.priorReceivables,
      priorRevenue: input.priorRevenue,
    );

    final gmi = calculateGMI(
      currentRevenue: input.currentRevenue,
      currentGrossProfit: input.currentGrossProfit,
      priorRevenue: input.priorRevenue,
      priorGrossProfit: input.priorGrossProfit,
    );

    final aqi = calculateAQI(
      currentTotalAssets: input.currentTotalAssets,
      currentCurrentAssets: input.currentCurrentAssets,
      currentPPE: input.currentPPE,
      priorTotalAssets: input.priorTotalAssets,
      priorCurrentAssets: input.priorCurrentAssets,
      priorPPE: input.priorPPE,
    );

    final sgi = calculateSGI(
      currentRevenue: input.currentRevenue,
      priorRevenue: input.priorRevenue,
    );

    final depi = calculateDEPI(
      currentDepreciation: input.currentDepreciation,
      currentPPE: input.currentPPE,
      priorDepreciation: input.priorDepreciation,
      priorPPE: input.priorPPE,
    );

    final sgai = calculateSGAI(
      currentSGA: input.currentSGA,
      currentRevenue: input.currentRevenue,
      priorSGA: input.priorSGA,
      priorRevenue: input.priorRevenue,
    );

    final tata = calculateTATA(
      currentNetIncome: input.currentNetIncome,
      currentCFO: input.currentCFO,
      currentTotalAssets: input.currentTotalAssets,
    );

    final lvgi = calculateLVGI(
      currentLongTermDebt: input.currentLongTermDebt,
      currentCurrentLiabilities: input.currentCurrentLiabilities,
      currentTotalAssets: input.currentTotalAssets,
      priorLongTermDebt: input.priorLongTermDebt,
      priorCurrentLiabilities: input.priorCurrentLiabilities,
      priorTotalAssets: input.priorTotalAssets,
    );

    // Calculate M-Score using Beneish coefficients
    final mScore =
        -4.84 +
        (0.920 * dsri) +
        (0.528 * gmi) +
        (0.404 * aqi) +
        (0.892 * sgi) +
        (0.115 * depi) -
        (0.172 * sgai) +
        (4.679 * tata) -
        (0.327 * lvgi);

    // Determine risk level
    final String riskLevel;
    final bool isProbableManipulator;

    if (mScore > -1.78) {
      riskLevel = 'HIGH';
      isProbableManipulator = true;
    } else if (mScore > -2.22) {
      riskLevel = 'MODERATE';
      isProbableManipulator = false;
    } else {
      riskLevel = 'LOW';
      isProbableManipulator = false;
    }

    // Identify red flags
    final redFlags = <String>[];

    if (dsri > 1.031) {
      redFlags.add(
        'High DSRI (${dsri.toStringAsFixed(3)}): Receivables growing faster than sales',
      );
    }
    if (gmi > 1.041) {
      redFlags.add(
        'High GMI (${gmi.toStringAsFixed(3)}): Deteriorating gross margins',
      );
    }
    if (aqi > 1.254) {
      redFlags.add(
        'High AQI (${aqi.toStringAsFixed(3)}): Possible expense capitalization',
      );
    }
    if (sgi > 1.134) {
      redFlags.add(
        'High SGI (${sgi.toStringAsFixed(3)}): High growth pressure',
      );
    }
    if (depi > 1.077) {
      redFlags.add(
        'High DEPI (${depi.toStringAsFixed(3)}): Slowing depreciation',
      );
    }
    if (tata > 0.018) {
      redFlags.add(
        'High TATA (${tata.toStringAsFixed(3)}): High accruals vs cash',
      );
    }
    if (lvgi > 1.111) {
      redFlags.add(
        'High LVGI (${lvgi.toStringAsFixed(3)}): Increasing leverage',
      );
    }

    return BeneishMScoreResult(
      dsri: dsri,
      gmi: gmi,
      aqi: aqi,
      sgi: sgi,
      depi: depi,
      sgai: sgai,
      tata: tata,
      lvgi: lvgi,
      mScore: mScore,
      riskLevel: riskLevel,
      isProbableManipulator: isProbableManipulator,
      redFlags: redFlags,
    );
  }

  /// Quick assessment using only 5 key variables (simplified model)
  /// Useful when CFO data is not available
  static double calculateSimplifiedMScore({
    required double dsri,
    required double gmi,
    required double aqi,
    required double sgi,
    required double tata,
  }) {
    return -6.065 +
        (0.823 * dsri) +
        (0.906 * gmi) +
        (0.593 * aqi) +
        (0.717 * sgi) +
        (4.840 * tata);
  }
}

// ============================================================================
// PROVIDERS
// ============================================================================

/// Provider for FinancialAnalysisService
final financialAnalysisServiceProvider = Provider<FinancialAnalysisService>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  return FinancialAnalysisService(db);
});

/// Provider for financial ratios with date range
final financialRatiosProvider =
    FutureProvider.family<FinancialRatiosResult, DateTimeRange>((ref, period) {
      final service = ref.watch(financialAnalysisServiceProvider);
      return service.calculateAllRatios(period: period);
    });
