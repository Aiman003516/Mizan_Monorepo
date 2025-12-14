import 'package:core_database/core_database.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Providers
final arRepositoryProvider = Provider<ARRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ARRepository(db);
});

final customersStreamProvider = StreamProvider.autoDispose<List<Customer>>((
  ref,
) {
  return ref.watch(arRepositoryProvider).watchAllCustomers();
});

final customerInvoicesProvider = StreamProvider.autoDispose
    .family<List<Invoice>, String>((ref, customerId) {
      return ref.watch(arRepositoryProvider).watchCustomerInvoices(customerId);
    });

final invoiceWithItemsProvider = FutureProvider.autoDispose
    .family<InvoiceWithItems?, String>((ref, invoiceId) {
      return ref.watch(arRepositoryProvider).getInvoiceWithItems(invoiceId);
    });

final arAgingReportProvider = FutureProvider.autoDispose<ARAgingReport>((ref) {
  return ref.watch(arRepositoryProvider).getARAgingReport();
});

/// Data class for invoice with line items
class InvoiceWithItems {
  final Invoice invoice;
  final Customer customer;
  final List<InvoiceItem> items;

  InvoiceWithItems({
    required this.invoice,
    required this.customer,
    required this.items,
  });

  int get outstanding => invoice.totalAmount - invoice.amountPaid;
  bool get isPaid => outstanding <= 0;
}

/// Data class for AR aging report
class ARAgingReport {
  final int totalReceivables;
  final int current; // 0-30 days
  final int days31to60;
  final int days61to90;
  final int over90Days;
  final List<CustomerBalance> customerBalances;

  ARAgingReport({
    required this.totalReceivables,
    required this.current,
    required this.days31to60,
    required this.days61to90,
    required this.over90Days,
    required this.customerBalances,
  });
}

class CustomerBalance {
  final Customer customer;
  final int balance;
  final int current;
  final int days31to60;
  final int days61to90;
  final int over90Days;

  CustomerBalance({
    required this.customer,
    required this.balance,
    required this.current,
    required this.days31to60,
    required this.days61to90,
    required this.over90Days,
  });
}

/// Accounts Receivable Repository
class ARRepository {
  final AppDatabase _db;

  ARRepository(this._db);

  // ==================== CUSTOMERS ====================

  /// Watch all customers ordered by name
  Stream<List<Customer>> watchAllCustomers() {
    return (_db.select(
      _db.customers,
    )..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
  }

  /// Get a single customer by ID
  Future<Customer?> getCustomer(String id) {
    return (_db.select(
      _db.customers,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Create a new customer
  Future<Customer> createCustomer({
    required String name,
    String? email,
    String? phone,
    String? address,
    String? taxId,
    int creditLimit = 0,
    String? receivableAccountId,
    String? notes,
  }) async {
    final companion = CustomersCompanion.insert(
      name: name,
      email: Value(email),
      phone: Value(phone),
      address: Value(address),
      taxId: Value(taxId),
      creditLimit: Value(creditLimit),
      receivableAccountId: Value(receivableAccountId),
      notes: Value(notes),
    );

    final id = await _db.into(_db.customers).insert(companion);
    return (await (_db.select(
      _db.customers,
    )..where((t) => t.id.equals(id.toString()))).getSingle());
  }

  /// Update customer
  Future<void> updateCustomer(String id, CustomersCompanion companion) async {
    await (_db.update(
      _db.customers,
    )..where((t) => t.id.equals(id))).write(companion);
  }

  /// Update customer balance
  Future<void> updateCustomerBalance(String customerId) async {
    // Calculate total outstanding from unpaid invoices
    final invoices =
        await (_db.select(_db.invoices)
              ..where((t) => t.customerId.equals(customerId))
              ..where((t) => t.status.isNotIn(['void', 'paid'])))
            .get();

    int totalOutstanding = 0;
    for (final inv in invoices) {
      totalOutstanding += inv.totalAmount - inv.amountPaid;
    }

    await (_db.update(_db.customers)..where((t) => t.id.equals(customerId)))
        .write(CustomersCompanion(balance: Value(totalOutstanding)));
  }

  // ==================== INVOICES ====================

  /// Watch all invoices for a customer
  Stream<List<Invoice>> watchCustomerInvoices(String customerId) {
    return (_db.select(_db.invoices)
          ..where((t) => t.customerId.equals(customerId))
          ..orderBy([(t) => OrderingTerm.desc(t.invoiceDate)]))
        .watch();
  }

  /// Watch all invoices
  Stream<List<Invoice>> watchAllInvoices() {
    return (_db.select(
      _db.invoices,
    )..orderBy([(t) => OrderingTerm.desc(t.invoiceDate)])).watch();
  }

  /// Get invoice with items
  Future<InvoiceWithItems?> getInvoiceWithItems(String invoiceId) async {
    final invoice = await (_db.select(
      _db.invoices,
    )..where((t) => t.id.equals(invoiceId))).getSingleOrNull();

    if (invoice == null) return null;

    final customer = await (_db.select(
      _db.customers,
    )..where((t) => t.id.equals(invoice.customerId))).getSingle();

    final items = await (_db.select(
      _db.invoiceItems,
    )..where((t) => t.invoiceId.equals(invoiceId))).get();

    return InvoiceWithItems(invoice: invoice, customer: customer, items: items);
  }

  /// Generate next invoice number
  Future<String> generateInvoiceNumber() async {
    final count = await _db
        .customSelect('SELECT COUNT(*) as cnt FROM invoices')
        .getSingle();
    final num = (count.read<int>('cnt') ?? 0) + 1;
    return 'INV-${num.toString().padLeft(4, '0')}';
  }

  /// Create a new invoice
  Future<Invoice> createInvoice({
    required String customerId,
    required DateTime invoiceDate,
    required DateTime dueDate,
    required List<InvoiceItemData> items,
    String? notes,
  }) async {
    return await _db.transaction(() async {
      final invoiceNumber = await generateInvoiceNumber();

      // Calculate totals
      int subtotal = 0;
      for (final item in items) {
        subtotal += (item.quantity * item.unitPrice).round();
      }

      final companion = InvoicesCompanion.insert(
        invoiceNumber: invoiceNumber,
        customerId: customerId,
        invoiceDate: invoiceDate,
        dueDate: dueDate,
        subtotal: subtotal,
        totalAmount: subtotal, // No tax for now
      );

      // Get the generated ID from insert
      await _db.into(_db.invoices).insert(companion);

      // Query to get the inserted invoice
      final invoice = await (_db.select(
        _db.invoices,
      )..where((t) => t.invoiceNumber.equals(invoiceNumber))).getSingle();

      // Insert line items
      for (final item in items) {
        await _db
            .into(_db.invoiceItems)
            .insert(
              InvoiceItemsCompanion.insert(
                invoiceId: invoice.id,
                description: item.description,
                quantity: item.quantity,
                unitPrice: item.unitPrice,
                amount: (item.quantity * item.unitPrice).round(),
                productId: Value(item.productId),
                revenueAccountId: Value(item.revenueAccountId),
              ),
            );
      }

      // Update customer balance
      await updateCustomerBalance(customerId);

      return invoice;
    });
  }

  /// Update invoice status
  Future<void> updateInvoiceStatus(String invoiceId, String status) async {
    await (_db.update(_db.invoices)..where((t) => t.id.equals(invoiceId)))
        .write(InvoicesCompanion(status: Value(status)));
  }

  /// Check and update overdue invoices
  Future<void> markOverdueInvoices() async {
    final now = DateTime.now();
    await (_db.update(_db.invoices)
          ..where((t) => t.status.isIn(['draft', 'sent', 'partial']))
          ..where((t) => t.dueDate.isSmallerThanValue(now)))
        .write(const InvoicesCompanion(status: Value('overdue')));
  }

  // ==================== PAYMENTS ====================

  /// Record a payment from customer
  Future<CustomerPayment> recordPayment({
    required String customerId,
    required DateTime paymentDate,
    required int amount,
    required List<PaymentAllocationData> allocations,
    String? paymentMethodId,
    String? reference,
    String? notes,
  }) async {
    return await _db.transaction(() async {
      // Create payment record
      final paymentCompanion = CustomerPaymentsCompanion.insert(
        customerId: customerId,
        paymentDate: paymentDate,
        amount: amount,
        paymentMethodId: Value(paymentMethodId),
        reference: Value(reference),
        notes: Value(notes),
      );

      await _db.into(_db.customerPayments).insert(paymentCompanion);

      // Get the payment
      final payment =
          await (_db.select(_db.customerPayments)
                ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
                ..limit(1))
              .getSingle();

      // Create allocations and update invoices
      for (final alloc in allocations) {
        await _db
            .into(_db.paymentAllocations)
            .insert(
              PaymentAllocationsCompanion.insert(
                paymentId: payment.id,
                invoiceId: alloc.invoiceId,
                amount: alloc.amount,
              ),
            );

        // Update invoice amountPaid
        final invoice = await (_db.select(
          _db.invoices,
        )..where((t) => t.id.equals(alloc.invoiceId))).getSingle();

        final newAmountPaid = invoice.amountPaid + alloc.amount;
        final newStatus = newAmountPaid >= invoice.totalAmount
            ? 'paid'
            : 'partial';

        await (_db.update(
          _db.invoices,
        )..where((t) => t.id.equals(alloc.invoiceId))).write(
          InvoicesCompanion(
            amountPaid: Value(newAmountPaid),
            status: Value(newStatus),
          ),
        );
      }

      // Update customer balance
      await updateCustomerBalance(customerId);

      return payment;
    });
  }

  // ==================== REPORTS ====================

  /// Get AR Aging Report
  Future<ARAgingReport> getARAgingReport() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final sixtyDaysAgo = now.subtract(const Duration(days: 60));
    final ninetyDaysAgo = now.subtract(const Duration(days: 90));

    // Get all customers with outstanding invoices
    final customers = await _db.select(_db.customers).get();

    List<CustomerBalance> balances = [];
    int totalReceivables = 0;
    int totalCurrent = 0;
    int total31to60 = 0;
    int total61to90 = 0;
    int totalOver90 = 0;

    for (final customer in customers) {
      // Get unpaid invoices for this customer
      final invoices =
          await (_db.select(_db.invoices)
                ..where((t) => t.customerId.equals(customer.id))
                ..where((t) => t.status.isNotIn(['void', 'paid'])))
              .get();

      int current = 0;
      int days31to60 = 0;
      int days61to90 = 0;
      int over90 = 0;

      for (final invoice in invoices) {
        final outstanding = invoice.totalAmount - invoice.amountPaid;
        if (outstanding <= 0) continue;

        if (invoice.invoiceDate.isAfter(thirtyDaysAgo)) {
          current += outstanding;
        } else if (invoice.invoiceDate.isAfter(sixtyDaysAgo)) {
          days31to60 += outstanding;
        } else if (invoice.invoiceDate.isAfter(ninetyDaysAgo)) {
          days61to90 += outstanding;
        } else {
          over90 += outstanding;
        }
      }

      final balance = current + days31to60 + days61to90 + over90;
      if (balance > 0) {
        balances.add(
          CustomerBalance(
            customer: customer,
            balance: balance,
            current: current,
            days31to60: days31to60,
            days61to90: days61to90,
            over90Days: over90,
          ),
        );

        totalReceivables += balance;
        totalCurrent += current;
        total31to60 += days31to60;
        total61to90 += days61to90;
        totalOver90 += over90;
      }
    }

    // Sort by balance descending
    balances.sort((a, b) => b.balance.compareTo(a.balance));

    return ARAgingReport(
      totalReceivables: totalReceivables,
      current: totalCurrent,
      days31to60: total31to60,
      days61to90: total61to90,
      over90Days: totalOver90,
      customerBalances: balances,
    );
  }
}

/// Data class for creating invoice items
class InvoiceItemData {
  final String description;
  final double quantity;
  final int unitPrice;
  final String? productId;
  final String? revenueAccountId;

  InvoiceItemData({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.productId,
    this.revenueAccountId,
  });
}

/// Data class for payment allocation
class PaymentAllocationData {
  final String invoiceId;
  final int amount;

  PaymentAllocationData({required this.invoiceId, required this.amount});
}
