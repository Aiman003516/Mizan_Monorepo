// FILE: packages/core/core_data/lib/src/services/saas_seeding_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/rbac_models.dart';

final saasSeedingServiceProvider = Provider<SaasSeedingService>((ref) {
  return SaasSeedingService(
    Supabase.instance.client,
  );
});

class SaasSeedingService {
  final SupabaseClient _supabase;

  SaasSeedingService(this._supabase);

  /// 👑 ACTIVATION PROTOCOL
  /// This runs ONCE when the buyer sets up their system.
  /// It creates the 'Owner' role and assigns the current user to it.
  Future<void> activateSystemForBuyer(String tenantId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception("⛔ Authentication required to activate system.");
    }

    print("🚀 [SaaS] Activating Business License for: ${user.email}");

    final trialEnd = DateTime.now().add(const Duration(days: 14)).toIso8601String();

    // 1. Initialize Tenant Meta-Data & Billing Fields
    await _supabase.from('tenants').upsert({
      'id': tenantId,
      'created_at': DateTime.now().toIso8601String(),
      'owner_uid': user.id,
      'subscription_status': 'active', // Maps to plan status
      'currency': 'USD',
    });

    // 2. Insert the owner role to the roles table
    final ownerRoleId = const Uuid().v4();
    final ownerRole = AppRole(
      id: ownerRoleId,
      name: 'System Administrator', // Professional Name
      permissions: [], 
      isSystemAdmin: true,
    );

    await _supabase.from('roles').upsert({
      'id': ownerRole.id,
      'tenant_id': tenantId,
      'name': ownerRole.name,
      'permissions': ownerRole.permissions,
      'is_system_admin': ownerRole.isSystemAdmin,
    });

    // 3. Promote User (Link user profile to tenant)
    await _supabase.from('user_profiles').upsert({
      'id': user.id,
      'tenant_id': tenantId,
      'email': user.email,
    });

    // 4. Assign Owner Role in Staff Members
    await _supabase.from('staff_members').insert({
      'tenant_id': tenantId,
      'user_id': user.id,
      'role_id': ownerRoleId,
    });

    print("✅ [SaaS] System Activated. You are now the System Admin.");
  }
}