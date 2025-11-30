// FILE: packages/features/feature_accounts/lib/src/data/accounts_repository.dart

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:core_database/src/initial_constants.dart' as c;
import 'package:feature_accounts/src/data/database_provider.dart';

final accountsRepositoryProvider = Provider<AccountsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  // 🛡️ TEMP FIX: Hardcode Tenant ID for Phase 3 Testing
  return AccountsRepository(db, tenantId: 'test_tenant_123');
});

class AccountsRepository {
  final AppDatabase _db;
  final String? tenantId; // 🌍 The Scope Context

  AccountsRepository(this._db, {this.tenantId});

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
    double initialBalance = 0.0,
    String? phoneNumber,
    String? classificationId,
  }) {
    final int balanceCents = (initialBalance * 100).round();

    final companion = AccountsCompanion.insert(
      name: name,
      type: type,
      initialBalance: balanceCents,
      phoneNumber: Value(phoneNumber),
      classificationId: Value(classificationId),
      // 🚀 INJECT TENANT ID
      tenantId: Value(tenantId),
    );
    return _db.into(_db.accounts).insert(companion);
  }

  Future<void> updateAccount(Account account) {
    // 🚀 PRESERVE TENANT ID ON UPDATE
    // When updating, we usually keep the existing tenantId, 
    // but ensuring it matches the current scope is safer.
    return _db.update(_db.accounts).replace(
        account.toCompanion(false).copyWith(
          lastUpdated: Value(DateTime.now()),
          tenantId: Value(tenantId), // Ensure ownership stays correct
        ));
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

  Future<double> getAccountBalance(String accountId) async {
    final account = await (_db.select(_db.accounts)
          ..where((tbl) => tbl.id.equals(accountId)))
        .getSingleOrNull();

    final int initialBalanceCents = account?.initialBalance ?? 0;

    final entries = _db.transactionEntries;
    final amountSum = entries.amount.sum();

    final result = await (_db.selectOnly(entries)
      ..where(entries.accountId.equals(accountId))
      ..addColumns([amountSum]))
      .getSingleOrNull();

    final int transactionTotalCents = result?.read(amountSum) ?? 0;
    final int totalCents = initialBalanceCents + transactionTotalCents;

    return totalCents / 100.0;
  }
}