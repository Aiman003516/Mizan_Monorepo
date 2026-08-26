import 'package:async/async.dart';
import 'package:core_data/core_data.dart';
import 'package:core_database/core_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(ref.watch(appDatabaseProvider));
});

final budgetSummariesProvider =
    StreamProvider.autoDispose<List<BudgetReportSummary>>((ref) {
      return ref.watch(budgetRepositoryProvider).watchSummaries();
    });

class BudgetLineSummary {
  const BudgetLineSummary({
    required this.line,
    required this.account,
    required this.actualAmount,
  });

  final BudgetLine line;
  final Account account;
  final int actualAmount;

  int get variance => actualAmount - line.budgetedAmount;
  bool get isRevenue => account.type.toLowerCase() == 'revenue';
  bool get isFavorable => isRevenue ? variance > 0 : variance < 0;
}

class BudgetReportSummary {
  const BudgetReportSummary({required this.budget, required this.lines});

  final Budget budget;
  final List<BudgetLineSummary> lines;

  int get budgetedRevenue =>
      _sum('revenue', (line) => line.line.budgetedAmount);
  int get actualRevenue => _sum('revenue', (line) => line.actualAmount);
  int get budgetedExpenses =>
      _sum('expense', (line) => line.line.budgetedAmount);
  int get actualExpenses => _sum('expense', (line) => line.actualAmount);
  int get budgetedNetIncome => budgetedRevenue - budgetedExpenses;
  int get actualNetIncome => actualRevenue - actualExpenses;
  int get netIncomeVariance => actualNetIncome - budgetedNetIncome;

  int _sum(String type, int Function(BudgetLineSummary line) value) {
    return lines
        .where((line) => line.account.type.toLowerCase() == type)
        .fold(0, (total, line) => total + value(line));
  }
}

class BudgetRepository {
  BudgetRepository(this._db);

  final AppDatabase _db;

  Stream<List<Budget>> watchBudgets() {
    return (_db.select(_db.budgets)
          ..where((budget) => budget.isDeleted.equals(false))
          ..orderBy([(budget) => OrderingTerm.desc(budget.startDate)]))
        .watch();
  }

  Stream<List<BudgetReportSummary>> watchSummaries() {
    final budgets = watchBudgets();
    final lines = (_db.select(
      _db.budgetLines,
    )..where((line) => line.isDeleted.equals(false))).watch();
    final accounts = (_db.select(
      _db.accounts,
    )..where((account) => account.isDeleted.equals(false))).watch();
    final entries = _db.select(_db.transactionEntries).join([
      innerJoin(
        _db.transactions,
        _db.transactions.id.equalsExp(_db.transactionEntries.transactionId),
      ),
    ]).watch();

    return StreamZip([budgets, lines, accounts, entries]).map((values) {
      final budgetRows = values[0] as List<Budget>;
      final lineRows = values[1] as List<BudgetLine>;
      final accountRows = values[2] as List<Account>;
      final entryRows = values[3] as List<TypedResult>;
      final accountById = {
        for (final account in accountRows) account.id: account,
      };
      return budgetRows.map((budget) {
        final budgetLines = lineRows.where(
          (line) => line.budgetId == budget.id,
        );
        final summaries = <BudgetLineSummary>[];
        for (final line in budgetLines) {
          final account = accountById[line.accountId];
          if (account == null) continue;
          var actual = 0;
          for (final row in entryRows) {
            final entry = row.readTable(_db.transactionEntries);
            if (entry.accountId != account.id) continue;
            final transaction = row.readTable(_db.transactions);
            final date = transaction.transactionDate;
            if (!date.isBefore(budget.startDate) &&
                !date.isAfter(budget.endDate)) {
              actual += entry.amount;
            }
          }
          if (account.type.toLowerCase() == 'revenue') actual = -actual;
          summaries.add(
            BudgetLineSummary(
              line: line,
              account: account,
              actualAmount: actual,
            ),
          );
        }
        return BudgetReportSummary(budget: budget, lines: summaries);
      }).toList();
    });
  }

  Future<String> createBudget({
    required String name,
    String? description,
    required String periodType,
    required DateTime startDate,
    required DateTime endDate,
    required String status,
    required String budgetType,
    required List<BudgetLineDraft> lines,
  }) async {
    if (name.trim().isEmpty) throw ArgumentError('Budget name is required.');
    if (!endDate.isAfter(startDate)) {
      throw ArgumentError('Budget end date must be after its start date.');
    }
    final id = await _db.transaction(() async {
      final budgetId = await _db
          .into(_db.budgets)
          .insertReturning(
            BudgetsCompanion.insert(
              name: name.trim(),
              description: Value(
                description?.trim().isEmpty == true
                    ? null
                    : description?.trim(),
              ),
              periodType: periodType,
              startDate: startDate,
              endDate: endDate,
              status: Value(status),
              budgetType: Value(budgetType),
            ),
          );
      for (final line in lines) {
        if (line.budgetedAmount < 0) {
          throw ArgumentError('Budget amounts cannot be negative.');
        }
        await _db
            .into(_db.budgetLines)
            .insert(
              BudgetLinesCompanion.insert(
                budgetId: budgetId.id,
                accountId: line.accountId,
                budgetedAmount: line.budgetedAmount,
                notes: Value(line.notes),
              ),
            );
      }
      return budgetId.id;
    });
    return id;
  }

  Future<void> updateBudget(Budget budget) async {
    if (budget.name.trim().isEmpty ||
        !budget.endDate.isAfter(budget.startDate)) {
      throw ArgumentError('A budget requires a name and valid date range.');
    }
    await (_db.update(
      _db.budgets,
    )..where((row) => row.id.equals(budget.id))).write(
      BudgetsCompanion(
        name: Value(budget.name.trim()),
        description: Value(budget.description),
        periodType: Value(budget.periodType),
        startDate: Value(budget.startDate),
        endDate: Value(budget.endDate),
        status: Value(budget.status),
        budgetType: Value(budget.budgetType),
        lastUpdated: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateBudgetLine(BudgetLine line) async {
    if (line.budgetedAmount < 0) {
      throw ArgumentError('Budget amounts cannot be negative.');
    }
    await (_db.update(
      _db.budgetLines,
    )..where((row) => row.id.equals(line.id))).write(
      BudgetLinesCompanion(
        budgetedAmount: Value(line.budgetedAmount),
        notes: Value(line.notes),
        lastUpdated: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteBudget(String id) async {
    await (_db.update(_db.budgets)..where((row) => row.id.equals(id))).write(
      BudgetsCompanion(
        isDeleted: const Value(true),
        lastUpdated: Value(DateTime.now()),
      ),
    );
  }
}

class BudgetLineDraft {
  const BudgetLineDraft({
    required this.accountId,
    required this.budgetedAmount,
    this.notes,
  });

  final String accountId;
  final int budgetedAmount;
  final String? notes;
}
