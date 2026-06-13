import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';

/// Simple RBAC Service for role-based access control.
class RbacService {
  final AppDatabase _db;

  RbacService(this._db);

  /// Assigns a role to a user.
  Future<void> assignRole(String userId, String role) async {
    // Remove existing role first
    await (_db.delete(
      _db.userRoles,
    )..where((r) => r.userId.equals(userId))).go();

    await _db
        .into(_db.userRoles)
        .insert(UserRolesCompanion.insert(userId: userId, role: role));
  }

  /// Gets the role for a user.
  Future<String?> getRole(String userId) async {
    final entry = await (_db.select(
      _db.userRoles,
    )..where((r) => r.userId.equals(userId))).getSingleOrNull();
    return entry?.role;
  }

  /// Checks if user has permission.
  bool canEdit(String? role) {
    return role == 'admin' || role == 'editor';
  }

  bool canDelete(String? role) {
    return role == 'admin';
  }

  bool canViewReports(String? role) {
    return role != null; // All roles can view
  }
}

final rbacServiceProvider = Provider((ref) {
  final db = ref.watch(appDatabaseProvider);
  return RbacService(db);
});
