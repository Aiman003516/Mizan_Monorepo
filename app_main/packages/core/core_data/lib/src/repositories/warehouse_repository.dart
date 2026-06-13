import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:drift/drift.dart';

/// Warehouse Repository for multi-warehouse inventory.
class WarehouseRepository {
  final AppDatabase _db;

  WarehouseRepository(this._db);

  /// Creates a new warehouse.
  Future<void> create({
    required String name,
    String? address,
    bool isDefault = false,
  }) async {
    await _db
        .into(_db.warehouses)
        .insert(
          WarehousesCompanion.insert(
            name: name,
            address: Value(address),
            isDefault: Value(isDefault),
          ),
        );
  }

  /// Watches all warehouses.
  Stream<List<Warehouse>> watchAll() {
    return (_db.select(
      _db.warehouses,
    )..orderBy([(w) => OrderingTerm.asc(w.name)])).watch();
  }

  /// Gets inventory for a specific warehouse.
  Future<List<WarehouseInventory>> getInventory(String warehouseId) async {
    return (_db.select(
      _db.warehouseInventoryItems,
    )..where((w) => w.warehouseId.equals(warehouseId))).get();
  }

  /// Adjusts stock in a specific warehouse.
  Future<void> adjustStock({
    required String warehouseId,
    required String productId,
    required double quantityChange,
  }) async {
    // Check if entry exists
    final existing =
        await (_db.select(_db.warehouseInventoryItems)..where(
              (w) =>
                  w.warehouseId.equals(warehouseId) &
                  w.productId.equals(productId),
            ))
            .getSingleOrNull();

    if (existing != null) {
      // Update existing
      final newQty = existing.quantityOnHand + quantityChange;
      await (_db.update(
        _db.warehouseInventoryItems,
      )..where((w) => w.id.equals(existing.id))).write(
        WarehouseInventoryItemsCompanion(
          quantityOnHand: Value(newQty < 0 ? 0 : newQty),
        ),
      );
    } else {
      // Create new entry
      await _db
          .into(_db.warehouseInventoryItems)
          .insert(
            WarehouseInventoryItemsCompanion.insert(
              warehouseId: warehouseId,
              productId: productId,
              quantityOnHand: Value(quantityChange < 0 ? 0 : quantityChange),
            ),
          );
    }
  }
}

final warehouseRepositoryProvider = Provider((ref) {
  final db = ref.watch(appDatabaseProvider);
  return WarehouseRepository(db);
});
