import 'package:core_data/core_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

void main() {
  test(
    'supplier quick adjustment updates AP balance and writes balanced entries',
    () async {
      final db = AppDatabase.connect(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = APRepository(db, cloudMode: false);

      await db
          .into(db.accounts)
          .insert(
            AccountsCompanion.insert(
              id: const Value('ap-account'),
              name: 'Accounts Payable',
              type: 'liability',
              initialBalance: 0,
            ),
          );
      await db
          .into(db.accounts)
          .insert(
            AccountsCompanion.insert(
              id: const Value('expense-account'),
              name: 'Supplier Adjustments',
              type: 'expense',
              initialBalance: 0,
            ),
          );
      await db
          .into(db.accounts)
          .insert(
            AccountsCompanion.insert(
              id: const Value('cash-account'),
              name: 'Cash',
              type: 'asset',
              initialBalance: 0,
            ),
          );

      final vendor = await repository.createVendor(name: 'Local Supplier');

      await repository.recordQuickAdjustment(
        vendorId: vendor.id,
        amount: 1500,
        increasePayable: true,
        notes: 'Additional supplier charge',
      );
      await repository.recordQuickAdjustment(
        vendorId: vendor.id,
        amount: 500,
        increasePayable: false,
        notes: 'Supplier payment correction',
      );

      final updatedVendor = await repository.getVendor(vendor.id);
      expect(updatedVendor?.balance, 1000);

      final entries = await db.select(db.transactionEntries).get();
      expect(entries, hasLength(4));
      expect(entries.fold<int>(0, (sum, entry) => sum + entry.amount), 0);

      final apAccountId = (await db.select(db.accounts).get())
          .firstWhere((account) => account.name == 'Accounts Payable')
          .id;
      final payableEntries = entries
          .where((entry) => entry.accountId == apAccountId)
          .map((entry) => entry.amount)
          .toList();
      expect(payableEntries, containsAll(<int>[-1500, 500]));
    },
  );
}
