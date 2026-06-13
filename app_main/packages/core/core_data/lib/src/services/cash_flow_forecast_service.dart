import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';

/// Cash Flow Forecasting Service.
/// Projects future cash balance based on open invoices and bills.
class CashFlowForecastService {
  final AppDatabase _db;

  CashFlowForecastService(this._db);

  /// Gets projected cash flow for the next N days.
  /// Returns a list of {date, projectedBalance} maps.
  Future<List<Map<String, dynamic>>> getForecast({
    required int currentBalance,
    int daysAhead = 30,
  }) async {
    final today = DateTime.now();
    final endDate = today.add(Duration(days: daysAhead));
    final forecasts = <Map<String, dynamic>>[];

    // Get all open invoices within date range
    final allInvoices = await _db.select(_db.invoices).get();
    final openInvoices = allInvoices
        .where(
          (i) =>
              (i.status == 'draft' ||
                  i.status == 'sent' ||
                  i.status == 'partial') &&
              i.dueDate.isAfter(today.subtract(const Duration(days: 1))) &&
              i.dueDate.isBefore(endDate.add(const Duration(days: 1))),
        )
        .toList();

    // Get all unpaid bills within date range
    final allBills = await _db.select(_db.bills).get();
    final unpaidBills = allBills
        .where(
          (b) =>
              (b.status == 'pending' || b.status == 'partial') &&
              b.dueDate.isAfter(today.subtract(const Duration(days: 1))) &&
              b.dueDate.isBefore(endDate.add(const Duration(days: 1))),
        )
        .toList();

    // Build daily forecast
    int runningBalance = currentBalance;

    for (int i = 0; i <= daysAhead; i++) {
      final date = today.add(Duration(days: i));

      // Add expected income from invoices due on this date
      for (final invoice in openInvoices) {
        if (_isSameDay(invoice.dueDate, date)) {
          runningBalance += (invoice.totalAmount - invoice.amountPaid);
        }
      }

      // Subtract expected expenses from bills due on this date
      for (final bill in unpaidBills) {
        if (_isSameDay(bill.dueDate, date)) {
          runningBalance -= (bill.totalAmount - bill.amountPaid);
        }
      }

      forecasts.add({'date': date, 'balance': runningBalance});
    }

    return forecasts;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

final cashFlowForecastServiceProvider = Provider((ref) {
  final db = ref.watch(appDatabaseProvider);
  return CashFlowForecastService(db);
});
