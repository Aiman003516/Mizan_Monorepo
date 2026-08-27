import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/approval_models.dart';
import '../tenant_context.dart';

final approvalRepositoryProvider = Provider<ApprovalRepository>(
  (ref) => ApprovalRepository(
    Supabase.instance.client,
    ref.watch(tenantContextProvider),
  ),
);

class ApprovalRepository {
  ApprovalRepository(this._supabase, this._tenantContext);

  final SupabaseClient _supabase;
  final TenantContext _tenantContext;

  Future<String> _requireTenant() => _tenantContext.currentTenantId();

  Future<List<ApprovalRequest>> fetchRequests({
    ApprovalStatus? status,
    String? branchId,
  }) async {
    final tenantId = await _requireTenant();
    var query = _supabase
        .from('approval_requests')
        .select()
        .eq('tenant_id', tenantId);
    if (status != null) query = query.eq('status', status.databaseValue);
    if (branchId != null && branchId.isNotEmpty) {
      query = query.eq('branch_id', branchId);
    }
    final response = await query.order('created_at', ascending: false);
    return response
        .map((row) => ApprovalRequest.fromJson(row))
        .toList(growable: false);
  }

  Future<List<ApprovalRequestEvent>> fetchEvents(String requestId) async {
    await _requireTenant();
    final response = await _supabase
        .from('approval_request_events')
        .select()
        .eq('approval_request_id', requestId)
        .order('created_at');
    return response
        .map((row) => ApprovalRequestEvent.fromJson(row))
        .toList(growable: false);
  }

  Future<ApprovalRequest> createRequest({
    required ApprovalRequestType requestType,
    required int amountMinor,
    required String currencyCode,
    required String reason,
    Map<String, dynamic> payload = const {},
    String? targetId,
    String? branchId,
    String? idempotencyKey,
  }) async {
    final tenantId = await _requireTenant();
    if (amountMinor < 0) {
      throw ArgumentError.value(amountMinor, 'amountMinor');
    }
    final normalizedCurrency = currencyCode.trim().toUpperCase();
    if (!RegExp(r'^[A-Z]{3,5}$').hasMatch(normalizedCurrency)) {
      throw ArgumentError.value(currencyCode, 'currencyCode');
    }
    final normalizedReason = reason.trim();
    if (normalizedReason.isEmpty || normalizedReason.length > 1000) {
      throw ArgumentError.value(reason, 'reason');
    }

    final response = await _supabase.rpc(
      'create_approval_request',
      params: {
        'p_tenant_id': tenantId,
        'p_request_type': requestType.databaseValue,
        'p_target_id': targetId,
        'p_payload': payload,
        'p_amount_minor': amountMinor,
        'p_currency_code': normalizedCurrency,
        'p_reason': normalizedReason,
        'p_branch_id': branchId,
        'p_idempotency_key': idempotencyKey?.trim(),
      },
    );
    if (response is! Map) {
      throw const PostgrestException(
        message: 'Approval request RPC returned no result.',
        code: 'MIZAN_APPROVAL_INVALID_RESPONSE',
      );
    }
    return ApprovalRequest.fromJson(Map<String, dynamic>.from(response));
  }

  Future<ApprovalRequest> decideRequest({
    required String requestId,
    required ApprovalStatus decision,
    String? reason,
  }) async {
    if (decision == ApprovalStatus.pending) {
      throw ArgumentError.value(decision, 'decision');
    }
    final response = await _supabase.rpc(
      'decide_approval_request',
      params: {
        'p_request_id': requestId,
        'p_decision': decision.databaseValue,
        'p_reason': reason?.trim(),
      },
    );
    if (response is! Map) {
      throw const PostgrestException(
        message: 'Approval decision RPC returned no result.',
        code: 'MIZAN_APPROVAL_INVALID_RESPONSE',
      );
    }
    return ApprovalRequest.fromJson(Map<String, dynamic>.from(response));
  }
}
