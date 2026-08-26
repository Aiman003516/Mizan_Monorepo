import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/rbac_models.dart';

class StaffInvitation {
  const StaffInvitation({
    required this.id,
    required this.email,
    required this.roleId,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String roleId;
  final String status;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  factory StaffInvitation.fromJson(Map<String, dynamic> json) {
    return StaffInvitation(
      id: json['id'] as String? ?? '',
      email: (json['recipient_email'] ?? json['email'] ?? '') as String,
      roleId: json['role_id'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? ''),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}

class BulkInvitationResult {
  const BulkInvitationResult({
    required this.email,
    required this.success,
    this.code,
  });

  final String email;
  final bool success;
  final String? code;

  factory BulkInvitationResult.fromJson(Map<String, dynamic> json) {
    return BulkInvitationResult(
      email: json['email'] as String? ?? '',
      success: json['success'] == true,
      code: json['code'] as String?,
    );
  }
}

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  return StaffRepository(Supabase.instance.client);
});

final staffStreamProvider = StreamProvider.autoDispose<List<StaffMember>>((
  ref,
) {
  final repository = ref.watch(staffRepositoryProvider);
  return repository.watchCurrentTenantStaff();
});

final invitationsStreamProvider =
    StreamProvider.autoDispose<List<StaffInvitation>>((ref) {
      return ref.watch(staffRepositoryProvider).watchInvitations();
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
              .eq('tenant_id', tenantId)) {
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

  Stream<List<StaffInvitation>> watchInvitations() async* {
    final tenantId = await _getTenantId();
    Future<List<StaffInvitation>> fetch() async {
      final rows = await _supabase
          .from('invites')
          .select(
            'id,recipient_email,email,role_id,status,expires_at,created_at',
          )
          .eq('tenant_id', tenantId)
          .order('created_at', ascending: false);
      return (rows as List)
          .map(
            (row) =>
                StaffInvitation.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList(growable: false);
    }

    try {
      yield await fetch();
    } catch (_) {
      yield const <StaffInvitation>[];
      return;
    }
    try {
      await for (final _
          in _supabase
              .from('invites')
              .stream(primaryKey: ['id'])
              .eq('tenant_id', tenantId)) {
        try {
          yield await fetch();
        } catch (_) {
          // Preserve the last successful invitation snapshot.
        }
      }
    } catch (_) {
      // Realtime is optional; the REST snapshot remains usable.
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
              .eq('tenant_id', tenantId)) {
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

  Future<void> setStaffStatus(String uid, String status) async {
    await _supabase.rpc(
      'set_staff_status',
      params: {'p_user_id': uid, 'p_status': status},
    );
  }

  Future<void> removeStaffMember(String uid) async {
    await setStaffStatus(uid, 'removed');
  }

  Future<void> revokeInvitation(String invitationId) async {
    await _supabase.rpc(
      'revoke_invitation',
      params: {'p_invitation_id': invitationId},
    );
  }

  Future<String> createInvite(String roleId, {String? recipientEmail}) async {
    try {
      final result = await _supabase.rpc(
        'create_invitation',
        params: {
          'p_role_id': roleId,
          'p_recipient_email': recipientEmail?.trim().toLowerCase(),
        },
      );
      if (result is Map && result['code'] is String) {
        return result['code'] as String;
      }
      throw const PostgrestException(
        message: 'Invitation creation returned no code.',
        code: 'MIZAN_INVITE_INVALID_RESPONSE',
      );
    } on PostgrestException catch (error) {
      // Do not silently downgrade an email-bound invite to an unbound code.
      if (!_isMissingInvitationFunction(error, 'create_invitation') ||
          recipientEmail?.trim().isNotEmpty == true) {
        rethrow;
      }
    }

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

  bool _isMissingInvitationFunction(
    PostgrestException error,
    String functionName,
  ) {
    final message = error.message.toLowerCase();
    return error.code == '42883' ||
        message.contains(functionName) &&
            (message.contains('does not exist') ||
                message.contains('function'));
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

    try {
      final result = await _supabase.rpc(
        'redeem_invitation',
        params: {'p_code': code.trim(), 'p_display_name': displayName.trim()},
      );
      if (result is Map && result['role_id'] is String) {
        return result['role_id'] as String;
      }
    } on PostgrestException catch (error) {
      if (!_isMissingInvitationFunction(error, 'redeem_invitation')) rethrow;
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

  Future<List<BulkInvitationResult>> createInvitationsBulk({
    required String roleId,
    required List<String> emails,
  }) async {
    final normalizedEmails = emails
        .map((email) => email.trim().toLowerCase())
        .where((email) => email.isNotEmpty)
        .toSet()
        .toList();
    if (normalizedEmails.isEmpty || normalizedEmails.length > 100) {
      throw const PostgrestException(
        message: 'Bulk invitations require between 1 and 100 recipients.',
        code: 'MIZAN_INVITE_BATCH_SIZE',
      );
    }
    final result = await _supabase.rpc(
      'create_invitations_bulk',
      params: {
        'p_role_id': roleId,
        'p_recipient_emails': normalizedEmails,
        'p_idempotency_key': const Uuid().v4(),
      },
    );
    if (result is! Map || result['results'] is! List) {
      throw const PostgrestException(
        message: 'Bulk invitation creation returned no results.',
        code: 'MIZAN_INVITE_INVALID_RESPONSE',
      );
    }
    return (result['results'] as List)
        .whereType<Map>()
        .map(
          (row) =>
              BulkInvitationResult.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<Map<String, dynamic>?> validateInviteCode(String code) async {
    try {
      final result = await _supabase.rpc(
        'validate_invitation',
        params: {'p_code': code.trim()},
      );
      if (result is! Map) return null;
      final data = Map<String, dynamic>.from(result);
      return {
        'id': data['id'],
        'roleId': data['role_id'],
        'roleName': data['role_name'],
        'tenantId': data['tenant_id'],
        'tenantName': data['tenant_name'],
        'recipientEmail': data['recipient_email'],
        'displayName': data['display_name'],
        'expiresAt': data['expires_at'],
      };
    } on PostgrestException catch (error) {
      if (!_isMissingInvitationFunction(error, 'validate_invitation')) rethrow;
    }

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
