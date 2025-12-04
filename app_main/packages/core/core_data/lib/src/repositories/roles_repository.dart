import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rbac_models.dart';
import '../services/permission_service.dart';

final rolesRepositoryProvider = Provider<RolesRepository>((ref) {
  return RolesRepository(FirebaseFirestore.instance);
});

final rolesStreamProvider = StreamProvider.autoDispose<List<AppRole>>((ref) {
  return ref.watch(rolesRepositoryProvider).watchAllRoles();
});

class RolesRepository {
  final FirebaseFirestore _firestore;
  
  // 🛡️ Phase 4 Hardcoded Tenant. In Phase 5, this comes from User Profile.
  static const String _tenantId = 'test_tenant_123';

  RolesRepository(this._firestore);

  /// 🕵️‍♂️ Watch all roles for this tenant
  Stream<List<AppRole>> watchAllRoles() {
    return _firestore
        .collection('tenants')
        .doc(_tenantId)
        .collection('roles')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AppRole.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  /// 📝 Create or Update a Role
  Future<void> saveRole(AppRole role) async {
    final docRef = _firestore
        .collection('tenants')
        .doc(_tenantId)
        .collection('roles')
        .doc(role.id.isEmpty ? null : role.id); // null ID = Auto-generate

    // If new, we need to ensure the ID in the object matches the generated ID
    final roleToSave = AppRole(
      id: docRef.id,
      name: role.name,
      permissions: role.permissions,
      isSystemAdmin: role.isSystemAdmin,
    );

    await docRef.set(roleToSave.toJson());
  }

  /// 🗑️ Delete a Role
  Future<void> deleteRole(String roleId) async {
    // Safety: Don't allow deleting the Owner role
    if (roleId == 'owner') {
      throw Exception("Cannot delete the System Administrator role.");
    }

    await _firestore
        .collection('tenants')
        .doc(_tenantId)
        .collection('roles')
        .doc(roleId)
        .delete();
  }
}