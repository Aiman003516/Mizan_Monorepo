import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/rbac_models.dart';

/// The primary authorization stream used by PermissionGuard and Settings.
final userRoleProvider = StreamProvider<AppRole>((ref) {
  return ref.watch(permissionServiceProvider).watchCurrentUserRole();
});

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService(Supabase.instance.client);
});

class PermissionService {
  final SupabaseClient _supabase;

  PermissionService(this._supabase);

  /// Loads the current role from REST first. Realtime is not required for
  /// authorization UI and must not turn a settings page into a raw transport
  /// error when a table is missing from the project's publication.
  Stream<AppRole> watchCurrentUserRole() async* {
    final initialUser = _supabase.auth.currentUser;
    yield await _safeLoadRole(initialUser);

    await for (final authState in _supabase.auth.onAuthStateChange) {
      yield await _safeLoadRole(authState.session?.user);
    }
  }

  Future<AppRole> _safeLoadRole(User? user) async {
    if (user == null) return AppRole.guest();
    try {
      return await _loadRole(user);
    } catch (_) {
      return AppRole.guest();
    }
  }

  Future<AppRole> _loadRole(User user) async {
    final profile = await _supabase
        .from('user_profiles')
        .select('tenant_id')
        .eq('id', user.id)
        .maybeSingle();
    final tenantId = profile?['tenant_id'] as String?;
    if (tenantId == null || tenantId.isEmpty) return AppRole.guest();

    final membership = await _supabase
        .from('staff_members')
        .select('role_id,roles(id,name,permissions,is_system_admin)')
        .eq('tenant_id', tenantId)
        .eq('user_id', user.id)
        .eq('status', 'active')
        .maybeSingle();
    final roleMap = membership?['roles'] is Map
        ? Map<String, dynamic>.from(membership!['roles'] as Map)
        : null;
    final roleId = membership?['role_id'] as String?;
    if (roleMap == null || roleId == null || roleId.isEmpty) {
      return AppRole.guest();
    }

    return AppRole.fromJson(<String, dynamic>{
      ...roleMap,
      'id': roleId,
    }, roleId);
  }
}
