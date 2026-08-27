import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/close_preflight_models.dart';
import '../tenant_context.dart';

final closePreflightRepositoryProvider = Provider<ClosePreflightRepository>(
  (ref) => ClosePreflightRepository(
    Supabase.instance.client,
    ref.watch(tenantContextProvider),
  ),
);

class ClosePreflightRepository {
  ClosePreflightRepository(this._supabase, this._tenantContext);

  final SupabaseClient _supabase;
  final TenantContext _tenantContext;

  Future<List<ClosePreflightCheck>> run(String periodId) async {
    if (periodId.trim().isEmpty) {
      throw ArgumentError.value(periodId, 'periodId');
    }
    await _tenantContext.currentTenantId();
    final response = await _supabase.rpc(
      'accounting_close_preflight',
      params: {'p_period_id': periodId},
    );
    if (response is! List) {
      throw const PostgrestException(
        message: 'Close preflight returned no result.',
        code: 'MIZAN_CLOSE_PREFLIGHT_INVALID_RESPONSE',
      );
    }
    return response
        .whereType<Map>()
        .map(
          (row) => ClosePreflightCheck.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList(growable: false);
  }
}
