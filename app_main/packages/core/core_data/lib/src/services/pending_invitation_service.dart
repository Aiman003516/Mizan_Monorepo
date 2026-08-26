import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../preferences_repository.dart';

final pendingInvitationServiceProvider = Provider<PendingInvitationService>((
  ref,
) {
  return PendingInvitationService(ref.watch(sharedPreferencesProvider));
});

final pendingInvitationProvider = StateProvider<PendingInvitation?>((ref) {
  return ref.watch(pendingInvitationServiceProvider).read();
});

class PendingInvitation {
  const PendingInvitation({
    required this.code,
    this.tenantId,
    this.roleId,
    this.recipientEmail,
    this.recipientPhone,
    this.displayName,
    this.token,
    this.stage = 'code',
    this.expiresAt,
  });

  final String code;
  final String? tenantId;
  final String? roleId;
  final String? recipientEmail;
  final String? recipientPhone;
  final String? displayName;
  final String? token;
  final String stage;
  final DateTime? expiresAt;

  Map<String, dynamic> toJson() => {
    'code': code,
    if (tenantId != null) 'tenantId': tenantId,
    if (roleId != null) 'roleId': roleId,
    if (recipientEmail != null) 'recipientEmail': recipientEmail,
    if (recipientPhone != null) 'recipientPhone': recipientPhone,
    if (displayName != null) 'displayName': displayName,
    if (token != null) 'token': token,
    'stage': stage,
    if (expiresAt != null) 'expiresAt': expiresAt!.toUtc().toIso8601String(),
  };

  static PendingInvitation? fromJson(Map<String, dynamic> json) {
    final code = json['code'] as String?;
    if (code == null || !RegExp(r'^\d{6}$').hasMatch(code)) return null;
    final expiresAt = DateTime.tryParse(json['expiresAt'] as String? ?? '');
    if (expiresAt != null &&
        !expiresAt.toUtc().isAfter(DateTime.now().toUtc())) {
      return null;
    }
    return PendingInvitation(
      code: code,
      tenantId: json['tenantId'] as String?,
      roleId: json['roleId'] as String?,
      recipientEmail: json['recipientEmail'] as String?,
      recipientPhone: json['recipientPhone'] as String?,
      displayName: json['displayName'] as String?,
      token: json['token'] as String?,
      stage: json['stage'] as String? ?? 'code',
      expiresAt: expiresAt,
    );
  }
}

class PendingInvitationService {
  PendingInvitationService(this._preferences);

  static const _key = 'pending_invitation_context';
  final SharedPreferences _preferences;

  PendingInvitation? read() {
    final raw = _preferences.getString(_key);
    if (raw == null) return null;
    try {
      final value = PendingInvitation.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
      if (value == null) {
        _preferences.remove(_key);
      }
      return value;
    } catch (_) {
      _preferences.remove(_key);
      return null;
    }
  }

  Future<PendingInvitation?> save({
    required String code,
    String? tenantId,
    String? roleId,
    String? recipientEmail,
    String? recipientPhone,
    String? displayName,
    String? token,
    String stage = 'code',
    DateTime? expiresAt,
  }) async {
    final invitation = PendingInvitation(
      code: code.trim(),
      tenantId: tenantId,
      roleId: roleId,
      recipientEmail: recipientEmail,
      recipientPhone: recipientPhone,
      displayName: displayName,
      token: token,
      stage: stage,
      expiresAt: expiresAt,
    );
    await _preferences.setString(_key, jsonEncode(invitation.toJson()));
    return invitation;
  }

  Future<void> clear() => _preferences.remove(_key);
}
