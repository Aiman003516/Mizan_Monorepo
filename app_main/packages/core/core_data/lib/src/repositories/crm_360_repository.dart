import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../tenant_context.dart';

final crm360RepositoryProvider = Provider<Crm360Repository>(
  (ref) => Crm360Repository(
    Supabase.instance.client,
    ref.watch(tenantContextProvider),
  ),
);

class CrmCustomer360 {
  const CrmCustomer360({
    required this.customerId,
    required this.customerName,
    required this.email,
    required this.phone,
    required this.balance,
    required this.creditLimit,
    required this.invoiceCount,
    required this.outstandingMinor,
    required this.overdueInvoiceCount,
    required this.openOpportunityCount,
    required this.interactionCount,
    required this.healthScore,
    required this.healthRiskLevel,
    required this.healthFactors,
  });

  final String customerId;
  final String customerName;
  final String? email;
  final String? phone;
  final int balance;
  final int creditLimit;
  final int invoiceCount;
  final int outstandingMinor;
  final int overdueInvoiceCount;
  final int openOpportunityCount;
  final int interactionCount;
  final int? healthScore;
  final String? healthRiskLevel;
  final Map<String, dynamic> healthFactors;

  factory CrmCustomer360.fromJson(Map<String, dynamic> json) {
    return CrmCustomer360(
      customerId: json['customer_id']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      balance: (json['balance'] as num?)?.toInt() ?? 0,
      creditLimit: (json['credit_limit'] as num?)?.toInt() ?? 0,
      invoiceCount: (json['invoice_count'] as num?)?.toInt() ?? 0,
      outstandingMinor: (json['outstanding_minor'] as num?)?.toInt() ?? 0,
      overdueInvoiceCount:
          (json['overdue_invoice_count'] as num?)?.toInt() ?? 0,
      openOpportunityCount:
          (json['open_opportunity_count'] as num?)?.toInt() ?? 0,
      interactionCount: (json['interaction_count'] as num?)?.toInt() ?? 0,
      healthScore: (json['health_score'] as num?)?.toInt(),
      healthRiskLevel: json['health_risk_level']?.toString(),
      healthFactors: json['health_factors'] is Map
          ? Map<String, dynamic>.from(json['health_factors'] as Map)
          : const <String, dynamic>{},
    );
  }
}

class Crm360Repository {
  Crm360Repository(this._supabase, this._tenantContext);

  final SupabaseClient _supabase;
  final TenantContext _tenantContext;

  Future<String> _tenantId() => _tenantContext.currentTenantId();

  Future<List<CrmCustomer360>> listCustomer360() async {
    await _tenantId();
    final response = await _supabase.rpc('list_customer_360');
    if (response is! List) {
      throw const PostgrestException(
        message: 'Customer 360 returned no result.',
        code: 'MIZAN_CRM_360_INVALID_RESPONSE',
      );
    }
    return response
        .whereType<Map>()
        .map((row) => CrmCustomer360.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> calculateCustomerHealth(
    String customerId,
  ) async {
    await _tenantId();
    final response = await _supabase.rpc(
      'calculate_customer_health',
      params: {'p_customer_id': customerId},
    );
    if (response is! Map) {
      throw const PostgrestException(
        message: 'Customer health returned no result.',
        code: 'MIZAN_CRM_HEALTH_INVALID_RESPONSE',
      );
    }
    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> recordInteraction({
    required String entityType,
    required String entityId,
    required String channel,
    required String direction,
    required String summary,
    DateTime? occurredAt,
  }) async {
    await _tenantId();
    if (summary.trim().isEmpty) {
      throw const PostgrestException(
        message: 'Interaction summary is required.',
        code: 'MIZAN_CRM_INTERACTION_INVALID_INPUT',
      );
    }
    final response = await _supabase.rpc(
      'record_crm_interaction',
      params: {
        'p_entity_type': entityType,
        'p_entity_id': entityId,
        'p_channel': channel,
        'p_direction': direction,
        'p_summary': summary.trim(),
        'p_occurred_at': occurredAt?.toIso8601String(),
      },
    );
    if (response is! Map) {
      throw const PostgrestException(
        message: 'Interaction returned no result.',
        code: 'MIZAN_CRM_INTERACTION_INVALID_RESPONSE',
      );
    }
    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> createQuoteDraft({
    required String quoteNumber,
    required String customerId,
    String? opportunityId,
    required String currencyCode,
    DateTime? validUntil,
    String? notes,
    required List<CrmQuoteLineInput> lines,
  }) async {
    await _tenantId();
    if (quoteNumber.trim().isEmpty ||
        customerId.trim().isEmpty ||
        lines.isEmpty) {
      throw const PostgrestException(
        message: 'Quote number, customer, and at least one line are required.',
        code: 'MIZAN_CRM_QUOTE_INVALID_INPUT',
      );
    }
    final response = await _supabase.rpc(
      'create_crm_quote_draft',
      params: {
        'p_quote_number': quoteNumber.trim(),
        'p_customer_id': customerId,
        'p_opportunity_id': opportunityId,
        'p_currency_code': currencyCode.trim().toUpperCase(),
        'p_valid_until': validUntil?.toIso8601String().substring(0, 10),
        'p_notes': notes?.trim(),
        'p_lines': lines.map((line) => line.toJson()).toList(growable: false),
      },
    );
    if (response is! Map) {
      throw const PostgrestException(
        message: 'Quote draft returned no result.',
        code: 'MIZAN_CRM_QUOTE_INVALID_RESPONSE',
      );
    }
    return Map<String, dynamic>.from(response);
  }
}

class CrmQuoteLineInput {
  const CrmQuoteLineInput({
    required this.description,
    required this.quantity,
    required this.unitPriceMinor,
  });

  final String description;
  final double quantity;
  final int unitPriceMinor;

  Map<String, dynamic> toJson() => {
    'description': description.trim(),
    'quantity': quantity,
    'unit_price_minor': unitPriceMinor,
  };
}
