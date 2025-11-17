import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:feature_reports/src/data/report_models.dart';
import 'package:feature_reports/src/data/reports_service.dart';

/// StreamProvider that provides the full list of joined transaction details.
final generalLedgerStreamProvider =
StreamProvider<List<TransactionDetail>>((ref) {
  final reportsService = ref.watch(reportsServiceProvider);
  return reportsService.watchTransactionDetails();
});