import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../tenant_context.dart';

final arApSettlementRepositoryProvider = Provider<ArApSettlementRepository>(
  (ref) => ArApSettlementRepository(
    Supabase.instance.client,
    ref.watch(tenantContextProvider),
  ),
);

class ArApAgingEntry {
  const ArApAgingEntry({
    required this.documentId,
    required this.partyId,
    required this.documentNumber,
    required this.dueDate,
    required this.currencyCode,
    required this.totalAmount,
    required this.amountPaid,
    required this.outstandingMinor,
    required this.daysOverdue,
    required this.agingBucket,
  });

  final String documentId;
  final String partyId;
  final String documentNumber;
  final DateTime dueDate;
  final String currencyCode;
  final int totalAmount;
  final int amountPaid;
  final int outstandingMinor;
  final int daysOverdue;
  final String agingBucket;

  factory ArApAgingEntry.fromJson(
    Map<String, dynamic> json, {
    required bool receivable,
  }) {
    return ArApAgingEntry(
      documentId:
          (json[receivable ? 'invoice_id' : 'bill_id'])?.toString() ?? '',
      partyId:
          (json[receivable ? 'customer_id' : 'vendor_id'])?.toString() ?? '',
      documentNumber:
          (json[receivable ? 'invoice_number' : 'bill_number'])?.toString() ??
          '',
      dueDate:
          DateTime.tryParse(json['due_date']?.toString() ?? '') ??
          DateTime(1970),
      currencyCode: json['currency_code']?.toString() ?? '',
      totalAmount: (json['total_amount'] as num?)?.toInt() ?? 0,
      amountPaid: (json['amount_paid'] as num?)?.toInt() ?? 0,
      outstandingMinor: (json['outstanding_minor'] as num?)?.toInt() ?? 0,
      daysOverdue: (json['days_overdue'] as num?)?.toInt() ?? 0,
      agingBucket: json['aging_bucket']?.toString() ?? 'current',
    );
  }
}

class ArApSettlementRepository {
  ArApSettlementRepository(this._supabase, this._tenantContext);

  final SupabaseClient _supabase;
  final TenantContext _tenantContext;

  Future<void> _requireTenant() => _tenantContext.currentTenantId();

  Future<List<ArApAgingEntry>> receivablesAging({DateTime? asOf}) async {
    await _requireTenant();
    final response = await _supabase.rpc(
      'receivables_aging',
      params: {'p_as_of': asOf?.toIso8601String().substring(0, 10)},
    );
    return _mapAgingResponse(response, receivable: true);
  }

  Future<List<ArApAgingEntry>> payablesAging({DateTime? asOf}) async {
    await _requireTenant();
    final response = await _supabase.rpc(
      'payables_aging',
      params: {'p_as_of': asOf?.toIso8601String().substring(0, 10)},
    );
    return _mapAgingResponse(response, receivable: false);
  }

  Future<Map<String, dynamic>> createSettlementDraft({
    required String direction,
    String? invoiceId,
    String? billId,
    required int amountMinor,
    required String currencyCode,
    DateTime? settlementDate,
    required String paymentMethod,
    String? reference,
    required String cashAccountId,
    required String counterpartyAccountId,
    required String entryNumber,
  }) async {
    await _requireTenant();
    final normalizedDate = (settlementDate ?? DateTime.now())
        .toIso8601String()
        .substring(0, 10);
    final normalizedCurrency = currencyCode.trim().toUpperCase();
    final normalizedMethod = paymentMethod.trim();
    final normalizedReference = reference?.trim() ?? '';
    final idempotencyKey =
        'settlement:${direction.trim()}:${invoiceId ?? billId}:$amountMinor:$normalizedCurrency:$normalizedDate:$normalizedMethod:$normalizedReference';
    final response = await _supabase.rpc(
      'create_settlement_draft_idempotent',
      params: {
        'p_idempotency_key': idempotencyKey,
        'p_direction': direction,
        'p_invoice_id': invoiceId,
        'p_bill_id': billId,
        'p_amount_minor': amountMinor,
        'p_currency_code': normalizedCurrency,
        'p_settlement_date': normalizedDate,
        'p_payment_method': normalizedMethod,
        'p_reference': normalizedReference,
        'p_cash_account_id': cashAccountId,
        'p_counterparty_account_id': counterpartyAccountId,
        'p_entry_number': entryNumber.trim(),
      },
    );
    if (response is! Map) {
      throw const PostgrestException(
        message: 'Settlement draft returned no result.',
        code: 'MIZAN_SETTLEMENT_INVALID_RESPONSE',
      );
    }
    return Map<String, dynamic>.from(response);
  }

  List<ArApAgingEntry> _mapAgingResponse(
    dynamic response, {
    required bool receivable,
  }) {
    if (response is! List) {
      throw const PostgrestException(
        message: 'Aging report returned no result.',
        code: 'MIZAN_AGING_INVALID_RESPONSE',
      );
    }
    return response
        .whereType<Map>()
        .map(
          (row) => ArApAgingEntry.fromJson(
            Map<String, dynamic>.from(row),
            receivable: receivable,
          ),
        )
        .toList(growable: false);
  }
}
