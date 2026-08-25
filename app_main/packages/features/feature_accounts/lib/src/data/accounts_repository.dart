import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';

import 'package:feature_accounts/src/data/database_provider.dart';

final accountsRepositoryProvider = Provider<AccountsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final tenantContext = ref.watch(tenantContextProvider);
  final cloudMode = ref.watch(cloudDataModeProvider);
  return AccountsRepository(
    db,
    tenantIdResolver: cloudMode ? tenantContext.currentTenantId : null,
  );
});

class AccountsRepository {
  final AppDatabase _db;
  final String? tenantId;
  final Future<String> Function()? tenantIdResolver;

  AccountsRepository(this._db, {this.tenantId, this.tenantIdResolver});

  Future<String?> _resolveTenantId() async {
    final resolved = tenantId ?? await tenantIdResolver?.call();
    final normalized = resolved?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  Stream<List<Account>> watchAllAccounts() async* {
    final scope = await _resolveTenantId();
    final query = _db.select(_db.accounts)
      ..where((tbl) => tbl.isDeleted.equals(false))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]);
    if (scope == null) {
      query.where((tbl) => tbl.tenantId.isNull());
    } else {
      query.where((tbl) => tbl.tenantId.equals(scope));
    }
    yield* query.watch();
  }

  Stream<List<Account>> watchAccounts() async* {
    final scope = await _resolveTenantId();
    final query = _db.select(_db.accounts)
      ..where((tbl) => tbl.isDeleted.equals(false))
      ..where(
        (tbl) => tbl.name.isNotIn([
          kCashAccountName,
          kSalesRevenueAccountName,
          kEquityAccountName,
        ]),
      )
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]);
    if (scope == null) {
      query.where((tbl) => tbl.tenantId.isNull());
    } else {
      query.where((tbl) => tbl.tenantId.equals(scope));
    }
    yield* query.watch();
  }

  Future<void> createAccount({
    required String name,
    required String type,
    double initialBalance = 0.0,
    String? phoneNumber,
    String? classificationId,
    String? customAttributes,
  }) async {
    final scope = await _resolveTenantId();
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
    final scope = await _resolveTenantId();
    final update = _db.update(_db.accounts)
      ..where((tbl) => tbl.id.equals(account.id));
    if (scope == null) {
      update.where((tbl) => tbl.tenantId.isNull());
    } else {
      update.where((tbl) => tbl.tenantId.equals(scope));
    }
    await update.write(
      account
          .toCompanion(false)
          .copyWith(lastUpdated: Value(DateTime.now()), tenantId: Value(scope)),
    );
  }

  Future<void> deleteAccount(String id) async {
    final scope = await _resolveTenantId();
    final update = _db.update(_db.accounts)..where((tbl) => tbl.id.equals(id));
    if (scope == null) {
      update.where((tbl) => tbl.tenantId.isNull());
    } else {
      update.where((tbl) => tbl.tenantId.equals(scope));
    }
    await update.write(
      AccountsCompanion(
        isDeleted: const Value(true),
        lastUpdated: Value(DateTime.now()),
      ),
    );
  }

  Stream<List<Account>> watchAccountsByClassification(
    String classificationId,
  ) async* {
    final scope = await _resolveTenantId();
    final query = _db.select(_db.accounts)
      ..where((tbl) => tbl.isDeleted.equals(false))
      ..where((tbl) => tbl.classificationId.equals(classificationId))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]);
    if (scope == null) {
      query.where((tbl) => tbl.tenantId.isNull());
    } else {
      query.where((tbl) => tbl.tenantId.equals(scope));
    }
    yield* query.watch();
  }

  Future<String?> getClassificationIdByName(String name) async {
    final scope = await _resolveTenantId();
    final query = _db.select(_db.classifications)
      ..where((tbl) => tbl.isDeleted.equals(false))
      ..where((tbl) => tbl.name.equals(name));
    if (scope == null) {
      query.where((tbl) => tbl.tenantId.isNull());
    } else {
      query.where((tbl) => tbl.tenantId.equals(scope));
    }
    final classification = await query.getSingleOrNull();
    return classification?.id;
  }

  Future<String?> getAccountIdByName(String name) async {
    final scope = await _resolveTenantId();
    final query = _db.select(_db.accounts)
      ..where((tbl) => tbl.isDeleted.equals(false))
      ..where((tbl) => tbl.name.equals(name));
    if (scope == null) {
      query.where((tbl) => tbl.tenantId.isNull());
    } else {
      query.where((tbl) => tbl.tenantId.equals(scope));
    }
    final account = await query.getSingleOrNull();
    return account?.id;
  }

  Future<double> getAccountBalance(String accountId) async {
    final scope = await _resolveTenantId();
    final accountQuery = _db.select(_db.accounts)
      ..where((tbl) => tbl.id.equals(accountId));
    if (scope == null) {
      accountQuery.where((tbl) => tbl.tenantId.isNull());
    } else {
      accountQuery.where((tbl) => tbl.tenantId.equals(scope));
    }
    final account = await accountQuery.getSingleOrNull();

    final initialBalanceCents = account?.initialBalance ?? 0;
    final entries = _db.transactionEntries;
    final amountSum = entries.amount.sum();

    final entriesQuery = _db.selectOnly(entries)
      ..where(
        entries.accountId.equals(accountId) & entries.isDeleted.equals(false),
      )
      ..addColumns([amountSum]);
    if (scope == null) {
      entriesQuery.where(entries.tenantId.isNull());
    } else {
      entriesQuery.where(entries.tenantId.equals(scope));
    }
    final result = await entriesQuery.getSingleOrNull();

    final transactionTotalCents = result?.read(amountSum) ?? 0;
    return (initialBalanceCents + transactionTotalCents) / 100.0;
  }
}
