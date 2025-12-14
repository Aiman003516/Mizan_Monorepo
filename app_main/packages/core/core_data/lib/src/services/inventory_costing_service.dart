// FILE: packages/core/core_data/lib/src/services/inventory_costing_service.dart
// Purpose: Advanced inventory costing methods (FIFO, LIFO, Weighted Average)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:drift/drift.dart';

/// Inventory costing methods
enum CostingMethod {
  fifo, // First-In, First-Out
  lifo, // Last-In, First-Out
  weightedAverage, // Weighted Average Cost
  specificId, // Specific Identification
}

/// Result of cost calculation
class CostOfGoodsSoldResult {
  final int costOfGoodsSold;
  final int endingInventoryValue;
  final double averageCost;
  final List<LayerUsage> layersUsed;

  const CostOfGoodsSoldResult({
    required this.costOfGoodsSold,
    required this.endingInventoryValue,
    required this.averageCost,
    required this.layersUsed,
  });
}

/// Details of inventory layer usage
class LayerUsage {
  final String layerId;
  final double quantityUsed;
  final int costPerUnit;
  final int totalCost;

  const LayerUsage({
    required this.layerId,
    required this.quantityUsed,
    required this.costPerUnit,
    required this.totalCost,
  });
}

/// Service for inventory costing calculations
class InventoryCostingService {
  final AppDatabase _db;

  InventoryCostingService(this._db);

  /// Add inventory purchase to cost layers
  Future<InventoryCostLayer> addPurchaseLayer({
    required String productId,
    required double quantityPurchased,
    required int costPerUnit,
    required DateTime purchaseDate,
  }) async {
    return await _db
        .into(_db.inventoryCostLayers)
        .insertReturning(
          InventoryCostLayersCompanion.insert(
            productId: productId,
            purchaseDate: purchaseDate,
            quantityPurchased: quantityPurchased,
            quantityRemaining: quantityPurchased,
            costPerUnit: costPerUnit,
          ),
        );
  }

  /// Calculate COGS using FIFO (First-In, First-Out)
  /// Oldest inventory is sold first
  Future<CostOfGoodsSoldResult> calculateFifo({
    required String productId,
    required double quantitySold,
  }) async {
    // Get layers ordered by purchase date (oldest first)
    final layers =
        await (_db.select(_db.inventoryCostLayers)
              ..where((t) => t.productId.equals(productId))
              ..where((t) => t.quantityRemaining.isBiggerThanValue(0))
              ..orderBy([(t) => OrderingTerm.asc(t.purchaseDate)]))
            .get();

    return _allocateCost(layers, quantitySold, productId);
  }

  /// Calculate COGS using LIFO (Last-In, First-Out)
  /// Newest inventory is sold first
  Future<CostOfGoodsSoldResult> calculateLifo({
    required String productId,
    required double quantitySold,
  }) async {
    // Get layers ordered by purchase date (newest first)
    final layers =
        await (_db.select(_db.inventoryCostLayers)
              ..where((t) => t.productId.equals(productId))
              ..where((t) => t.quantityRemaining.isBiggerThanValue(0))
              ..orderBy([(t) => OrderingTerm.desc(t.purchaseDate)]))
            .get();

    return _allocateCost(layers, quantitySold, productId);
  }

  /// Calculate COGS using Weighted Average
  /// All units have the same average cost
  Future<CostOfGoodsSoldResult> calculateWeightedAverage({
    required String productId,
    required double quantitySold,
  }) async {
    // Get all layers with remaining quantity
    final layers =
        await (_db.select(_db.inventoryCostLayers)
              ..where((t) => t.productId.equals(productId))
              ..where((t) => t.quantityRemaining.isBiggerThanValue(0)))
            .get();

    if (layers.isEmpty) {
      return CostOfGoodsSoldResult(
        costOfGoodsSold: 0,
        endingInventoryValue: 0,
        averageCost: 0,
        layersUsed: [],
      );
    }

    // Calculate weighted average cost
    double totalQuantity = 0;
    int totalValue = 0;
    for (final layer in layers) {
      totalQuantity += layer.quantityRemaining;
      totalValue += (layer.quantityRemaining * layer.costPerUnit).round();
    }

    final avgCost = totalValue / totalQuantity;
    final cogs = (quantitySold * avgCost).round();

    // Update layers proportionally
    final layersUsed = <LayerUsage>[];
    double remainingToSell = quantitySold;

    for (final layer in layers) {
      if (remainingToSell <= 0) break;

      final proportion = layer.quantityRemaining / totalQuantity;
      final quantityFromLayer = (quantitySold * proportion)
          .clamp(0.0, layer.quantityRemaining)
          .toDouble();

      if (quantityFromLayer > 0) {
        layersUsed.add(
          LayerUsage(
            layerId: layer.id,
            quantityUsed: quantityFromLayer,
            costPerUnit: avgCost.round(),
            totalCost: (quantityFromLayer * avgCost).round(),
          ),
        );

        // Update layer
        await (_db.update(
          _db.inventoryCostLayers,
        )..where((t) => t.id.equals(layer.id))).write(
          InventoryCostLayersCompanion(
            quantityRemaining: Value(
              layer.quantityRemaining - quantityFromLayer,
            ),
            lastUpdated: Value(DateTime.now()),
          ),
        );

        remainingToSell -= quantityFromLayer;
      }
    }

    final endingValue = totalValue - cogs;

    return CostOfGoodsSoldResult(
      costOfGoodsSold: cogs,
      endingInventoryValue: endingValue,
      averageCost: avgCost,
      layersUsed: layersUsed,
    );
  }

  /// Internal method to allocate cost from layers (used by FIFO and LIFO)
  Future<CostOfGoodsSoldResult> _allocateCost(
    List<InventoryCostLayer> layers,
    double quantitySold,
    String productId,
  ) async {
    if (layers.isEmpty) {
      return CostOfGoodsSoldResult(
        costOfGoodsSold: 0,
        endingInventoryValue: 0,
        averageCost: 0,
        layersUsed: [],
      );
    }

    int cogs = 0;
    double remainingToSell = quantitySold;
    final layersUsed = <LayerUsage>[];

    for (final layer in layers) {
      if (remainingToSell <= 0) break;

      final quantityFromLayer = remainingToSell <= layer.quantityRemaining
          ? remainingToSell
          : layer.quantityRemaining;

      final costFromLayer = (quantityFromLayer * layer.costPerUnit).round();
      cogs += costFromLayer;

      layersUsed.add(
        LayerUsage(
          layerId: layer.id,
          quantityUsed: quantityFromLayer,
          costPerUnit: layer.costPerUnit,
          totalCost: costFromLayer,
        ),
      );

      // Update layer
      await (_db.update(
        _db.inventoryCostLayers,
      )..where((t) => t.id.equals(layer.id))).write(
        InventoryCostLayersCompanion(
          quantityRemaining: Value(layer.quantityRemaining - quantityFromLayer),
          lastUpdated: Value(DateTime.now()),
        ),
      );

      remainingToSell -= quantityFromLayer;
    }

    // Calculate ending inventory
    final allLayers = await (_db.select(
      _db.inventoryCostLayers,
    )..where((t) => t.productId.equals(productId))).get();

    int endingValue = 0;
    double endingQty = 0;
    for (final layer in allLayers) {
      endingValue += (layer.quantityRemaining * layer.costPerUnit).round();
      endingQty += layer.quantityRemaining;
    }

    return CostOfGoodsSoldResult(
      costOfGoodsSold: cogs,
      endingInventoryValue: endingValue,
      averageCost: endingQty > 0 ? endingValue / endingQty : 0,
      layersUsed: layersUsed,
    );
  }

  /// Get inventory valuation for a product
  Future<Map<String, dynamic>> getInventoryValuation(String productId) async {
    final layers = await (_db.select(
      _db.inventoryCostLayers,
    )..where((t) => t.productId.equals(productId))).get();

    double totalQuantity = 0;
    int totalValue = 0;
    int layerCount = 0;

    for (final layer in layers) {
      if (layer.quantityRemaining > 0) {
        totalQuantity += layer.quantityRemaining;
        totalValue += (layer.quantityRemaining * layer.costPerUnit).round();
        layerCount++;
      }
    }

    return {
      'productId': productId,
      'totalQuantity': totalQuantity,
      'totalValue': totalValue,
      'averageCost': totalQuantity > 0 ? totalValue / totalQuantity : 0,
      'layerCount': layerCount,
    };
  }

  /// Apply Lower of Cost or Market (LCM) valuation
  /// Writes down inventory if market value is less than cost
  Future<int> applyLcmValuation({
    required String productId,
    required int currentMarketPrice,
    required String inventoryWriteDownAccountId,
    required String inventoryAccountId,
  }) async {
    final valuation = await getInventoryValuation(productId);
    final currentCost = valuation['averageCost'] as double;
    final quantity = valuation['totalQuantity'] as double;

    if (currentMarketPrice >= currentCost) {
      return 0; // No write-down needed
    }

    // Calculate write-down
    final writeDownPerUnit = currentCost - currentMarketPrice;
    final totalWriteDown = (writeDownPerUnit * quantity).round();

    // Record write-down journal entry
    final transaction = await _db
        .into(_db.transactions)
        .insertReturning(
          TransactionsCompanion.insert(
            description: 'LCM Write-down for product: $productId',
            transactionDate: DateTime.now(),
            isAdjustment: const Value(true),
          ),
        );

    // Debit Loss on Inventory Write-down
    await _db
        .into(_db.transactionEntries)
        .insert(
          TransactionEntriesCompanion.insert(
            transactionId: transaction.id,
            accountId: inventoryWriteDownAccountId,
            amount: totalWriteDown,
          ),
        );

    // Credit Inventory
    await _db
        .into(_db.transactionEntries)
        .insert(
          TransactionEntriesCompanion.insert(
            transactionId: transaction.id,
            accountId: inventoryAccountId,
            amount: -totalWriteDown,
          ),
        );

    return totalWriteDown;
  }
}

/// Provider for InventoryCostingService
final inventoryCostingServiceProvider = Provider<InventoryCostingService>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  return InventoryCostingService(db);
});
