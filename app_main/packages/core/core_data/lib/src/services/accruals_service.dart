// FILE: packages/core/core_data/lib/src/services/accruals_service.dart
// Purpose: Automated accruals and deferrals management

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:drift/drift.dart';

/// Types of accrual/deferral entries
enum AccrualType {
  accruedExpense, // Expense incurred but not yet paid
  accruedRevenue, // Revenue earned but not yet received
  prepaidExpense, // Expense paid in advance
  unearnedRevenue, // Revenue received in advance
}

/// Schedule for recurring accruals
class AccrualSchedule {
  final String description;
  final AccrualType type;
  final String debitAccountId;
  final String creditAccountId;
  final int amount;
  final DateTime startDate;
  final DateTime? endDate;
  final String frequency; // 'monthly', 'quarterly', 'annually'
  final int totalPeriods;
  final int periodsCompleted;

  const AccrualSchedule({
    required this.description,
    required this.type,
    required this.debitAccountId,
    required this.creditAccountId,
    required this.amount,
    required this.startDate,
    this.endDate,
    required this.frequency,
    required this.totalPeriods,
    this.periodsCompleted = 0,
  });

  /// Amount per period for amortization
  int get amountPerPeriod => amount ~/ totalPeriods;

  /// Remaining amount to amortize
  int get remainingAmount => amount - (amountPerPeriod * periodsCompleted);

  /// Check if schedule is complete
  bool get isComplete => periodsCompleted >= totalPeriods;

  /// Next scheduled date
  DateTime get nextDate {
    switch (frequency) {
      case 'monthly':
        return DateTime(
          startDate.year,
          startDate.month + periodsCompleted,
          startDate.day,
        );
      case 'quarterly':
        return DateTime(
          startDate.year,
          startDate.month + (periodsCompleted * 3),
          startDate.day,
        );
      case 'annually':
        return DateTime(
          startDate.year + periodsCompleted,
          startDate.month,
          startDate.day,
        );
      default:
        return startDate;
    }
  }

  Map<String, dynamic> toJson() => {
    'description': description,
    'type': type.name,
    'debitAccountId': debitAccountId,
    'creditAccountId': creditAccountId,
    'amount': amount,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'frequency': frequency,
    'totalPeriods': totalPeriods,
    'periodsCompleted': periodsCompleted,
  };

  factory AccrualSchedule.fromJson(Map<String, dynamic> json) =>
      AccrualSchedule(
        description: json['description'] as String,
        type: AccrualType.values.firstWhere((e) => e.name == json['type']),
        debitAccountId: json['debitAccountId'] as String,
        creditAccountId: json['creditAccountId'] as String,
        amount: json['amount'] as int,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: json['endDate'] != null
            ? DateTime.parse(json['endDate'] as String)
            : null,
        frequency: json['frequency'] as String,
        totalPeriods: json['totalPeriods'] as int,
        periodsCompleted: json['periodsCompleted'] as int? ?? 0,
      );
}

/// Service for managing accruals and deferrals
class AccrualsService {
  final AppDatabase _db;

  AccrualsService(this._db);

  /// Create a prepaid expense and schedule amortization
  /// e.g., Prepaid Insurance for 12 months
  Future<String> createPrepaidExpense({
    required String description,
    required int totalAmount,
    required String prepaidAssetAccountId, // e.g., Prepaid Insurance
    required String expenseAccountId, // e.g., Insurance Expense
    required String cashAccountId, // e.g., Cash
    required DateTime paymentDate,
    required int amortizationPeriods, // e.g., 12 months
    required String frequency, // 'monthly', 'quarterly'
  }) async {
    // 1. Record the initial payment (Debit Prepaid, Credit Cash)
    final transaction = await _db
        .into(_db.transactions)
        .insertReturning(
          TransactionsCompanion.insert(
            description: 'Payment: $description',
            transactionDate: paymentDate,
            recurringSchedule: Value(
              jsonEncode(
                AccrualSchedule(
                  description: description,
                  type: AccrualType.prepaidExpense,
                  debitAccountId: expenseAccountId,
                  creditAccountId: prepaidAssetAccountId,
                  amount: totalAmount,
                  startDate: paymentDate,
                  frequency: frequency,
                  totalPeriods: amortizationPeriods,
                ).toJson(),
              ),
            ),
          ),
        );

    // Debit Prepaid Asset
    await _db
        .into(_db.transactionEntries)
        .insert(
          TransactionEntriesCompanion.insert(
            transactionId: transaction.id,
            accountId: prepaidAssetAccountId,
            amount: totalAmount,
          ),
        );

    // Credit Cash
    await _db
        .into(_db.transactionEntries)
        .insert(
          TransactionEntriesCompanion.insert(
            transactionId: transaction.id,
            accountId: cashAccountId,
            amount: -totalAmount,
          ),
        );

    return transaction.id;
  }

  /// Record an accrued expense (expense incurred but not paid)
  /// e.g., Salaries payable at month end
  Future<String> recordAccruedExpense({
    required String description,
    required int amount,
    required String expenseAccountId, // e.g., Salaries Expense
    required String liabilityAccountId, // e.g., Salaries Payable
    required DateTime accrualDate,
  }) async {
    final transaction = await _db
        .into(_db.transactions)
        .insertReturning(
          TransactionsCompanion.insert(
            description: 'Accrued: $description',
            transactionDate: accrualDate,
            isAdjustment: const Value(true),
          ),
        );

    // Debit Expense
    await _db
        .into(_db.transactionEntries)
        .insert(
          TransactionEntriesCompanion.insert(
            transactionId: transaction.id,
            accountId: expenseAccountId,
            amount: amount,
          ),
        );

    // Credit Liability (Payable)
    await _db
        .into(_db.transactionEntries)
        .insert(
          TransactionEntriesCompanion.insert(
            transactionId: transaction.id,
            accountId: liabilityAccountId,
            amount: -amount,
          ),
        );

    return transaction.id;
  }

  /// Record unearned revenue (payment received before service)
  /// e.g., Annual subscription paid upfront
  Future<String> recordUnearnedRevenue({
    required String description,
    required int totalAmount,
    required String cashAccountId, // e.g., Cash
    required String unearnedRevenueAccountId, // e.g., Unearned Revenue
    required String revenueAccountId, // e.g., Service Revenue
    required DateTime receiptDate,
    required int recognitionPeriods, // e.g., 12 months
    required String frequency,
  }) async {
    final transaction = await _db
        .into(_db.transactions)
        .insertReturning(
          TransactionsCompanion.insert(
            description: 'Received: $description',
            transactionDate: receiptDate,
            recurringSchedule: Value(
              jsonEncode(
                AccrualSchedule(
                  description: description,
                  type: AccrualType.unearnedRevenue,
                  debitAccountId: unearnedRevenueAccountId,
                  creditAccountId: revenueAccountId,
                  amount: totalAmount,
                  startDate: receiptDate,
                  frequency: frequency,
                  totalPeriods: recognitionPeriods,
                ).toJson(),
              ),
            ),
          ),
        );

    // Debit Cash
    await _db
        .into(_db.transactionEntries)
        .insert(
          TransactionEntriesCompanion.insert(
            transactionId: transaction.id,
            accountId: cashAccountId,
            amount: totalAmount,
          ),
        );

    // Credit Unearned Revenue (Liability)
    await _db
        .into(_db.transactionEntries)
        .insert(
          TransactionEntriesCompanion.insert(
            transactionId: transaction.id,
            accountId: unearnedRevenueAccountId,
            amount: -totalAmount,
          ),
        );

    return transaction.id;
  }

  /// Process all pending amortizations due up to a date
  Future<List<String>> processAmortizations(DateTime asOfDate) async {
    final processedIds = <String>[];

    // Get all transactions with recurring schedules
    final transactions = await (_db.select(
      _db.transactions,
    )..where((t) => t.recurringSchedule.isNotNull())).get();

    for (final transaction in transactions) {
      if (transaction.recurringSchedule == null) continue;

      final schedule = AccrualSchedule.fromJson(
        jsonDecode(transaction.recurringSchedule!) as Map<String, dynamic>,
      );

      if (schedule.isComplete) continue;
      if (schedule.nextDate.isAfter(asOfDate)) continue;

      // Create amortization entry
      final amortEntry = await _db
          .into(_db.transactions)
          .insertReturning(
            TransactionsCompanion.insert(
              description: 'Amortization: ${schedule.description}',
              transactionDate: schedule.nextDate,
              isAdjustment: const Value(true),
            ),
          );

      // Debit and Credit based on type
      await _db
          .into(_db.transactionEntries)
          .insert(
            TransactionEntriesCompanion.insert(
              transactionId: amortEntry.id,
              accountId: schedule.debitAccountId,
              amount: schedule.amountPerPeriod,
            ),
          );

      await _db
          .into(_db.transactionEntries)
          .insert(
            TransactionEntriesCompanion.insert(
              transactionId: amortEntry.id,
              accountId: schedule.creditAccountId,
              amount: -schedule.amountPerPeriod,
            ),
          );

      // Update the schedule
      final updatedSchedule = AccrualSchedule(
        description: schedule.description,
        type: schedule.type,
        debitAccountId: schedule.debitAccountId,
        creditAccountId: schedule.creditAccountId,
        amount: schedule.amount,
        startDate: schedule.startDate,
        endDate: schedule.endDate,
        frequency: schedule.frequency,
        totalPeriods: schedule.totalPeriods,
        periodsCompleted: schedule.periodsCompleted + 1,
      );

      await (_db.update(
        _db.transactions,
      )..where((t) => t.id.equals(transaction.id))).write(
        TransactionsCompanion(
          recurringSchedule: Value(jsonEncode(updatedSchedule.toJson())),
          lastUpdated: Value(DateTime.now()),
        ),
      );

      processedIds.add(amortEntry.id);
    }

    return processedIds;
  }
}

/// Provider for AccrualsService
final accrualsServiceProvider = Provider<AccrualsService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return AccrualsService(db);
});
