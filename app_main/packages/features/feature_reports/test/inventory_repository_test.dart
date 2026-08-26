import 'package:core_database/core_database.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feature_reports/src/data/inventory_repository.dart';

void main() {
  test('empty operations reports return safe empty summaries', () async {
    final db = AppDatabase.connect(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = InventoryRepository(db);
    final range = DateTimeRange(
      start: DateTime(2026, 1, 1),
      end: DateTime(2026, 1, 31, 23, 59, 59),
    );

    final lowStock = await repository.watchReorderAlerts().first;
    final velocity = await repository.getProductVelocity(range);
    final tax = await repository.getTaxLiability(range);
    final cashierSales = await repository.getSalesByCashier(range);

    expect(lowStock, isEmpty);
    expect(velocity, isEmpty);
    expect(cashierSales, isEmpty);
    expect(tax.salesTaxCents, 0);
    expect(tax.purchaseTaxCents, 0);
    expect(tax.netTaxDueCents, 0);
    expect(tax.invoiceCount, 0);
    expect(tax.billCount, 0);
  });
}
