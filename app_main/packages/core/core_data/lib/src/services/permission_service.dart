// FILE: packages/core/core_data/lib/src/services/permission_service.dart

import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rbac_models.dart';

/// 🛡️ THE GATEKEEPER PROVIDER
/// This is the primary way the UI asks: "What can I do?"
/// Usage: final role = ref.watch(userRoleProvider);
final userRoleProvider = StreamProvider<AppRole>((ref) {
  final service = ref.watch(permissionServiceProvider);
  return service.watchCurrentUserRole();
});

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService(Supabase.instance.client);
});

class PermissionService {
  final SupabaseClient _supabase;

  PermissionService(this._supabase);

  /// 🕵️‍♂️ WATCHER: Live stream of the user's power level.
  Stream<AppRole> watchCurrentUserRole() {
    return _supabase.auth.onAuthStateChange.switchMap((authState) {
      final user = authState.session?.user;
      if (user == null) {
        // Not logged in? No powers.
        return Stream.value(_guestRole());
      }

      // 1. Listen to the Staff Members table
      return _supabase
          .from('staff_members')
          .stream(primaryKey: ['id'])
          .eq('user_id', user.id)
          .switchMap((staffMaps) {
        if (staffMaps.isEmpty) {
          return Stream.value(_guestRole());
        }

        final data = staffMaps.first;
        final roleId = data['role_id'] as String?;

        if (roleId == null) return Stream.value(_guestRole());

        // 👑 OWNER OVERRIDE (For backward compatibility in testing)
        if (roleId == 'owner') {
          return Stream.value(AppRole.owner());
        }

        // 2. Fetch the Role Definition from 'roles' table
        return _supabase
            .from('roles')
            .stream(primaryKey: ['id'])
            .eq('id', roleId)
            .map((roleMaps) {
          if (roleMaps.isEmpty) return _guestRole();
          return AppRole.fromJson(roleMaps.first, roleMaps.first['id']);
        });
      });
    });
  }

  /// 💀 FALLBACK: The Guest Role (Now bypassed for testing)
  AppRole _guestRole() {
    return AppRole.owner();
  }
}

// 🔧 UTILITY EXTENSION (RxDart-style switchMap for native Streams)
extension _StreamSwitchMap<T> on Stream<T> {
  Stream<R> switchMap<R>(Stream<R> Function(T event) mapper) {
    return map(mapper).asyncExpand((stream) => stream);
  }
}
