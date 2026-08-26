import 'package:core_data/core_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class AiAgentException implements Exception {
  const AiAgentException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

class AiGuestModeException extends AiAgentException {
  const AiGuestModeException()
    : super(
        'MIZAN_AI_GUEST_MODE',
        'The AI Copilot is available after connecting an authenticated tenant.',
      );
}

class AiChatMessage {
  const AiChatMessage({required this.role, required this.content});

  final String role;
  final String content;
}

class AiAgentResponse {
  const AiAgentResponse({
    required this.conversationId,
    required this.requestId,
    required this.message,
    required this.readOnly,
    this.model,
  });

  factory AiAgentResponse.fromData(Map<String, dynamic> data) {
    final message = data['message'];
    final conversationId = data['conversation_id'];
    final requestId = data['request_id'];
    if (message is! String ||
        message.trim().isEmpty ||
        conversationId is! String ||
        requestId is! String) {
      throw const AiAgentException(
        'MIZAN_AI_INVALID_RESPONSE',
        'The AI assistant returned an invalid response.',
      );
    }
    return AiAgentResponse(
      conversationId: conversationId,
      requestId: requestId,
      message: message,
      model: data['model'] is String ? data['model'] as String : null,
      readOnly: data['read_only'] == true,
    );
  }

  final String conversationId;
  final String requestId;
  final String message;
  final String? model;
  final bool readOnly;
}

class AiAgentRepository {
  AiAgentRepository({
    required SupabaseClient supabase,
    required TenantContext tenantContext,
    required bool cloudMode,
  }) : _supabase = supabase,
       _tenantContext = tenantContext,
       _cloudMode = cloudMode;

  final SupabaseClient _supabase;
  final TenantContext _tenantContext;
  final bool _cloudMode;

  Future<AiAgentResponse> sendMessage({
    required String message,
    required String locale,
    String? conversationId,
  }) async {
    if (!_cloudMode || _supabase.auth.currentSession == null) {
      throw const AiGuestModeException();
    }
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty || trimmedMessage.length > 8_000) {
      throw const AiAgentException(
        'MIZAN_AI_INVALID_MESSAGE',
        'The message must contain between 1 and 8000 characters.',
      );
    }

    final tenantId = await _tenantContext.currentTenantId();
    final response = await _supabase.functions.invoke(
      'mizan-ai-agent',
      body: {
        'message': trimmedMessage,
        'locale': locale == 'ar' ? 'ar' : 'en',
        'tenant_id': tenantId,
        if (conversationId != null) 'conversation_id': conversationId,
      },
    );
    final data = response.data;
    if (response.status < 200 || response.status >= 300) {
      final errorData = data is Map
          ? Map<String, dynamic>.from(data)
          : const {};
      throw AiAgentException(
        'MIZAN_AI_HTTP_${response.status}',
        _safeError(errorData['error']),
      );
    }
    if (data is! Map) {
      throw const AiAgentException(
        'MIZAN_AI_INVALID_RESPONSE',
        'The AI assistant returned an invalid response.',
      );
    }
    return AiAgentResponse.fromData(Map<String, dynamic>.from(data));
  }

  Future<AiActionRequest> createActionDraft({
    required String actionType,
    required Map<String, dynamic> payload,
    String? conversationId,
  }) async {
    if (!_cloudMode || _supabase.auth.currentSession == null) {
      throw const AiGuestModeException();
    }
    final tenantId = await _tenantContext.currentTenantId();
    final response = await _supabase.functions.invoke(
      'mizan-ai-action',
      body: {
        'action': 'create_draft',
        'action_type': actionType,
        'payload': payload,
        'tenant_id': tenantId,
        'idempotency_key': const Uuid().v4(),
        if (conversationId != null) 'conversation_id': conversationId,
      },
    );
    return _parseActionResponse(response);
  }

  Future<AiActionRequest> cancelActionDraft(String actionRequestId) async {
    if (!_cloudMode || _supabase.auth.currentSession == null) {
      throw const AiGuestModeException();
    }
    final tenantId = await _tenantContext.currentTenantId();
    final response = await _supabase.functions.invoke(
      'mizan-ai-action',
      body: {
        'action': 'cancel',
        'action_request_id': actionRequestId,
        'tenant_id': tenantId,
      },
    );
    return _parseActionResponse(response);
  }

  Future<AiActionRequest> confirmActionDraft(String actionRequestId) async {
    if (!_cloudMode || _supabase.auth.currentSession == null) {
      throw const AiGuestModeException();
    }
    final tenantId = await _tenantContext.currentTenantId();
    final response = await _supabase.functions.invoke(
      'mizan-ai-action',
      body: {
        'action': 'confirm',
        'action_request_id': actionRequestId,
        'tenant_id': tenantId,
      },
    );
    return _parseActionResponse(response);
  }

  AiActionRequest _parseActionResponse(FunctionResponse response) {
    final data = response.data;
    if (response.status < 200 || response.status >= 300) {
      final errorData = data is Map
          ? Map<String, dynamic>.from(data)
          : const {};
      throw AiAgentException(
        'MIZAN_AI_ACTION_HTTP_${response.status}',
        _safeError(errorData['error']),
      );
    }
    if (data is! Map || data['action_request'] is! Map) {
      throw const AiAgentException(
        'MIZAN_AI_INVALID_ACTION_RESPONSE',
        'The AI action draft returned an invalid response.',
      );
    }
    return AiActionRequest.fromJson(
      Map<String, dynamic>.from(data['action_request'] as Map),
    );
  }

  String _safeError(Object? value) {
    switch (value) {
      case 'Authentication required':
        return 'Authentication is required for the AI Copilot.';
      case 'Active tenant membership required':
      case 'Tenant selection is required':
        return 'An active tenant membership is required for the AI Copilot.';
      case 'AI is not configured':
      case 'AI provider is not configured correctly':
        return 'The AI service is not configured yet.';
      case 'AI assistant is temporarily unavailable':
        return 'The AI assistant is temporarily unavailable. Please try again later.';
      default:
        return 'The AI assistant could not complete this request.';
    }
  }
}

class AiActionRequest {
  const AiActionRequest({
    required this.id,
    required this.actionType,
    required this.payload,
    required this.preview,
    required this.status,
    required this.expiresAt,
    this.createdAt,
  });

  factory AiActionRequest.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final actionType = json['action_type'];
    final status = json['status'];
    final payload = json['payload'];
    final preview = json['preview'];
    final expiresAt = json['expires_at'];
    if (id is! String ||
        actionType is! String ||
        status is! String ||
        payload is! Map ||
        preview is! Map ||
        expiresAt is! String) {
      throw const AiAgentException(
        'MIZAN_AI_INVALID_ACTION_RESPONSE',
        'The AI action draft returned an invalid response.',
      );
    }
    return AiActionRequest(
      id: id,
      actionType: actionType,
      payload: Map<String, dynamic>.from(payload),
      preview: Map<String, dynamic>.from(preview),
      status: status,
      expiresAt: DateTime.tryParse(expiresAt),
      createdAt: json['created_at'] is String
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  final String id;
  final String actionType;
  final Map<String, dynamic> payload;
  final Map<String, dynamic> preview;
  final String status;
  final DateTime? expiresAt;
  final DateTime? createdAt;
}

final aiAgentRepositoryProvider = Provider<AiAgentRepository>((ref) {
  return AiAgentRepository(
    supabase: Supabase.instance.client,
    tenantContext: ref.watch(tenantContextProvider),
    cloudMode: ref.watch(cloudDataModeProvider),
  );
});
