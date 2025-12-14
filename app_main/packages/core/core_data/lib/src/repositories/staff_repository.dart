import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rbac_models.dart';

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  return StaffRepository(FirebaseFirestore.instance);
});

final staffStreamProvider = StreamProvider.autoDispose<List<StaffMember>>((
  ref,
) {
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
    final String code =
        (100000 + DateTime.now().microsecondsSinceEpoch % 899999).toString();

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
          'createdBy': _firestore
              .collection('users')
              .doc('current_user_placeholder')
              .id, // Optional audit
          'isUsed': false,
        });

    return code;
  }

  /// 🎟️ REDEEM INVITE CODE
  /// Validates an invite code and adds the user to the organization.
  /// Returns the roleId if successful, throws on error.
  Future<String> redeemInvite({
    required String code,
    required String userId,
    required String displayName,
    String? email,
  }) async {
    // 1. Get the invite document
    final inviteDoc = await _firestore
        .collection('tenants')
        .doc(_tenantId)
        .collection('invites')
        .doc(code)
        .get();

    if (!inviteDoc.exists) {
      throw Exception('Invalid invite code');
    }

    final inviteData = inviteDoc.data()!;

    // 2. Check if already used
    if (inviteData['isUsed'] == true) {
      throw Exception('This invite code has already been used');
    }

    // 3. Check expiration
    final expiresAt = (inviteData['expiresAt'] as Timestamp).toDate();
    if (DateTime.now().isAfter(expiresAt)) {
      throw Exception('This invite code has expired');
    }

    final roleId = inviteData['roleId'] as String;

    // 4. Add user to members collection
    await _firestore
        .collection('tenants')
        .doc(_tenantId)
        .collection('members')
        .doc(userId)
        .set({
          'uid': userId,
          'displayName': displayName,
          'email': email ?? '',
          'roleId': roleId,
          'joinedAt': FieldValue.serverTimestamp(),
          'inviteCode': code,
        });

    // 5. Mark invite as used
    await _firestore
        .collection('tenants')
        .doc(_tenantId)
        .collection('invites')
        .doc(code)
        .update({
          'isUsed': true,
          'usedBy': userId,
          'usedAt': FieldValue.serverTimestamp(),
        });

    return roleId;
  }

  /// 🔍 VALIDATE INVITE CODE (without redeeming)
  /// Returns invite details if valid, null if invalid
  Future<Map<String, dynamic>?> validateInviteCode(String code) async {
    final inviteDoc = await _firestore
        .collection('tenants')
        .doc(_tenantId)
        .collection('invites')
        .doc(code)
        .get();

    if (!inviteDoc.exists) return null;

    final data = inviteDoc.data()!;

    // Check if valid
    if (data['isUsed'] == true) return null;

    final expiresAt = (data['expiresAt'] as Timestamp).toDate();
    if (DateTime.now().isAfter(expiresAt)) return null;

    return data;
  }
}
