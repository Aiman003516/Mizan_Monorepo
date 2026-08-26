import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../tenant_context.dart';

final inventoryPosRepositoryProvider = Provider<InventoryPosRepository>(
  (ref) => InventoryPosRepository(
    Supabase.instance.client,
    ref.watch(tenantContextProvider),
  ),
);

class InventoryBalance {
  const InventoryBalance({
    required this.id,
    required this.warehouseId,
    required this.productId,
    required this.quantityOnHand,
    required this.averageCostMinor,
    required this.currencyCode,
  });

  final String id;
  final String warehouseId;
  final String productId;
  final double quantityOnHand;
  final int averageCostMinor;
  final String currencyCode;

  factory InventoryBalance.fromJson(Map<String, dynamic> json) {
    return InventoryBalance(
      id: json['id']?.toString() ?? '',
      warehouseId: json['warehouse_id']?.toString() ?? 'default',
      productId: json['product_id']?.toString() ?? '',
      quantityOnHand: (json['quantity_on_hand'] as num?)?.toDouble() ?? 0,
      averageCostMinor: (json['average_cost_minor'] as num?)?.toInt() ?? 0,
      currencyCode: json['currency_code']?.toString() ?? '',
    );
  }
}

class InventoryPosRepository {
  InventoryPosRepository(this._supabase, this._tenantContext);

  final SupabaseClient _supabase;
  final TenantContext _tenantContext;

  Future<String> _tenantId() => _tenantContext.currentTenantId();

  Future<List<InventoryBalance>> listBalances({String? warehouseId}) async {
    final tenantId = await _tenantId();
    var query = _supabase
        .from('inventory_balances')
        .select()
        .eq('tenant_id', tenantId);
    if (warehouseId?.trim().isNotEmpty == true) {
      query = query.eq('warehouse_id', warehouseId!.trim());
    }
    final rows = await query.order('product_id');
    return rows
        .whereType<Map>()
        .map((row) => InventoryBalance.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> createReceiptDraft({
    required String productId,
    String warehouseId = 'default',
    required double quantity,
    required int unitCostMinor,
    required String currencyCode,
    required String inventoryAccountId,
    required String payableAccountId,
    required String entryNumber,
    DateTime? receiptDate,
  }) async {
    await _tenantId();
    _validateQuantity(quantity);
    _validateMinor(unitCostMinor);
    final response = await _supabase.rpc(
      'create_inventory_receipt_draft',
      params: {
        'p_product_id': productId.trim(),
        'p_warehouse_id': warehouseId.trim(),
        'p_quantity': quantity,
        'p_unit_cost_minor': unitCostMinor,
        'p_currency_code': currencyCode.trim().toUpperCase(),
        'p_inventory_account_id': inventoryAccountId,
        'p_payable_account_id': payableAccountId,
        'p_entry_number': entryNumber.trim(),
        'p_receipt_date': (receiptDate ?? DateTime.now())
            .toIso8601String()
            .substring(0, 10),
      },
    );
    return _requireMap(response, 'MIZAN_INVENTORY_RECEIPT_INVALID_RESPONSE');
  }

  Future<Map<String, dynamic>> createSaleDraft({
    required String saleNumber,
    String warehouseId = 'default',
    DateTime? saleDate,
    required String currencyCode,
    required String paymentAccountId,
    required String revenueAccountId,
    required String inventoryAccountId,
    required String cogsAccountId,
    required List<PosSaleLineInput> lines,
  }) async {
    await _tenantId();
    if (saleNumber.trim().isEmpty || lines.isEmpty) {
      throw const PostgrestException(
        message: 'A POS sale number and at least one line are required.',
        code: 'MIZAN_POS_SALE_INVALID_INPUT',
      );
    }
    final response = await _supabase.rpc(
      'create_pos_sale_draft',
      params: {
        'p_sale_number': saleNumber.trim(),
        'p_warehouse_id': warehouseId.trim(),
        'p_sale_date': (saleDate ?? DateTime.now()).toIso8601String().substring(
          0,
          10,
        ),
        'p_currency_code': currencyCode.trim().toUpperCase(),
        'p_payment_account_id': paymentAccountId,
        'p_revenue_account_id': revenueAccountId,
        'p_inventory_account_id': inventoryAccountId,
        'p_cogs_account_id': cogsAccountId,
        'p_lines': lines.map((line) => line.toJson()).toList(growable: false),
      },
    );
    return _requireMap(response, 'MIZAN_POS_SALE_INVALID_RESPONSE');
  }

  void _validateQuantity(double quantity) {
    if (!quantity.isFinite || quantity <= 0) {
      throw const PostgrestException(
        message: 'Quantity must be positive and finite.',
        code: 'MIZAN_INVENTORY_INVALID_QUANTITY',
      );
    }
  }

  void _validateMinor(int value) {
    if (value < 0) {
      throw const PostgrestException(
        message: 'Minor-unit amount cannot be negative.',
        code: 'MIZAN_INVENTORY_INVALID_AMOUNT',
      );
    }
  }

  Map<String, dynamic> _requireMap(dynamic response, String code) {
    if (response is! Map) {
      throw PostgrestException(
        message: 'Inventory/POS operation returned no result.',
        code: code,
      );
    }
    return Map<String, dynamic>.from(response);
  }
}

class PosSaleLineInput {
  const PosSaleLineInput({
    required this.productId,
    required this.quantity,
    required this.unitPriceMinor,
  });

  final String productId;
  final double quantity;
  final int unitPriceMinor;

  Map<String, dynamic> toJson() => {
    'product_id': productId.trim(),
    'quantity': quantity,
    'unit_price_minor': unitPriceMinor,
  };
}
