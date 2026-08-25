import 'dart:async';

import 'package:core_database/core_database.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../services/sync_queue_service.dart';
import 'ar_repository.dart';
import 'ap_repository.dart';

final cloudCrmRepositoryProvider = Provider<CloudCrmRepository>((ref) {
  return CloudCrmRepository(
    ref.watch(appDatabaseProvider),
    Supabase.instance.client,
    ref.watch(syncQueueServiceProvider),
  );
});

class CloudCrmRepository {
  CloudCrmRepository(this._db, this._supabase, this._queue);

  final AppDatabase _db;
  final SupabaseClient _supabase;
  final SyncQueueService _queue;
  String? _cachedTenantId;
  static const _uuid = Uuid();

  DateTime _date(dynamic value) => value is DateTime
      ? value.toUtc()
      : DateTime.parse(value as String).toUtc();

  int _int(dynamic value) => value is num ? value.round() : int.parse('$value');

  double _double(dynamic value) =>
      value is num ? value.toDouble() : double.parse('$value');

  bool _isRetryable(Object error) {
    if (error is TimeoutException) return true;
    final message = error.toString().toLowerCase();
    return message.contains('socket') ||
        message.contains('network') ||
        message.contains('connection') ||
        message.contains('failed host lookup') ||
        message.contains('timed out');
  }

  Future<void> syncPendingMutations({int limit = 100}) async {
    final tenantId = await currentTenantId();
    final entries = await _queue.pending(tenantId, limit: limit);
    for (final entry in entries) {
      try {
        final payload = _queue.decodePayload(entry);
        final table = _supabase.from(entry.entityTable);
        if (entry.operation == 'delete') {
          await table
              .update({
                'is_deleted': true,
                'updated_at': DateTime.now().toUtc().toIso8601String(),
              })
              .eq('id', entry.recordId)
              .eq('tenant_id', tenantId);
        } else {
          await table.upsert(payload, onConflict: 'id');
        }
        await _queue.markSucceeded(entry.id);
      } catch (error) {
        await _queue.markFailed(entry.id, error);
      }
    }
  }

  Future<String> currentTenantId() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw const AuthException('Authentication is required.');
    try {
      final membership = await _supabase
          .from('staff_members')
          .select('tenant_id')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .order('created_at')
          .limit(1)
          .maybeSingle();
      final tenantId = membership?['tenant_id'] as String?;
      if (tenantId == null || tenantId.isEmpty) {
        throw const PostgrestException(
          message: 'Tenant membership was not found.',
          code: 'MIZAN_TENANT_NOT_FOUND',
        );
      }
      _cachedTenantId = tenantId;
      return tenantId;
    } catch (error) {
      if (_cachedTenantId != null && _isRetryable(error))
        return _cachedTenantId!;
      rethrow;
    }
  }

  Customer _customerFromMap(Map<String, dynamic> row) {
    return Customer(
      id: row['id'] as String,
      createdAt: _date(row['created_at']),
      lastUpdated: _date(row['updated_at'] ?? row['created_at']),
      tenantId: row['tenant_id'] as String?,
      isDeleted: row['is_deleted'] == true,
      name: row['name'] as String,
      email: row['email'] as String?,
      phone: row['phone'] as String?,
      address: row['address'] as String?,
      taxId: row['tax_id'] as String?,
      creditLimit: _int(row['credit_limit'] ?? 0),
      balance: _int(row['balance'] ?? 0),
      receivableAccountId: null,
      notes: row['notes'] as String?,
      isOnHold: row['is_on_hold'] == true,
    );
  }

  Vendor _vendorFromMap(Map<String, dynamic> row) {
    return Vendor(
      id: row['id'] as String,
      createdAt: _date(row['created_at']),
      lastUpdated: _date(row['updated_at'] ?? row['created_at']),
      tenantId: row['tenant_id'] as String?,
      isDeleted: row['is_deleted'] == true,
      name: row['name'] as String,
      email: row['email'] as String?,
      phone: row['phone'] as String?,
      address: row['address'] as String?,
      taxId: row['tax_id'] as String?,
      balance: _int(row['balance'] ?? 0),
      payableAccountId: null,
      paymentTerms: row['payment_terms'] as String?,
      notes: row['notes'] as String?,
    );
  }

  Invoice _invoiceFromMap(Map<String, dynamic> row) {
    return Invoice(
      id: row['id'] as String,
      createdAt: _date(row['created_at']),
      lastUpdated: _date(row['updated_at'] ?? row['created_at']),
      tenantId: row['tenant_id'] as String?,
      isDeleted: false,
      invoiceNumber: row['invoice_number'] as String,
      customerId: row['customer_id'] as String,
      invoiceDate: _date(row['invoice_date']),
      dueDate: _date(row['due_date']),
      subtotal: _int(row['subtotal']),
      taxAmount: _int(row['tax_amount'] ?? 0),
      totalAmount: _int(row['total_amount']),
      amountPaid: _int(row['amount_paid'] ?? 0),
      status: row['status'] as String,
      notes: row['notes'] as String?,
      transactionId: null,
      currencyCode: row['currency_code'] as String? ?? 'USD',
      isRecurring: false,
      recurrenceInterval: null,
    );
  }

  Bill _billFromMap(Map<String, dynamic> row) {
    return Bill(
      id: row['id'] as String,
      createdAt: _date(row['created_at']),
      lastUpdated: _date(row['updated_at'] ?? row['created_at']),
      tenantId: row['tenant_id'] as String?,
      isDeleted: false,
      billNumber: row['bill_number'] as String,
      vendorId: row['vendor_id'] as String,
      vendorBillNumber: row['vendor_bill_number'] as String?,
      billDate: _date(row['bill_date']),
      dueDate: _date(row['due_date']),
      subtotal: _int(row['subtotal']),
      taxAmount: _int(row['tax_amount'] ?? 0),
      totalAmount: _int(row['total_amount']),
      amountPaid: _int(row['amount_paid'] ?? 0),
      status: row['status'] as String,
      notes: row['notes'] as String?,
      transactionId: null,
      currencyCode: row['currency_code'] as String? ?? 'USD',
    );
  }

  InvoiceItem _invoiceItemFromMap(Map<String, dynamic> row) {
    return InvoiceItem(
      id: row['id'] as String,
      createdAt: _date(row['created_at']),
      lastUpdated: _date(row['updated_at'] ?? row['created_at']),
      tenantId: row['tenant_id'] as String?,
      isDeleted: false,
      invoiceId: row['invoice_id'] as String,
      productId: row['product_id'] as String?,
      description: row['description'] as String,
      quantity: _double(row['quantity']),
      unitPrice: _int(row['unit_price']),
      amount: _int(row['amount']),
      revenueAccountId: null,
    );
  }

  BillItem _billItemFromMap(Map<String, dynamic> row) {
    return BillItem(
      id: row['id'] as String,
      createdAt: _date(row['created_at']),
      lastUpdated: _date(row['updated_at'] ?? row['created_at']),
      tenantId: row['tenant_id'] as String?,
      isDeleted: false,
      billId: row['bill_id'] as String,
      productId: row['product_id'] as String?,
      description: row['description'] as String,
      quantity: _double(row['quantity']),
      unitPrice: _int(row['unit_price']),
      amount: _int(row['amount']),
      expenseAccountId: null,
    );
  }

  Stream<List<Customer>> watchCustomers() async* {
    final tenantId = await currentTenantId();
    final remote = _supabase
        .from('customers')
        .stream(primaryKey: ['id'])
        .eq('tenant_id', tenantId)
        .eq('is_deleted', false)
        .order('name');
    try {
      await for (final rows in remote) {
        final customers = rows
            .map((row) => _customerFromMap(Map<String, dynamic>.from(row)))
            .toList(growable: false);
        await _cacheCustomers(customers);
        yield customers;
      }
    } catch (_) {
      yield await (_db.select(_db.customers)
            ..where((table) => table.tenantId.equals(tenantId))
            ..where((table) => table.isDeleted.equals(false))
            ..orderBy([(table) => drift.OrderingTerm.asc(table.name)]))
          .get();
    }
  }

  Future<void> _cacheCustomers(List<Customer> customers) async {
    await _db.transaction(() async {
      for (final customer in customers) {
        await _db.into(_db.customers).insertOnConflictUpdate(customer);
      }
    });
  }

  Future<Customer> createCustomer({
    required String name,
    String? email,
    String? phone,
    String? address,
    String? taxId,
    int creditLimit = 0,
    String? notes,
    bool isOnHold = false,
  }) async {
    final tenantId = await currentTenantId();
    final userId = _supabase.auth.currentUser!.id;
    final id = _uuid.v4();
    final now = DateTime.now().toUtc().toIso8601String();
    final row = <String, dynamic>{
      'id': id,
      'tenant_id': tenantId,
      'name': name.trim(),
      'email': email?.trim().isEmpty == true
          ? null
          : email?.trim().toLowerCase(),
      'phone': phone?.trim().isEmpty == true ? null : phone?.trim(),
      'address': address?.trim().isEmpty == true ? null : address?.trim(),
      'tax_id': taxId?.trim().isEmpty == true ? null : taxId?.trim(),
      'credit_limit': creditLimit,
      'notes': notes,
      'is_on_hold': isOnHold,
      'created_by': userId,
      'created_at': now,
      'updated_at': now,
    };
    try {
      final response = await _supabase
          .from('customers')
          .insert(row)
          .select()
          .single();
      final customer = _customerFromMap(Map<String, dynamic>.from(response));
      await _db.into(_db.customers).insertOnConflictUpdate(customer);
      return customer;
    } catch (error) {
      if (!_isRetryable(error)) rethrow;
      final customer = _customerFromMap(row);
      await _db.into(_db.customers).insertOnConflictUpdate(customer);
      await _queue.enqueue(
        tenantId: tenantId,
        tableName: 'customers',
        recordId: id,
        operation: 'insert',
        payload: row,
      );
      return customer;
    }
  }

  Future<void> updateCustomer(String id, Map<String, dynamic> values) async {
    final tenantId = await currentTenantId();
    final now = DateTime.now().toUtc();
    final updatedValues = {...values, 'updated_at': now.toIso8601String()};
    try {
      final response = await _supabase
          .from('customers')
          .update(updatedValues)
          .eq('id', id)
          .eq('tenant_id', tenantId)
          .select()
          .single();
      await _db
          .into(_db.customers)
          .insertOnConflictUpdate(
            _customerFromMap(Map<String, dynamic>.from(response)),
          );
    } catch (error) {
      if (!_isRetryable(error)) rethrow;
      final local =
          await (_db.select(_db.customers)
                ..where((row) => row.id.equals(id))
                ..where((row) => row.tenantId.equals(tenantId)))
              .getSingleOrNull();
      if (local == null) rethrow;
      await (_db.update(
        _db.customers,
      )..where((row) => row.id.equals(id))).write(
        CustomersCompanion(
          name: values.containsKey('name')
              ? Value(values['name'] as String)
              : const Value.absent(),
          email: values.containsKey('email')
              ? Value(values['email'] as String?)
              : const Value.absent(),
          phone: values.containsKey('phone')
              ? Value(values['phone'] as String?)
              : const Value.absent(),
          address: values.containsKey('address')
              ? Value(values['address'] as String?)
              : const Value.absent(),
          taxId: values.containsKey('tax_id')
              ? Value(values['tax_id'] as String?)
              : const Value.absent(),
          creditLimit: values.containsKey('credit_limit')
              ? Value(values['credit_limit'] as int)
              : const Value.absent(),
          notes: values.containsKey('notes')
              ? Value(values['notes'] as String?)
              : const Value.absent(),
          lastUpdated: Value(now),
        ),
      );
      await _queue.enqueue(
        tenantId: tenantId,
        tableName: 'customers',
        recordId: id,
        operation: 'update',
        payload: {'id': id, 'tenant_id': tenantId, ...updatedValues},
      );
    }
  }

  Future<Customer?> getCustomer(String id) async {
    final tenantId = await currentTenantId();
    final response = await _supabase
        .from('customers')
        .select()
        .eq('id', id)
        .eq('tenant_id', tenantId)
        .maybeSingle();
    if (response == null) return null;
    final customer = _customerFromMap(Map<String, dynamic>.from(response));
    await _db.into(_db.customers).insertOnConflictUpdate(customer);
    return customer;
  }

  Stream<List<Invoice>> watchCustomerInvoices(String customerId) async* {
    final tenantId = await currentTenantId();
    final remote = _supabase
        .from('invoices')
        .stream(primaryKey: ['id'])
        .eq('tenant_id', tenantId)
        .eq('customer_id', customerId)
        .order('invoice_date', ascending: false);
    try {
      await for (final rows in remote) {
        final invoices = rows
            .map((row) => _invoiceFromMap(Map<String, dynamic>.from(row)))
            .toList(growable: false);
        await _cacheInvoices(invoices);
        yield invoices;
      }
    } catch (_) {
      yield await (_db.select(_db.invoices)
            ..where((table) => table.tenantId.equals(tenantId))
            ..where((table) => table.customerId.equals(customerId))
            ..orderBy([(table) => drift.OrderingTerm.desc(table.invoiceDate)]))
          .get();
    }
  }

  Future<void> _cacheInvoices(List<Invoice> invoices) async {
    await _db.transaction(() async {
      for (final invoice in invoices) {
        await _db.into(_db.invoices).insertOnConflictUpdate(invoice);
      }
    });
  }

  Stream<List<Invoice>> watchAllInvoices() async* {
    final tenantId = await currentTenantId();
    final remote = _supabase
        .from('invoices')
        .stream(primaryKey: ['id'])
        .eq('tenant_id', tenantId)
        .order('invoice_date', ascending: false);
    try {
      await for (final rows in remote) {
        final invoices = rows
            .map((row) => _invoiceFromMap(Map<String, dynamic>.from(row)))
            .toList(growable: false);
        await _cacheInvoices(invoices);
        yield invoices;
      }
    } catch (error) {
      if (!_isRetryable(error)) rethrow;
      yield await (_db.select(_db.invoices)
            ..where((table) => table.tenantId.equals(tenantId))
            ..where((table) => table.isDeleted.equals(false))
            ..orderBy([(table) => drift.OrderingTerm.desc(table.invoiceDate)]))
          .get();
    }
  }

  Future<InvoiceWithItems?> getInvoiceWithItems(String invoiceId) async {
    final tenantId = await currentTenantId();
    final response = await _supabase
        .from('invoices')
        .select('*,invoice_items(*)')
        .eq('id', invoiceId)
        .eq('tenant_id', tenantId)
        .maybeSingle();
    if (response == null) return null;
    final row = Map<String, dynamic>.from(response);
    final invoice = _invoiceFromMap(row);
    final customer = await getCustomer(invoice.customerId);
    if (customer == null) return null;
    final itemRows = (row['invoice_items'] as List? ?? const [])
        .map(
          (item) => _invoiceItemFromMap(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
    await _db.into(_db.invoices).insertOnConflictUpdate(invoice);
    return InvoiceWithItems(
      invoice: invoice,
      customer: customer,
      items: itemRows,
    );
  }

  Future<Invoice> createInvoice({
    required String customerId,
    required DateTime invoiceDate,
    required DateTime dueDate,
    required List<InvoiceItemData> items,
    required String currencyCode,
    String? notes,
  }) async {
    if (items.isEmpty) {
      throw const PostgrestException(
        message: 'At least one invoice item is required.',
        code: 'MIZAN_EMPTY_DOCUMENT',
      );
    }
    final result = await _supabase.rpc(
      'create_invoice',
      params: {
        'p_customer_id': customerId,
        'p_invoice_date': invoiceDate
            .toUtc()
            .toIso8601String()
            .split('T')
            .first,
        'p_due_date': dueDate.toUtc().toIso8601String().split('T').first,
        'p_currency_code': currencyCode.toUpperCase(),
        'p_notes': notes,
        'p_items': items
            .map(
              (item) => {
                'description': item.description.trim(),
                'quantity': item.quantity,
                'unit_price': item.unitPrice,
                'product_id': item.productId,
              },
            )
            .toList(growable: false),
      },
    );
    if (result is! Map || result['invoice'] is! Map) {
      throw const PostgrestException(
        message: 'Invoice creation returned no committed document.',
        code: 'MIZAN_DOCUMENT_INVALID_RESPONSE',
      );
    }
    final invoice = _invoiceFromMap(
      Map<String, dynamic>.from(result['invoice'] as Map),
    );
    final itemRows = (result['items'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
    final customer = await getCustomer(customerId);
    if (customer == null) return invoice;
    await _db.transaction(() async {
      await _db.into(_db.invoices).insertOnConflictUpdate(invoice);
      for (final item in itemRows) {
        await _db
            .into(_db.invoiceItems)
            .insertOnConflictUpdate(_invoiceItemFromMap(item));
      }
    });
    return invoice;
  }

  Stream<List<Bill>> watchVendorBills(String vendorId) async* {
    final tenantId = await currentTenantId();
    final remote = _supabase
        .from('bills')
        .stream(primaryKey: ['id'])
        .eq('tenant_id', tenantId)
        .eq('vendor_id', vendorId)
        .order('bill_date', ascending: false);
    try {
      await for (final rows in remote) {
        final bills = rows
            .map((row) => _billFromMap(Map<String, dynamic>.from(row)))
            .toList(growable: false);
        await _cacheBills(bills);
        yield bills;
      }
    } catch (_) {
      yield await (_db.select(_db.bills)
            ..where((table) => table.tenantId.equals(tenantId))
            ..where((table) => table.vendorId.equals(vendorId))
            ..orderBy([(table) => drift.OrderingTerm.desc(table.billDate)]))
          .get();
    }
  }

  Stream<List<Vendor>> watchVendors() async* {
    final tenantId = await currentTenantId();
    final remote = _supabase
        .from('vendors')
        .stream(primaryKey: ['id'])
        .eq('tenant_id', tenantId)
        .eq('is_deleted', false)
        .order('name');
    try {
      await for (final rows in remote) {
        final vendors = rows
            .map((row) => _vendorFromMap(Map<String, dynamic>.from(row)))
            .toList(growable: false);
        await _cacheVendors(vendors);
        yield vendors;
      }
    } catch (_) {
      yield await (_db.select(_db.vendors)
            ..where((table) => table.tenantId.equals(tenantId))
            ..where((table) => table.isDeleted.equals(false))
            ..orderBy([(table) => drift.OrderingTerm.asc(table.name)]))
          .get();
    }
  }

  Future<void> _cacheVendors(List<Vendor> vendors) async {
    await _db.transaction(() async {
      for (final vendor in vendors) {
        await _db.into(_db.vendors).insertOnConflictUpdate(vendor);
      }
    });
  }

  Future<void> _cacheBills(List<Bill> bills) async {
    await _db.transaction(() async {
      for (final bill in bills) {
        await _db.into(_db.bills).insertOnConflictUpdate(bill);
      }
    });
  }

  Stream<List<Bill>> watchAllBills() async* {
    final tenantId = await currentTenantId();
    final remote = _supabase
        .from('bills')
        .stream(primaryKey: ['id'])
        .eq('tenant_id', tenantId)
        .order('bill_date', ascending: false);
    try {
      await for (final rows in remote) {
        final bills = rows
            .map((row) => _billFromMap(Map<String, dynamic>.from(row)))
            .toList(growable: false);
        await _cacheBills(bills);
        yield bills;
      }
    } catch (error) {
      if (!_isRetryable(error)) rethrow;
      yield await (_db.select(_db.bills)
            ..where((table) => table.tenantId.equals(tenantId))
            ..where((table) => table.isDeleted.equals(false))
            ..orderBy([(table) => drift.OrderingTerm.desc(table.billDate)]))
          .get();
    }
  }

  Future<Vendor> createVendor({
    required String name,
    String? email,
    String? phone,
    String? address,
    String? taxId,
    String? paymentTerms,
    String? notes,
  }) async {
    final tenantId = await currentTenantId();
    final row = await _supabase
        .from('vendors')
        .insert({
          'id': _uuid.v4(),
          'tenant_id': tenantId,
          'name': name.trim(),
          'email': email?.trim().isEmpty == true
              ? null
              : email?.trim().toLowerCase(),
          'phone': phone?.trim().isEmpty == true ? null : phone?.trim(),
          'address': address?.trim().isEmpty == true ? null : address?.trim(),
          'tax_id': taxId?.trim().isEmpty == true ? null : taxId?.trim(),
          'payment_terms': paymentTerms,
          'notes': notes,
          'created_by': _supabase.auth.currentUser!.id,
        })
        .select()
        .single();
    final vendor = _vendorFromMap(Map<String, dynamic>.from(row));
    await _db.into(_db.vendors).insertOnConflictUpdate(vendor);
    return vendor;
  }

  Future<void> updateVendor(String id, Map<String, dynamic> values) async {
    final tenantId = await currentTenantId();
    final row = await _supabase
        .from('vendors')
        .update({
          ...values,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .eq('tenant_id', tenantId)
        .select()
        .single();
    await _db
        .into(_db.vendors)
        .insertOnConflictUpdate(_vendorFromMap(Map<String, dynamic>.from(row)));
  }

  Future<Vendor?> getVendor(String id) async {
    final tenantId = await currentTenantId();
    final row = await _supabase
        .from('vendors')
        .select()
        .eq('id', id)
        .eq('tenant_id', tenantId)
        .maybeSingle();
    if (row == null) return null;
    final vendor = _vendorFromMap(Map<String, dynamic>.from(row));
    await _db.into(_db.vendors).insertOnConflictUpdate(vendor);
    return vendor;
  }

  Future<Bill> createBill({
    required String vendorId,
    required DateTime billDate,
    required DateTime dueDate,
    required List<BillItemData> items,
    required String currencyCode,
    String? vendorBillNumber,
    String? notes,
  }) async {
    if (items.isEmpty) {
      throw const PostgrestException(
        message: 'At least one bill item is required.',
        code: 'MIZAN_EMPTY_DOCUMENT',
      );
    }
    final result = await _supabase.rpc(
      'create_bill',
      params: {
        'p_vendor_id': vendorId,
        'p_bill_date': billDate.toUtc().toIso8601String().split('T').first,
        'p_due_date': dueDate.toUtc().toIso8601String().split('T').first,
        'p_currency_code': currencyCode.toUpperCase(),
        'p_vendor_bill_number': vendorBillNumber,
        'p_notes': notes,
        'p_items': items
            .map(
              (item) => {
                'description': item.description.trim(),
                'quantity': item.quantity,
                'unit_price': item.unitPrice,
                'product_id': item.productId,
              },
            )
            .toList(growable: false),
      },
    );
    if (result is! Map || result['bill'] is! Map) {
      throw const PostgrestException(
        message: 'Bill creation returned no committed document.',
        code: 'MIZAN_DOCUMENT_INVALID_RESPONSE',
      );
    }
    final bill = _billFromMap(Map<String, dynamic>.from(result['bill'] as Map));
    final itemRows = (result['items'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
    await _db.transaction(() async {
      await _db.into(_db.bills).insertOnConflictUpdate(bill);
      for (final item in itemRows) {
        await _db
            .into(_db.billItems)
            .insertOnConflictUpdate(_billItemFromMap(item));
      }
    });
    return bill;
  }
}
