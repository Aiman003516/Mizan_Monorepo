// FILE: packages/core/core_data/lib/src/services/budgeting_service.dart
// Purpose: Budget management and variance analysis
// Reference: Accounting Principles 13e (Weygandt), Chapters 23-24 - Budgetary Planning & Control

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:drift/drift.dart';

// ============================================================================
// DATA CLASSES
// ============================================================================

/// Variance result for a single account
class BudgetVarianceResult {
  final String accountId;
  final String accountName;
  final String accountType;
  final int budgetedAmount;
  final int actualAmount;
  final int
  variance; // Actual - Budgeted (negative = under budget for expenses)
  final double variancePercent;
  final bool isFavorable;

  const BudgetVarianceResult({
    required this.accountId,
    required this.accountName,
    required this.accountType,
    required this.budgetedAmount,
    required this.actualAmount,
    required this.variance,
    required this.variancePercent,
    required this.isFavorable,
  });
}

/// Flexible budget calculation result
class FlexibleBudgetResult {
  final int staticBudget; // Original budgeted amount
  final int flexibleBudget; // Adjusted for actual activity
  final int actualAmount;
  final int volumeVariance; // Flexible - Static (due to activity level)
  final int spendingVariance; // Actual - Flexible (due to efficiency)
  final int totalVariance; // Actual - Static
  final int plannedActivity;
  final int actualActivity;

  const FlexibleBudgetResult({
    required this.staticBudget,
    required this.flexibleBudget,
    required this.actualAmount,
    required this.volumeVariance,
    required this.spendingVariance,
    required this.totalVariance,
    required this.plannedActivity,
    required this.actualActivity,
  });
}

/// Summary of budget vs actual performance
class BudgetSummary {
  final String budgetId;
  final String budgetName;
  final DateTime startDate;
  final DateTime endDate;
  final int totalBudgetedRevenue;
  final int totalActualRevenue;
  final int totalBudgetedExpenses;
  final int totalActualExpenses;
  final int budgetedNetIncome;
  final int actualNetIncome;
  final List<BudgetVarianceResult> lineItems;

  const BudgetSummary({
    required this.budgetId,
    required this.budgetName,
    required this.startDate,
    required this.endDate,
    required this.totalBudgetedRevenue,
    required this.totalActualRevenue,
    required this.totalBudgetedExpenses,
    required this.totalActualExpenses,
    required this.budgetedNetIncome,
    required this.actualNetIncome,
    required this.lineItems,
  });

  int get revenueVariance => totalActualRevenue - totalBudgetedRevenue;
  int get expenseVariance => totalActualExpenses - totalBudgetedExpenses;
  int get netIncomeVariance => actualNetIncome - budgetedNetIncome;

  double get revenueVariancePercent =>
      totalBudgetedRevenue > 0 ? revenueVariance / totalBudgetedRevenue : 0;
  double get expenseVariancePercent =>
      totalBudgetedExpenses > 0 ? expenseVariance / totalBudgetedExpenses : 0;
}

/// Budget period type
enum BudgetPeriodType { monthly, quarterly, annual, custom }

/// Budget status
enum BudgetStatus { draft, active, closed, archived }

// ============================================================================
// SERVICE
// ============================================================================

/// Service for budget management and variance analysis
///
/// Reference: Accounting Principles 13e (Weygandt), Chapters 23-24
class BudgetingService {
  final AppDatabase _db;

  BudgetingService(this._db);

  // ========================================================================
  // BUDGET CRUD OPERATIONS
  // ========================================================================

  /// Create a new budget
  Future<String> createBudget({
    required String name,
    String? description,
    required BudgetPeriodType periodType,
    required DateTime startDate,
    required DateTime endDate,
    bool isFlexible = false,
    int? plannedActivityLevel,
  }) async {
    final budget = BudgetsCompanion.insert(
      name: name,
      description: Value(description),
      periodType: periodType.name,
      startDate: startDate,
      endDate: endDate,
      status: const Value('draft'),
      budgetType: Value(isFlexible ? 'flexible' : 'static'),
      flexibleActivityLevel: Value(plannedActivityLevel),
    );

    final id = await _db.into(_db.budgets).insert(budget);
    final inserted = await (_db.select(
      _db.budgets,
    )..where((t) => t.rowId.equals(id))).getSingle();
    return inserted.id;
  }

  /// Add a budget line item
  Future<void> addBudgetLine({
    required String budgetId,
    required String accountId,
    required int budgetedAmount,
    int fixedPortion = 0,
    int variableRate = 0,
    String? notes,
  }) async {
    final line = BudgetLinesCompanion.insert(
      budgetId: budgetId,
      accountId: accountId,
      budgetedAmount: budgetedAmount,
      fixedPortion: Value(fixedPortion),
      variableRate: Value(variableRate),
      notes: Value(notes),
    );

    await _db.into(_db.budgetLines).insert(line);
  }

  /// Update budget line amount
  Future<void> updateBudgetLine({
    required String lineId,
    int? budgetedAmount,
    int? fixedPortion,
    int? variableRate,
    String? notes,
  }) async {
    await (_db.update(
      _db.budgetLines,
    )..where((t) => t.id.equals(lineId))).write(
      BudgetLinesCompanion(
        budgetedAmount: budgetedAmount != null
            ? Value(budgetedAmount)
            : const Value.absent(),
        fixedPortion: fixedPortion != null
            ? Value(fixedPortion)
            : const Value.absent(),
        variableRate: variableRate != null
            ? Value(variableRate)
            : const Value.absent(),
        notes: notes != null ? Value(notes) : const Value.absent(),
        lastUpdated: Value(DateTime.now()),
      ),
    );
  }

  /// Get all budgets
  Future<List<Budget>> getAllBudgets() async {
    return await (_db.select(_db.budgets)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Get budget by ID with lines
  Future<Budget?> getBudget(String budgetId) async {
    return await (_db.select(
      _db.budgets,
    )..where((t) => t.id.equals(budgetId))).getSingleOrNull();
  }

  /// Get budget lines for a budget
  Future<List<BudgetLine>> getBudgetLines(String budgetId) async {
    return await (_db.select(_db.budgetLines)
          ..where((t) => t.budgetId.equals(budgetId))
          ..where((t) => t.isDeleted.equals(false)))
        .get();
  }

  /// Activate a budget
  Future<void> activateBudget(String budgetId) async {
    await (_db.update(_db.budgets)..where((t) => t.id.equals(budgetId))).write(
      BudgetsCompanion(
        status: const Value('active'),
        lastUpdated: Value(DateTime.now()),
      ),
    );
  }

  /// Close a budget
  Future<void> closeBudget(String budgetId) async {
    await (_db.update(_db.budgets)..where((t) => t.id.equals(budgetId))).write(
      BudgetsCompanion(
        status: const Value('closed'),
        lastUpdated: Value(DateTime.now()),
      ),
    );
  }

  // ========================================================================
  // VARIANCE ANALYSIS (PURE CALCULATIONS)
  // ========================================================================

  /// Calculate budget variance
  /// Favorable: For expenses, actual < budget. For revenue, actual > budget.
  static BudgetVarianceResult calculateVariance({
    required String accountId,
    required String accountName,
    required String accountType,
    required int budgetedAmount,
    required int actualAmount,
  }) {
    final variance = actualAmount - budgetedAmount;
    final variancePercent = budgetedAmount != 0
        ? variance / budgetedAmount
        : 0.0;

    // Determine if favorable
    // For expenses: under budget (negative variance) is favorable
    // For revenues: over budget (positive variance) is favorable
    final bool isFavorable;
    if (accountType == 'expense') {
      isFavorable = variance < 0; // Spending less is good
    } else if (accountType == 'revenue') {
      isFavorable = variance > 0; // Earning more is good
    } else {
      isFavorable = false; // Assets/Liabilities - neutral
    }

    return BudgetVarianceResult(
      accountId: accountId,
      accountName: accountName,
      accountType: accountType,
      budgetedAmount: budgetedAmount,
      actualAmount: actualAmount,
      variance: variance,
      variancePercent: variancePercent,
      isFavorable: isFavorable,
    );
  }

  /// Calculate flexible budget
  /// Flexible Budget = Fixed Costs + (Variable Rate × Actual Activity Level)
  static FlexibleBudgetResult calculateFlexibleBudget({
    required int fixedPortion,
    required int variableRate,
    required int plannedActivity,
    required int actualActivity,
    required int actualAmount,
  }) {
    // Static budget (what we originally planned)
    final staticBudget = fixedPortion + (variableRate * plannedActivity);

    // Flexible budget (adjusted for actual activity)
    final flexibleBudget = fixedPortion + (variableRate * actualActivity);

    // Volume Variance = Flexible Budget - Static Budget
    // Shows variance due to activity level being different than planned
    final volumeVariance = flexibleBudget - staticBudget;

    // Spending Variance = Actual - Flexible Budget
    // Shows variance due to efficiency/price differences
    final spendingVariance = actualAmount - flexibleBudget;

    // Total Variance = Actual - Static Budget
    final totalVariance = actualAmount - staticBudget;

    return FlexibleBudgetResult(
      staticBudget: staticBudget,
      flexibleBudget: flexibleBudget,
      actualAmount: actualAmount,
      volumeVariance: volumeVariance,
      spendingVariance: spendingVariance,
      totalVariance: totalVariance,
      plannedActivity: plannedActivity,
      actualActivity: actualActivity,
    );
  }

  /// Calculate percentage variance
  static double calculateVariancePercent(int budgeted, int actual) {
    if (budgeted == 0) return 0;
    return (actual - budgeted) / budgeted;
  }

  // ========================================================================
  // BUDGET VS ACTUAL REPORTS
  // ========================================================================

  /// Get budget vs actual summary with variances
  Future<BudgetSummary> getBudgetVsActual(String budgetId) async {
    final budget = await getBudget(budgetId);
    if (budget == null) {
      throw Exception('Budget not found: $budgetId');
    }

    final lines = await getBudgetLines(budgetId);
    final variances = <BudgetVarianceResult>[];

    int totalBudgetedRevenue = 0;
    int totalActualRevenue = 0;
    int totalBudgetedExpenses = 0;
    int totalActualExpenses = 0;

    for (final line in lines) {
      // Get the account
      final account = await (_db.select(
        _db.accounts,
      )..where((t) => t.id.equals(line.accountId))).getSingleOrNull();

      if (account == null) continue;

      // Calculate actual amount for this account in the budget period
      final actualAmount = await _getActualAmountForAccount(
        accountId: line.accountId,
        startDate: budget.startDate,
        endDate: budget.endDate,
      );

      // Calculate variance
      final result = calculateVariance(
        accountId: line.accountId,
        accountName: account.name,
        accountType: account.type,
        budgetedAmount: line.budgetedAmount,
        actualAmount: actualAmount,
      );

      variances.add(result);

      // Aggregate by type
      if (account.type == 'revenue') {
        totalBudgetedRevenue += line.budgetedAmount;
        totalActualRevenue += actualAmount;
      } else if (account.type == 'expense') {
        totalBudgetedExpenses += line.budgetedAmount;
        totalActualExpenses += actualAmount;
      }
    }

    return BudgetSummary(
      budgetId: budget.id,
      budgetName: budget.name,
      startDate: budget.startDate,
      endDate: budget.endDate,
      totalBudgetedRevenue: totalBudgetedRevenue,
      totalActualRevenue: totalActualRevenue,
      totalBudgetedExpenses: totalBudgetedExpenses,
      totalActualExpenses: totalActualExpenses,
      budgetedNetIncome: totalBudgetedRevenue - totalBudgetedExpenses,
      actualNetIncome: totalActualRevenue - totalActualExpenses,
      lineItems: variances,
    );
  }

  /// Get actual amount for an account within a date range
  Future<int> _getActualAmountForAccount({
    required String accountId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Sum all transaction entries for this account in the period
    final entries =
        await (_db.select(_db.transactionEntries).join([
                innerJoin(
                  _db.transactions,
                  _db.transactions.id.equalsExp(
                    _db.transactionEntries.transactionId,
                  ),
                ),
              ])
              ..where(_db.transactionEntries.accountId.equals(accountId))
              ..where(
                _db.transactions.transactionDate.isBetweenValues(
                  startDate,
                  endDate,
                ),
              )
              ..where(_db.transactions.isDeleted.equals(false)))
            .get();

    int total = 0;
    for (final entry in entries) {
      final te = entry.readTable(_db.transactionEntries);
      total += te.amount;
    }

    return total.abs(); // Return absolute value for comparison
  }

  /// Get active budgets for a date
  Future<List<Budget>> getActiveBudgetsForDate(DateTime date) async {
    return await (_db.select(_db.budgets)
          ..where((t) => t.status.equals('active'))
          ..where((t) => t.startDate.isSmallerOrEqualValue(date))
          ..where((t) => t.endDate.isBiggerOrEqualValue(date))
          ..where((t) => t.isDeleted.equals(false)))
        .get();
  }

  // ========================================================================
  // HELPER: GENERATE BUDGET FROM PRIOR PERIOD
  // ========================================================================

  /// Create a budget based on prior period actuals
  Future<String> createBudgetFromPriorPeriod({
    required String name,
    required DateTime priorStartDate,
    required DateTime priorEndDate,
    required DateTime newStartDate,
    required DateTime newEndDate,
    double adjustmentPercent = 0, // e.g., 0.05 for 5% increase
  }) async {
    // Create new budget
    final budgetId = await createBudget(
      name: name,
      periodType: BudgetPeriodType.custom,
      startDate: newStartDate,
      endDate: newEndDate,
    );

    // Get all accounts with activity in prior period
    final revenueAccounts =
        await (_db.select(_db.accounts)
              ..where((t) => t.type.equals('revenue'))
              ..where((t) => t.isDeleted.equals(false)))
            .get();

    final expenseAccounts =
        await (_db.select(_db.accounts)
              ..where((t) => t.type.equals('expense'))
              ..where((t) => t.isDeleted.equals(false)))
            .get();

    // Add budget lines based on prior actuals
    for (final account in [...revenueAccounts, ...expenseAccounts]) {
      final priorAmount = await _getActualAmountForAccount(
        accountId: account.id,
        startDate: priorStartDate,
        endDate: priorEndDate,
      );

      if (priorAmount > 0) {
        final adjustedAmount = (priorAmount * (1 + adjustmentPercent)).round();
        await addBudgetLine(
          budgetId: budgetId,
          accountId: account.id,
          budgetedAmount: adjustedAmount,
          notes: 'Based on prior period: $priorAmount',
        );
      }
    }

    return budgetId;
  }
}

// ============================================================================
// PROVIDER
// ============================================================================

/// Provider for BudgetingService
final budgetingServiceProvider = Provider<BudgetingService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return BudgetingService(db);
});
