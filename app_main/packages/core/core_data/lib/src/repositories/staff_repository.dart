import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rbac_models.dart';

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  return StaffRepository(Supabase.instance.client);
});

final staffStreamProvider = StreamProvider.autoDispose<List<StaffMember>>((ref) {
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
        if (tenantId == null) return Stream.value(<StaffMember>[]);
        return ref.watch(staffRepositoryProvider).watchAllStaff(tenantId);
      });
});

class StaffRepository {
  final SupabaseClient _supabase;

  StaffRepository(this._supabase);

  Future<String> _getTenantId() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not logged in');
    final res = await _supabase.from('user_profiles').select('tenant_id').eq('id', user.id).maybeSingle();
    if (res == null || res['tenant_id'] == null) throw Exception('Tenant ID not found');
    return res['tenant_id'] as String;
  }

  /// 🕵️‍♂️ Watch all members of this tenant
  Stream<List<StaffMember>> watchAllStaff(String tenantId) {
    // In our schema, user_profiles acts as members table
    return _supabase
        .from('user_profiles')
        .stream(primaryKey: ['id'])
        .eq('tenant_id', tenantId)
        .map((snapshot) {
          return snapshot.map((doc) => StaffMember(
            uid: doc['id'],
            email: doc['email'] ?? '',
            displayName: doc['display_name'] ?? 'Unknown',
            roleId: doc['role'] ?? 'guest',
            isOwner: doc['role'] == 'owner',
            status: 'active',
          )).toList();
        });
  }

  /// 🔄 Change a staff member's role
  Future<void> updateStaffRole(String uid, String newRoleId) async {
    final tenantId = await _getTenantId();
    await _supabase
        .from('user_profiles')
        .update({'role': newRoleId})
        .eq('id', uid)
        .eq('tenant_id', tenantId);
  }

  /// 🚫 Remove/Suspend a staff member
  Future<void> removeStaffMember(String uid) async {
    final tenantId = await _getTenantId();
    // For Phase 4, we just remove them from the tenant by setting tenant_id to null
    await _supabase
        .from('user_profiles')
        .update({'tenant_id': null, 'role': 'guest'})
        .eq('id', uid)
        .eq('tenant_id', tenantId);
  }

  /// 🎟️ CREATE INVITE CODE
  Future<String> createInvite(String roleId) async {
    final tenantId = await _getTenantId();
    final String code = (100000 + DateTime.now().microsecondsSinceEpoch % 899999).toString();
    final expiresAt = DateTime.now().add(const Duration(hours: 24));

    await _supabase.from('invites').insert({
      'code': code,
      'tenant_id': tenantId,
      'role_id': roleId,
      'expires_at': expiresAt.toIso8601String(),
      'created_by': _supabase.auth.currentUser?.id,
      'is_used': false,
    });

    return code;
  }

  /// 🎟️ REDEEM INVITE CODE
  Future<String> redeemInvite({
    required String code,
    required String userId,
    required String displayName,
    String? email,
  }) async {
    // 1. Get the invite document
    final inviteDoc = await _supabase.from('invites').select().eq('code', code).maybeSingle();

    if (inviteDoc == null) throw Exception('Invalid invite code');
    if (inviteDoc['is_used'] == true) throw Exception('This invite code has already been used');

    final expiresAt = DateTime.parse(inviteDoc['expires_at']);
    if (DateTime.now().isAfter(expiresAt)) throw Exception('This invite code has expired');

    final tenantId = inviteDoc['tenant_id'] as String;
    final roleId = inviteDoc['role_id'] as String;

    // 2. Add user to members collection (Update user_profiles)
    await _supabase.from('user_profiles').upsert({
      'id': userId,
      'tenant_id': tenantId,
      'display_name': displayName,
      'email': email ?? '',
      'role': roleId,
    });

    // 3. Mark invite as used
    await _supabase.from('invites').update({
      'is_used': true,
      'used_by': userId,
      'used_at': DateTime.now().toIso8601String(),
    }).eq('code', code);

    return roleId;
  }

  /// 🔍 VALIDATE INVITE CODE (without redeeming)
  Future<Map<String, dynamic>?> validateInviteCode(String code) async {
    final inviteDoc = await _supabase.from('invites').select().eq('code', code).maybeSingle();

    if (inviteDoc == null) return null;
    if (inviteDoc['is_used'] == true) return null;

    final expiresAt = DateTime.parse(inviteDoc['expires_at']);
    if (DateTime.now().isAfter(expiresAt)) return null;

    // Map back to camelCase for UI compatibility if needed
    return {
      'roleId': inviteDoc['role_id'],
      'tenantId': inviteDoc['tenant_id'],
      'expiresAt': inviteDoc['expires_at'],
    };
  }
}
