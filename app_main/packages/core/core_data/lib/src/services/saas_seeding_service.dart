import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final saasSeedingServiceProvider = Provider<SaasSeedingService>((ref) {
  return SaasSeedingService(Supabase.instance.client);
});

class SaasSeedingService {
  SaasSeedingService(this._supabase);

  final SupabaseClient _supabase;

  /// Activates an owner-owned tenant through a transactionally protected RPC.
  Future<void> activateSystemForBuyer(String tenantId) async {
    if (_supabase.auth.currentUser == null) {
      throw const AuthException('Authentication is required.');
    }
    if (tenantId.trim().isEmpty || tenantId == 'test_tenant_123') {
      throw const PostgrestException(
        message: 'A real tenant identifier is required.',
        code: 'MIZAN_INVALID_TENANT_ID',
      );
    }
    await _supabase.rpc(
      'activate_existing_business',
      params: {'p_tenant_id': tenantId},
    );
  }
}
