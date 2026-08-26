import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/erp_domain_contracts.dart';
import '../tenant_context.dart';

final extensionRegistryRepositoryProvider =
    Provider<ExtensionRegistryRepository>(
      (ref) => ExtensionRegistryRepository(
        Supabase.instance.client,
        ref.watch(tenantContextProvider),
      ),
    );

class ReviewedExtension {
  const ReviewedExtension({
    required this.id,
    required this.extensionKey,
    required this.displayName,
    required this.version,
    required this.hook,
    required this.capabilities,
    required this.configuration,
    required this.status,
    required this.reviewedAt,
  });

  final String id;
  final String extensionKey;
  final String displayName;
  final String version;
  final ExtensionHook hook;
  final Set<String> capabilities;
  final Map<String, dynamic> configuration;
  final String status;
  final DateTime? reviewedAt;

  bool get enabled => status == 'approved';

  ExtensionDescriptor get descriptor => ExtensionDescriptor(
    id: id,
    name: displayName,
    version: version,
    hook: hook,
    capabilities: capabilities,
    enabled: enabled,
  );

  factory ReviewedExtension.fromJson(Map<String, dynamic> json) {
    final rawCapabilities = json['capabilities'];
    return ReviewedExtension(
      id: json['id']?.toString() ?? '',
      extensionKey: json['extension_key']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      version: json['version']?.toString() ?? '',
      hook: ExtensionHook.values.firstWhere(
        (hook) => hook.wireValue == json['hook']?.toString(),
        orElse: () => ExtensionHook.preValidate,
      ),
      capabilities: rawCapabilities is List
          ? rawCapabilities.map((value) => value.toString()).toSet()
          : const <String>{},
      configuration: json['configuration'] is Map
          ? Map<String, dynamic>.from(json['configuration'] as Map)
          : const <String, dynamic>{},
      status: json['status']?.toString() ?? 'proposed',
      reviewedAt: DateTime.tryParse(json['reviewed_at']?.toString() ?? ''),
    );
  }
}

class ExtensionRegistryRepository {
  ExtensionRegistryRepository(this._supabase, this._tenantContext);

  final SupabaseClient _supabase;
  final TenantContext _tenantContext;

  Future<String> _tenantId() => _tenantContext.currentTenantId();

  Future<Map<String, dynamic>> register({
    required String extensionKey,
    required String displayName,
    required String version,
    required ExtensionHook hook,
    required Set<String> capabilities,
    Map<String, dynamic> configuration = const {},
  }) async {
    await _tenantId();
    final response = await _supabase.rpc(
      'register_erp_extension',
      params: {
        'p_extension_key': extensionKey.trim(),
        'p_display_name': displayName.trim(),
        'p_version': version.trim(),
        'p_hook': hook.wireValue,
        'p_capabilities': capabilities.toList(growable: false),
        'p_configuration': configuration,
      },
    );
    if (response is! Map) {
      throw const PostgrestException(
        message: 'Extension registration returned no result.',
        code: 'MIZAN_EXTENSION_INVALID_RESPONSE',
      );
    }
    return Map<String, dynamic>.from(response);
  }

  Future<List<ReviewedExtension>> list({String? hook}) async {
    await _tenantId();
    final response = await _supabase.rpc(
      'list_erp_extensions',
      params: {'p_hook': hook},
    );
    if (response is! List) {
      throw const PostgrestException(
        message: 'Extension registry returned no result.',
        code: 'MIZAN_EXTENSION_LIST_INVALID_RESPONSE',
      );
    }
    return response
        .whereType<Map>()
        .map(
          (row) => ReviewedExtension.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> review({
    required String extensionId,
    required String status,
    required String reviewNote,
  }) async {
    await _tenantId();
    final response = await _supabase.rpc(
      'review_erp_extension',
      params: {
        'p_extension_id': extensionId,
        'p_status': status,
        'p_review_note': reviewNote.trim(),
      },
    );
    if (response is! Map) {
      throw const PostgrestException(
        message: 'Extension review returned no result.',
        code: 'MIZAN_EXTENSION_REVIEW_INVALID_RESPONSE',
      );
    }
    return Map<String, dynamic>.from(response);
  }
}
