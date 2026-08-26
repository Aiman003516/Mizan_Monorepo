import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:feature_reports/src/data/reports_service.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return InventoryRepository(db);
});

final reorderAlertsProvider = StreamProvider.autoDispose<List<Product>>((ref) {
  return ref.watch(inventoryRepositoryProvider).watchReorderAlerts();
});

final productVelocityProvider = FutureProvider.autoDispose
    .family<List<ProductVelocity>, DateTimeRange>((ref, range) {
      return ref.watch(inventoryRepositoryProvider).getProductVelocity(range);
    });

final taxLiabilityProvider = FutureProvider.autoDispose
    .family<TaxLiabilitySummary, DateTimeRange>((ref, range) {
      return ref.watch(inventoryRepositoryProvider).getTaxLiability(range);
    });

final cashierSalesProvider = FutureProvider.autoDispose
    .family<List<CashierSalesSummary>, DateTimeRange>((ref, range) {
      return ref.watch(inventoryRepositoryProvider).getSalesByCashier(range);
    });

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

  double get score => quantitySold;
}

class TaxLiabilitySummary {
  final int salesTaxCents;
  final int purchaseTaxCents;
  final int invoiceCount;
  final int billCount;

  const TaxLiabilitySummary({
    required this.salesTaxCents,
    required this.purchaseTaxCents,
    required this.invoiceCount,
    required this.billCount,
  });

  int get netTaxDueCents => salesTaxCents - purchaseTaxCents;
}

class CashierSalesSummary {
  final String cashierId;
  final int totalSalesCents;
  final int orderCount;

  const CashierSalesSummary({
    required this.cashierId,
    required this.totalSalesCents,
    required this.orderCount,
  });
}

class InventoryRepository {
  final AppDatabase _db;
  InventoryRepository(this._db);

  /// Products at or below their configured reorder point, including products
  /// with no stock. Products without a reorder point are not flagged unless
  /// their stock is already zero.
  Stream<List<Product>> watchReorderAlerts() {
    return (_db.select(_db.products)
          ..where(
            (p) =>
                p.quantityOnHand.isSmallerOrEqual(
                  p.reorderPoint.cast<double>(),
                ) |
                p.quantityOnHand.equals(0),
          )
          ..orderBy([
            (p) => OrderingTerm.asc(p.quantityOnHand),
            (p) => OrderingTerm.asc(p.name),
          ]))
        .watch();
  }

  /// Legacy threshold-based low-stock query retained for existing callers.
  Stream<List<Product>> watchLowStockProducts({double threshold = 5.0}) {
    return (_db.select(_db.products)
          ..where((p) => p.quantityOnHand.isSmallerOrEqualValue(threshold))
          ..orderBy([(p) => OrderingTerm.asc(p.quantityOnHand)]))
        .watch();
  }

  /// Aggregates net sold quantities and revenue for the selected range.
  Future<List<ProductVelocity>> getProductVelocity(DateTimeRange range) async {
    final query =
        _db.select(_db.orderItems).join([
          innerJoin(
            _db.orders,
            _db.orders.id.equalsExp(_db.orderItems.orderId),
          ),
          innerJoin(
            _db.transactions,
            _db.transactions.id.equalsExp(_db.orders.transactionId),
          ),
          innerJoin(
            _db.products,
            _db.products.id.equalsExp(_db.orderItems.productId),
          ),
        ])..where(
          _db.transactions.transactionDate.isBetweenValues(
            range.start,
            range.end,
          ),
        );

    final rows = await query.get();
    final Map<String, ProductVelocity> map = {};

    for (final row in rows) {
      final item = row.readTable(_db.orderItems);
      final product = row.readTable(_db.products);
      final netQuantity = (item.quantity - item.quantityReturned)
          .clamp(0.0, double.infinity)
          .toDouble();
      if (netQuantity == 0) continue;

      final existing = map[product.id];
      map[product.id] = ProductVelocity(
        productId: product.id,
        productName: product.name,
        currentStock: product.quantityOnHand,
        quantitySold: (existing?.quantitySold ?? 0) + netQuantity,
        totalRevenue:
            (existing?.totalRevenue ?? 0) + (netQuantity * item.priceAtSale),
      );
    }

    final list = map.values.toList()
      ..sort((a, b) => b.quantitySold.compareTo(a.quantitySold));
    return list;
  }

  Future<TaxLiabilitySummary> getTaxLiability(DateTimeRange range) async {
    final invoices =
        await (_db.select(_db.invoices)
              ..where(
                (invoice) =>
                    invoice.invoiceDate.isBetweenValues(range.start, range.end),
              )
              ..where((invoice) => invoice.status.isNotIn(['void'])))
            .get();
    final bills =
        await (_db.select(_db.bills)
              ..where(
                (bill) => bill.billDate.isBetweenValues(range.start, range.end),
              )
              ..where((bill) => bill.status.isNotIn(['void'])))
            .get();

    return TaxLiabilitySummary(
      salesTaxCents: invoices.fold(
        0,
        (sum, invoice) => sum + invoice.taxAmount,
      ),
      purchaseTaxCents: bills.fold(0, (sum, bill) => sum + bill.taxAmount),
      invoiceCount: invoices.length,
      billCount: bills.length,
    );
  }

  Future<List<CashierSalesSummary>> getSalesByCashier(
    DateTimeRange range,
  ) async {
    final query =
        _db.select(_db.orders).join([
          innerJoin(
            _db.transactions,
            _db.transactions.id.equalsExp(_db.orders.transactionId),
          ),
        ])..where(
          _db.transactions.transactionDate.isBetweenValues(
            range.start,
            range.end,
          ),
        );

    final rows = await query.get();
    final summaries = <String, CashierSalesSummary>{};
    for (final row in rows) {
      final order = row.readTable(_db.orders);
      final transaction = row.readTable(_db.transactions);
      final cashierId = transaction.createdByUserId?.trim().isNotEmpty == true
          ? transaction.createdByUserId!.trim()
          : 'unassigned';
      final existing = summaries[cashierId];
      summaries[cashierId] = CashierSalesSummary(
        cashierId: cashierId,
        totalSalesCents: (existing?.totalSalesCents ?? 0) + order.totalAmount,
        orderCount: (existing?.orderCount ?? 0) + 1,
      );
    }

    return summaries.values.toList()
      ..sort((a, b) => b.totalSalesCents.compareTo(a.totalSalesCents));
  }
}
