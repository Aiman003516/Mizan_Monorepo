// Repository for Ghost Money entries
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';

final ghostMoneyRepositoryProvider = Provider<GhostMoneyRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return GhostMoneyRepository(db);
});

final unreconciledGhostMoneyProvider = StreamProvider<List<GhostMoneyEntry>>((
  ref,
) {
  return ref.watch(ghostMoneyRepositoryProvider).watchUnreconciled();
});

final ghostMoneySummaryProvider =
    FutureProvider<Map<String, GhostMoneySummary>>((ref) {
      return ref.watch(ghostMoneyRepositoryProvider).getSummaryByCurrency();
    });

/// Summary of ghost money for a currency
class GhostMoneySummary {
  final String currency;
  final int totalAmount;
  final int entryCount;

  GhostMoneySummary({
    required this.currency,
    required this.totalAmount,
    required this.entryCount,
  });
}

class GhostMoneyRepository {
  GhostMoneyRepository(this._db);
  final AppDatabase _db;

  /// Watch all unreconciled ghost money entries
  Stream<List<GhostMoneyEntry>> watchUnreconciled() {
    return (_db.select(_db.ghostMoneyEntries)
          ..where((t) => t.reconciled.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// Watch all ghost money entries
  Stream<List<GhostMoneyEntry>> watchAll() {
    return (_db.select(
      _db.ghostMoneyEntries,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  }

  /// Get summary by currency
  Future<Map<String, GhostMoneySummary>> getSummaryByCurrency() async {
    final entries = await (_db.select(
      _db.ghostMoneyEntries,
    )..where((t) => t.reconciled.equals(false))).get();

    final summaryMap = <String, GhostMoneySummary>{};

    for (final entry in entries) {
      final currencyCode = entry.currency;
      if (summaryMap.containsKey(currencyCode)) {
        final existing = summaryMap[currencyCode]!;
        summaryMap[currencyCode] = GhostMoneySummary(
          currency: currencyCode,
          totalAmount: existing.totalAmount + entry.ghostAmount,
          entryCount: existing.entryCount + 1,
        );
      } else {
        summaryMap[currencyCode] = GhostMoneySummary(
          currency: currencyCode,
          totalAmount: entry.ghostAmount,
          entryCount: 1,
        );
      }
    }

    return summaryMap;
  }

  /// Reconcile all entries for a currency
  Future<int> reconcileByCurrency(String currencyCode) async {
    final entries =
        await (_db.select(_db.ghostMoneyEntries)..where(
              (t) =>
                  t.currency.equals(currencyCode) & t.reconciled.equals(false),
            ))
            .get();

    for (final entry in entries) {
      await (_db.update(
        _db.ghostMoneyEntries,
      )..where((t) => t.id.equals(entry.id))).write(
        GhostMoneyEntriesCompanion(
          reconciled: const Value(true),
          lastUpdated: Value(DateTime.now()),
        ),
      );
    }

    return entries.length;
  }

  /// Reconcile a single entry
  Future<void> reconcileEntry(String id) async {
    await (_db.update(
      _db.ghostMoneyEntries,
    )..where((t) => t.id.equals(id))).write(
      GhostMoneyEntriesCompanion(
        reconciled: const Value(true),
        lastUpdated: Value(DateTime.now()),
      ),
    );
  }
}
