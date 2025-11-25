// FILE: packages/features/feature_accounts/lib/src/data/accounts_repository.dart

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:core_database/src/initial_constants.dart' as c;
// FIX: Import the provider from its source, do not redefine it
import 'package:feature_accounts/src/data/database_provider.dart';

final accountsRepositoryProvider = Provider<AccountsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return AccountsRepository(db);
});

class AccountsRepository {
  AccountsRepository(this._db);
  final AppDatabase _db;

  Stream<List<Account>> watchAllAccounts() {
    return (_db.select(_db.accounts)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Stream<List<Account>> watchAccounts() {
    return (_db.select(_db.accounts)
          ..where((tbl) => tbl.name.isNotIn([
                c.kCashAccountName,
                c.kSalesRevenueAccountName,
                c.kEquityAccountName
              ]))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Future<void> createAccount({
    required String name,
    required String type,
    double initialBalance = 0.0, // Kept as double for API consistency
    String? phoneNumber,
    String? classificationId,
  }) {
    // FIX: Convert Double (Dollars) to Int (Cents)
    final int balanceCents = (initialBalance * 100).round();

    final companion = AccountsCompanion.insert(
      name: name,
      type: type,
      initialBalance: balanceCents, // Pass Int
      phoneNumber: Value(phoneNumber),
      classificationId: Value(classificationId),
    );
    return _db.into(_db.accounts).insert(companion);
  }

  Future<void> updateAccount(Account account) {
    return _db.update(_db.accounts).replace(
        account.toCompanion(false).copyWith(lastUpdated: Value(DateTime.now())));
  }

  Future<void> deleteAccount(String id) {
    return (_db.delete(_db.accounts)..where((tbl) => tbl.id.equals(id))).go();
  }

  Stream<List<Account>> watchAccountsByClassification(String classificationId) {
    return (_db.select(_db.accounts)
          ..where((tbl) => tbl.classificationId.equals(classificationId))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Future<String?> getClassificationIdByName(String name) async {
    final classification = await (_db.select(_db.classifications)
          ..where((tbl) => tbl.name.equals(name)))
        .getSingleOrNull();
    return classification?.id;
  }

  Future<String?> getAccountIdByName(String name) async {
    final account = await (_db.select(_db.accounts)
          ..where((tbl) => tbl.name.equals(name)))
        .getSingleOrNull();
    return account?.id;
  }

  // FIX: Use SQL Aggregation (selectOnly) for performance
  Future<double> getAccountBalance(String accountId) async {
    // 1. Get Initial Balance (Int)
    final account = await (_db.select(_db.accounts)
          ..where((tbl) => tbl.id.equals(accountId)))
        .getSingleOrNull();

    final int initialBalanceCents = account?.initialBalance ?? 0;

    // 2. Sum Transactions (SQL SUM)
    final entries = _db.transactionEntries;
    final amountSum = entries.amount.sum();

    final result = await (_db.selectOnly(entries)
      ..where(entries.accountId.equals(accountId))
      ..addColumns([amountSum]))
      .getSingleOrNull();

    // 3. Calculate Total
    final int transactionTotalCents = result?.read(amountSum) ?? 0;
    final int totalCents = initialBalanceCents + transactionTotalCents;

    // 4. Convert to Double for UI
    return totalCents / 100.0;
  }
}