import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rbac_models.dart';

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  return StaffRepository(FirebaseFirestore.instance);
});

final staffStreamProvider = StreamProvider.autoDispose<List<StaffMember>>((ref) {
  return ref.watch(staffRepositoryProvider).watchAllStaff();
});

class StaffRepository {
  final FirebaseFirestore _firestore;
  
  // 🛡️ Phase 4 Hardcoded Tenant.
  static const String _tenantId = 'test_tenant_123';

  StaffRepository(this._firestore);

  /// 🕵️‍♂️ Watch all members of this tenant
  Stream<List<StaffMember>> watchAllStaff() {
    return _firestore
        .collection('tenants')
        .doc(_tenantId)
        .collection('members')
        .orderBy('joinedAt', descending: true) // Newest first
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => StaffMember.fromJson(doc.data()))
          .toList();
    });
  }

  /// 🔄 Change a staff member's role
  Future<void> updateStaffRole(String uid, String newRoleId) async {
    await _firestore
        .collection('tenants')
        .doc(_tenantId)
        .collection('members')
        .doc(uid)
        .update({'roleId': newRoleId});
  }

  /// 🚫 Remove/Suspend a staff member
  Future<void> removeStaffMember(String uid) async {
    // We don't delete the doc (to keep history), we just mark status/access.
    // But for Phase 4, let's just delete the member record to revoke access.
    await _firestore
        .collection('tenants')
        .doc(_tenantId)
        .collection('members')
        .doc(uid)
        .delete();
  }


  /// 🎟️ CREATE INVITE CODE
  /// Generates a 6-digit code valid for 24 hours.
  /// Returns the code string.
  Future<String> createInvite(String roleId) async {
    // 1. Generate secure random 6-digit code
    // (Simple math version for brevity, use crypto in high security)
    final String code = (100000 + DateTime.now().microsecondsSinceEpoch % 899999).toString();
    
    final expiresAt = DateTime.now().add(const Duration(hours: 24));

    // 2. Save to Firestore
    // Path: tenants/{id}/invites/{code}
    await _firestore
        .collection('tenants')
        .doc(_tenantId)
        .collection('invites')
        .doc(code)
        .set({
      'code': code,
      'roleId': roleId,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'createdBy': _firestore.collection('users').doc('current_user_placeholder').id, // Optional audit
      'isUsed': false,
    });

    return code;
  }
}