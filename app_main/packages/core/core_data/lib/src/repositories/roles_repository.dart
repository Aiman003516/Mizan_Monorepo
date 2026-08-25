import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/rbac_models.dart';

final rolesRepositoryProvider = Provider<RolesRepository>((ref) {
  return RolesRepository(Supabase.instance.client);
});

final rolesStreamProvider = StreamProvider.autoDispose<List<AppRole>>((ref) {
  final repository = ref.watch(rolesRepositoryProvider);
  return repository.watchCurrentTenantRoles();
});

class RolesRepository {
  final SupabaseClient _supabase;

  RolesRepository(this._supabase);

  Stream<List<AppRole>> watchCurrentTenantRoles() async* {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      yield const <AppRole>[];
      return;
    }

    String tenantId;
    try {
      tenantId = await _getTenantId();
    } catch (_) {
      // A guest, incomplete membership, or unavailable backend should render
      // as an empty admin surface rather than leak a transport exception.
      yield const <AppRole>[];
      return;
    }

    try {
      // REST is the source for the initial state. Realtime is an enhancement,
      // not a prerequisite for opening the Roles screen.
      yield await _fetchRoles(tenantId);

      try {
        await for (final rows
            in _supabase
                .from('roles')
                .stream(primaryKey: ['id'])
                .eq('tenant_id', tenantId)
                .order('name')) {
          yield rows
              .map(
                (row) => AppRole.fromJson(
                  Map<String, dynamic>.from(row),
                  row['id'] as String,
                ),
              )
              .toList(growable: false);
        }
      } catch (_) {
        // Keep the REST snapshot visible when the project has not enabled the
        // affected table in supabase_realtime.
      }
    } catch (_) {
      yield const <AppRole>[];
    }
  }

  Stream<List<AppRole>> watchAllRoles(String tenantId) {
    return _supabase
        .from('roles')
        .stream(primaryKey: ['id'])
        .eq('tenant_id', tenantId)
        .order('name')
        .map(
          (rows) => rows
              .map(
                (row) => AppRole.fromJson(
                  Map<String, dynamic>.from(row),
                  row['id'] as String,
                ),
              )
              .toList(growable: false),
        );
  }

  Future<List<AppRole>> _fetchRoles(String tenantId) async {
    final rows = await _supabase
        .from('roles')
        .select('id,name,permissions,is_system_admin')
        .eq('tenant_id', tenantId)
        .order('name');
    return (rows as List)
        .map(
          (row) => AppRole.fromJson(
            Map<String, dynamic>.from(row as Map),
            row['id'] as String,
          ),
        )
        .toList(growable: false);
  }

  Future<String> _getTenantId() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw const AuthException('Authentication is required.');

    final row = await _supabase
        .from('staff_members')
        .select('tenant_id')
        .eq('user_id', user.id)
        .eq('status', 'active')
        .order('created_at')
        .limit(1)
        .maybeSingle();
    final tenantId = row?['tenant_id'] as String?;
    if (tenantId == null || tenantId.isEmpty) {
      throw const PostgrestException(
        message: 'Tenant membership was not found.',
        code: 'MIZAN_TENANT_NOT_FOUND',
      );
    }
    return tenantId;
  }

  Future<void> saveRole(AppRole role) async {
    final tenantId = await _getTenantId();
    if (role.isSystemAdmin) {
      throw const PostgrestException(
        message: 'System administrator roles are managed by the system.',
        code: 'MIZAN_SYSTEM_ROLE_PROTECTED',
      );
    }

    final roleId = role.id.isEmpty ? const Uuid().v4() : role.id;
    await _supabase.from('roles').upsert({
      'id': roleId,
      'tenant_id': tenantId,
      'name': role.name.trim(),
      'permissions': role.permissions
          .map((permission) => permission.name)
          .toList(),
      'is_system_admin': false,
      if (role.id.isEmpty) 'created_by': _supabase.auth.currentUser!.id,
    }, onConflict: 'id');
  }

  Future<void> deleteRole(String roleId) async {
    final tenantId = await _getTenantId();
    final role = await _supabase
        .from('roles')
        .select('is_system_admin')
        .eq('id', roleId)
        .eq('tenant_id', tenantId)
        .maybeSingle();
    if (role?['is_system_admin'] == true) {
      throw const PostgrestException(
        message: 'System administrator roles are managed by the system.',
        code: 'MIZAN_SYSTEM_ROLE_PROTECTED',
      );
    }

    await _supabase
        .from('roles')
        .delete()
        .eq('id', roleId)
        .eq('tenant_id', tenantId);
  }
}
