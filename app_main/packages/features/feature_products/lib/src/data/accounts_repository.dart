// FILE: packages/features/feature_products/lib/src/data/accounts_repository.dart

import 'package:core_database/core_database.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// FIX: Import the local database provider
import 'package:feature_products/src/data/database_provider.dart';

final accountsRepositoryProvider = Provider<AccountsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return AccountsRepository(db);
});

class AccountsRepository {
  AccountsRepository(this._db);
  final AppDatabase _db;

  /// Watches all accounts, ordered by name.
  Stream<List<Account>> watchAccounts() {
    return (_db.select(_db.accounts)
      ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  /// Creates a new account.
  Future<void> createAccount({
    required String name,
    required String type,
    double initialBalance = 0.0,
  }) {
    // FIX: Convert Double (Dollars) to Int (Cents) for the database
    final int balanceCents = (initialBalance * 100).round();

    final companion = AccountsCompanion.insert(
      name: name,
      type: type,
      initialBalance: balanceCents, // Pass Int
    );
    return _db.into(_db.accounts).insert(companion);
  }

  /// Updates an existing account.
  Future<void> updateAccount(Account account) {
    return _db.update(_db.accounts).replace(
        account.toCompanion(false).copyWith(lastUpdated: Value(DateTime.now())));
  }

  /// Deletes an account.
  Future<void> deleteAccount(String id) {
    return (_db.delete(_db.accounts)..where((tbl) => tbl.id.equals(id))).go();
  }
}