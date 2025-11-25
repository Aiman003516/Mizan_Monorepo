import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:feature_transactions/src/data/database_provider.dart';
import 'package:feature_transactions/src/data/transactions_repository.dart';
import 'package:uuid/uuid.dart';

// Provider
final adjustingEntriesRepositoryProvider = Provider<AdjustingEntriesRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final transactionsRepo = ref.watch(transactionsRepositoryProvider);
  return AdjustingEntriesRepository(db, transactionsRepo);
});

class AdjustingEntriesRepository {
  final AppDatabase _db;
  final TransactionsRepository _transactionsRepo;

  AdjustingEntriesRepository(this._db, this._transactionsRepo);

  /// 1. WATCH Pending Tasks
  Stream<List<AdjustingEntryTask>> watchPendingTasks() {
    return (_db.select(_db.adjustingEntryTasks)
          ..where((tbl) => tbl.status.equals('pending'))
          ..orderBy([(t) => OrderingTerm.desc(t.adjustmentDate)]))
        .watch();
  }

  /// 2. CREATE Proposal (The "Airlock" Entry)
  /// Instead of creating a journal entry, we save a JSON description of it.
  Future<void> createProposal({
    required DateTime date,
    required String description,
    required String taskType, // e.g., 'prepaid_usage', 'accrual'
    required List<Map<String, dynamic>> proposedEntries, // The JSON Payload
  }) async {
    final jsonPayload = jsonEncode(proposedEntries);

    await _db.into(_db.adjustingEntryTasks).insert(
          AdjustingEntryTasksCompanion.insert(
            adjustmentDate: date,
            description: description,
            taskType: taskType,
            status: const Value('pending'),
            proposedEntryJson: jsonPayload,
          ),
        );
  }

  /// 3. APPROVE Proposal (The "Guard" Action)
  /// Reads the JSON, creates the REAL entry (with isAdjustment=true), 
  /// and marks the task as approved.
  Future<void> approveTask(AdjustingEntryTask task) async {
    return _db.transaction(() async {
      // A. Decode the payload
      final List<dynamic> rawEntries = jsonDecode(task.proposedEntryJson);
      
      // B. Convert to Real Database Companions
      final entries = rawEntries.map((e) {
        return TransactionEntriesCompanion.insert(
          // We use 'TEMP' because createJournalTransaction generates the real ID
          transactionId: 'TEMP', 
          accountId: e['accountId'],
          amount: e['amount'], // Already in Cents
          currencyRate: const Value(1.0),
        );
      }).toList();

      // C. Post the REAL Journal Entry
      // We rely on the existing repo to handle the debit/credit validation logic.
      // But we need a way to set 'isAdjustment = true'. 
      // Since `createJournalTransaction` doesn't support that flag yet, 
      // we will perform a direct insert here for maximum control.
      
      final newTransactionId = const Uuid().v4(); // Generate ID
      
      await _db.into(_db.transactions).insert(TransactionsCompanion.insert(
        id: Value(newTransactionId),
        description: task.description,
        transactionDate: task.adjustmentDate,
        isAdjustment: const Value(true), // ⭐️ THE GUARD FLAG
        createdAt: Value(DateTime.now()),
        lastUpdated: Value(DateTime.now()),
      ));

      for (final entry in entries) {
        await _db.into(_db.transactionEntries).insert(entry.copyWith(
          transactionId: Value(newTransactionId),
        ));
      }

      // D. Update the Task Status
      await (_db.update(_db.adjustingEntryTasks)
            ..where((t) => t.id.equals(task.id)))
          .write(AdjustingEntryTasksCompanion(
            status: const Value('approved'),
            journalEntryId: Value(newTransactionId),
          ));
    });
  }

  /// 4. REJECT/DELETE Proposal
  Future<void> deleteTask(String id) async {
    await (_db.delete(_db.adjustingEntryTasks)..where((t) => t.id.equals(id))).go();
  }
}