import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/analytics_repository.dart';

// 1. Sales Trend (Last 30 Days)
final dailySalesProvider = FutureProvider.autoDispose<List<DailySalesPoint>>((ref) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  final end = DateTime.now();
  final start = end.subtract(const Duration(days: 30));
  return repo.getDailySalesStats(start, end);
});

// 2. Category Performance (All Time)
final categorySalesProvider = FutureProvider.autoDispose<List<CategoryShare>>((ref) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getSalesByCategory();
});

// 3. Top Products (Top 5)
final topProductsProvider = FutureProvider.autoDispose<List<ProductPerformance>>((ref) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getTopSellingProducts(limit: 5);
});