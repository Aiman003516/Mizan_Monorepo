import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/procurement_models.dart';
import '../tenant_context.dart';
import '../validation/procurement_validation.dart';

final procurementRepositoryProvider = Provider<ProcurementRepository>(
  (ref) => ProcurementRepository(
    Supabase.instance.client,
    ref.watch(tenantContextProvider),
  ),
);

class ProcurementRepository {
  ProcurementRepository(this._supabase, this._tenantContext);

  final SupabaseClient _supabase;
  final TenantContext _tenantContext;

  Future<String> _requireTenant() => _tenantContext.currentTenantId();

  Future<Map<String, dynamic>> createRequisition({
    required String requisitionNumber,
    String? branchId,
    DateTime? neededBy,
    required String purpose,
    required String currencyCode,
    required List<ProcurementLineInput> lines,
  }) async {
    await _requireTenant();
    ProcurementValidation.documentNumber(
      requisitionNumber,
      'requisitionNumber',
    );
    ProcurementValidation.purpose(purpose);
    final normalizedCurrency = ProcurementValidation.currency(currencyCode);
    ProcurementValidation.lines(lines, requisition: true);
    return _requireMap(
      await _supabase.rpc(
        'create_purchase_requisition',
        params: {
          'p_requisition_number': requisitionNumber.trim(),
          'p_branch_id': branchId,
          'p_needed_by': _date(neededBy),
          'p_purpose': purpose.trim(),
          'p_currency_code': normalizedCurrency,
          'p_lines': lines
              .map((line) => line.toRequisitionJson())
              .toList(growable: false),
        },
      ),
      'MIZAN_REQUISITION_INVALID_RESPONSE',
    );
  }

  Future<Map<String, dynamic>> submitRequisitionForApproval(
    String requisitionId, {
    String? reason,
  }) async {
    await _requireTenant();
    ProcurementValidation.id(requisitionId, 'requisitionId');
    return _requireMap(
      await _supabase.rpc(
        'submit_purchase_requisition_for_approval',
        params: {'p_requisition_id': requisitionId, 'p_reason': reason?.trim()},
      ),
      'MIZAN_REQUISITION_APPROVAL_INVALID_RESPONSE',
    );
  }

  Future<Map<String, dynamic>> createPurchaseOrder({
    required String orderNumber,
    required String vendorId,
    String? requisitionId,
    String? branchId,
    required DateTime orderDate,
    DateTime? expectedDate,
    required String currencyCode,
    required List<ProcurementLineInput> lines,
  }) async {
    await _requireTenant();
    ProcurementValidation.documentNumber(orderNumber, 'orderNumber');
    ProcurementValidation.id(vendorId, 'vendorId');
    final normalizedCurrency = ProcurementValidation.currency(currencyCode);
    ProcurementValidation.lines(lines);
    if (requisitionId != null) {
      ProcurementValidation.id(requisitionId, 'requisitionId');
    }
    if (expectedDate != null && expectedDate.isBefore(orderDate)) {
      throw ArgumentError.value(expectedDate, 'expectedDate');
    }
    return _requireMap(
      await _supabase.rpc(
        'create_purchase_order_draft',
        params: {
          'p_order_number': orderNumber.trim(),
          'p_vendor_id': vendorId,
          'p_requisition_id': requisitionId,
          'p_branch_id': branchId,
          'p_order_date': _date(orderDate),
          'p_expected_date': _date(expectedDate),
          'p_currency_code': normalizedCurrency,
          'p_lines': lines
              .map((line) => line.toPurchaseOrderJson())
              .toList(growable: false),
        },
      ),
      'MIZAN_PURCHASE_ORDER_INVALID_RESPONSE',
    );
  }

  Future<Map<String, dynamic>> submitPurchaseOrderForApproval(
    String purchaseOrderId, {
    String? reason,
  }) async {
    await _requireTenant();
    ProcurementValidation.id(purchaseOrderId, 'purchaseOrderId');
    return _requireMap(
      await _supabase.rpc(
        'submit_purchase_order_for_approval',
        params: {
          'p_purchase_order_id': purchaseOrderId,
          'p_reason': reason?.trim(),
        },
      ),
      'MIZAN_PURCHASE_ORDER_APPROVAL_INVALID_RESPONSE',
    );
  }

  Future<Map<String, dynamic>> createReceipt({
    required String purchaseOrderId,
    required String receiptNumber,
    String warehouseId = 'default',
    required DateTime receiptDate,
    required List<ProcurementReceiptLineInput> lines,
  }) async {
    await _requireTenant();
    ProcurementValidation.id(purchaseOrderId, 'purchaseOrderId');
    ProcurementValidation.documentNumber(receiptNumber, 'receiptNumber');
    ProcurementValidation.receiptLines(lines);
    return _requireMap(
      await _supabase.rpc(
        'create_purchase_receipt_draft',
        params: {
          'p_purchase_order_id': purchaseOrderId,
          'p_receipt_number': receiptNumber.trim(),
          'p_warehouse_id': warehouseId.trim(),
          'p_receipt_date': _date(receiptDate),
          'p_lines': lines.map((line) => line.toJson()).toList(growable: false),
        },
      ),
      'MIZAN_PURCHASE_RECEIPT_INVALID_RESPONSE',
    );
  }

  Future<Map<String, dynamic>> postReceipt(String receiptId) async {
    await _requireTenant();
    ProcurementValidation.id(receiptId, 'receiptId');
    return _requireMap(
      await _supabase.rpc(
        'post_purchase_receipt',
        params: {'p_receipt_id': receiptId},
      ),
      'MIZAN_PURCHASE_RECEIPT_POST_INVALID_RESPONSE',
    );
  }

  Future<Map<String, dynamic>> createReturn({
    required String purchaseOrderId,
    String? receiptId,
    required String returnNumber,
    required DateTime returnDate,
    required String reason,
    required List<ProcurementReceiptLineInput> lines,
  }) async {
    await _requireTenant();
    ProcurementValidation.id(purchaseOrderId, 'purchaseOrderId');
    ProcurementValidation.documentNumber(returnNumber, 'returnNumber');
    ProcurementValidation.purpose(reason);
    ProcurementValidation.receiptLines(lines);
    return _requireMap(
      await _supabase.rpc(
        'create_purchase_return_draft',
        params: {
          'p_purchase_order_id': purchaseOrderId,
          'p_receipt_id': receiptId,
          'p_return_number': returnNumber.trim(),
          'p_return_date': _date(returnDate),
          'p_reason': reason.trim(),
          'p_lines': lines.map((line) => line.toJson()).toList(growable: false),
        },
      ),
      'MIZAN_PURCHASE_RETURN_INVALID_RESPONSE',
    );
  }

  Future<Map<String, dynamic>> postReturn(String returnId) async {
    await _requireTenant();
    ProcurementValidation.id(returnId, 'returnId');
    return _requireMap(
      await _supabase.rpc(
        'post_purchase_return',
        params: {'p_return_id': returnId},
      ),
      'MIZAN_PURCHASE_RETURN_POST_INVALID_RESPONSE',
    );
  }

  Future<Map<String, dynamic>> linkReceiptToInventory({
    required String purchaseReceiptId,
    required String inventoryAccountId,
    required String payableAccountId,
    required String entryNumberPrefix,
  }) async {
    await _requireTenant();
    ProcurementValidation.id(purchaseReceiptId, 'purchaseReceiptId');
    ProcurementValidation.id(inventoryAccountId, 'inventoryAccountId');
    ProcurementValidation.id(payableAccountId, 'payableAccountId');
    ProcurementValidation.documentNumber(
      entryNumberPrefix,
      'entryNumberPrefix',
    );
    return _requireMap(
      await _supabase.rpc(
        'post_purchase_receipt_to_inventory',
        params: {
          'p_purchase_receipt_id': purchaseReceiptId,
          'p_inventory_account_id': inventoryAccountId,
          'p_payable_account_id': payableAccountId,
          'p_entry_number_prefix': entryNumberPrefix.trim(),
        },
      ),
      'MIZAN_PROCUREMENT_RECEIPT_INVENTORY_INVALID_RESPONSE',
    );
  }

  Future<Map<String, dynamic>> linkReturnToInventory({
    required String purchaseReturnId,
    required String inventoryAccountId,
    required String payableAccountId,
    required String entryNumberPrefix,
  }) async {
    await _requireTenant();
    ProcurementValidation.id(purchaseReturnId, 'purchaseReturnId');
    ProcurementValidation.id(inventoryAccountId, 'inventoryAccountId');
    ProcurementValidation.id(payableAccountId, 'payableAccountId');
    ProcurementValidation.documentNumber(
      entryNumberPrefix,
      'entryNumberPrefix',
    );
    return _requireMap(
      await _supabase.rpc(
        'post_purchase_return_to_inventory',
        params: {
          'p_purchase_return_id': purchaseReturnId,
          'p_inventory_account_id': inventoryAccountId,
          'p_payable_account_id': payableAccountId,
          'p_entry_number_prefix': entryNumberPrefix.trim(),
        },
      ),
      'MIZAN_PROCUREMENT_RETURN_INVENTORY_INVALID_RESPONSE',
    );
  }

  Future<Map<String, dynamic>> assertPurchaseBillMatch(String billId) async {
    await _requireTenant();
    ProcurementValidation.id(billId, 'billId');
    return _requireMap(
      await _supabase.rpc(
        'assert_purchase_bill_match',
        params: {'p_bill_id': billId},
      ),
      'MIZAN_PURCHASE_BILL_MATCH_GATE_INVALID_RESPONSE',
    );
  }

  Future<List<ThreeWayMatchResult>> matchBill(String billId) async {
    await _requireTenant();
    ProcurementValidation.id(billId, 'billId');
    final response = await _supabase.rpc(
      'purchase_bill_three_way_match',
      params: {'p_bill_id': billId},
    );
    if (response is! List) {
      throw const PostgrestException(
        message: 'Three-way match returned no result.',
        code: 'MIZAN_THREE_WAY_MATCH_INVALID_RESPONSE',
      );
    }
    return response
        .whereType<Map>()
        .map(
          (row) => ThreeWayMatchResult.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList(growable: false);
  }

  String? _date(DateTime? value) => value?.toIso8601String().substring(0, 10);

  Map<String, dynamic> _requireMap(dynamic response, String code) {
    if (response is! Map) {
      throw PostgrestException(
        message: 'Procurement operation returned no result.',
        code: code,
      );
    }
    return Map<String, dynamic>.from(response);
  }
}
