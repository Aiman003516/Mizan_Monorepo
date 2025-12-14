import 'package:core_database/core_database.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Providers
final bankReconciliationRepositoryProvider =
    Provider<BankReconciliationRepository>((ref) {
      final db = ref.watch(appDatabaseProvider);
      return BankReconciliationRepository(db);
    });

final reconciliationsStreamProvider = StreamProvider.autoDispose
    .family<List<BankReconciliation>, String>((ref, accountId) {
      return ref
          .watch(bankReconciliationRepositoryProvider)
          .watchReconciliationsForAccount(accountId);
    });

final unreconciledTransactionsProvider = FutureProvider.autoDispose
    .family<List<UnreconciledTransaction>, String>((ref, accountId) {
      return ref
          .watch(bankReconciliationRepositoryProvider)
          .getUnreconciledTransactions(accountId);
    });

/// Unreconciled transaction with details
class UnreconciledTransaction {
  final Transaction transaction;
  final double amount;
  final String? description;
  bool isSelected;

  UnreconciledTransaction({
    required this.transaction,
    required this.amount,
    this.description,
    this.isSelected = false,
  });
}

/// Reconciliation summary
class ReconciliationSummary {
  final BankReconciliation reconciliation;
  final Account account;
  final int reconciledCount;
  final double reconciledTotal;

  ReconciliationSummary({
    required this.reconciliation,
    required this.account,
    required this.reconciledCount,
    required this.reconciledTotal,
  });
}

/// Bank Reconciliation Repository
class BankReconciliationRepository {
  final AppDatabase _db;

  BankReconciliationRepository(this._db);

  // ==================== RECONCILIATIONS ====================

  /// Watch all reconciliations for an account
  Stream<List<BankReconciliation>> watchReconciliationsForAccount(
    String accountId,
  ) {
    return (_db.select(_db.bankReconciliations)
          ..where((r) => r.accountId.equals(accountId))
          ..orderBy([(r) => OrderingTerm.desc(r.statementDate)]))
        .watch();
  }

  /// Get all reconciliations (for listing)
  Stream<List<ReconciliationSummary>> watchAllReconciliations() async* {
    final recsQuery = _db.select(_db.bankReconciliations)
      ..orderBy([(r) => OrderingTerm.desc(r.statementDate)]);

    await for (final recs in recsQuery.watch()) {
      final summaries = <ReconciliationSummary>[];
      for (final rec in recs) {
        final account = await (_db.select(
          _db.accounts,
        )..where((a) => a.id.equals(rec.accountId))).getSingleOrNull();

        if (account == null) continue;

        final reconciledTxns = await (_db.select(
          _db.reconciledTransactions,
        )..where((r) => r.reconciliationId.equals(rec.id))).get();

        double total = 0;
        for (final rt in reconciledTxns) {
          final entries =
              await (_db.select(_db.transactionEntries)
                    ..where((e) => e.transactionId.equals(rt.transactionId))
                    ..where((e) => e.accountId.equals(rec.accountId)))
                  .get();
          for (final entry in entries) {
            total += entry.amount / 100;
          }
        }

        summaries.add(
          ReconciliationSummary(
            reconciliation: rec,
            account: account,
            reconciledCount: reconciledTxns.length,
            reconciledTotal: total,
          ),
        );
      }
      yield summaries;
    }
  }

  /// Create a new reconciliation
  Future<BankReconciliation> createReconciliation({
    required String accountId,
    required DateTime statementDate,
    required int statementEndingBalance,
  }) async {
    final companion = BankReconciliationsCompanion.insert(
      accountId: accountId,
      statementDate: statementDate,
      statementEndingBalance: statementEndingBalance,
    );

    await _db.into(_db.bankReconciliations).insert(companion);

    return (await (_db.select(_db.bankReconciliations)
          ..orderBy([(r) => OrderingTerm.desc(r.createdAt)])
          ..limit(1))
        .getSingle());
  }

  /// Get unreconciled transactions for an account
  Future<List<UnreconciledTransaction>> getUnreconciledTransactions(
    String accountId,
  ) async {
    // Get all transaction IDs that have been reconciled
    final reconciliations = await (_db.select(
      _db.bankReconciliations,
    )..where((r) => r.accountId.equals(accountId))).get();

    final reconciledTxnIds = <String>{};
    for (final rec in reconciliations) {
      final reconciledTxns = await (_db.select(
        _db.reconciledTransactions,
      )..where((r) => r.reconciliationId.equals(rec.id))).get();
      for (final rt in reconciledTxns) {
        reconciledTxnIds.add(rt.transactionId);
      }
    }

    // Get all transactions for this account that aren't reconciled
    final entries = await (_db.select(
      _db.transactionEntries,
    )..where((e) => e.accountId.equals(accountId))).get();

    final unreconciled = <UnreconciledTransaction>[];
    final processedTxnIds = <String>{};

    for (final entry in entries) {
      if (reconciledTxnIds.contains(entry.transactionId)) continue;
      if (processedTxnIds.contains(entry.transactionId)) continue;

      final txn = await (_db.select(
        _db.transactions,
      )..where((t) => t.id.equals(entry.transactionId))).getSingleOrNull();

      if (txn == null) continue;

      processedTxnIds.add(entry.transactionId);

      unreconciled.add(
        UnreconciledTransaction(
          transaction: txn,
          amount: entry.amount / 100,
          description: txn.description,
        ),
      );
    }

    unreconciled.sort(
      (a, b) => b.transaction.transactionDate.compareTo(
        a.transaction.transactionDate,
      ),
    );
    return unreconciled;
  }

  /// Mark transactions as reconciled
  Future<void> reconcileTransactions({
    required String reconciliationId,
    required List<String> transactionIds,
  }) async {
    await _db.transaction(() async {
      for (final txnId in transactionIds) {
        await _db
            .into(_db.reconciledTransactions)
            .insert(
              ReconciledTransactionsCompanion.insert(
                reconciliationId: reconciliationId,
                transactionId: txnId,
              ),
            );
      }

      // Update reconciliation status
      await (_db.update(
        _db.bankReconciliations,
      )..where((r) => r.id.equals(reconciliationId))).write(
        const BankReconciliationsCompanion(status: Value('completed')),
      );
    });
  }

  /// Get bank accounts (for selection)
  Future<List<Account>> getBankAccounts() async {
    return (_db.select(_db.accounts)
          ..where((a) => a.type.equals('Asset'))
          ..where(
            (a) =>
                a.name.contains('Bank') |
                a.name.contains('Cash') |
                a.name.contains('Checking') |
                a.name.contains('Savings'),
          ))
        .get();
  }

  /// Calculate book balance for an account
  Future<double> getBookBalance(String accountId) async {
    final account = await (_db.select(
      _db.accounts,
    )..where((a) => a.id.equals(accountId))).getSingleOrNull();

    if (account == null) return 0;

    double balance = account.initialBalance / 100;

    final entries = await (_db.select(
      _db.transactionEntries,
    )..where((e) => e.accountId.equals(accountId))).get();

    for (final entry in entries) {
      balance += entry.amount / 100;
    }

    return balance;
  }
}
