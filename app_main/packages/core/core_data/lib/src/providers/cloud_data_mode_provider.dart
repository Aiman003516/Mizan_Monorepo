import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../env_config.dart';

enum CloudDataMode { guestLocal, resolvingTenant, authenticatedTenant }

/// Emits the current Supabase session, including changes caused by sign-in and
/// sign-out. The app can therefore rebuild repository providers when a user
/// chooses to connect or disconnect their account.
final supabaseSessionProvider = StreamProvider<Session?>((ref) async* {
  final client = Supabase.instance.client;
  yield client.auth.currentSession;
  await for (final authState in client.auth.onAuthStateChange) {
    yield authState.session;
  }
});

/// Resolves cloud mode only after the authenticated user has a usable tenant.
///
/// A session alone is not enough: profile and staff membership resolution can
/// still be in flight, and RLS-backed repositories must never invent a tenant.
/// During that interval the app stays on local Drift data rather than replacing
/// a visible guest list with an empty or failing cloud stream.
final cloudDataModeStateProvider = StreamProvider<CloudDataMode>((ref) async* {
  final client = Supabase.instance.client;
  final isConfigured = EnvConfig.isProd || EnvConfig.supabaseUrl.isNotEmpty;

  Future<CloudDataMode> resolve(Session? session) async {
    if (!isConfigured || session == null) {
      return CloudDataMode.guestLocal;
    }

    try {
      final row = await client
          .from('staff_members')
          .select('tenant_id')
          .eq('user_id', session.user.id)
          .eq('status', 'active')
          .order('created_at')
          .limit(1)
          .maybeSingle();
      final tenantId = row?['tenant_id'] as String?;
      if (tenantId != null && tenantId.isNotEmpty) {
        return CloudDataMode.authenticatedTenant;
      }
    } catch (_) {
      // Keep the app local-first when tenant discovery is unavailable. A later
      // auth event or explicit invalidation can retry without exposing raw
      // backend details in the UI.
    }
    return CloudDataMode.guestLocal;
  }

  Stream<CloudDataMode> emitResolved(Session? session) async* {
    if (!isConfigured || session == null) {
      yield CloudDataMode.guestLocal;
      return;
    }
    yield CloudDataMode.resolvingTenant;
    yield await resolve(session);
  }

  yield* emitResolved(client.auth.currentSession);
  await for (final authState in client.auth.onAuthStateChange) {
    yield* emitResolved(authState.session);
  }
});

/// Cloud persistence is opt-in and tenant-scoped. Guests and users whose
/// membership is still resolving continue using local Drift storage.
final cloudDataModeProvider = Provider<bool>((ref) {
  return ref.watch(cloudDataModeStateProvider).valueOrNull ==
      CloudDataMode.authenticatedTenant;
});
