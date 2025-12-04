import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final db = ref.watch(appDatabaseProvider); 
  return AnalyticsRepository(db);
});

/// 📊 THE CRUNCHER
/// Executes complex aggregations (SUM, COUNT, GROUP BY) on the local database.
class AnalyticsRepository {
  final AppDatabase _db;

  AnalyticsRepository(this._db);

  // --- 1. SALES TREND (Bar/Line Chart) ---
  /// Returns total revenue grouped by day for the given range.
  Future<List<DailySalesPoint>> getDailySalesStats(DateTime start, DateTime end) async {
    
    // 🛡️ FIX: Removed the invalid '_db.transactions.totalAmount' reference.
    // We query the ORDERS table (which has the amount) and join with TRANSACTIONS (for the date).
    
    final query = _db.select(_db.orders).join([
      innerJoin(_db.transactions, _db.transactions.id.equalsExp(_db.orders.transactionId))
    ]);

    query.where(_db.transactions.transactionDate.isBetweenValues(start, end));
    
    final results = await query.map((row) {
      return {
        'date': row.readTable(_db.transactions).transactionDate,
        'amount': row.readTable(_db.orders).totalAmount,
      };
    }).get();

    // Grouping Logic in Dart
    final Map<DateTime, double> groupedMap = {};
    
    for (var row in results) {
      final date = row['date'] as DateTime;
      final amountCents = row['amount'] as int;
      
      // Normalize to midnight (Day only)
      final dayKey = DateTime(date.year, date.month, date.day);
      
      groupedMap[dayKey] = (groupedMap[dayKey] ?? 0) + (amountCents / 100.0);
    }

    // Convert to List
    final List<DailySalesPoint> points = groupedMap.entries.map((e) {
      return DailySalesPoint(e.key, e.value);
    }).toList();

    // Sort by Date
    points.sort((a, b) => a.date.compareTo(b.date));
    
    return points;
  }

  // --- 2. CATEGORY PERFORMANCE (Pie Chart) ---
  Future<List<CategoryShare>> getSalesByCategory() async {
    final orderItems = _db.orderItems;
    final products = _db.products;
    final categories = _db.categories;

    // Expression: SUM(quantity * priceAtSale)
    final totalValueExpr = orderItems.quantity * orderItems.priceAtSale.cast<double>();
    final sumTotal = totalValueExpr.sum();

    final query = _db.selectOnly(orderItems).join([
      innerJoin(products, products.id.equalsExp(orderItems.productId)),
      innerJoin(categories, categories.id.equalsExp(products.categoryId)),
    ]);

    query.addColumns([categories.name, sumTotal]);
    query.groupBy([categories.id]);

    final results = await query.get();

    return results.map((row) {
      final categoryName = row.read(categories.name) ?? 'Unknown';
      final totalCents = row.read(sumTotal) ?? 0.0;
      
      return CategoryShare(categoryName, totalCents / 100.0);
    }).toList();
  }

  // --- 3. TOP PRODUCTS (Leaderboard) ---
  Future<List<ProductPerformance>> getTopSellingProducts({int limit = 5}) async {
    final orderItems = _db.orderItems;
    
    // Sum Quantity
    final sumQty = orderItems.quantity.sum();

    final query = _db.selectOnly(orderItems)
      ..addColumns([orderItems.productName, sumQty])
      ..groupBy([orderItems.productId])
      ..orderBy([OrderingTerm(expression: sumQty, mode: OrderingMode.desc)])
      ..limit(limit);

    final results = await query.get();

    return results.map((row) {
      return ProductPerformance(
        row.read(orderItems.productName) ?? 'Unknown',
        row.read(sumQty) ?? 0.0,
      );
    }).toList();
  }
}

// --- 📉 ANALYTICS DATA MODELS ---

class DailySalesPoint {
  final DateTime date;
  final double amount;
  DailySalesPoint(this.date, this.amount);
}

class CategoryShare {
  final String categoryName;
  final double totalRevenue;
  CategoryShare(this.categoryName, this.totalRevenue);
}

class ProductPerformance {
  final String productName;
  final double quantitySold;
  ProductPerformance(this.productName, this.quantitySold);
}