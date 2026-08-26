import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/rbac_models.dart';

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  return StaffRepository(Supabase.instance.client);
});

final staffStreamProvider = StreamProvider.autoDispose<List<StaffMember>>((
  ref,
) {
  final repository = ref.watch(staffRepositoryProvider);
  return repository.watchCurrentTenantStaff();
});

class StaffRepository {
  final SupabaseClient _supabase;

  StaffRepository(this._supabase);

  Stream<List<StaffMember>> watchCurrentTenantStaff() async* {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      yield const <StaffMember>[];
      return;
    }

    String tenantId;
    try {
      // REST is the source for the first render. A user_profiles Realtime
      // channel must not be required just to open Employee Management.
      tenantId = await _getTenantId();
      yield await _fetchStaff(tenantId);
    } catch (_) {
      yield const <StaffMember>[];
      return;
    }

    try {
      // Realtime is an optional refresh enhancement. If the project has not
      // enabled the publication, the REST snapshot above remains usable.
      await for (final _
          in _supabase
              .from('staff_members')
              .stream(primaryKey: ['id'])
              .eq('tenant_id', tenantId)
              .eq('status', 'active')) {
        try {
          yield await _fetchStaff(tenantId);
        } catch (_) {
          // Preserve the last successful staff snapshot.
        }
      }
    } catch (_) {
      // Nonfatal when Realtime is unavailable or not configured.
    }
  }

  Stream<List<StaffMember>> watchAllStaff(String tenantId) async* {
    try {
      yield await _fetchStaff(tenantId);
    } catch (_) {
      yield const <StaffMember>[];
      return;
    }

    try {
      await for (final _
          in _supabase
              .from('staff_members')
              .stream(primaryKey: ['id'])
              .eq('tenant_id', tenantId)
              .eq('status', 'active')) {
        try {
          yield await _fetchStaff(tenantId);
        } catch (_) {
          // Preserve the last successful snapshot.
        }
      }
    } catch (_) {
      // Nonfatal Realtime enhancement failure.
    }
  }

  Future<List<StaffMember>> _fetchStaff(String tenantId) async {
    final rows = await _supabase
        .from('staff_members')
        .select(
          'id,user_id,role_id,status,created_at,user_profiles(email,display_name)',
        )
        .eq('tenant_id', tenantId)
        .eq('status', 'active')
        .order('created_at');
    return (rows as List)
        .map(
          (row) => StaffMember.fromJson(Map<String, dynamic>.from(row as Map)),
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

  Future<void> updateStaffRole(String uid, String newRoleId) async {
    final tenantId = await _getTenantId();
    await _supabase
        .from('staff_members')
        .update({'role_id': newRoleId})
        .eq('user_id', uid)
        .eq('tenant_id', tenantId)
        .eq('status', 'active');
  }

  Future<void> removeStaffMember(String uid) async {
    final tenantId = await _getTenantId();
    await _supabase
        .from('staff_members')
        .update({'status': 'removed'})
        .eq('user_id', uid)
        .eq('tenant_id', tenantId)
        .eq('status', 'active');
  }

  Future<String> createInvite(String roleId) async {
    final result = await _supabase.rpc(
      'create_invite',
      params: {'p_role_id': roleId},
    );
    if (result is String && result.isNotEmpty) return result;
    throw const PostgrestException(
      message: 'Invite creation returned no code.',
      code: 'MIZAN_INVITE_INVALID_RESPONSE',
    );
  }

  Future<String> redeemInvite({
    required String code,
    required String userId,
    required String displayName,
    String? email,
  }) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      throw const AuthException('Authentication is required.');
    }
    if (currentUser.id != userId) {
      throw const AuthException(
        'The signed-in user does not match the invite request.',
      );
    }

    final result = await _supabase.rpc(
      'redeem_invite',
      params: {'p_code': code.trim(), 'p_display_name': displayName.trim()},
    );
    if (result is Map && result['role_id'] is String) {
      return result['role_id'] as String;
    }
    throw const PostgrestException(
      message: 'Invite redemption returned no role.',
      code: 'MIZAN_INVITE_INVALID_RESPONSE',
    );
  }

  Future<Map<String, dynamic>?> validateInviteCode(String code) async {
    final result = await _supabase.rpc(
      'validate_invite',
      params: {'p_code': code.trim()},
    );
    if (result is! Map) return null;
    final data = Map<String, dynamic>.from(result);
    return {
      'roleId': data['role_id'],
      'tenantId': data['tenant_id'],
      'expiresAt': data['expires_at'],
    };
  }
}
