import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../tenant_context.dart';

final documentIntakeRepositoryProvider = Provider<DocumentIntakeRepository>(
  (ref) => DocumentIntakeRepository(
    Supabase.instance.client,
    ref.watch(tenantContextProvider),
  ),
);

class DocumentAnomaly {
  const DocumentAnomaly({
    required this.id,
    required this.ruleCode,
    required this.severity,
    required this.message,
    required this.evidence,
  });

  final String id;
  final String ruleCode;
  final String severity;
  final String message;
  final Map<String, dynamic> evidence;

  factory DocumentAnomaly.fromJson(Map<String, dynamic> json) {
    return DocumentAnomaly(
      id: json['anomaly_id']?.toString() ?? json['id']?.toString() ?? '',
      ruleCode: json['rule_code']?.toString() ?? '',
      severity: json['severity']?.toString() ?? 'medium',
      message: json['message']?.toString() ?? '',
      evidence: json['evidence'] is Map
          ? Map<String, dynamic>.from(json['evidence'] as Map)
          : const <String, dynamic>{},
    );
  }
}

class AiPolicyContext {
  const AiPolicyContext({
    required this.policyCode,
    required this.scope,
    required this.action,
    required this.policyText,
  });

  final String policyCode;
  final String scope;
  final String action;
  final String policyText;

  factory AiPolicyContext.fromJson(Map<String, dynamic> json) {
    return AiPolicyContext(
      policyCode: json['policy_code']?.toString() ?? '',
      scope: json['scope']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      policyText: json['policy_text']?.toString() ?? '',
    );
  }
}

class DocumentIntakeRepository {
  DocumentIntakeRepository(this._supabase, this._tenantContext);

  final SupabaseClient _supabase;
  final TenantContext _tenantContext;

  Future<String> _tenantId() => _tenantContext.currentTenantId();

  Future<Map<String, dynamic>> createIntake({
    required String sourceType,
    String? sourceId,
    required String storagePath,
    required String fileName,
    required String mimeType,
    String? sha256,
  }) async {
    await _tenantId();
    final response = await _supabase.rpc(
      'create_document_intake',
      params: {
        'p_source_type': sourceType,
        'p_source_id': sourceId,
        'p_storage_path': storagePath.trim(),
        'p_file_name': fileName.trim(),
        'p_mime_type': mimeType.trim(),
        'p_sha256': sha256?.trim().toLowerCase(),
      },
    );
    return _requireMap(response, 'MIZAN_DOCUMENT_INTAKE_INVALID_RESPONSE');
  }

  Future<Map<String, dynamic>> recordExtractionDraft({
    required String documentId,
    required String provider,
    String? version,
    Map<String, dynamic> extractedData = const {},
  }) async {
    await _tenantId();
    final response = await _supabase.rpc(
      'record_document_extraction_draft',
      params: {
        'p_document_id': documentId,
        'p_provider': provider.trim(),
        'p_version': version?.trim(),
        'p_extracted_data': extractedData,
      },
    );
    return _requireMap(response, 'MIZAN_DOCUMENT_EXTRACTION_INVALID_RESPONSE');
  }

  Future<List<DocumentAnomaly>> runAnomalyRules(String documentId) async {
    await _tenantId();
    final response = await _supabase.rpc(
      'run_document_anomaly_rules',
      params: {'p_document_id': documentId},
    );
    if (response is! List) {
      throw const PostgrestException(
        message: 'Document anomaly scan returned no result.',
        code: 'MIZAN_DOCUMENT_ANOMALY_INVALID_RESPONSE',
      );
    }
    return response
        .whereType<Map>()
        .map((row) => DocumentAnomaly.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  Future<List<AiPolicyContext>> retrievePolicyContext({
    required String scope,
    required String action,
  }) async {
    await _tenantId();
    final response = await _supabase.rpc(
      'retrieve_ai_policy_context',
      params: {'p_scope': scope.trim(), 'p_action': action.trim()},
    );
    if (response is! List) {
      throw const PostgrestException(
        message: 'AI policy context returned no result.',
        code: 'MIZAN_AI_POLICY_INVALID_RESPONSE',
      );
    }
    return response
        .whereType<Map>()
        .map((row) => AiPolicyContext.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  Map<String, dynamic> _requireMap(dynamic response, String code) {
    if (response is! Map) {
      throw PostgrestException(
        message: 'Document operation returned no result.',
        code: code,
      );
    }
    return Map<String, dynamic>.from(response);
  }
}
