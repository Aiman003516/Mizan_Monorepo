import 'package:core_data/core_data.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'customer adjustment uses revenue for charges and records history',
    () async {
      final db = AppDatabase.connect(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = ARRepository(db, cloudMode: false);

      await db
          .into(db.accounts)
          .insert(
            AccountsCompanion.insert(
              id: const Value('ar-account'),
              name: 'Accounts Receivable',
              type: 'asset',
              initialBalance: 0,
            ),
          );
      await db
          .into(db.accounts)
          .insert(
            AccountsCompanion.insert(
              id: const Value('revenue-account'),
              name: 'Service Revenue',
              type: 'revenue',
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

      final customer = await repository.createCustomer(name: 'Local Customer');
      await repository.recordQuickAdjustment(
        customerId: customer.id,
        amount: 1250,
        isCharge: true,
        notes: 'Unbilled service correction',
      );
      await repository.recordQuickAdjustment(
        customerId: customer.id,
        amount: 250,
        isCharge: false,
        notes: 'Receipt correction',
      );

      expect((await repository.getCustomer(customer.id))?.balance, 1000);
      final adjustments = await repository
          .watchCustomerAdjustments(customer.id)
          .first;
      expect(adjustments, hasLength(2));
      expect(
        adjustments.map((item) => item.direction),
        containsAll(['increase', 'decrease']),
      );

      final entries = await db.select(db.transactionEntries).get();
      expect(entries, hasLength(4));
      expect(entries.fold<int>(0, (sum, entry) => sum + entry.amount), 0);
      expect(entries.where((entry) => entry.amount == -1250), hasLength(1));
      expect(entries.where((entry) => entry.amount == 250), hasLength(1));

      expect(
        () => repository.recordQuickAdjustment(
          customerId: customer.id,
          amount: 1001,
          isCharge: false,
          notes: 'Too much receipt',
        ),
        throwsA(isA<StateError>()),
      );
    },
  );
}
