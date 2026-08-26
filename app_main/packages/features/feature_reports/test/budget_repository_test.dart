import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core_database/core_database.dart';
import 'package:feature_reports/src/data/budget_repository.dart';

void main() {
  test('empty budget stream returns no summaries', () async {
    final db = AppDatabase.connect(NativeDatabase.memory());
    addTearDown(db.close);

    final summaries = await BudgetRepository(db).watchSummaries().first;

    expect(summaries, isEmpty);
  });

  test('budget persists and actuals respect the budget date range', () async {
    final db = AppDatabase.connect(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = BudgetRepository(db);

    final revenueAccount = await db
        .into(db.accounts)
        .insertReturning(
          AccountsCompanion.insert(
            name: 'Sales Revenue',
            type: 'revenue',
            initialBalance: 0,
          ),
        );
    final expenseAccount = await db
        .into(db.accounts)
        .insertReturning(
          AccountsCompanion.insert(
            name: 'Rent Expense',
            type: 'expense',
            initialBalance: 0,
          ),
        );

    final budgetStart = DateTime(2026, 1, 1);
    final budgetEnd = DateTime(2026, 1, 31, 23, 59, 59);
    final budgetId = await repository.createBudget(
      name: 'January operating budget',
      periodType: 'monthly',
      startDate: budgetStart,
      endDate: budgetEnd,
      status: 'active',
      budgetType: 'static',
      lines: [
        BudgetLineDraft(accountId: revenueAccount.id, budgetedAmount: 10000),
        BudgetLineDraft(accountId: expenseAccount.id, budgetedAmount: 4000),
      ],
    );

    final inPeriodTransaction = await db
        .into(db.transactions)
        .insertReturning(
          TransactionsCompanion.insert(
            description: 'January sale',
            transactionDate: DateTime(2026, 1, 15),
          ),
        );
    await db
        .into(db.transactionEntries)
        .insert(
          TransactionEntriesCompanion.insert(
            transactionId: inPeriodTransaction.id,
            accountId: revenueAccount.id,
            amount: -12000,
          ),
        );
    await db
        .into(db.transactionEntries)
        .insert(
          TransactionEntriesCompanion.insert(
            transactionId: inPeriodTransaction.id,
            accountId: expenseAccount.id,
            amount: 3000,
          ),
        );

    final outOfPeriodTransaction = await db
        .into(db.transactions)
        .insertReturning(
          TransactionsCompanion.insert(
            description: 'February sale',
            transactionDate: DateTime(2026, 2, 1),
          ),
        );
    await db
        .into(db.transactionEntries)
        .insert(
          TransactionEntriesCompanion.insert(
            transactionId: outOfPeriodTransaction.id,
            accountId: revenueAccount.id,
            amount: -90000,
          ),
        );

    final summaries = await repository.watchSummaries().firstWhere(
      (rows) => rows.isNotEmpty && rows.first.budget.id == budgetId,
    );
    final summary = summaries.single;

    expect(summary.actualRevenue, 12000);
    expect(summary.actualExpenses, 3000);
    expect(summary.budgetedNetIncome, 6000);
    expect(summary.actualNetIncome, 9000);
    expect(summary.netIncomeVariance, 3000);
  });

  test('invalid budget date range is rejected before persistence', () async {
    final db = AppDatabase.connect(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = BudgetRepository(db);

    expect(
      () => repository.createBudget(
        name: 'Invalid',
        periodType: 'custom',
        startDate: DateTime(2026, 1, 31),
        endDate: DateTime(2026, 1, 1),
        status: 'draft',
        budgetType: 'static',
        lines: const [],
      ),
      throwsArgumentError,
    );
  });
}
