import 'package:core_database/core_database.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();
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
    bool isOnHold = false,
    int openingBalance = 0,
  }) async {
    return await _db.transaction(() async {
      // Pre-generate UUID so we can use it as both the PK and in FK references
      final customerUuid = _uuid.v4();

      final companion = CustomersCompanion.insert(
        id: Value(customerUuid),
        name: name,
        email: Value(email),
        phone: Value(phone),
        address: Value(address),
        taxId: Value(taxId),
        creditLimit: Value(creditLimit),
        receivableAccountId: Value(receivableAccountId),
        notes: Value(notes),
        isOnHold: Value(isOnHold),
        balance: Value(openingBalance),
      );

      await _db.into(_db.customers).insert(companion);

      if (openingBalance != 0) {
        final accountsList = await _db.select(_db.accounts).get();
        final arAccount = accountsList.firstWhereOrNull(
            (a) => a.name == 'Accounts Receivable' || a.name.contains('Receivable'))
            ?? accountsList.firstWhereOrNull((a) => a.type == 'asset');
        final equityAccount = accountsList.firstWhereOrNull(
            (a) => a.name == 'Equity' || a.name.contains('Equity'))
            ?? accountsList.firstWhereOrNull((a) => a.type == 'equity');

        if (arAccount == null || equityAccount == null) {
          throw Exception('Required system accounts (Accounts Receivable or Equity) are missing from the database.');
        }

        // Pre-generate transaction UUID for FK references
        final txnUuid = _uuid.v4();
        final txnCompanion = TransactionsCompanion.insert(
          id: Value(txnUuid),
          transactionDate: DateTime.now(),
          description: 'Opening Balance for $name',
        );
        await _db.into(_db.transactions).insert(txnCompanion);

        await _db.into(_db.transactionEntries).insert(TransactionEntriesCompanion.insert(
          transactionId: txnUuid, // ✅ UUID string, not int rowid
          accountId: arAccount.id,
          amount: openingBalance,
        ));

        await _db.into(_db.transactionEntries).insert(TransactionEntriesCompanion.insert(
          transactionId: txnUuid, // ✅ UUID string, not int rowid
          accountId: equityAccount.id,
          amount: -openingBalance,
        ));
      }

      // Use the pre-generated UUID — no need to re-query by rowid
      return (await (_db.select(_db.customers)..where((t) => t.id.equals(customerUuid))).getSingle());
    });
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

  /// Record Quick Ledger Adjustment
  Future<void> recordQuickAdjustment({
    required String customerId,
    required int amount,
    required bool isCharge,
    String? notes,
  }) async {
    await _db.transaction(() async {
      final customer = await getCustomer(customerId);
      if (customer == null) return;

      final accountsList = await _db.select(_db.accounts).get();
      final arAccount = accountsList.firstWhereOrNull(
          (a) => a.name == 'Accounts Receivable' || a.name.contains('Receivable'))
          ?? accountsList.firstWhereOrNull((a) => a.type == 'asset');
      final cashAccount = accountsList.firstWhereOrNull(
          (a) => a.name == 'Cash' || a.name.contains('Cash'))
          ?? accountsList.firstWhereOrNull((a) => a.type == 'asset');

      if (arAccount == null || cashAccount == null) {
        throw Exception('Required system accounts (Accounts Receivable or Cash) are missing from the database.');
      }

      // Pre-generate transaction UUID for FK references
      final txnUuid = _uuid.v4();
      final txnCompanion = TransactionsCompanion.insert(
        id: Value(txnUuid),
        transactionDate: DateTime.now(),
        description: notes ?? (isCharge ? 'Quick Charge for ${customer.name}' : 'Payment Received from ${customer.name}'),
      );
      await _db.into(_db.transactions).insert(txnCompanion);

      if (isCharge) {
        // Customer owes us more: Debit AR (positive), Credit Cash (negative)
        await _db.into(_db.transactionEntries).insert(TransactionEntriesCompanion.insert(
          transactionId: txnUuid, // ✅ UUID string, not int rowid
          accountId: arAccount.id,
          amount: amount,
        ));
        await _db.into(_db.transactionEntries).insert(TransactionEntriesCompanion.insert(
          transactionId: txnUuid, // ✅ UUID string, not int rowid
          accountId: cashAccount.id,
          amount: -amount,
        ));
      } else {
        // Customer pays us: Debit Cash (positive), Credit AR (negative)
        await _db.into(_db.transactionEntries).insert(TransactionEntriesCompanion.insert(
          transactionId: txnUuid, // ✅ UUID string, not int rowid
          accountId: cashAccount.id,
          amount: amount,
        ));
        await _db.into(_db.transactionEntries).insert(TransactionEntriesCompanion.insert(
          transactionId: txnUuid, // ✅ UUID string, not int rowid
          accountId: arAccount.id,
          amount: -amount,
        ));
      }

      final newBalance = customer.balance + (isCharge ? amount : -amount);
      await (_db.update(_db.customers)..where((t) => t.id.equals(customerId)))
          .write(CustomersCompanion(balance: Value(newBalance)));
    });
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
    final now = DateTime.now();
    final yearStr = now.year.toString();
    final monthStr = now.month.toString().padLeft(2, '0');
    final prefix = 'INV-$yearStr-$monthStr-';

    final result = await _db.customSelect(
      '''
      SELECT invoice_number 
      FROM invoices 
      WHERE invoice_number LIKE ? 
      ORDER BY invoice_number DESC 
      LIMIT 1
      ''',
      variables: [Variable<String>('$prefix%')],
    ).getSingleOrNull();

    int nextNum = 1;
    if (result != null) {
      final lastNumber = result.read<String>('invoice_number');
      final parts = lastNumber.split('-');
      if (parts.length >= 4) {
        final lastSeq = int.tryParse(parts[3]) ?? 0;
        nextNum = lastSeq + 1;
      }
    }

    return '$prefix${nextNum.toString().padLeft(4, '0')}';
  }

  /// Create a new invoice
  Future<Invoice> createInvoice({
    required String customerId,
    required DateTime invoiceDate,
    required DateTime dueDate,
    required List<InvoiceItemData> items,
    required String currencyCode,
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
        currencyCode: Value(currencyCode),
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
