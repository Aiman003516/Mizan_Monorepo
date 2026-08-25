import 'package:core_data/core_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class CustomFieldsRepository {
  final SupabaseClient _supabase;

  CustomFieldsRepository(this._supabase);

  Stream<List<CustomFieldDefinition>> watchDefinitions(
    String tenantId,
    String targetTable,
  ) {
    return _supabase
        .from('custom_fields')
        .stream(primaryKey: ['id'])
        .eq('tenant_id', tenantId)
        .eq('target_table', targetTable)
        .order('label')
        .map(
          (snapshot) => snapshot
              .map((doc) => CustomFieldDefinition.fromJson(doc, doc['id']))
              .toList(growable: false),
        );
  }

  Future<void> saveDefinition(
    String tenantId,
    CustomFieldDefinition def,
  ) async {
    final normalizedKey = def.key.trim().toLowerCase();
    final normalizedLabel = def.label.trim();
    if (!RegExp(r'^[a-z][a-z0-9_]{0,62}$').hasMatch(normalizedKey)) {
      throw const FormatException(
        'Custom field keys must use snake_case letters, numbers, and underscores.',
      );
    }
    if (normalizedLabel.isEmpty || normalizedLabel.length > 120) {
      throw const FormatException(
        'Custom field labels must contain 1 to 120 characters.',
      );
    }
    const supportedTargets = {
      'products',
      'accounts',
      'transactions',
      'customers',
      'vendors',
    };
    if (!supportedTargets.contains(def.targetTable)) {
      throw const FormatException('Unsupported custom field target.');
    }

    final defId = def.id.isEmpty || def.id == 'new'
        ? const Uuid().v4()
        : def.id;
    final data = def.toJson()
      ..['key'] = normalizedKey
      ..['label'] = normalizedLabel
      ..['id'] = defId
      ..['tenant_id'] = tenantId;

    await _supabase.from('custom_fields').upsert(data, onConflict: 'id');
  }

  Future<void> deleteDefinition(String tenantId, String defId) async {
    await _supabase
        .from('custom_fields')
        .delete()
        .eq('id', defId)
        .eq('tenant_id', tenantId);
  }
}

final customFieldsRepositoryProvider = Provider<CustomFieldsRepository>((ref) {
  return CustomFieldsRepository(Supabase.instance.client);
});

final productFieldsProvider =
    StreamProvider.family<List<CustomFieldDefinition>, String>((ref, tenantId) {
      return ref
          .watch(customFieldsRepositoryProvider)
          .watchDefinitions(tenantId, 'products');
    });
