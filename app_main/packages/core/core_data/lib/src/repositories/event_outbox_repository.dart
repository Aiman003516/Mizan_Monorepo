import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../tenant_context.dart';

final eventOutboxRepositoryProvider = Provider<EventOutboxRepository>(
  (ref) => EventOutboxRepository(
    Supabase.instance.client,
    ref.watch(tenantContextProvider),
  ),
);

class ErpOutboxEvent {
  const ErpOutboxEvent({
    required this.id,
    required this.tenantId,
    required this.eventName,
    required this.aggregateType,
    required this.aggregateId,
    required this.eventVersion,
    required this.idempotencyKey,
    required this.payload,
    required this.attemptCount,
  });

  final String id;
  final String tenantId;
  final String eventName;
  final String aggregateType;
  final String? aggregateId;
  final int eventVersion;
  final String idempotencyKey;
  final Map<String, dynamic> payload;
  final int attemptCount;

  factory ErpOutboxEvent.fromJson(Map<String, dynamic> json) {
    return ErpOutboxEvent(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenant_id']?.toString() ?? '',
      eventName: json['event_name']?.toString() ?? '',
      aggregateType: json['aggregate_type']?.toString() ?? '',
      aggregateId: json['aggregate_id']?.toString(),
      eventVersion: (json['event_version'] as num?)?.toInt() ?? 1,
      idempotencyKey: json['idempotency_key']?.toString() ?? '',
      payload: json['payload'] is Map
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : const <String, dynamic>{},
      attemptCount: (json['attempt_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class SyncConflict {
  const SyncConflict({
    required this.id,
    required this.clientMutationId,
    required this.entityType,
    required this.entityId,
    required this.localPayload,
    required this.serverPayload,
    required this.conflictFields,
    required this.status,
  });

  final String id;
  final String clientMutationId;
  final String entityType;
  final String? entityId;
  final Map<String, dynamic> localPayload;
  final Map<String, dynamic> serverPayload;
  final List<dynamic> conflictFields;
  final String status;

  factory SyncConflict.fromJson(Map<String, dynamic> json) {
    return SyncConflict(
      id: json['id']?.toString() ?? '',
      clientMutationId: json['client_mutation_id']?.toString() ?? '',
      entityType: json['entity_type']?.toString() ?? '',
      entityId: json['entity_id']?.toString(),
      localPayload: json['local_payload'] is Map
          ? Map<String, dynamic>.from(json['local_payload'] as Map)
          : const <String, dynamic>{},
      serverPayload: json['server_payload'] is Map
          ? Map<String, dynamic>.from(json['server_payload'] as Map)
          : const <String, dynamic>{},
      conflictFields: json['conflict_fields'] is List
          ? List<dynamic>.from(json['conflict_fields'] as List)
          : const <dynamic>[],
      status: json['status']?.toString() ?? 'open',
    );
  }
}

class EventOutboxRepository {
  EventOutboxRepository(this._supabase, this._tenantContext);

  final SupabaseClient _supabase;
  final TenantContext _tenantContext;

  Future<String> _tenantId() => _tenantContext.currentTenantId();

  Future<String> enqueue({
    required String eventName,
    required String aggregateType,
    String? aggregateId,
    int eventVersion = 1,
    required String idempotencyKey,
    Map<String, dynamic> payload = const {},
  }) async {
    await _tenantId();
    if (eventName.trim().isEmpty ||
        aggregateType.trim().isEmpty ||
        idempotencyKey.trim().length < 8 ||
        eventVersion <= 0) {
      throw const PostgrestException(
        message: 'ERP event envelope is invalid.',
        code: 'MIZAN_EVENT_INVALID_INPUT',
      );
    }
    final response = await _supabase.rpc(
      'enqueue_erp_event',
      params: {
        'p_event_name': eventName.trim(),
        'p_aggregate_type': aggregateType.trim(),
        'p_aggregate_id': aggregateId,
        'p_event_version': eventVersion,
        'p_idempotency_key': idempotencyKey.trim(),
        'p_payload': payload,
      },
    );
    if (response is! String) {
      throw const PostgrestException(
        message: 'ERP event enqueue returned no identifier.',
        code: 'MIZAN_EVENT_INVALID_RESPONSE',
      );
    }
    return response;
  }

  Future<List<ErpOutboxEvent>> claim({
    required String workerId,
    int limit = 50,
  }) async {
    await _tenantId();
    final response = await _supabase.rpc(
      'claim_erp_events',
      params: {'p_worker_id': workerId.trim(), 'p_limit': limit},
    );
    if (response is! List) {
      throw const PostgrestException(
        message: 'ERP event claim returned no result.',
        code: 'MIZAN_EVENT_CLAIM_INVALID_RESPONSE',
      );
    }
    return response
        .whereType<Map>()
        .map((row) => ErpOutboxEvent.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> complete({
    required String eventId,
    required String workerId,
    required String status,
    String? error,
    int retrySeconds = 300,
  }) async {
    await _tenantId();
    final response = await _supabase.rpc(
      'complete_erp_event',
      params: {
        'p_event_id': eventId,
        'p_worker_id': workerId.trim(),
        'p_status': status,
        'p_error': error?.trim(),
        'p_retry_seconds': retrySeconds,
      },
    );
    if (response is! Map) {
      throw const PostgrestException(
        message: 'ERP event completion returned no result.',
        code: 'MIZAN_EVENT_COMPLETE_INVALID_RESPONSE',
      );
    }
    return Map<String, dynamic>.from(response);
  }

  Future<List<SyncConflict>> listConflicts({bool openOnly = true}) async {
    final tenantId = await _tenantId();
    var query = _supabase
        .from('sync_conflicts')
        .select()
        .eq('tenant_id', tenantId);
    if (openOnly) query = query.eq('status', 'open');
    final response = await query.order('created_at', ascending: false);
    return response
        .whereType<Map>()
        .map((row) => SyncConflict.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  Future<String> recordConflict({
    required String clientMutationId,
    required String entityType,
    String? entityId,
    required Map<String, dynamic> localPayload,
    required Map<String, dynamic> serverPayload,
    required List<String> conflictFields,
  }) async {
    await _tenantId();
    final response = await _supabase.rpc(
      'record_sync_conflict',
      params: {
        'p_client_mutation_id': clientMutationId.trim(),
        'p_entity_type': entityType.trim(),
        'p_entity_id': entityId,
        'p_local_payload': localPayload,
        'p_server_payload': serverPayload,
        'p_conflict_fields': conflictFields,
      },
    );
    if (response is! String) {
      throw const PostgrestException(
        message: 'Sync conflict returned no identifier.',
        code: 'MIZAN_CONFLICT_INVALID_RESPONSE',
      );
    }
    return response;
  }

  Future<Map<String, dynamic>> resolveConflict({
    required String conflictId,
    required String status,
    required String resolutionNote,
  }) async {
    await _tenantId();
    final response = await _supabase.rpc(
      'resolve_sync_conflict',
      params: {
        'p_conflict_id': conflictId,
        'p_status': status,
        'p_resolution_note': resolutionNote.trim(),
      },
    );
    if (response is! Map) {
      throw const PostgrestException(
        message: 'Sync conflict resolution returned no result.',
        code: 'MIZAN_CONFLICT_RESOLUTION_INVALID_RESPONSE',
      );
    }
    return Map<String, dynamic>.from(response);
  }
}
