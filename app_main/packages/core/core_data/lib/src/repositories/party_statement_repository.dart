import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/party_statement_models.dart';
import '../tenant_context.dart';

final partyStatementRepositoryProvider = Provider<PartyStatementRepository>(
  (ref) => PartyStatementRepository(
    Supabase.instance.client,
    ref.watch(tenantContextProvider),
  ),
);

class PartyStatementRepository {
  PartyStatementRepository(this._supabase, this._tenantContext);

  final SupabaseClient _supabase;
  final TenantContext _tenantContext;

  Future<List<PartyStatementEntry>> fetchStatement({
    required String partyType,
    required String partyId,
    DateTime? from,
    DateTime? to,
  }) async {
    if (partyType != 'customer' && partyType != 'vendor') {
      throw ArgumentError.value(partyType, 'partyType');
    }
    if (partyId.trim().isEmpty) {
      throw ArgumentError.value(partyId, 'partyId');
    }
    await _tenantContext.currentTenantId();
    final response = await _supabase.rpc(
      'party_statement',
      params: {
        'p_party_type': partyType,
        'p_party_id': partyId,
        'p_from': _date(from),
        'p_to': _date(to),
      },
    );
    if (response is! List) {
      throw const PostgrestException(
        message: 'Party statement returned no result.',
        code: 'MIZAN_PARTY_STATEMENT_INVALID_RESPONSE',
      );
    }
    return response
        .whereType<Map>()
        .map(
          (row) => PartyStatementEntry.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList(growable: false);
  }

  String? _date(DateTime? value) => value?.toIso8601String().substring(0, 10);
}
