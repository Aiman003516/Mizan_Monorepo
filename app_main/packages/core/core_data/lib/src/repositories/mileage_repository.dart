import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:drift/drift.dart';

/// Mileage Tracker Repository for tax deduction tracking.
class MileageRepository {
  final AppDatabase _db;

  MileageRepository(this._db);

  /// Creates a new mileage entry.
  Future<void> create({
    required DateTime tripDate,
    required double startKm,
    required double endKm,
    required int ratePerKm,
    String? description,
  }) async {
    final distance = endKm - startKm;
    final deduction = (distance * ratePerKm).round();

    await _db
        .into(_db.mileageEntries)
        .insert(
          MileageEntriesCompanion.insert(
            tripDate: tripDate,
            startKm: startKm,
            endKm: endKm,
            ratePerKm: ratePerKm,
            totalDeduction: deduction,
            description: Value(description),
          ),
        );
  }

  /// Watches all mileage entries.
  Stream<List<MileageEntry>> watchAll() {
    return (_db.select(
      _db.mileageEntries,
    )..orderBy([(m) => OrderingTerm.desc(m.tripDate)])).watch();
  }

  /// Gets total deductions for a date range.
  Future<int> getTotalDeduction(DateTime start, DateTime end) async {
    final entries =
        await (_db.select(_db.mileageEntries)..where(
              (m) =>
                  m.tripDate.isBiggerOrEqualValue(start) &
                  m.tripDate.isSmallerOrEqualValue(end),
            ))
            .get();

    return entries.fold<int>(0, (sum, e) => sum + e.totalDeduction);
  }
}

final mileageRepositoryProvider = Provider((ref) {
  final db = ref.watch(appDatabaseProvider);
  return MileageRepository(db);
});
