import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:feature_reports/feature_reports.dart';

final mainDashboardSearchProvider = StateProvider<String>((ref) => '');

final totalRevenueProvider = FutureProvider.autoDispose<double>((ref) {
  final service = ref.watch(reportsServiceProvider);
  return service.getTotalRevenue();
});

final totalExpensesProvider = FutureProvider.autoDispose<double>((ref) {
  final service = ref.watch(reportsServiceProvider);
  return service.getTotalExpenses();
});

final totalReceivableProvider = FutureProvider.autoDispose<double>((ref) {
  final service = ref.watch(reportsServiceProvider);
  return service.getTotalReceivable();
});

final totalPayableProvider = FutureProvider.autoDispose<double>((ref) {
  final service = ref.watch(reportsServiceProvider);
  return service.getTotalPayable();
});