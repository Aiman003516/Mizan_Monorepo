// FILE: packages/features/feature_reports/lib/src/data/inventory_repository.dart

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:feature_reports/src/data/reports_service.dart'; // For databaseProvider

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return InventoryRepository(db);
});

// --- MODELS ---

class ProductVelocity {
  final String productId;
  final String productName;
  final double currentStock;
  final double quantitySold;
  final double totalRevenue;

  ProductVelocity({
    required this.productId,
    required this.productName,
    required this.currentStock,
    required this.quantitySold,
    required this.totalRevenue,
  });
  
  // Velocity Score: Simple Ratio for sorting
  double get score => quantitySold;
}

class InventoryRepository {
  final AppDatabase _db;
  InventoryRepository(this._db);

  /// 1. Low Stock Alert
  /// Returns products where quantity is below [threshold].
  Stream<List<Product>> watchLowStockProducts({double threshold = 5.0}) {
    return (_db.select(_db.products)
          ..where((p) => p.quantityOnHand.isSmallerOrEqualValue(threshold))
          ..orderBy([(p) => OrderingTerm.asc(p.quantityOnHand)]))
        .watch();
  }

  /// 2. Stock Velocity (Fast Movers)
  /// Aggregates OrderItems to find top sellers in the given [range].
  Future<List<ProductVelocity>> getProductVelocity(DateTimeRange range) async {
    // 1. Get all OrderItems within range
    final query = _db.select(_db.orderItems).join([
      innerJoin(_db.orders, _db.orders.id.equalsExp(_db.orderItems.orderId)),
      innerJoin(_db.transactions, _db.transactions.id.equalsExp(_db.orders.transactionId)),
      innerJoin(_db.products, _db.products.id.equalsExp(_db.orderItems.productId)),
    ])
      ..where(_db.transactions.transactionDate.isBetweenValues(range.start, range.end));

    final rows = await query.get();

    // 2. Aggregate in Memory (Drift's group_by can be tricky with complex joins, this is safer for now)
    final Map<String, ProductVelocity> map = {};

    for (final row in rows) {
      final item = row.readTable(_db.orderItems);
      final product = row.readTable(_db.products);

      if (map.containsKey(product.id)) {
        final existing = map[product.id]!;
        map[product.id] = ProductVelocity(
          productId: product.id,
          productName: product.name,
          currentStock: product.quantityOnHand,
          quantitySold: existing.quantitySold + item.quantity,
          totalRevenue: existing.totalRevenue + (item.quantity * item.priceAtSale),
        );
      } else {
        map[product.id] = ProductVelocity(
          productId: product.id,
          productName: product.name,
          currentStock: product.quantityOnHand,
          quantitySold: item.quantity,
          totalRevenue: (item.quantity * item.priceAtSale).toDouble(),
        );
      }
    }

    final list = map.values.toList();
    
    // 3. Sort by Quantity Sold (Descending)
    list.sort((a, b) => b.quantitySold.compareTo(a.quantitySold));
    
    return list;
  }
}