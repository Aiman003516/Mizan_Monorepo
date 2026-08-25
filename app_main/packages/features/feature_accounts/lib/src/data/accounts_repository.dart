import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';

import 'package:feature_accounts/src/data/database_provider.dart';

final accountsRepositoryProvider = Provider<AccountsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final tenantContext = ref.watch(tenantContextProvider);
  return AccountsRepository(
    db,
    tenantIdResolver: tenantContext.currentTenantId,
  );
});

class AccountsRepository {
  final AppDatabase _db;
  final String? tenantId;
  final Future<String> Function()? tenantIdResolver;

  AccountsRepository(this._db, {this.tenantId, this.tenantIdResolver});

  Future<String> _requireTenantId() async {
    final resolved = tenantId ?? await tenantIdResolver?.call();
    if (resolved == null || resolved.trim().isEmpty) {
      throw StateError(
        'An authenticated tenant is required for account access.',
      );
    }
    return resolved;
  }

  Stream<List<Account>> watchAllAccounts() async* {
    final scope = await _requireTenantId();
    yield* (_db.select(_db.accounts)
          ..where((tbl) => tbl.tenantId.equals(scope))
          ..where((tbl) => tbl.isDeleted.equals(false))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
        .watch();
  }

  Stream<List<Account>> watchAccounts() async* {
    final scope = await _requireTenantId();
    yield* (_db.select(_db.accounts)
          ..where(
            (tbl) =>
                tbl.tenantId.equals(scope) &
                tbl.isDeleted.equals(false) &
                tbl.name.isNotIn([
                  kCashAccountName,
                  kSalesRevenueAccountName,
                  kEquityAccountName,
                ]),
          )
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
        .watch();
  }

  Future<void> createAccount({
    required String name,
    required String type,
    double initialBalance = 0.0,
    String? phoneNumber,
    String? classificationId,
    String? customAttributes,
  }) async {
    final scope = await _requireTenantId();
    final balanceCents = (initialBalance * 100).round();

    final companion = AccountsCompanion.insert(
      name: name,
      type: type,
      initialBalance: balanceCents,
      phoneNumber: Value(phoneNumber),
      classificationId: Value(classificationId),
      customAttributes: Value(customAttributes),
      tenantId: Value(scope),
    );
    await _db.into(_db.accounts).insert(companion);
  }

  Future<void> updateAccount(Account account) async {
    final scope = await _requireTenantId();
    await (_db.update(_db.accounts)..where(
          (tbl) => tbl.id.equals(account.id) & tbl.tenantId.equals(scope),
        ))
        .write(
          account
              .toCompanion(false)
              .copyWith(
                lastUpdated: Value(DateTime.now()),
                tenantId: Value(scope),
              ),
        );
  }

  Future<void> deleteAccount(String id) async {
    final scope = await _requireTenantId();
    await (_db.update(
      _db.accounts,
    )..where((tbl) => tbl.id.equals(id) & tbl.tenantId.equals(scope))).write(
      AccountsCompanion(
        isDeleted: const Value(true),
        lastUpdated: Value(DateTime.now()),
      ),
    );
  }

  Stream<List<Account>> watchAccountsByClassification(
    String classificationId,
  ) async* {
    final scope = await _requireTenantId();
    yield* (_db.select(_db.accounts)
          ..where(
            (tbl) =>
                tbl.tenantId.equals(scope) &
                tbl.isDeleted.equals(false) &
                tbl.classificationId.equals(classificationId),
          )
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
        .watch();
  }

  Future<String?> getClassificationIdByName(String name) async {
    final scope = await _requireTenantId();
    final classification =
        await (_db.select(_db.classifications)..where(
              (tbl) =>
                  tbl.tenantId.equals(scope) &
                  tbl.isDeleted.equals(false) &
                  tbl.name.equals(name),
            ))
            .getSingleOrNull();
    return classification?.id;
  }

  Future<String?> getAccountIdByName(String name) async {
    final scope = await _requireTenantId();
    final account =
        await (_db.select(_db.accounts)..where(
              (tbl) =>
                  tbl.tenantId.equals(scope) &
                  tbl.isDeleted.equals(false) &
                  tbl.name.equals(name),
            ))
            .getSingleOrNull();
    return account?.id;
  }

  Future<double> getAccountBalance(String accountId) async {
    final scope = await _requireTenantId();
    final account =
        await (_db.select(_db.accounts)..where(
              (tbl) => tbl.id.equals(accountId) & tbl.tenantId.equals(scope),
            ))
            .getSingleOrNull();

    final initialBalanceCents = account?.initialBalance ?? 0;
    final entries = _db.transactionEntries;
    final amountSum = entries.amount.sum();

    final result =
        await (_db.selectOnly(entries)
              ..where(
                entries.accountId.equals(accountId) &
                    entries.tenantId.equals(scope) &
                    entries.isDeleted.equals(false),
              )
              ..addColumns([amountSum]))
            .getSingleOrNull();

    final transactionTotalCents = result?.read(amountSum) ?? 0;
    return (initialBalanceCents + transactionTotalCents) / 100.0;
  }
}
