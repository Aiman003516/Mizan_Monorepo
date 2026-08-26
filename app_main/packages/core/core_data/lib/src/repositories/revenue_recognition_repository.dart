import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../tenant_context.dart';

final revenueRecognitionRepositoryProvider = Provider<RevenueRecognitionRepository>(
  (ref) => RevenueRecognitionRepository(
    Supabase.instance.client,
    ref.watch(tenantContextProvider),
  ),
);

class RevenueScheduleLine {
  const RevenueScheduleLine({
    required this.id,
    required this.contractId,
    required this.contractNumber,
    required this.recognitionOn,
    required this.amountMinor,
    required this.currencyCode,
    required this.status,
    required this.journalEntryId,
  });

  final String id;
  final String contractId;
  final String contractNumber;
  final DateTime recognitionOn;
  final int amountMinor;
  final String currencyCode;
  final String status;
  final String? journalEntryId;

  bool get isReady => status == 'planned';

  factory RevenueScheduleLine.fromJson(Map<String, dynamic> json) {
    return RevenueScheduleLine(
      id: json['id']?.toString() ?? '',
      contractId: json['contract_id']?.toString() ?? '',
      contractNumber: json['contract_number']?.toString() ?? '',
      recognitionOn:
          DateTime.tryParse(json['recognition_on']?.toString() ?? '') ??
          DateTime(1970),
      amountMinor: (json['amount_minor'] as num?)?.toInt() ?? 0,
      currencyCode: json['currency_code']?.toString() ?? '',
      status: json['status']?.toString() ?? 'planned',
      journalEntryId: json['journal_entry_id']?.toString(),
    );
  }
}

class RevenueRecognitionRepository {
  RevenueRecognitionRepository(this._supabase, this._tenantContext);

  final SupabaseClient _supabase;
  final TenantContext _tenantContext;

  Future<String> _tenantId() => _tenantContext.currentTenantId();

  Future<List<RevenueScheduleLine>> listSchedule({
    String? status,
    DateTime? asOf,
  }) async {
    await _tenantId();
    final response = await _supabase.rpc(
      'list_revenue_schedule',
      params: {
        'p_status': status,
        'p_as_of': asOf?.toIso8601String().substring(0, 10),
      },
    );
    if (response is! List) {
      throw const PostgrestException(
        message: 'Revenue schedule returned no result.',
        code: 'MIZAN_REVENUE_INVALID_RESPONSE',
      );
    }
    return response
        .whereType<Map>()
        .map(
          (row) => RevenueScheduleLine.fromJson(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> createContract({
    required String contractNumber,
    String? customerId,
    required String currencyCode,
    required int totalMinor,
    required DateTime startsOn,
    required DateTime endsOn,
    required String deferredRevenueAccountId,
    required String revenueAccountId,
  }) async {
    await _tenantId();
    final response = await _supabase.rpc(
      'create_revenue_contract',
      params: {
        'p_contract_number': contractNumber.trim(),
        'p_customer_id': customerId,
        'p_currency_code': currencyCode.trim().toUpperCase(),
        'p_total_minor': totalMinor,
        'p_starts_on': startsOn.toIso8601String().substring(0, 10),
        'p_ends_on': endsOn.toIso8601String().substring(0, 10),
        'p_deferred_revenue_account_id': deferredRevenueAccountId,
        'p_revenue_account_id': revenueAccountId,
      },
    );
    if (response is! Map) {
      throw const PostgrestException(
        message: 'Revenue contract returned no result.',
        code: 'MIZAN_REVENUE_CONTRACT_INVALID_RESPONSE',
      );
    }
    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> createRecognitionDraft({
    required String scheduleLineId,
    required String entryNumber,
    DateTime? entryDate,
  }) async {
    await _tenantId();
    final response = await _supabase.rpc(
      'create_revenue_recognition_draft',
      params: {
        'p_schedule_line_id': scheduleLineId,
        'p_entry_number': entryNumber.trim(),
        'p_entry_date':
            (entryDate ?? DateTime.now()).toIso8601String().substring(0, 10),
      },
    );
    if (response is! Map) {
      throw const PostgrestException(
        message: 'Revenue recognition draft returned no result.',
        code: 'MIZAN_REVENUE_DRAFT_INVALID_RESPONSE',
      );
    }
    return Map<String, dynamic>.from(response);
  }
}
