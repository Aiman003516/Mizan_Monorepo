import 'dart:async';

import 'package:core_database/core_database.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/balance_adjustment.dart';
import '../services/sync_queue_service.dart';
import '../tenant_context.dart';
import 'ar_repository.dart';
import 'ap_repository.dart';

final cloudCrmRepositoryProvider = Provider<CloudCrmRepository>((ref) {
  return CloudCrmRepository(
    ref.watch(appDatabaseProvider),
    Supabase.instance.client,
    ref.watch(syncQueueServiceProvider),
    ref.watch(tenantContextProvider),
  );
});

class CloudCrmRepository {
  CloudCrmRepository(
    this._db,
    this._supabase,
    this._queue,
    this._tenantContext,
  );

  final AppDatabase _db;
  final SupabaseClient _supabase;
  final SyncQueueService _queue;
  final TenantContext _tenantContext;
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
          final deleted = await table
              .update({
                'is_deleted': true,
                'updated_at': DateTime.now().toUtc().toIso8601String(),
              })
              .eq('id', entry.recordId)
              .eq('tenant_id', tenantId)
              .select('id')
              .maybeSingle();
          if (deleted == null) {
            throw StateError(
              'Queued delete affected no ${entry.entityTable} row.',
            );
          }
        } else if (entry.operation == 'update') {
          final updatePayload = Map<String, dynamic>.from(payload)
            ..remove('id')
            ..remove('tenant_id');
          final updated = await table
              .update(updatePayload)
              .eq('id', entry.recordId)
              .eq('tenant_id', tenantId)
              .select('id')
              .maybeSingle();
          if (updated == null) {
            throw StateError(
              'Queued update affected no ${entry.entityTable} row.',
            );
          }
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
    try {
      final tenantId = await _tenantContext.currentTenantId();
      _cachedTenantId = tenantId;
      return tenantId;
    } catch (error) {
      if (_cachedTenantId != null && _isRetryable(error)) {
        return _cachedTenantId!;
      }
      rethrow;
    }
  }

  Future<void> postBalanceAdjustment(BalanceAdjustmentInput input) async {
    final tenantId = await currentTenantId();
    if (input.partyId.isEmpty || input.amountMinor <= 0) {
      throw ArgumentError('A valid party and positive adjustment are required');
    }
    if (input.reason.trim().length < 3) {
      throw ArgumentError('A reason of at least three characters is required');
    }
    if (input.currencyCode != input.currencyCode.toUpperCase()) {
      throw ArgumentError('The adjustment currency must be uppercase');
    }
    final idempotencyKey =
        'manual-adjustment:${input.partyType.wireName}:${input.partyId}:${input.effectiveDate.toIso8601String()}:${input.amountMinor}:${input.direction.wireName}:${input.reference ?? ''}';
    final response = await _supabase.rpc(
      'post_manual_balance_adjustment',
      params: {
        'p_party_type': input.partyType.wireName,
        'p_party_id': input.partyId,
        'p_amount_minor': input.amountMinor,
        'p_direction': input.direction.wireName,
        'p_currency_code': input.currencyCode,
        'p_reason': input.reason.trim(),
        'p_reference': input.reference,
        'p_effective_date': input.effectiveDate
            .toIso8601String()
            .split('T')
            .first,
        'p_debit_account_id': input.debitAccountId,
        'p_credit_account_id': input.creditAccountId,
        'p_idempotency_key': idempotencyKey,
      },
    );
    if (response is! Map) {
      throw const PostgrestException(
        message: 'The balance adjustment was not committed.',
        code: 'MIZAN_BALANCE_ADJUSTMENT_INVALID_RESPONSE',
      );
    }
    final row = Map<String, dynamic>.from(response);
    final adjustmentId = row['adjustment_id']?.toString();
    final journalEntryId = row['journal_entry_id']?.toString();
    final newBalance = _int(row['new_balance']);
    if (adjustmentId == null || journalEntryId == null) {
      throw const PostgrestException(
        message: 'The balance adjustment response is incomplete.',
        code: 'MIZAN_BALANCE_ADJUSTMENT_INCOMPLETE_RESPONSE',
      );
    }
    final effectiveDate = _date(row['effective_date']);
    await _db.transaction(() async {
      if (input.partyType == BalancePartyType.customer) {
        final local =
            await (_db.select(_db.customers)
                  ..where((item) => item.id.equals(input.partyId))
                  ..where((item) => item.tenantId.equals(tenantId)))
                .getSingleOrNull();
        if (local != null) {
          await (_db.update(_db.customers)
                ..where((item) => item.id.equals(input.partyId))
                ..where((item) => item.tenantId.equals(tenantId)))
              .write(
                CustomersCompanion(
                  balance: Value(newBalance),
                  lastUpdated: Value(DateTime.now().toUtc()),
                ),
              );
        }
      } else {
        final local =
            await (_db.select(_db.vendors)
                  ..where((item) => item.id.equals(input.partyId))
                  ..where((item) => item.tenantId.equals(tenantId)))
                .getSingleOrNull();
        if (local != null) {
          await (_db.update(_db.vendors)
                ..where((item) => item.id.equals(input.partyId))
                ..where((item) => item.tenantId.equals(tenantId)))
              .write(
                VendorsCompanion(
                  balance: Value(newBalance),
                  lastUpdated: Value(DateTime.now().toUtc()),
                ),
              );
        }
      }
      await _db
          .into(_db.balanceAdjustments)
          .insertOnConflictUpdate(
            BalanceAdjustmentsCompanion.insert(
              id: Value(adjustmentId),
              partyType: input.partyType.wireName,
              partyId: input.partyId,
              amount: _int(row['amount_minor']),
              direction:
                  row['direction']?.toString() ?? input.direction.wireName,
              currencyCode: Value(
                row['currency_code']?.toString() ?? input.currencyCode,
              ),
              reason: row['reason']?.toString() ?? input.reason.trim(),
              reference: Value(row['reference']?.toString()),
              transactionId: Value(journalEntryId),
              status: Value(row['status']?.toString() ?? 'posted'),
              effectiveDate: effectiveDate,
            ),
          );
    });
  }

  BalanceAdjustment _balanceAdjustmentFromMap(Map<String, dynamic> row) {
    return BalanceAdjustment(
      id: row['id'] as String,
      createdAt: _date(row['created_at']),
      lastUpdated: _date(row['updated_at'] ?? row['created_at']),
      tenantId: row['tenant_id'] as String?,
      isDeleted: row['is_deleted'] == true,
      partyType: row['party_type'] as String,
      partyId: row['party_id'] as String,
      amount: _int(row['amount_minor']),
      direction: row['direction'] as String,
      currencyCode: row['currency_code'] as String,
      reason: row['reason'] as String,
      reference: row['reference'] as String?,
      transactionId: row['journal_entry_id'] as String?,
      status: row['status'] as String,
      effectiveDate: _date(row['effective_date']),
      createdByUserId: row['created_by'] as String?,
    );
  }

  Stream<List<BalanceAdjustment>> watchBalanceAdjustments({
    required String partyType,
    required String partyId,
  }) async* {
    final tenantId = await currentTenantId();
    final remote = _supabase
        .from('balance_adjustments')
        .stream(primaryKey: ['id'])
        .eq('tenant_id', tenantId)
        .eq('party_type', partyType)
        .eq('party_id', partyId)
        .order('effective_date', ascending: false);
    try {
      await for (final rows in remote) {
        final adjustments = rows
            .map(
              (row) =>
                  _balanceAdjustmentFromMap(Map<String, dynamic>.from(row)),
            )
            .toList(growable: false);
        await _db.transaction(() async {
          for (final adjustment in adjustments) {
            await _db
                .into(_db.balanceAdjustments)
                .insertOnConflictUpdate(adjustment);
          }
        });
        yield adjustments;
      }
    } catch (_) {
      yield* (_db.select(_db.balanceAdjustments)
            ..where((row) => row.tenantId.equals(tenantId))
            ..where((row) => row.partyType.equals(partyType))
            ..where((row) => row.partyId.equals(partyId))
            ..where((row) => row.isDeleted.equals(false))
            ..orderBy([(row) => drift.OrderingTerm.desc(row.effectiveDate)]))
          .watch();
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
      // Keep the UI reactive while the remote stream is unavailable. A one-shot
      // query would leave the screen stale after a local write or retry.
      yield* (_db.select(_db.customers)
            ..where((table) => table.tenantId.equals(tenantId))
            ..where((table) => table.isDeleted.equals(false))
            ..orderBy([(table) => drift.OrderingTerm.asc(table.name)]))
          .watch();
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
    final local =
        await (_db.select(_db.customers)
              ..where((row) => row.id.equals(id))
              ..where((row) => row.tenantId.equals(tenantId)))
            .getSingleOrNull();
    if (local == null) {
      throw StateError('Customer is not available in the current tenant.');
    }
    final now = DateTime.now().toUtc();
    final payload = Map<String, dynamic>.from(values);
    try {
      final response = await _supabase.rpc(
        'update_customer',
        params: {
          'p_customer_id': id,
          'p_expected_updated_at': local.lastUpdated.toUtc().toIso8601String(),
          'p_patch': payload,
        },
      );
      if (response is! Map) {
        throw const PostgrestException(
          message: 'Customer update returned no committed record.',
          code: 'MIZAN_INVALID_UPDATE_RESPONSE',
        );
      }
      await _db
          .into(_db.customers)
          .insertOnConflictUpdate(
            _customerFromMap(Map<String, dynamic>.from(response)),
          );
    } catch (error) {
      if (!_isRetryable(error)) rethrow;
      final updatedLocal = local.copyWith(
        name: values.containsKey('name')
            ? values['name'] as String
            : local.name,
        email: Value(
          values.containsKey('email')
              ? values['email'] as String?
              : local.email,
        ),
        phone: Value(
          values.containsKey('phone')
              ? values['phone'] as String?
              : local.phone,
        ),
        address: Value(
          values.containsKey('address')
              ? values['address'] as String?
              : local.address,
        ),
        taxId: Value(
          values.containsKey('tax_id')
              ? values['tax_id'] as String?
              : local.taxId,
        ),
        creditLimit: values.containsKey('credit_limit')
            ? values['credit_limit'] as int
            : local.creditLimit,
        notes: Value(
          values.containsKey('notes')
              ? values['notes'] as String?
              : local.notes,
        ),
        lastUpdated: now,
      );
      await _db.into(_db.customers).insertOnConflictUpdate(updatedLocal);
      await _queue.enqueue(
        tenantId: tenantId,
        tableName: 'customers',
        recordId: id,
        operation: 'update',
        payload: {'id': id, 'tenant_id': tenantId, ...payload},
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
      yield* (_db.select(_db.invoices)
            ..where((table) => table.tenantId.equals(tenantId))
            ..where((table) => table.customerId.equals(customerId))
            ..where((table) => table.isDeleted.equals(false))
            ..orderBy([(table) => drift.OrderingTerm.desc(table.invoiceDate)]))
          .watch();
    }
  }

  Future<Invoice> _createOfflineInvoice({
    required String tenantId,
    required String customerId,
    required DateTime invoiceDate,
    required DateTime dueDate,
    required List<InvoiceItemData> items,
    required String currencyCode,
    String? notes,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().toUtc();
    final subtotal = items.fold<int>(
      0,
      (sum, item) => sum + (item.quantity * item.unitPrice).round(),
    );
    final header = <String, dynamic>{
      'id': id,
      'tenant_id': tenantId,
      'customer_id': customerId,
      'invoice_number':
          'OFFLINE-${now.millisecondsSinceEpoch}-${id.substring(0, 6)}',
      'invoice_date': invoiceDate.toUtc().toIso8601String(),
      'due_date': dueDate.toUtc().toIso8601String(),
      'subtotal': subtotal,
      'tax_amount': 0,
      'total_amount': subtotal,
      'amount_paid': 0,
      'status': 'draft',
      'currency_code': currencyCode.toUpperCase(),
      'notes': notes,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };
    final invoice = _invoiceFromMap(header);
    final itemRows = items
        .map((item) {
          final itemId = _uuid.v4();
          final itemTimestamp = DateTime.now().toUtc().toIso8601String();
          return <String, dynamic>{
            'id': itemId,
            'tenant_id': tenantId,
            'invoice_id': id,
            'description': item.description.trim(),
            'quantity': item.quantity,
            'unit_price': item.unitPrice,
            'amount': (item.quantity * item.unitPrice).round(),
            'product_id': item.productId,
            'created_at': itemTimestamp,
            'updated_at': itemTimestamp,
          };
        })
        .toList(growable: false);
    await _db.transaction(() async {
      await _db.into(_db.invoices).insertOnConflictUpdate(invoice);
      for (final row in itemRows) {
        await _db
            .into(_db.invoiceItems)
            .insertOnConflictUpdate(_invoiceItemFromMap(row));
      }
    });
    await _queue.enqueue(
      tenantId: tenantId,
      tableName: 'invoices',
      recordId: id,
      operation: 'insert',
      payload: header,
    );
    for (final row in itemRows) {
      await _queue.enqueue(
        tenantId: tenantId,
        tableName: 'invoice_items',
        recordId: row['id'] as String,
        operation: 'insert',
        payload: row,
      );
    }
    return invoice;
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

  Future<void> updateInvoiceStatus(String invoiceId, String status) async {
    final tenantId = await currentTenantId();
    final now = DateTime.now().toUtc();
    final payload = <String, dynamic>{
      'status': status,
      'updated_at': now.toIso8601String(),
    };
    try {
      final row = await _supabase
          .from('invoices')
          .update(payload)
          .eq('id', invoiceId)
          .eq('tenant_id', tenantId)
          .select()
          .single();
      await _db
          .into(_db.invoices)
          .insertOnConflictUpdate(
            _invoiceFromMap(Map<String, dynamic>.from(row)),
          );
    } catch (error) {
      if (!_isRetryable(error)) rethrow;
      final local =
          await (_db.select(_db.invoices)
                ..where((row) => row.id.equals(invoiceId))
                ..where((row) => row.tenantId.equals(tenantId)))
              .getSingleOrNull();
      if (local == null) rethrow;
      await (_db.update(_db.invoices)
            ..where((row) => row.id.equals(invoiceId))
            ..where((row) => row.tenantId.equals(tenantId)))
          .write(
            InvoicesCompanion(status: Value(status), lastUpdated: Value(now)),
          );
      await _queue.enqueue(
        tenantId: tenantId,
        tableName: 'invoices',
        recordId: invoiceId,
        operation: 'update',
        payload: {'id': invoiceId, 'tenant_id': tenantId, ...payload},
      );
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
    final tenantId = await currentTenantId();
    try {
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
    } catch (error) {
      if (!_isRetryable(error)) rethrow;
      return _createOfflineInvoice(
        tenantId: tenantId,
        customerId: customerId,
        invoiceDate: invoiceDate,
        dueDate: dueDate,
        items: items,
        currencyCode: currencyCode,
        notes: notes,
      );
    }
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
      yield* (_db.select(_db.bills)
            ..where((table) => table.tenantId.equals(tenantId))
            ..where((table) => table.vendorId.equals(vendorId))
            ..where((table) => table.isDeleted.equals(false))
            ..orderBy([(table) => drift.OrderingTerm.desc(table.billDate)]))
          .watch();
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
      yield* (_db.select(_db.vendors)
            ..where((table) => table.tenantId.equals(tenantId))
            ..where((table) => table.isDeleted.equals(false))
            ..orderBy([(table) => drift.OrderingTerm.asc(table.name)]))
          .watch();
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

  Future<Vendor> _createOfflineVendor({
    required String tenantId,
    required String name,
    String? email,
    String? phone,
    String? address,
    String? taxId,
    String? paymentTerms,
    String? notes,
  }) async {
    final id = _uuid.v4();
    final timestamp = DateTime.now().toUtc().toIso8601String();
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
      'payment_terms': paymentTerms,
      'notes': notes,
      'balance': 0,
      'is_deleted': false,
      'created_at': timestamp,
      'updated_at': timestamp,
      'created_by': _supabase.auth.currentUser!.id,
    };
    final vendor = _vendorFromMap(row);
    await _db.into(_db.vendors).insertOnConflictUpdate(vendor);
    await _queue.enqueue(
      tenantId: tenantId,
      tableName: 'vendors',
      recordId: id,
      operation: 'insert',
      payload: row,
    );
    return vendor;
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
    try {
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
    } catch (error) {
      if (!_isRetryable(error)) rethrow;
      return _createOfflineVendor(
        tenantId: tenantId,
        name: name,
        email: email,
        phone: phone,
        address: address,
        taxId: taxId,
        paymentTerms: paymentTerms,
        notes: notes,
      );
    }
  }

  Future<void> updateVendor(String id, Map<String, dynamic> values) async {
    final tenantId = await currentTenantId();
    final local =
        await (_db.select(_db.vendors)
              ..where((row) => row.id.equals(id))
              ..where((row) => row.tenantId.equals(tenantId)))
            .getSingleOrNull();
    if (local == null) {
      throw StateError('Vendor is not available in the current tenant.');
    }
    final now = DateTime.now().toUtc();
    final payload = Map<String, dynamic>.from(values);
    try {
      final response = await _supabase.rpc(
        'update_vendor',
        params: {
          'p_vendor_id': id,
          'p_expected_updated_at': local.lastUpdated.toUtc().toIso8601String(),
          'p_patch': payload,
        },
      );
      if (response is! Map) {
        throw const PostgrestException(
          message: 'Vendor update returned no committed record.',
          code: 'MIZAN_INVALID_UPDATE_RESPONSE',
        );
      }
      await _db
          .into(_db.vendors)
          .insertOnConflictUpdate(
            _vendorFromMap(Map<String, dynamic>.from(response)),
          );
    } catch (error) {
      if (!_isRetryable(error)) rethrow;
      final updatedLocal = local.copyWith(
        name: values.containsKey('name')
            ? values['name'] as String
            : local.name,
        email: Value(
          values.containsKey('email')
              ? values['email'] as String?
              : local.email,
        ),
        phone: Value(
          values.containsKey('phone')
              ? values['phone'] as String?
              : local.phone,
        ),
        address: Value(
          values.containsKey('address')
              ? values['address'] as String?
              : local.address,
        ),
        taxId: Value(
          values.containsKey('tax_id')
              ? values['tax_id'] as String?
              : local.taxId,
        ),
        paymentTerms: Value(
          values.containsKey('payment_terms')
              ? values['payment_terms'] as String?
              : local.paymentTerms,
        ),
        notes: Value(
          values.containsKey('notes')
              ? values['notes'] as String?
              : local.notes,
        ),
        lastUpdated: now,
      );
      await _db.into(_db.vendors).insertOnConflictUpdate(updatedLocal);
      await _queue.enqueue(
        tenantId: tenantId,
        tableName: 'vendors',
        recordId: id,
        operation: 'update',
        payload: {'id': id, 'tenant_id': tenantId, ...payload},
      );
    }
  }

  Future<void> updateBillStatus(String billId, String status) async {
    final tenantId = await currentTenantId();
    final now = DateTime.now().toUtc();
    final payload = <String, dynamic>{
      'status': status,
      'updated_at': now.toIso8601String(),
    };
    try {
      final row = await _supabase
          .from('bills')
          .update(payload)
          .eq('id', billId)
          .eq('tenant_id', tenantId)
          .select()
          .single();
      await _db
          .into(_db.bills)
          .insertOnConflictUpdate(_billFromMap(Map<String, dynamic>.from(row)));
    } catch (error) {
      if (!_isRetryable(error)) rethrow;
      final local =
          await (_db.select(_db.bills)
                ..where((row) => row.id.equals(billId))
                ..where((row) => row.tenantId.equals(tenantId)))
              .getSingleOrNull();
      if (local == null) rethrow;
      await (_db.update(_db.bills)
            ..where((row) => row.id.equals(billId))
            ..where((row) => row.tenantId.equals(tenantId)))
          .write(
            BillsCompanion(status: Value(status), lastUpdated: Value(now)),
          );
      await _queue.enqueue(
        tenantId: tenantId,
        tableName: 'bills',
        recordId: billId,
        operation: 'update',
        payload: {'id': billId, 'tenant_id': tenantId, ...payload},
      );
    }
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

  Future<Bill> _createOfflineBill({
    required String tenantId,
    required String vendorId,
    required DateTime billDate,
    required DateTime dueDate,
    required List<BillItemData> items,
    required String currencyCode,
    String? vendorBillNumber,
    String? notes,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().toUtc();
    final subtotal = items.fold<int>(
      0,
      (sum, item) => sum + (item.quantity * item.unitPrice).round(),
    );
    final header = <String, dynamic>{
      'id': id,
      'tenant_id': tenantId,
      'vendor_id': vendorId,
      'bill_number':
          'OFFLINE-${now.millisecondsSinceEpoch}-${id.substring(0, 6)}',
      'vendor_bill_number': vendorBillNumber,
      'bill_date': billDate.toUtc().toIso8601String(),
      'due_date': dueDate.toUtc().toIso8601String(),
      'subtotal': subtotal,
      'tax_amount': 0,
      'total_amount': subtotal,
      'amount_paid': 0,
      'status': 'draft',
      'currency_code': currencyCode.toUpperCase(),
      'notes': notes,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };
    final bill = _billFromMap(header);
    final itemRows = items
        .map((item) {
          final itemId = _uuid.v4();
          final itemTimestamp = DateTime.now().toUtc().toIso8601String();
          return <String, dynamic>{
            'id': itemId,
            'tenant_id': tenantId,
            'bill_id': id,
            'description': item.description.trim(),
            'quantity': item.quantity,
            'unit_price': item.unitPrice,
            'amount': (item.quantity * item.unitPrice).round(),
            'product_id': item.productId,
            'created_at': itemTimestamp,
            'updated_at': itemTimestamp,
          };
        })
        .toList(growable: false);
    await _db.transaction(() async {
      await _db.into(_db.bills).insertOnConflictUpdate(bill);
      for (final row in itemRows) {
        await _db
            .into(_db.billItems)
            .insertOnConflictUpdate(_billItemFromMap(row));
      }
    });
    await _queue.enqueue(
      tenantId: tenantId,
      tableName: 'bills',
      recordId: id,
      operation: 'insert',
      payload: header,
    );
    for (final row in itemRows) {
      await _queue.enqueue(
        tenantId: tenantId,
        tableName: 'bill_items',
        recordId: row['id'] as String,
        operation: 'insert',
        payload: row,
      );
    }
    return bill;
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
    final tenantId = await currentTenantId();
    try {
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
      final bill = _billFromMap(
        Map<String, dynamic>.from(result['bill'] as Map),
      );
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
    } catch (error) {
      if (!_isRetryable(error)) rethrow;
      return _createOfflineBill(
        tenantId: tenantId,
        vendorId: vendorId,
        billDate: billDate,
        dueDate: dueDate,
        items: items,
        currencyCode: currencyCode,
        vendorBillNumber: vendorBillNumber,
        notes: notes,
      );
    }
  }
}
