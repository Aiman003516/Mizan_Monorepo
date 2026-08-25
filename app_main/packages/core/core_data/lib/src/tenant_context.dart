import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final tenantContextProvider = Provider<TenantContext>((ref) {
  return TenantContext(Supabase.instance.client);
});

/// Resolves the active tenant from authenticated Supabase membership.
///
/// Repositories should use this context for writes and never invent a tenant
/// identifier locally. RLS remains the final enforcement layer in Supabase.
class TenantContext {
  final SupabaseClient _supabase;

  const TenantContext(this._supabase);

  Future<String> currentTenantId() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('Authentication is required.');
    }

    final membership = await _supabase
        .from('staff_members')
        .select('tenant_id')
        .eq('user_id', user.id)
        .eq('status', 'active')
        .order('created_at')
        .limit(1)
        .maybeSingle();
    final tenantId = membership?['tenant_id'] as String?;
    if (tenantId == null || tenantId.isEmpty) {
      throw const PostgrestException(
        message: 'Tenant membership was not found.',
        code: 'MIZAN_TENANT_NOT_FOUND',
      );
    }
    return tenantId;
  }
}
