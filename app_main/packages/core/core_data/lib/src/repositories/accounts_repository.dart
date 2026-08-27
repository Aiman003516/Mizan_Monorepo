import 'package:core_database/core_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/cloud_data_mode_provider.dart';
import '../tenant_context.dart';

final accountsRepositoryProvider = Provider<AccountsRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  final tenantContext = ref.watch(tenantContextProvider);
  final cloudMode = ref.watch(cloudDataModeProvider);
  return AccountsRepository(
    database,
    tenantIdResolver: cloudMode ? tenantContext.currentTenantId : null,
  );
});

final accountsStreamProvider = StreamProvider<List<Account>>((ref) {
  return ref.watch(accountsRepositoryProvider).watchAccounts();
});

final allAccountsStreamProvider = StreamProvider<List<Account>>((ref) {
  return ref.watch(accountsRepositoryProvider).watchAllAccounts();
});

/// Public account query/mutation contract shared by ledger-facing features.
/// Account screens remain owned by feature_accounts; this repository belongs to
/// the core data boundary so reports, transactions, POS, and future contexts do
/// not depend on another feature's private implementation.
class AccountsRepository {
  const AccountsRepository(this._db, {this.tenantId, this.tenantIdResolver});

  final AppDatabase _db;
  final String? tenantId;
  final Future<String> Function()? tenantIdResolver;

  Future<String?> _resolveTenantId() async {
    final resolved = tenantId ?? await tenantIdResolver?.call();
    final normalized = resolved?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  Stream<List<Account>> watchAllAccounts() async* {
    final scope = await _resolveTenantId();
    final query = _db.select(_db.accounts)
      ..where((table) => table.isDeleted.equals(false))
      ..orderBy([(table) => OrderingTerm.asc(table.name)]);
    if (scope == null) {
      query.where((table) => table.tenantId.isNull());
    } else {
      query.where((table) => table.tenantId.equals(scope));
    }
    yield* query.watch();
  }

  Stream<List<Account>> watchAccounts() async* {
    final scope = await _resolveTenantId();
    final query = _db.select(_db.accounts)
      ..where((table) => table.isDeleted.equals(false))
      ..where(
        (table) => table.name.isNotIn([
          kCashAccountName,
          kSalesRevenueAccountName,
          kEquityAccountName,
        ]),
      )
      ..orderBy([(table) => OrderingTerm.asc(table.name)]);
    if (scope == null) {
      query.where((table) => table.tenantId.isNull());
    } else {
      query.where((table) => table.tenantId.equals(scope));
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
    await _db
        .into(_db.accounts)
        .insert(
          AccountsCompanion.insert(
            name: name.trim(),
            type: type,
            initialBalance: balanceCents,
            phoneNumber: Value(phoneNumber),
            classificationId: Value(classificationId),
            customAttributes: Value(customAttributes),
            tenantId: Value(scope),
          ),
        );
  }

  Future<void> updateAccount(Account account) async {
    final scope = await _resolveTenantId();
    final update = _db.update(_db.accounts)
      ..where((table) => table.id.equals(account.id));
    if (scope == null) {
      update.where((table) => table.tenantId.isNull());
    } else {
      update.where((table) => table.tenantId.equals(scope));
    }
    await update.write(
      account
          .toCompanion(false)
          .copyWith(
            lastUpdated: Value(DateTime.now().toUtc()),
            tenantId: Value(scope),
          ),
    );
  }

  Future<void> deleteAccount(String id) async {
    final scope = await _resolveTenantId();
    final update = _db.update(_db.accounts)
      ..where((table) => table.id.equals(id));
    if (scope == null) {
      update.where((table) => table.tenantId.isNull());
    } else {
      update.where((table) => table.tenantId.equals(scope));
    }
    await update.write(
      AccountsCompanion(
        isDeleted: const Value(true),
        lastUpdated: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Stream<List<Account>> watchAccountsByClassification(
    String classificationId,
  ) async* {
    final scope = await _resolveTenantId();
    final query = _db.select(_db.accounts)
      ..where((table) => table.isDeleted.equals(false))
      ..where((table) => table.classificationId.equals(classificationId))
      ..orderBy([(table) => OrderingTerm.asc(table.name)]);
    if (scope == null) {
      query.where((table) => table.tenantId.isNull());
    } else {
      query.where((table) => table.tenantId.equals(scope));
    }
    yield* query.watch();
  }

  Future<String?> getClassificationIdByName(String name) async {
    final scope = await _resolveTenantId();
    final query = _db.select(_db.classifications)
      ..where((table) => table.isDeleted.equals(false))
      ..where((table) => table.name.equals(name));
    if (scope == null) {
      query.where((table) => table.tenantId.isNull());
    } else {
      query.where((table) => table.tenantId.equals(scope));
    }
    return (await query.getSingleOrNull())?.id;
  }

  Future<String?> getAccountIdByName(String name) async {
    final scope = await _resolveTenantId();
    final query = _db.select(_db.accounts)
      ..where((table) => table.isDeleted.equals(false))
      ..where((table) => table.name.equals(name));
    if (scope == null) {
      query.where((table) => table.tenantId.isNull());
    } else {
      query.where((table) => table.tenantId.equals(scope));
    }
    return (await query.getSingleOrNull())?.id;
  }

  Future<double> getAccountBalance(String accountId) async {
    final scope = await _resolveTenantId();
    final accountQuery = _db.select(_db.accounts)
      ..where((table) => table.id.equals(accountId));
    if (scope == null) {
      accountQuery.where((table) => table.tenantId.isNull());
    } else {
      accountQuery.where((table) => table.tenantId.equals(scope));
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
