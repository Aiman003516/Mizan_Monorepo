import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../tenant_context.dart';

final crmPipelineRepositoryProvider = Provider<CrmPipelineRepository>((ref) {
  return CrmPipelineRepository(
    Supabase.instance.client,
    ref.watch(tenantContextProvider),
  );
});

class CrmPipelineStage {
  const CrmPipelineStage({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.probabilityPercent,
    required this.isWon,
    required this.isLost,
    required this.isActive,
  });

  final String id;
  final String name;
  final int sortOrder;
  final double probabilityPercent;
  final bool isWon;
  final bool isLost;
  final bool isActive;

  factory CrmPipelineStage.fromJson(Map<String, dynamic> json) {
    return CrmPipelineStage(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      probabilityPercent:
          (json['probability_percent'] as num?)?.toDouble() ?? 0,
      isWon: json['is_won'] == true,
      isLost: json['is_lost'] == true,
      isActive: json['is_active'] != false,
    );
  }
}

class CrmLead {
  const CrmLead({
    required this.id,
    required this.displayName,
    required this.email,
    required this.phone,
    required this.companyName,
    required this.source,
    required this.status,
    required this.ownerStaffMemberId,
    required this.updatedAt,
  });

  final String id;
  final String displayName;
  final String? email;
  final String? phone;
  final String? companyName;
  final String? source;
  final String status;
  final String? ownerStaffMemberId;
  final DateTime? updatedAt;

  factory CrmLead.fromJson(Map<String, dynamic> json) {
    return CrmLead(
      id: json['id']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      companyName: json['company_name']?.toString(),
      source: json['source']?.toString(),
      status: json['status']?.toString() ?? 'new',
      ownerStaffMemberId: json['owner_staff_member_id']?.toString(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }
}

class CrmOpportunity {
  const CrmOpportunity({
    required this.id,
    required this.title,
    required this.stageId,
    required this.stageName,
    required this.ownerStaffMemberId,
    required this.customerId,
    required this.leadId,
    required this.amountMinor,
    required this.currencyCode,
    required this.expectedCloseOn,
    required this.status,
    required this.probabilityPercent,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String stageId;
  final String? stageName;
  final String? ownerStaffMemberId;
  final String? customerId;
  final String? leadId;
  final int amountMinor;
  final String currencyCode;
  final DateTime? expectedCloseOn;
  final String status;
  final double probabilityPercent;
  final DateTime? updatedAt;

  factory CrmOpportunity.fromJson(Map<String, dynamic> json) {
    final stage = json['crm_pipeline_stages'];
    return CrmOpportunity(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      stageId: json['stage_id']?.toString() ?? '',
      stageName: stage is Map ? stage['name']?.toString() : null,
      ownerStaffMemberId: json['owner_staff_member_id']?.toString(),
      customerId: json['customer_id']?.toString(),
      leadId: json['lead_id']?.toString(),
      amountMinor: (json['amount_minor'] as num?)?.toInt() ?? 0,
      currencyCode: json['currency_code']?.toString() ?? 'USD',
      expectedCloseOn: DateTime.tryParse(
        json['expected_close_on']?.toString() ?? '',
      ),
      status: json['status']?.toString() ?? 'open',
      probabilityPercent:
          (json['probability_percent'] as num?)?.toDouble() ?? 0,
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }
}

class CrmActivity {
  const CrmActivity({
    required this.id,
    required this.activityType,
    required this.subject,
    required this.body,
    required this.dueAt,
    required this.completedAt,
    required this.ownerStaffMemberId,
    required this.createdAt,
  });

  final String id;
  final String activityType;
  final String subject;
  final String? body;
  final DateTime? dueAt;
  final DateTime? completedAt;
  final String? ownerStaffMemberId;
  final DateTime? createdAt;

  factory CrmActivity.fromJson(Map<String, dynamic> json) {
    return CrmActivity(
      id: json['id']?.toString() ?? '',
      activityType: json['activity_type']?.toString() ?? 'note',
      subject: json['subject']?.toString() ?? '',
      body: json['body']?.toString(),
      dueAt: DateTime.tryParse(json['due_at']?.toString() ?? ''),
      completedAt: DateTime.tryParse(json['completed_at']?.toString() ?? ''),
      ownerStaffMemberId: json['owner_staff_member_id']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

class CrmPipelineRepository {
  CrmPipelineRepository(this._supabase, this._tenantContext);

  final SupabaseClient _supabase;
  final TenantContext _tenantContext;

  bool get hasAuthenticatedUser => _supabase.auth.currentUser != null;

  Future<String> _tenantId() => _tenantContext.currentTenantId();

  Future<List<CrmPipelineStage>> listStages() async {
    final tenantId = await _tenantId();
    final rows = await _supabase
        .from('crm_pipeline_stages')
        .select()
        .eq('tenant_id', tenantId)
        .eq('is_active', true)
        .order('sort_order');
    return rows
        .whereType<Map>()
        .map((row) => CrmPipelineStage.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  Future<List<CrmLead>> listLeads({String? status}) async {
    final tenantId = await _tenantId();
    var query = _supabase
        .from('crm_leads')
        .select()
        .eq('tenant_id', tenantId)
        .eq('is_deleted', false);
    if (status != null && status.isNotEmpty) query = query.eq('status', status);
    final rows = await query.order('updated_at', ascending: false);
    return rows
        .whereType<Map>()
        .map((row) => CrmLead.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  Future<List<CrmOpportunity>> listOpportunities({String? status}) async {
    final tenantId = await _tenantId();
    var query = _supabase
        .from('crm_opportunities')
        .select('*, crm_pipeline_stages(name)')
        .eq('tenant_id', tenantId)
        .eq('is_deleted', false);
    if (status != null && status.isNotEmpty) query = query.eq('status', status);
    final rows = await query.order('updated_at', ascending: false);
    return rows
        .whereType<Map>()
        .map((row) => CrmOpportunity.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  Future<List<CrmActivity>> listActivities({
    String? leadId,
    String? opportunityId,
    String? customerId,
  }) async {
    final tenantId = await _tenantId();
    var query = _supabase
        .from('crm_activities')
        .select()
        .eq('tenant_id', tenantId)
        .eq('is_deleted', false);
    if (leadId != null) query = query.eq('lead_id', leadId);
    if (opportunityId != null)
      query = query.eq('opportunity_id', opportunityId);
    if (customerId != null) query = query.eq('customer_id', customerId);
    final rows = await query.order('created_at', ascending: false);
    return rows
        .whereType<Map>()
        .map((row) => CrmActivity.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> transitionOpportunity({
    required String opportunityId,
    required String stageId,
    String? note,
  }) async {
    final result = await _supabase.rpc(
      'transition_crm_opportunity',
      params: {
        'p_opportunity_id': opportunityId,
        'p_stage_id': stageId,
        if (note?.trim().isNotEmpty == true) 'p_note': note!.trim(),
      },
    );
    if (result is! Map) {
      throw const PostgrestException(
        message: 'CRM stage transition returned no result.',
        code: 'MIZAN_CRM_INVALID_RESPONSE',
      );
    }
    return Map<String, dynamic>.from(result);
  }
}
