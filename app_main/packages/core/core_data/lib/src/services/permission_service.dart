// FILE: packages/core/core_data/lib/src/services/permission_service.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  return PermissionService(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
});

class PermissionService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // 🛡️ TEMP: Hardcoded for Phase 4 development.
  // In Phase 5 (Invites), this will come from the User Profile.
  static const String _debugTenantId = 'test_tenant_123';

  PermissionService(this._firestore, this._auth);

  /// 🕵️‍♂️ WATCHER: Live stream of the user's power level.
  Stream<AppRole> watchCurrentUserRole() {
    return _auth.authStateChanges().switchMap((user) {
      if (user == null) {
        // Not logged in? No powers.
        return Stream.value(_guestRole());
      }

      // 1. Listen to the User Document in the Tenant
      // Path: tenants/{tenantId}/members/{uid}
      final memberDocRef = _firestore
          .collection('tenants')
          .doc(_debugTenantId)
          .collection('members')
          .doc(user.uid);

      return memberDocRef.snapshots().switchMap((memberSnapshot) {
        if (!memberSnapshot.exists) {
          // User logged in, but not part of this business? Guest.
          return Stream.value(_guestRole());
        }

        final data = memberSnapshot.data();
        final roleId = data?['roleId'] as String?;
        final isOwner = data?['isOwner'] as bool? ?? false;

        // 👑 OWNER OVERRIDE
        if (isOwner) {
          return Stream.value(AppRole.owner());
        }

        if (roleId == null) return Stream.value(_guestRole());

        // 2. Fetch the Role Definition
        // Path: tenants/{tenantId}/roles/{roleId}
        return _firestore
            .collection('tenants')
            .doc(_debugTenantId)
            .collection('roles')
            .doc(roleId)
            .snapshots()
            .map((roleSnapshot) {
          if (!roleSnapshot.exists) return _guestRole();
          return AppRole.fromJson(roleSnapshot.data()!, roleSnapshot.id);
        });
      });
    });
  }

  /// 💀 FALLBACK: The Guest Role (No Permissions)
  AppRole _guestRole() {
    return const AppRole(
      id: 'guest',
      name: 'Guest',
      permissions: [],
    );
  }
}

// 🔧 UTILITY EXTENSION (RxDart-style switchMap for native Streams)
extension _StreamSwitchMap<T> on Stream<T> {
  Stream<R> switchMap<R>(Stream<R> Function(T event) mapper) {
    return map(mapper).asyncExpand((stream) => stream);
  }
}