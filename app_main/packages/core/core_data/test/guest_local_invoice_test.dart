import 'package:flutter_test/flutter_test.dart';
import 'package:core_data/core_data.dart';
import 'package:drift/native.dart';

void main() {
  test(
    'guest invoice is persisted and immediately visible in local Drift',
    () async {
      final db = AppDatabase.connect(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = ARRepository(db, cloudMode: false);

      final customer = await repository.createCustomer(name: 'Guest Customer');
      final invoice = await repository.createInvoice(
        customerId: customer.id,
        invoiceDate: DateTime(2026, 8, 25),
        dueDate: DateTime(2026, 9, 25),
        currencyCode: 'SAR',
        items: [
          InvoiceItemData(
            description: 'Local item',
            quantity: 2,
            unitPrice: 1250,
          ),
        ],
      );

      final visibleInvoices = await repository
          .watchCustomerInvoices(customer.id)
          .first;
      final detail = await repository.getInvoiceWithItems(invoice.id);

      expect(visibleInvoices.map((item) => item.id), contains(invoice.id));
      expect(detail, isNot(null));
      expect(detail!.items, hasLength(1));
      expect(detail.invoice.currencyCode, 'SAR');
      expect(detail.invoice.totalAmount, 2500);
    },
  );

  test('guest customer and vendor edits update the watched rows', () async {
    final db = AppDatabase.connect(NativeDatabase.memory());
    addTearDown(db.close);
    final ar = ARRepository(db, cloudMode: false);
    final ap = APRepository(db, cloudMode: false);

    final customer = await ar.createCustomer(name: 'Customer Before');
    await ar.updateCustomer(
      customer.id,
      CustomersCompanion(name: const Value('Customer After')),
    );
    final vendor = await ap.createVendor(name: 'Vendor Before');
    await ap.updateVendor(
      vendor.id,
      VendorsCompanion(name: const Value('Vendor After')),
    );

    final customers = await ar.watchAllCustomers().first;
    final vendors = await ap.watchAllVendors().first;
    expect(customers.single.name, 'Customer After');
    expect(vendors.single.name, 'Vendor After');
  });
}
