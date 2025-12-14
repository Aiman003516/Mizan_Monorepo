import 'package:core_database/core_database.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Providers
final apRepositoryProvider = Provider<APRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return APRepository(db);
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

  APRepository(this._db);

  // ==================== VENDORS ====================

  /// Watch all vendors ordered by name
  Stream<List<Vendor>> watchAllVendors() {
    return (_db.select(
      _db.vendors,
    )..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
  }

  /// Get a single vendor by ID
  Future<Vendor?> getVendor(String id) {
    return (_db.select(
      _db.vendors,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
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
  }) async {
    final companion = VendorsCompanion.insert(
      name: name,
      email: Value(email),
      phone: Value(phone),
      address: Value(address),
      taxId: Value(taxId),
      payableAccountId: Value(payableAccountId),
      paymentTerms: Value(paymentTerms),
      notes: Value(notes),
    );

    await _db.into(_db.vendors).insert(companion);
    return (await (_db.select(_db.vendors)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(1))
        .getSingle());
  }

  /// Update vendor
  Future<void> updateVendor(String id, VendorsCompanion companion) async {
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

  // ==================== BILLS ====================

  /// Watch all bills for a vendor
  Stream<List<Bill>> watchVendorBills(String vendorId) {
    return (_db.select(_db.bills)
          ..where((t) => t.vendorId.equals(vendorId))
          ..orderBy([(t) => OrderingTerm.desc(t.billDate)]))
        .watch();
  }

  /// Watch all bills
  Stream<List<Bill>> watchAllBills() {
    return (_db.select(
      _db.bills,
    )..orderBy([(t) => OrderingTerm.desc(t.billDate)])).watch();
  }

  /// Generate next bill number
  Future<String> generateBillNumber() async {
    final count = await _db
        .customSelect('SELECT COUNT(*) as cnt FROM bills')
        .getSingle();
    final num = (count.read<int>('cnt') ?? 0) + 1;
    return 'BILL-${num.toString().padLeft(4, '0')}';
  }

  /// Create a new bill
  Future<Bill> createBill({
    required String vendorId,
    required DateTime billDate,
    required DateTime dueDate,
    required List<BillItemData> items,
    String? vendorBillNumber,
    String? notes,
  }) async {
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
