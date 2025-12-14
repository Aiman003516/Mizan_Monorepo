// FILE: packages/core/core_data/lib/src/services/journal_entry_service.dart
// Purpose: Enhanced journal entry service with compound entries and reversing entries

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:drift/drift.dart';

/// A single line in a compound journal entry
class JournalLine {
  final String accountId;
  final int amount; // Positive = debit, Negative = credit
  final String? memo;

  const JournalLine({required this.accountId, required this.amount, this.memo});

  bool get isDebit => amount > 0;
  bool get isCredit => amount < 0;
  int get absoluteAmount => amount.abs();
}

/// Result of creating a journal entry
class JournalEntryResult {
  final String transactionId;
  final bool isBalanced;
  final int totalDebits;
  final int totalCredits;

  const JournalEntryResult({
    required this.transactionId,
    required this.isBalanced,
    required this.totalDebits,
    required this.totalCredits,
  });
}

/// Service for creating and managing journal entries
class JournalEntryService {
  final AppDatabase _db;

  JournalEntryService(this._db);

  /// Create a compound journal entry with multiple debits and credits
  /// Validates that debits = credits before saving
  Future<JournalEntryResult> createCompoundEntry({
    required String description,
    required DateTime date,
    required List<JournalLine> lines,
    String? attachmentPath,
    String currencyCode = 'Local',
    bool isAdjustment = false,
  }) async {
    // Validate: must have at least 2 lines
    if (lines.length < 2) {
      throw ArgumentError('Journal entry must have at least 2 lines');
    }

    // Calculate totals
    int totalDebits = 0;
    int totalCredits = 0;
    for (final line in lines) {
      if (line.isDebit) {
        totalDebits += line.absoluteAmount;
      } else {
        totalCredits += line.absoluteAmount;
      }
    }

    // Validate: debits must equal credits
    if (totalDebits != totalCredits) {
      throw ArgumentError(
        'Journal entry is not balanced. Debits: $totalDebits, Credits: $totalCredits',
      );
    }

    // Create the transaction header
    final transaction = await _db
        .into(_db.transactions)
        .insertReturning(
          TransactionsCompanion.insert(
            description: description,
            transactionDate: date,
            attachmentPath: Value(attachmentPath),
            currencyCode: Value(currencyCode),
            isAdjustment: Value(isAdjustment),
          ),
        );

    // Create all transaction entries (lines)
    for (final line in lines) {
      await _db
          .into(_db.transactionEntries)
          .insert(
            TransactionEntriesCompanion.insert(
              transactionId: transaction.id,
              accountId: line.accountId,
              amount: line.amount,
            ),
          );
    }

    return JournalEntryResult(
      transactionId: transaction.id,
      isBalanced: true,
      totalDebits: totalDebits,
      totalCredits: totalCredits,
    );
  }

  /// Create a simple two-line journal entry (debit one account, credit another)
  Future<JournalEntryResult> createSimpleEntry({
    required String description,
    required DateTime date,
    required String debitAccountId,
    required String creditAccountId,
    required int amount,
    String? attachmentPath,
    String currencyCode = 'Local',
  }) async {
    return createCompoundEntry(
      description: description,
      date: date,
      lines: [
        JournalLine(accountId: debitAccountId, amount: amount), // Debit
        JournalLine(accountId: creditAccountId, amount: -amount), // Credit
      ],
      attachmentPath: attachmentPath,
      currencyCode: currencyCode,
    );
  }

  /// Create a reversing entry for an existing transaction
  /// Swaps all debits and credits, links to original
  Future<JournalEntryResult> createReversingEntry({
    required String originalTransactionId,
    required DateTime reversalDate,
    String? description,
  }) async {
    // Get the original transaction
    final original = await (_db.select(
      _db.transactions,
    )..where((t) => t.id.equals(originalTransactionId))).getSingleOrNull();

    if (original == null) {
      throw ArgumentError(
        'Original transaction not found: $originalTransactionId',
      );
    }

    // Get all entries for the original transaction
    final originalEntries = await (_db.select(
      _db.transactionEntries,
    )..where((t) => t.transactionId.equals(originalTransactionId))).get();

    if (originalEntries.isEmpty) {
      throw ArgumentError('Original transaction has no entries');
    }

    // Create reversed lines (swap debit/credit)
    final reversedLines = originalEntries
        .map(
          (entry) => JournalLine(
            accountId: entry.accountId,
            amount: -entry.amount, // Reverse the sign
          ),
        )
        .toList();

    // Create the reversing transaction
    final reversingTransaction = await _db
        .into(_db.transactions)
        .insertReturning(
          TransactionsCompanion.insert(
            description: description ?? 'Reversal of: ${original.description}',
            transactionDate: reversalDate,
            currencyCode: Value(original.currencyCode),
            isReversing: const Value(true),
            reversedTransactionId: Value(originalTransactionId),
          ),
        );

    // Create reversed entries
    for (final line in reversedLines) {
      await _db
          .into(_db.transactionEntries)
          .insert(
            TransactionEntriesCompanion.insert(
              transactionId: reversingTransaction.id,
              accountId: line.accountId,
              amount: line.amount,
            ),
          );
    }

    // Calculate totals for result
    int totalDebits = 0;
    int totalCredits = 0;
    for (final line in reversedLines) {
      if (line.isDebit) {
        totalDebits += line.absoluteAmount;
      } else {
        totalCredits += line.absoluteAmount;
      }
    }

    return JournalEntryResult(
      transactionId: reversingTransaction.id,
      isBalanced: true,
      totalDebits: totalDebits,
      totalCredits: totalCredits,
    );
  }

  /// Get journal entries for a date range
  Future<List<Transaction>> getEntriesForPeriod(
    DateTime start,
    DateTime end,
  ) async {
    return await (_db.select(_db.transactions)
          ..where((t) => t.transactionDate.isBetweenValues(start, end))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
        .get();
  }

  /// Get all lines for a transaction
  Future<List<TransactionEntry>> getTransactionLines(
    String transactionId,
  ) async {
    return await (_db.select(
      _db.transactionEntries,
    )..where((t) => t.transactionId.equals(transactionId))).get();
  }

  /// Validate that a transaction is balanced
  Future<bool> isTransactionBalanced(String transactionId) async {
    final entries = await getTransactionLines(transactionId);
    int total = 0;
    for (final entry in entries) {
      total += entry.amount;
    }
    return total == 0;
  }
}

/// Provider for JournalEntryService
final journalEntryServiceProvider = Provider<JournalEntryService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return JournalEntryService(db);
});
