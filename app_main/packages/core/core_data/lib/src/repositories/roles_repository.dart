import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/rbac_models.dart';

final rolesRepositoryProvider = Provider<RolesRepository>((ref) {
  return RolesRepository(Supabase.instance.client);
});

final rolesStreamProvider = StreamProvider.autoDispose<List<AppRole>>((ref) {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) return Stream.value([]);
  
  return supabase
      .from('user_profiles')
      .stream(primaryKey: ['id'])
      .eq('id', user.id)
      .map((profiles) {
        if (profiles.isEmpty) return null;
        return profiles.first['tenant_id'] as String?;
      })
      .asyncExpand((tenantId) {
        if (tenantId == null) return Stream.value(<AppRole>[]);
        return ref.watch(rolesRepositoryProvider).watchAllRoles(tenantId);
      });
});

class RolesRepository {
  final SupabaseClient _supabase;

  RolesRepository(this._supabase);

  /// 🕵️‍♂️ Watch all roles for this tenant
  Stream<List<AppRole>> watchAllRoles(String tenantId) {
    return _supabase
        .from('roles')
        .stream(primaryKey: ['id'])
        .eq('tenant_id', tenantId)
        .map((snapshot) {
      return snapshot
          .map((doc) => AppRole.fromJson(doc, doc['id'] as String))
          .toList();
    });
  }

  Future<String> _getTenantId() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not logged in');
    final res = await _supabase.from('user_profiles').select('tenant_id').eq('id', user.id).maybeSingle();
    if (res == null || res['tenant_id'] == null) throw Exception('Tenant ID not found');
    return res['tenant_id'] as String;
  }

  /// 📝 Create or Update a Role
  Future<void> saveRole(AppRole role) async {
    final tenantId = await _getTenantId();
    final roleId = role.id.isEmpty ? const Uuid().v4() : role.id;

    await _supabase.from('roles').upsert({
      'id': roleId,
      'tenant_id': tenantId,
      'name': role.name,
      'permissions': role.permissions.map((e) => e.name).toList(),
      'is_system_admin': role.isSystemAdmin,
    });
  }

  /// 🗑️ Delete a Role
  Future<void> deleteRole(String roleId) async {
    final tenantId = await _getTenantId();
    // Safety: Don't allow deleting the Owner role
    if (roleId == 'owner') {
      throw Exception("Cannot delete the System Administrator role.");
    }

    await _supabase
        .from('roles')
        .delete()
        .eq('id', roleId)
        .eq('tenant_id', tenantId);
  }
}
