// FILE: packages/core/core_data/lib/src/services/ghost_money_service.dart
// Purpose: Track and reconcile ghost money (rounding differences)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:drift/drift.dart';

/// Strategy for reconciling accumulated ghost money
enum GhostReconciliationStrategy {
  /// Write off to an expense/income account
  writeOff,

  /// Add to next applicable transaction
  allocateToNext,

  /// Keep accumulating until it reaches a threshold, then allocate
  accumulate,
}

/// Service for tracking and reconciling ghost money
class GhostMoneyService {
  final AppDatabase _db;

  GhostMoneyService(this._db);

  /// Track a ghost amount from a calculation
  Future<void> trackGhostMoney({
    required String sourceType,
    required String sourceId,
    required int ghostAmount,
    required String currency,
    required String reason,
  }) async {
    if (ghostAmount == 0) return; // No ghost money to track

    await _db
        .into(_db.ghostMoneyEntries)
        .insert(
          GhostMoneyEntriesCompanion.insert(
            sourceType: sourceType,
            sourceId: sourceId,
            ghostAmount: ghostAmount,
            currency: currency,
            reason: reason,
          ),
        );
  }

  /// Get total unreconciled ghost money for a currency
  Future<int> getAccumulatedGhost(String currency) async {
    final query = _db.selectOnly(_db.ghostMoneyEntries)
      ..where(_db.ghostMoneyEntries.currency.equals(currency))
      ..where(_db.ghostMoneyEntries.reconciled.equals(false))
      ..addColumns([_db.ghostMoneyEntries.ghostAmount.sum()]);

    final result = await query.getSingleOrNull();
    if (result == null) return 0;

    return result.read(_db.ghostMoneyEntries.ghostAmount.sum()) ?? 0;
  }

  /// Get all unreconciled ghost entries for a currency
  Future<List<GhostMoneyEntry>> getUnreconciledEntries(String currency) async {
    return await (_db.select(_db.ghostMoneyEntries)
          ..where((t) => t.currency.equals(currency))
          ..where((t) => t.reconciled.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Reconcile ghost money by writing off to an account
  Future<void> reconcileWithWriteOff({
    required String currency,
    required String targetAccountId,
    required String description,
  }) async {
    final accumulated = await getAccumulatedGhost(currency);
    if (accumulated == 0) return;

    // Create a transaction for the write-off
    final transactionId = await _createWriteOffTransaction(
      amount: accumulated,
      currency: currency,
      accountId: targetAccountId,
      description: description,
    );

    // Mark all entries as reconciled
    await (_db.update(_db.ghostMoneyEntries)
          ..where((t) => t.currency.equals(currency))
          ..where((t) => t.reconciled.equals(false)))
        .write(
          GhostMoneyEntriesCompanion(
            reconciled: const Value(true),
            reconciledTransactionId: Value(transactionId),
            lastUpdated: Value(DateTime.now()),
          ),
        );
  }

  /// Create a write-off transaction for ghost money
  Future<String> _createWriteOffTransaction({
    required int amount,
    required String currency,
    required String accountId,
    required String description,
  }) async {
    // Get or create a rounding expense/income account
    final accountType = amount > 0 ? 'expense' : 'revenue';

    final transaction = await _db
        .into(_db.transactions)
        .insertReturning(
          TransactionsCompanion.insert(
            description: description,
            transactionDate: DateTime.now(),
            currencyCode: Value(currency),
          ),
        );

    // Create the journal entry
    // Debit rounding expense, credit ghost money (or vice versa)
    await _db
        .into(_db.transactionEntries)
        .insert(
          TransactionEntriesCompanion.insert(
            transactionId: transaction.id,
            accountId: accountId,
            amount: amount, // Positive = debit, Negative = credit
          ),
        );

    return transaction.id;
  }

  /// Get summary of ghost money by currency
  Future<Map<String, GhostMoneySummary>> getSummaryByCurrency() async {
    final query = _db.selectOnly(_db.ghostMoneyEntries)
      ..addColumns([
        _db.ghostMoneyEntries.currency,
        _db.ghostMoneyEntries.ghostAmount.sum(),
        _db.ghostMoneyEntries.id.count(),
      ])
      ..where(_db.ghostMoneyEntries.reconciled.equals(false))
      ..groupBy([_db.ghostMoneyEntries.currency]);

    final results = await query.get();
    final summaries = <String, GhostMoneySummary>{};

    for (final row in results) {
      final currency = row.read(_db.ghostMoneyEntries.currency)!;
      final total = row.read(_db.ghostMoneyEntries.ghostAmount.sum()) ?? 0;
      final count = row.read(_db.ghostMoneyEntries.id.count()) ?? 0;

      summaries[currency] = GhostMoneySummary(
        currency: currency,
        totalAmount: total,
        entryCount: count,
      );
    }

    return summaries;
  }
}

/// Summary of ghost money for a currency
class GhostMoneySummary {
  final String currency;
  final int totalAmount;
  final int entryCount;

  const GhostMoneySummary({
    required this.currency,
    required this.totalAmount,
    required this.entryCount,
  });
}

/// Provider for GhostMoneyService
final ghostMoneyServiceProvider = Provider<GhostMoneyService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return GhostMoneyService(db);
});
