import 'dart:async';

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

  Stream<AppRole> watchCurrentUserRole() {
    return _supabase.auth.onAuthStateChange.switchMap((authState) {
      final user = authState.session?.user;
      if (user == null) return Stream.value(AppRole.guest());

      return _supabase
          .from('user_profiles')
          .stream(primaryKey: ['id'])
          .eq('id', user.id)
          .asyncExpand((profiles) {
            final tenantId = profiles.isEmpty
                ? null
                : profiles.first['tenant_id'] as String?;
            if (tenantId == null || tenantId.isEmpty) {
              return Stream.value(AppRole.guest());
            }

            return _supabase
                .from('staff_members')
                .stream(primaryKey: ['id'])
                .eq('tenant_id', tenantId)
                .eq('user_id', user.id)
                .eq('status', 'active')
                .asyncExpand((memberships) {
                  if (memberships.isEmpty) {
                    return Stream.value(AppRole.guest());
                  }
                  final roleId = memberships.first['role_id'] as String?;
                  if (roleId == null || roleId.isEmpty) {
                    return Stream.value(AppRole.guest());
                  }
                  return _supabase
                      .from('roles')
                      .stream(primaryKey: ['id'])
                      .eq('tenant_id', tenantId)
                      .eq('id', roleId)
                      .map(
                        (roles) => roles.isEmpty
                            ? AppRole.guest()
                            : AppRole.fromJson(
                                roles.first,
                                roles.first['id'] as String,
                              ),
                      );
                });
          });
    });
  }
}

extension _StreamSwitchMap<T> on Stream<T> {
  Stream<R> switchMap<R>(Stream<R> Function(T event) mapper) {
    return asyncExpand(mapper);
  }
}
