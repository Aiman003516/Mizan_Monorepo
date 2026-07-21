import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:core_data/core_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        .map((snapshot) {
          return snapshot
              .where((doc) => doc['target_table'] == targetTable)
              .map((doc) => CustomFieldDefinition.fromJson(doc, doc['id']))
              .toList();
        });
  }

  /// Add or Update a Definition
  Future<void> saveDefinition(
    String tenantId,
    CustomFieldDefinition def,
  ) async {
    final defId = def.id.isEmpty || def.id == 'new'
        ? const Uuid().v4()
        : def.id;

    final data = def.toJson();
    data['id'] = defId;
    data['tenant_id'] = tenantId;

    await _supabase.from('custom_fields').upsert(data);
  }

  /// Delete a Definition
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

// Helper Stream: Get Product Fields
final productFieldsProvider =
    StreamProvider.family<List<CustomFieldDefinition>, String>((ref, tenantId) {
      return ref
          .watch(customFieldsRepositoryProvider)
          .watchDefinitions(tenantId, 'products');
    });
