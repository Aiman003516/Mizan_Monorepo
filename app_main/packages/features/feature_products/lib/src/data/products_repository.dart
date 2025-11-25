// FILE: mizan_monorepo.zip/app_main/packages/features/feature_products/lib/src/data/products_repository.dart

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'database_provider.dart';


final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ProductsRepository(db);
});

final productsByCategoryStreamProvider =
    StreamProvider.family<List<Product>, String>((ref, categoryId) {
  return ref.watch(productsRepositoryProvider).watchProducts(categoryId);
});

class ProductsRepository {
  final AppDatabase _db;
  ProductsRepository(this._db);

  Stream<List<Product>> watchProducts(String categoryId) {
    return (_db.select(_db.products)
          ..where((p) => p.categoryId.equals(categoryId))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .watch();
  }

  Stream<List<Product>> watchAllProducts() {
    return (_db.select(_db.products)
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .watch();
  }

  Future<Product?> findProductByBarcode(String barcode) {
    return (_db.select(_db.products)
          ..where((p) => p.barcode.equals(barcode)))
        .getSingleOrNull();
  }

  /// Takes [price] in standard currency units (e.g., 10.50) and stores it as cents (1050)
  Future<void> createProduct({
    required String name,
    required double price,
    required String categoryId,
    String? barcode,
    String? imagePath,
  }) async {
    await _db.into(_db.products).insert(
          ProductsCompanion.insert(
            name: name,
            price: (price * 100).round(), // Convert to Cents
            categoryId: categoryId,
            barcode: Value(barcode),
            imagePath: Value(imagePath),
            quantityOnHand: const Value(0.0),
            averageCost: const Value(0), // Initial cost is 0 cents
          ),
        );
  }

  Future<void> updateProduct(Product original, {
    required String newName,
    required double newPrice,
    required String newCategoryId,
    String? newBarcode,
    String? newImagePath,
  }) async {
    await _db.update(_db.products).replace(
      original.toCompanion(false).copyWith(
        name: Value(newName),
        price: Value((newPrice * 100).round()), // Convert to Cents
        categoryId: Value(newCategoryId),
        barcode: Value(newBarcode),
        imagePath: Value(newImagePath),
        lastUpdated: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteProduct(String id) async {
    await (_db.delete(_db.products)..where((p) => p.id.equals(id))).go();
  }

  /// [costPerItem] should be passed in standard currency (e.g., 5.00 for $5).
  Future<void> addStockToProduct({
    required String productId,
    required double quantityPurchased,
    required double costPerItem,
  }) async {

    final product = await (_db.select(_db.products)
          ..where((p) => p.id.equals(productId)))
        .getSingle();

    final double oldQty = product.quantityOnHand;
    // averageCost is now INT (cents). Convert to double for calculation:
    final double oldCostCents = product.averageCost.toDouble(); 
    
    final double newQty = quantityPurchased;
    final double newCostCents = costPerItem * 100.0;

    final double totalQuantity = oldQty + newQty;

    double newAverageCostCents = 0.0;
    if (totalQuantity > 0) {
      // Weighted Average Cost formula
      newAverageCostCents = ((oldQty * oldCostCents) + (newQty * newCostCents)) / totalQuantity;
    }

    final companion = product.toCompanion(false).copyWith(
          quantityOnHand: Value(totalQuantity),
          averageCost: Value(newAverageCostCents.round()), // Store as Int (Cents)
          lastUpdated: Value(DateTime.now()),
        );

    await _db.update(_db.products).replace(companion);
  }
}