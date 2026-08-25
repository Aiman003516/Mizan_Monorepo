import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../env_config.dart';

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

/// Cloud persistence is an opt-in mode for an authenticated user.
///
/// A configured Supabase URL alone must not force a guest into cloud-only
/// pages: unauthenticated users need to be able to create and edit records in
/// their local Drift database. Tenant resolution and RLS remain mandatory once
/// a session is present and cloud mode is selected.
final cloudDataModeProvider = Provider<bool>((ref) {
  final isConfigured = EnvConfig.isProd || EnvConfig.supabaseUrl.isNotEmpty;
  final session = ref.watch(supabaseSessionProvider).valueOrNull;
  return isConfigured && session != null;
});
