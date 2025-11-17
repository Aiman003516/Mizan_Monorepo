import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:core_database/src/initial_constants.dart' as c;
import 'package:feature_accounts/src/data/database_provider.dart';

// This provider must be overridden in app_mizan
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('databaseProvider must be overridden');
});

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
    double initialBalance = 0.0,
    String? phoneNumber,
    String? classificationId,
  }) {
    final companion = AccountsCompanion.insert(
      name: name,
      type: type,
      initialBalance: initialBalance,
      phoneNumber: Value(phoneNumber),
      classificationId: Value(classificationId),
    );
    return _db.into(_db.accounts).insert(companion);
  }

  // Logic moved from database.dart
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

  // Logic moved from database.dart
  Future<String?> getAccountIdByName(String name) async {
    final account = await (_db.select(_db.accounts) ..where((tbl) => tbl.name.equals(name))).getSingleOrNull();
    return account?.id;
  }

  Future<double> getAccountBalance(String accountId) async {
    final account = await (_db.select(_db.accounts)
          ..where((tbl) => tbl.id.equals(accountId)))
        .getSingleOrNull();

    final initialBalance = account?.initialBalance ?? 0.0;
    final entriesTable = _db.transactionEntries;
    final entriesQuery = _db.select(entriesTable)
      ..where((tbl) => tbl.accountId.equals(accountId));
    final sumExpression = entriesTable.amount.sum();
    final result = await (entriesQuery.map((row) => sumExpression).getSingle()
        as Future<double?>);
    final transactionTotal = result ?? 0.0;
    return initialBalance + transactionTotal;
  }
}