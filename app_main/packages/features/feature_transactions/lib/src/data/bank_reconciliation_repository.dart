import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:feature_transactions/src/data/database_provider.dart';
import 'package:uuid/uuid.dart';

final bankReconciliationRepositoryProvider = Provider<BankReconciliationRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return BankReconciliationRepository(db);
});

class BankReconciliationRepository {
  final AppDatabase _db;

  BankReconciliationRepository(this._db);

  /// 1. FETCH CANDIDATES
  /// Finds all transactions for [accountId] on or before [statementDate]
  /// that have NOT been reconciled yet.
  Future<List<TransactionEntry>> getUnreconciledEntries({
    required String accountId,
    required DateTime statementDate,
  }) async {
    // FIX 1: Execute the query to get a List<String>
    // We cannot pass a 'Selectable' query object directly to 'isNotIn'.
    final reconciledIds = await _db.select(_db.reconciledTransactions)
        .map((r) => r.transactionId)
        .get();

    final query = _db.select(_db.transactionEntries).join([
      innerJoin(
        _db.transactions,
        _db.transactions.id.equalsExp(_db.transactionEntries.transactionId),
      ),
    ]);

    query.where(
      _db.transactionEntries.accountId.equals(accountId) &
      _db.transactions.transactionDate.isSmallerOrEqualValue(statementDate) &
      _db.transactionEntries.transactionId.isNotIn(reconciledIds) // Now safe
    );
    
    // Order by date
    query.orderBy([OrderingTerm.asc(_db.transactions.transactionDate)]);

    final rows = await query.get();
    return rows.map((row) => row.readTable(_db.transactionEntries)).toList();
  }

  /// 2. CALCULATE STARTING BALANCE
  /// The sum of all *previously reconciled* transactions for this account.
  /// This is our "System Beginning Balance".
  Future<int> getReconciledBalance(String accountId) async {
    // FIX 2: Execute the query here as well
    final reconciledIds = await _db.select(_db.reconciledTransactions)
        .map((r) => r.transactionId)
        .get();
    
    final query = _db.select(_db.transactionEntries);
    query.where((tbl) => 
      tbl.accountId.equals(accountId) & 
      tbl.transactionId.isIn(reconciledIds)
    );

    final results = await query.get();
    
    // FIX 3: Explicitly type the fold accumulator as <int>
    // This prevents Dart from guessing 'FutureOr<int>' and causing the '+' error.
    return results.fold<int>(0, (sum, row) => sum + row.amount);
  }

  /// 3. FINALIZE RECONCILIATION
  /// Locks the session and marks transactions as cleared.
  Future<void> finalizeReconciliation({
    required String accountId,
    required DateTime statementDate,
    required int statementEndingBalance,
    required List<String> selectedTransactionIds,
  }) async {
    return _db.transaction(() async {
      final now = DateTime.now();
      
      // A. Create the Session Record
      final recId = const Uuid().v4();
      await _db.into(_db.bankReconciliations).insert(BankReconciliationsCompanion.insert(
        id: Value(recId),
        accountId: accountId,
        statementDate: statementDate,
        statementEndingBalance: statementEndingBalance,
        status: const Value('finalized'),
        createdAt: Value(now),
        lastUpdated: Value(now),
      ));

      // B. Mark transactions as cleared (The Link)
      for (final txId in selectedTransactionIds) {
        await _db.into(_db.reconciledTransactions).insert(ReconciledTransactionsCompanion.insert(
          id: Value(const Uuid().v4()),
          reconciliationId: recId,
          transactionId: txId,
          createdAt: Value(now),
          lastUpdated: Value(now),
        ));
      }
    });
  }
}