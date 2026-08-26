import 'package:core_database/core_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

import 'cloud_crm_repository.dart';
import '../providers/cloud_data_mode_provider.dart';

const _uuid = Uuid();
// Providers
final apRepositoryProvider = Provider<APRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return APRepository(
    db,
    cloud: ref.watch(cloudCrmRepositoryProvider),
    cloudMode: ref.watch(cloudDataModeProvider),
  );
});

final vendorsStreamProvider = StreamProvider.autoDispose<List<Vendor>>((ref) {
  return ref.watch(apRepositoryProvider).watchAllVendors();
});

final vendorBillsProvider = StreamProvider.autoDispose
    .family<List<Bill>, String>((ref, vendorId) {
      return ref.watch(apRepositoryProvider).watchVendorBills(vendorId);
    });

final apAgingReportProvider = FutureProvider.autoDispose<APAgingReport>((ref) {
  return ref.watch(apRepositoryProvider).getAPAgingReport();
});

/// Data class for bill with line items
class BillWithItems {
  final Bill bill;
  final Vendor vendor;
  final List<BillItem> items;

  BillWithItems({
    required this.bill,
    required this.vendor,
    required this.items,
  });

  int get outstanding => bill.totalAmount - bill.amountPaid;
  bool get isPaid => outstanding <= 0;
}

/// Data class for AP aging report
class APAgingReport {
  final int totalPayables;
  final int current; // 0-30 days
  final int days31to60;
  final int days61to90;
  final int over90Days;
  final List<VendorBalance> vendorBalances;

  APAgingReport({
    required this.totalPayables,
    required this.current,
    required this.days31to60,
    required this.days61to90,
    required this.over90Days,
    required this.vendorBalances,
  });
}

class VendorBalance {
  final Vendor vendor;
  final int balance;
  final int current;
  final int days31to60;
  final int days61to90;
  final int over90Days;

  VendorBalance({
    required this.vendor,
    required this.balance,
    required this.current,
    required this.days31to60,
    required this.days61to90,
    required this.over90Days,
  });
}

/// Accounts Payable Repository
class APRepository {
  final AppDatabase _db;
  final CloudCrmRepository? _cloud;
  final bool _cloudMode;

  APRepository(this._db, {CloudCrmRepository? cloud, bool cloudMode = false})
    : _cloud = cloud,
      _cloudMode = cloudMode;

  bool get _useCloud => _cloudMode && _cloud != null;
  CloudCrmRepository get _cloudRepository => _cloud!;

  // ==================== VENDORS ====================

  /// Watch all vendors ordered by name
  Stream<List<Vendor>> watchAllVendors() {
    if (_useCloud) return _cloudRepository.watchVendors();
    return (_db.select(_db.vendors)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  /// Get a single vendor by ID
  Future<Vendor?> getVendor(String id) {
    if (_useCloud) return _cloudRepository.getVendor(id);
    return (_db.select(_db.vendors)
          ..where((t) => t.id.equals(id))
          ..where((t) => t.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  /// Create a new vendor
  Future<Vendor> createVendor({
    required String name,
    String? email,
    String? phone,
    String? address,
    String? taxId,
    String? payableAccountId,
    String? paymentTerms,
    String? notes,
    int openingBalance = 0,
  }) async {
    if (_useCloud) {
      return _cloudRepository.createVendor(
        name: name,
        email: email,
        phone: phone,
        address: address,
        taxId: taxId,
        paymentTerms: paymentTerms,
        notes: notes,
      );
    }
    return await _db.transaction(() async {
      // Pre-generate UUID so we can use it as both the PK and in FK references
      final vendorUuid = _uuid.v4();

      final companion = VendorsCompanion.insert(
        id: Value(vendorUuid),
        name: name,
        email: Value(email),
        phone: Value(phone),
        address: Value(address),
        taxId: Value(taxId),
        payableAccountId: Value(payableAccountId),
        paymentTerms: Value(paymentTerms),
        notes: Value(notes),
        balance: Value(openingBalance),
      );

      await _db.into(_db.vendors).insert(companion);

      if (openingBalance != 0) {
        final accountsList = await _db.select(_db.accounts).get();
        final apAccount =
            accountsList.firstWhereOrNull(
              (a) => a.name == 'Accounts Payable' || a.name.contains('Payable'),
            ) ??
            accountsList.firstWhereOrNull((a) => a.type == 'liability');

        final equityAccount =
            accountsList.firstWhereOrNull(
              (a) => a.name == 'Equity' || a.name.contains('Equity'),
            ) ??
            accountsList.firstWhereOrNull((a) => a.type == 'equity');

        if (apAccount == null || equityAccount == null) {
          throw Exception(
            'Required system accounts (Accounts Payable or Equity) are missing from the database.',
          );
        }

        // Pre-generate transaction UUID for FK references
        final txnUuid = _uuid.v4();
        final txnCompanion = TransactionsCompanion.insert(
          id: Value(txnUuid),
          transactionDate: DateTime.now(),
          description: 'Opening Balance for $name',
        );
        await _db.into(_db.transactions).insert(txnCompanion);

        await _db
            .into(_db.transactionEntries)
            .insert(
              TransactionEntriesCompanion.insert(
                transactionId: txnUuid, // ✅ UUID string, not int rowid
                accountId: apAccount.id,
                amount:
                    -openingBalance, // Liabilities are increased with credits (-)
              ),
            );

        await _db
            .into(_db.transactionEntries)
            .insert(
              TransactionEntriesCompanion.insert(
                transactionId: txnUuid, // ✅ UUID string, not int rowid
                accountId: equityAccount.id,
                amount: openingBalance,
              ),
            );
      }

      // Use the pre-generated UUID — no need to re-query by rowid
      return (await (_db.select(
        _db.vendors,
      )..where((t) => t.id.equals(vendorUuid))).getSingle());
    });
  }

  /// Update vendor
  Future<void> updateVendor(String id, VendorsCompanion companion) async {
    if (_useCloud) {
      final values = <String, dynamic>{};
      if (companion.name.present) values['name'] = companion.name.value;
      if (companion.email.present) values['email'] = companion.email.value;
      if (companion.phone.present) values['phone'] = companion.phone.value;
      if (companion.address.present)
        values['address'] = companion.address.value;
      if (companion.taxId.present) values['tax_id'] = companion.taxId.value;
      if (companion.paymentTerms.present)
        values['payment_terms'] = companion.paymentTerms.value;
      if (companion.notes.present) values['notes'] = companion.notes.value;
      await _cloudRepository.updateVendor(id, values);
      return;
    }
    await (_db.update(
      _db.vendors,
    )..where((t) => t.id.equals(id))).write(companion);
  }

  /// Update vendor balance
  Future<void> updateVendorBalance(String vendorId) async {
    final bills =
        await (_db.select(_db.bills)
              ..where((t) => t.vendorId.equals(vendorId))
              ..where((t) => t.status.isNotIn(['paid'])))
            .get();

    int totalOutstanding = 0;
    for (final bill in bills) {
      totalOutstanding += bill.totalAmount - bill.amountPaid;
    }

    await (_db.update(_db.vendors)..where((t) => t.id.equals(vendorId))).write(
      VendorsCompanion(balance: Value(totalOutstanding)),
    );
  }

  /// Records a manual supplier balance adjustment in the local ledger.
  ///
  /// A positive adjustment increases the amount owed to the supplier and is
  /// posted as debit Expense/Equity + credit Accounts Payable. A negative
  /// adjustment reduces the payable and is posted as debit Accounts Payable +
  /// credit Cash. The vendor balance and its journal transaction are written
  /// atomically.
  ///
  /// The current cloud schema does not expose a tenant-scoped journal-posting
  /// RPC, so authenticated cloud mode is rejected rather than silently writing
  /// to the local cache. This matches the existing AR limitation and keeps
  /// cloud source-of-truth integrity explicit until that RPC is added.
  Future<void> recordQuickAdjustment({
    required String vendorId,
    required int amount,
    required bool increasePayable,
    String? notes,
  }) async {
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount');
    }
    if (_useCloud) {
      throw StateError('Cloud supplier journal adjustment is not available');
    }

    await _db.transaction(() async {
      final vendor = await getVendor(vendorId);
      if (vendor == null) return;

      final accountsList = await _db.select(_db.accounts).get();
      final apAccount =
          accountsList.firstWhereOrNull(
            (account) =>
                account.name == 'Accounts Payable' ||
                account.name.contains('Payable'),
          ) ??
          accountsList.firstWhereOrNull(
            (account) => account.type == 'liability',
          );
      final offsetAccount = increasePayable
          ? accountsList.firstWhereOrNull(
                  (account) => account.type == 'expense',
                ) ??
                accountsList.firstWhereOrNull(
                  (account) => account.type == 'equity',
                )
          : accountsList.firstWhereOrNull(
                  (account) =>
                      account.name == 'Cash' || account.name.contains('Cash'),
                ) ??
                accountsList.firstWhereOrNull(
                  (account) => account.type == 'asset',
                );

      if (apAccount == null || offsetAccount == null) {
        throw StateError(
          'Required Accounts Payable and offset accounts are missing from the database',
        );
      }

      final transactionId = _uuid.v4();
      await _db
          .into(_db.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: Value(transactionId),
              transactionDate: DateTime.now(),
              description: notes?.trim().isNotEmpty == true
                  ? notes!.trim()
                  : 'Supplier Balance Adjustment for ${vendor.name}',
            ),
          );

      final debitAccountId = increasePayable ? offsetAccount.id : apAccount.id;
      final creditAccountId = increasePayable ? apAccount.id : offsetAccount.id;
      await _db
          .into(_db.transactionEntries)
          .insert(
            TransactionEntriesCompanion.insert(
              transactionId: transactionId,
              accountId: debitAccountId,
              amount: amount,
            ),
          );
      await _db
          .into(_db.transactionEntries)
          .insert(
            TransactionEntriesCompanion.insert(
              transactionId: transactionId,
              accountId: creditAccountId,
              amount: -amount,
            ),
          );

      await (_db.update(
        _db.vendors,
      )..where((row) => row.id.equals(vendorId))).write(
        VendorsCompanion(
          balance: Value(vendor.balance + (increasePayable ? amount : -amount)),
        ),
      );
    });
  }

  // ==================== BILLS ====================

  /// Watch all bills for a vendor
  Stream<List<Bill>> watchVendorBills(String vendorId) {
    if (_useCloud) return _cloudRepository.watchVendorBills(vendorId);
    return (_db.select(_db.bills)
          ..where((t) => t.vendorId.equals(vendorId))
          ..orderBy([(t) => OrderingTerm.desc(t.billDate)]))
        .watch();
  }

  /// Watch all bills
  Stream<List<Bill>> watchAllBills() {
    if (_useCloud) return _cloudRepository.watchAllBills();
    return (_db.select(_db.bills)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.billDate)]))
        .watch();
  }

  /// Generate next bill number
  Future<String> generateBillNumber() async {
    final now = DateTime.now();
    final yearStr = now.year.toString();
    final monthStr = now.month.toString().padLeft(2, '0');
    final prefix = 'BILL-$yearStr-$monthStr-';

    final result = await _db
        .customSelect(
          '''
      SELECT bill_number 
      FROM bills 
      WHERE bill_number LIKE ? 
      ORDER BY bill_number DESC 
      LIMIT 1
      ''',
          variables: [Variable<String>('$prefix%')],
        )
        .getSingleOrNull();

    int nextNum = 1;
    if (result != null) {
      final lastNumber = result.read<String>('bill_number');
      final parts = lastNumber.split('-');
      if (parts.length >= 4) {
        final lastSeq = int.tryParse(parts[3]) ?? 0;
        nextNum = lastSeq + 1;
      }
    }

    return '$prefix${nextNum.toString().padLeft(4, '0')}';
  }

  /// Create a new bill
  Future<Bill> createBill({
    required String vendorId,
    required DateTime billDate,
    required DateTime dueDate,
    required List<BillItemData> items,
    required String currencyCode,
    String? vendorBillNumber,
    String? notes,
  }) async {
    if (_useCloud) {
      return _cloudRepository.createBill(
        vendorId: vendorId,
        billDate: billDate,
        dueDate: dueDate,
        items: items,
        currencyCode: currencyCode,
        vendorBillNumber: vendorBillNumber,
        notes: notes,
      );
    }
    return await _db.transaction(() async {
      final billNumber = await generateBillNumber();

      // Calculate totals
      int subtotal = 0;
      for (final item in items) {
        subtotal += (item.quantity * item.unitPrice).round();
      }

      final companion = BillsCompanion.insert(
        billNumber: billNumber,
        vendorId: vendorId,
        billDate: billDate,
        dueDate: dueDate,
        subtotal: subtotal,
        totalAmount: subtotal, // No tax for now
        vendorBillNumber: Value(vendorBillNumber),
        notes: Value(notes),
        currencyCode: Value(currencyCode),
      );

      await _db.into(_db.bills).insert(companion);

      final bill = await (_db.select(
        _db.bills,
      )..where((t) => t.billNumber.equals(billNumber))).getSingle();

      // Insert line items
      for (final item in items) {
        await _db
            .into(_db.billItems)
            .insert(
              BillItemsCompanion.insert(
                billId: bill.id,
                description: item.description,
                quantity: item.quantity,
                unitPrice: item.unitPrice,
                amount: (item.quantity * item.unitPrice).round(),
                productId: Value(item.productId),
                expenseAccountId: Value(item.expenseAccountId),
              ),
            );
      }

      // Update vendor balance
      await updateVendorBalance(vendorId);

      return bill;
    });
  }

  /// Update bill status
  Future<void> updateBillStatus(String billId, String status) async {
    await (_db.update(_db.bills)..where((t) => t.id.equals(billId))).write(
      BillsCompanion(status: Value(status)),
    );
  }

  /// Check and update overdue bills
  Future<void> markOverdueBills() async {
    final now = DateTime.now();
    await (_db.update(_db.bills)
          ..where((t) => t.status.isIn(['pending', 'partial']))
          ..where((t) => t.dueDate.isSmallerThanValue(now)))
        .write(const BillsCompanion(status: Value('overdue')));
  }

  // ==================== PAYMENTS ====================

  /// Record a payment to vendor
  Future<VendorPayment> recordPayment({
    required String vendorId,
    required DateTime paymentDate,
    required int amount,
    required List<BillPaymentData> allocations,
    String? paymentMethodId,
    String? reference,
    String? notes,
  }) async {
    return await _db.transaction(() async {
      final paymentCompanion = VendorPaymentsCompanion.insert(
        vendorId: vendorId,
        paymentDate: paymentDate,
        amount: amount,
        paymentMethodId: Value(paymentMethodId),
        reference: Value(reference),
        notes: Value(notes),
      );

      await _db.into(_db.vendorPayments).insert(paymentCompanion);

      final payment =
          await (_db.select(_db.vendorPayments)
                ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
                ..limit(1))
              .getSingle();

      // Create allocations and update bills
      for (final alloc in allocations) {
        await _db
            .into(_db.billPaymentAllocations)
            .insert(
              BillPaymentAllocationsCompanion.insert(
                paymentId: payment.id,
                billId: alloc.billId,
                amount: alloc.amount,
              ),
            );

        // Update bill amountPaid
        final bill = await (_db.select(
          _db.bills,
        )..where((t) => t.id.equals(alloc.billId))).getSingle();

        final newAmountPaid = bill.amountPaid + alloc.amount;
        final newStatus = newAmountPaid >= bill.totalAmount
            ? 'paid'
            : 'partial';

        await (_db.update(
          _db.bills,
        )..where((t) => t.id.equals(alloc.billId))).write(
          BillsCompanion(
            amountPaid: Value(newAmountPaid),
            status: Value(newStatus),
          ),
        );
      }

      // Update vendor balance
      await updateVendorBalance(vendorId);

      return payment;
    });
  }

  // ==================== REPORTS ====================

  /// Get AP Aging Report
  Future<APAgingReport> getAPAgingReport() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final sixtyDaysAgo = now.subtract(const Duration(days: 60));
    final ninetyDaysAgo = now.subtract(const Duration(days: 90));

    final vendors = await _db.select(_db.vendors).get();

    List<VendorBalance> balances = [];
    int totalPayables = 0;
    int totalCurrent = 0;
    int total31to60 = 0;
    int total61to90 = 0;
    int totalOver90 = 0;

    for (final vendor in vendors) {
      final bills =
          await (_db.select(_db.bills)
                ..where((t) => t.vendorId.equals(vendor.id))
                ..where((t) => t.status.isNotIn(['paid'])))
              .get();

      int current = 0;
      int days31to60 = 0;
      int days61to90 = 0;
      int over90 = 0;

      for (final bill in bills) {
        final outstanding = bill.totalAmount - bill.amountPaid;
        if (outstanding <= 0) continue;

        if (bill.billDate.isAfter(thirtyDaysAgo)) {
          current += outstanding;
        } else if (bill.billDate.isAfter(sixtyDaysAgo)) {
          days31to60 += outstanding;
        } else if (bill.billDate.isAfter(ninetyDaysAgo)) {
          days61to90 += outstanding;
        } else {
          over90 += outstanding;
        }
      }

      final balance = current + days31to60 + days61to90 + over90;
      if (balance > 0) {
        balances.add(
          VendorBalance(
            vendor: vendor,
            balance: balance,
            current: current,
            days31to60: days31to60,
            days61to90: days61to90,
            over90Days: over90,
          ),
        );

        totalPayables += balance;
        totalCurrent += current;
        total31to60 += days31to60;
        total61to90 += days61to90;
        totalOver90 += over90;
      }
    }

    balances.sort((a, b) => b.balance.compareTo(a.balance));

    return APAgingReport(
      totalPayables: totalPayables,
      current: totalCurrent,
      days31to60: total31to60,
      days61to90: total61to90,
      over90Days: totalOver90,
      vendorBalances: balances,
    );
  }
}

/// Data class for creating bill items
class BillItemData {
  final String description;
  final double quantity;
  final int unitPrice;
  final String? productId;
  final String? expenseAccountId;

  BillItemData({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.productId,
    this.expenseAccountId,
  });
}

/// Data class for bill payment allocation
class BillPaymentData {
  final String billId;
  final int amount;

  BillPaymentData({required this.billId, required this.amount});
}
