enum ProcurementDocumentStatus {
  draft,
  pendingApproval,
  approved,
  rejected,
  cancelled,
  converted,
  partiallyReceived,
  received,
  closed,
  posted,
  voided;

  static ProcurementDocumentStatus fromDatabase(String value) {
    return switch (value) {
      'draft' => draft,
      'pending_approval' => pendingApproval,
      'approved' => approved,
      'rejected' => rejected,
      'cancelled' => cancelled,
      'converted' => converted,
      'partially_received' => partiallyReceived,
      'received' => received,
      'closed' => closed,
      'posted' => posted,
      'void' => voided,
      _ => throw FormatException('Unknown procurement status: $value'),
    };
  }
}

class ProcurementLineInput {
  const ProcurementLineInput({
    this.productId,
    required this.description,
    required this.quantity,
    required this.unitPriceMinor,
    this.taxMinor = 0,
  });

  final String? productId;
  final String description;
  final double quantity;
  final int unitPriceMinor;
  final int taxMinor;

  Map<String, dynamic> toRequisitionJson() => {
    'product_id': productId?.trim(),
    'description': description.trim(),
    'quantity': quantity,
    'estimated_unit_price_minor': unitPriceMinor,
  };

  Map<String, dynamic> toPurchaseOrderJson() => {
    'product_id': productId?.trim(),
    'description': description.trim(),
    'ordered_quantity': quantity,
    'unit_price_minor': unitPriceMinor,
    'tax_minor': taxMinor,
  };
}

class ProcurementRequisition {
  const ProcurementRequisition({
    required this.id,
    required this.requisitionNumber,
    required this.status,
    required this.currencyCode,
    required this.totalMinor,
    this.branchId,
    this.approvalRequestId,
  });

  final String id;
  final String requisitionNumber;
  final ProcurementDocumentStatus status;
  final String currencyCode;
  final int totalMinor;
  final String? branchId;
  final String? approvalRequestId;

  factory ProcurementRequisition.fromJson(Map<String, dynamic> json) {
    return ProcurementRequisition(
      id: json['id']?.toString() ?? json['requisition_id']?.toString() ?? '',
      requisitionNumber: json['requisition_number']?.toString() ?? '',
      status: ProcurementDocumentStatus.fromDatabase(
        json['status']?.toString() ?? 'draft',
      ),
      currencyCode: json['currency_code']?.toString() ?? '',
      totalMinor: (json['total_minor'] as num?)?.toInt() ?? 0,
      branchId: json['branch_id']?.toString(),
      approvalRequestId: json['approval_request_id']?.toString(),
    );
  }
}

class PurchaseOrderSummary {
  const PurchaseOrderSummary({
    required this.id,
    required this.orderNumber,
    required this.vendorId,
    required this.status,
    required this.orderDate,
    required this.currencyCode,
    required this.totalMinor,
    this.branchId,
    this.approvalRequestId,
  });

  final String id;
  final String orderNumber;
  final String vendorId;
  final ProcurementDocumentStatus status;
  final DateTime orderDate;
  final String currencyCode;
  final int totalMinor;
  final String? branchId;
  final String? approvalRequestId;

  factory PurchaseOrderSummary.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderSummary(
      id: json['id']?.toString() ?? json['purchase_order_id']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ?? '',
      vendorId: json['vendor_id']?.toString() ?? '',
      status: ProcurementDocumentStatus.fromDatabase(
        json['status']?.toString() ?? 'draft',
      ),
      orderDate:
          DateTime.tryParse(json['order_date']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      currencyCode: json['currency_code']?.toString() ?? '',
      totalMinor: (json['total_minor'] as num?)?.toInt() ?? 0,
      branchId: json['branch_id']?.toString(),
      approvalRequestId: json['approval_request_id']?.toString(),
    );
  }
}

class ThreeWayMatchResult {
  const ThreeWayMatchResult({
    required this.billLineId,
    this.purchaseOrderId,
    this.purchaseOrderLineId,
    required this.orderedQuantity,
    required this.receivedQuantity,
    required this.returnedQuantity,
    required this.availableQuantity,
    required this.billedQuantity,
    this.orderedUnitPriceMinor,
    this.billedUnitPriceMinor,
    this.priceVarianceMinor,
    required this.currencyCode,
    required this.matchStatus,
    this.blockingReason,
  });

  final String billLineId;
  final String? purchaseOrderId;
  final String? purchaseOrderLineId;
  final double orderedQuantity;
  final double receivedQuantity;
  final double returnedQuantity;
  final double availableQuantity;
  final double billedQuantity;
  final int? orderedUnitPriceMinor;
  final int? billedUnitPriceMinor;
  final int? priceVarianceMinor;
  final String currencyCode;
  final String matchStatus;
  final String? blockingReason;

  bool get isMatched => matchStatus == 'matched';
  bool get isBlocked => matchStatus == 'blocked';

  factory ThreeWayMatchResult.fromJson(Map<String, dynamic> json) {
    return ThreeWayMatchResult(
      billLineId: json['bill_line_id']?.toString() ?? '',
      purchaseOrderId: json['purchase_order_id']?.toString(),
      purchaseOrderLineId: json['purchase_order_line_id']?.toString(),
      orderedQuantity: (json['ordered_quantity'] as num?)?.toDouble() ?? 0,
      receivedQuantity: (json['received_quantity'] as num?)?.toDouble() ?? 0,
      returnedQuantity: (json['returned_quantity'] as num?)?.toDouble() ?? 0,
      availableQuantity: (json['available_quantity'] as num?)?.toDouble() ?? 0,
      billedQuantity: (json['billed_quantity'] as num?)?.toDouble() ?? 0,
      orderedUnitPriceMinor: (json['ordered_unit_price_minor'] as num?)
          ?.toInt(),
      billedUnitPriceMinor: (json['billed_unit_price_minor'] as num?)?.toInt(),
      priceVarianceMinor: (json['price_variance_minor'] as num?)?.toInt(),
      currencyCode: json['currency_code']?.toString() ?? '',
      matchStatus: json['match_status']?.toString() ?? 'blocked',
      blockingReason: json['blocking_reason']?.toString(),
    );
  }
}

class ProcurementReceiptLineInput {
  const ProcurementReceiptLineInput({
    required this.purchaseOrderLineId,
    required this.quantity,
    required this.unitCostMinor,
  });

  final String purchaseOrderLineId;
  final double quantity;
  final int unitCostMinor;

  Map<String, dynamic> toJson() => {
    'purchase_order_line_id': purchaseOrderLineId.trim(),
    'quantity': quantity,
    'unit_cost_minor': unitCostMinor,
  };
}
