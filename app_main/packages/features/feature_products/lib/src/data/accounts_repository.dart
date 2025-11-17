import 'package:core_database/core_database.dart';
import 'package:drift/drift.dart';
import 'package:feature_products/feature_products.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Create a provider for the repository
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
    // --- THIS IS THE CORRECTED LINE ---
      ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  /// Creates a new account.
  Future<void> createAccount({
    required String name,
    required String type,
    double initialBalance = 0.0,
  }) {
    final companion = AccountsCompanion.insert(
      name: name,
      type: type,
      initialBalance: initialBalance,
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