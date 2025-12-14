// Repository for Fixed Assets management
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';

final fixedAssetsRepositoryProvider = Provider<FixedAssetsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return FixedAssetsRepository(db);
});

final fixedAssetsStreamProvider = StreamProvider<List<FixedAsset>>((ref) {
  return ref.watch(fixedAssetsRepositoryProvider).watchAssets();
});

final activeAssetsStreamProvider = StreamProvider<List<FixedAsset>>((ref) {
  return ref.watch(fixedAssetsRepositoryProvider).watchActiveAssets();
});

class FixedAssetsRepository {
  FixedAssetsRepository(this._db);
  final AppDatabase _db;

  /// Watch all fixed assets
  Stream<List<FixedAsset>> watchAssets() {
    return (_db.select(
      _db.fixedAssets,
    )..orderBy([(t) => OrderingTerm.desc(t.acquisitionDate)])).watch();
  }

  /// Watch only active fixed assets
  Stream<List<FixedAsset>> watchActiveAssets() {
    return (_db.select(_db.fixedAssets)
          ..where((t) => t.status.equals('ACTIVE'))
          ..orderBy([(t) => OrderingTerm.desc(t.acquisitionDate)]))
        .watch();
  }

  /// Get a single asset by ID
  Future<FixedAsset?> getAsset(String id) {
    return (_db.select(
      _db.fixedAssets,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Create a new fixed asset
  Future<FixedAsset> createAsset({
    required String name,
    String? description,
    required String assetAccountId,
    required String accumulatedDepreciationAccountId,
    required String depreciationExpenseAccountId,
    required int acquisitionCost,
    required int salvageValue,
    required DateTime acquisitionDate,
    required int usefulLifeMonths,
    required String depreciationMethod,
    double? decliningBalanceRate,
    int? usefulLifeUnits,
  }) {
    return _db
        .into(_db.fixedAssets)
        .insertReturning(
          FixedAssetsCompanion.insert(
            name: name,
            description: Value(description),
            assetAccountId: assetAccountId,
            accumulatedDepreciationAccountId: accumulatedDepreciationAccountId,
            depreciationExpenseAccountId: depreciationExpenseAccountId,
            acquisitionCost: acquisitionCost,
            salvageValue: salvageValue,
            acquisitionDate: acquisitionDate,
            usefulLifeMonths: usefulLifeMonths,
            depreciationMethod: depreciationMethod,
            decliningBalanceRate: Value(decliningBalanceRate),
            usefulLifeUnits: Value(usefulLifeUnits),
          ),
        );
  }

  /// Update an existing asset
  Future<void> updateAsset(FixedAsset asset) {
    return _db
        .update(_db.fixedAssets)
        .replace(
          asset.toCompanion(false).copyWith(lastUpdated: Value(DateTime.now())),
        );
  }

  /// Delete an asset
  Future<void> deleteAsset(String id) {
    return (_db.delete(_db.fixedAssets)..where((t) => t.id.equals(id))).go();
  }

  /// Get summary statistics for fixed assets
  Future<Map<String, dynamic>> getAssetSummary() async {
    final assets = await (_db.select(_db.fixedAssets)).get();

    int totalCost = 0;
    int totalDepreciation = 0;
    int activeCount = 0;
    int disposedCount = 0;
    int fullyDepreciatedCount = 0;

    for (final asset in assets) {
      totalCost += asset.acquisitionCost;
      totalDepreciation += asset.totalDepreciation;
      switch (asset.status) {
        case 'ACTIVE':
          activeCount++;
          break;
        case 'DISPOSED':
          disposedCount++;
          break;
        case 'FULLY_DEPRECIATED':
          fullyDepreciatedCount++;
          break;
      }
    }

    return {
      'totalAssets': assets.length,
      'totalCost': totalCost,
      'totalDepreciation': totalDepreciation,
      'netBookValue': totalCost - totalDepreciation,
      'activeCount': activeCount,
      'disposedCount': disposedCount,
      'fullyDepreciatedCount': fullyDepreciatedCount,
    };
  }
}
