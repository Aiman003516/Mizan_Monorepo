enum ApprovalRequestType {
  expense,
  invoice,
  bill,
  journal,
  balanceAdjustment,
  refund,
  discount,
  periodReopen;

  String get databaseValue => switch (this) {
    ApprovalRequestType.expense => 'expense',
    ApprovalRequestType.invoice => 'invoice',
    ApprovalRequestType.bill => 'bill',
    ApprovalRequestType.journal => 'journal',
    ApprovalRequestType.balanceAdjustment => 'balance_adjustment',
    ApprovalRequestType.refund => 'refund',
    ApprovalRequestType.discount => 'discount',
    ApprovalRequestType.periodReopen => 'period_reopen',
  };

  static ApprovalRequestType fromDatabase(String value) {
    return switch (value) {
      'expense' => ApprovalRequestType.expense,
      'invoice' => ApprovalRequestType.invoice,
      'bill' => ApprovalRequestType.bill,
      'journal' => ApprovalRequestType.journal,
      'balance_adjustment' => ApprovalRequestType.balanceAdjustment,
      'refund' => ApprovalRequestType.refund,
      'discount' => ApprovalRequestType.discount,
      'period_reopen' => ApprovalRequestType.periodReopen,
      _ => throw FormatException('Unknown approval request type: $value'),
    };
  }
}

enum ApprovalStatus { pending, approved, rejected }

extension ApprovalStatusDatabaseValue on ApprovalStatus {
  String get databaseValue => name;

  static ApprovalStatus fromDatabase(String value) {
    return switch (value) {
      'pending' => ApprovalStatus.pending,
      'approved' => ApprovalStatus.approved,
      'rejected' => ApprovalStatus.rejected,
      _ => throw FormatException('Unknown approval status: $value'),
    };
  }
}

class ApprovalRequest {
  const ApprovalRequest({
    required this.id,
    required this.tenantId,
    required this.requesterId,
    required this.requestType,
    required this.payload,
    required this.amountMinor,
    required this.currencyCode,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.targetId,
    this.branchId,
    this.idempotencyKey,
    this.decidedBy,
    this.decidedAt,
    this.updatedAt,
  });

  final String id;
  final String tenantId;
  final String requesterId;
  final ApprovalRequestType requestType;
  final String? targetId;
  final Map<String, dynamic> payload;
  final int amountMinor;
  final String currencyCode;
  final String reason;
  final ApprovalStatus status;
  final String? branchId;
  final String? idempotencyKey;
  final DateTime createdAt;
  final String? decidedBy;
  final DateTime? decidedAt;
  final DateTime? updatedAt;

  factory ApprovalRequest.fromJson(Map<String, dynamic> json) {
    final rawPayload = json['payload'];
    return ApprovalRequest(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenant_id']?.toString() ?? '',
      requesterId: json['requester_id']?.toString() ?? '',
      requestType: ApprovalRequestType.fromDatabase(
        json['request_type']?.toString() ?? '',
      ),
      targetId: json['target_id']?.toString(),
      payload: rawPayload is Map
          ? Map<String, dynamic>.from(rawPayload)
          : const <String, dynamic>{},
      amountMinor: (json['amount_minor'] as num?)?.toInt() ?? 0,
      currencyCode: json['currency_code']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      status: ApprovalStatusDatabaseValue.fromDatabase(
        json['status']?.toString() ?? '',
      ),
      branchId: json['branch_id']?.toString(),
      idempotencyKey: json['idempotency_key']?.toString(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      decidedBy: json['decided_by']?.toString(),
      decidedAt: _parseDate(json['decided_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class ApprovalRequestEvent {
  const ApprovalRequestEvent({
    required this.id,
    required this.tenantId,
    required this.approvalRequestId,
    required this.actorId,
    required this.toStatus,
    required this.createdAt,
    this.fromStatus,
    this.decisionReason,
  });

  final int id;
  final String tenantId;
  final String approvalRequestId;
  final String actorId;
  final ApprovalStatus? fromStatus;
  final ApprovalStatus toStatus;
  final String? decisionReason;
  final DateTime createdAt;

  factory ApprovalRequestEvent.fromJson(Map<String, dynamic> json) {
    final from = json['from_status']?.toString();
    return ApprovalRequestEvent(
      id: (json['id'] as num?)?.toInt() ?? 0,
      tenantId: json['tenant_id']?.toString() ?? '',
      approvalRequestId: json['approval_request_id']?.toString() ?? '',
      actorId: json['actor_id']?.toString() ?? '',
      fromStatus: from == null
          ? null
          : ApprovalStatusDatabaseValue.fromDatabase(from),
      toStatus: ApprovalStatusDatabaseValue.fromDatabase(
        json['to_status']?.toString() ?? '',
      ),
      decisionReason: json['decision_reason']?.toString(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}
