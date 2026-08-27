import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
// UPDATED import
import 'package:feature_auth/src/data/auth_repository.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated_online,
  authenticated_offline,
  emailConfirmationPending,
  unauthenticated,
}

class AuthState {
  AuthState({this.status = AuthStatus.initial, this.errorMessage});

  final AuthStatus status;
  final String? errorMessage;
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(ref.watch(authRepositoryProvider));
  },
);

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._authRepository) : super(AuthState()) {
    _trySilentSignIn();
  }

  final AuthRepository _authRepository;
  // ignore: unused_field

  Future<void> _trySilentSignIn() async {
    state = AuthState(status: AuthStatus.loading);
    try {
      if (await _authRepository.hasActiveSupabaseSession()) {
        state = AuthState(status: AuthStatus.authenticated_online);
        return;
      }

      final hasDriveCredentials = await _authRepository.hasStoredCredentials();
      if (!hasDriveCredentials) {
        state = AuthState(status: AuthStatus.unauthenticated);
        return;
      }

      try {
        final client = await _authRepository.signInSilently();
        if (client != null && _authRepository.currentSupabaseUser != null) {
          state = AuthState(status: AuthStatus.authenticated_online);
        } else {
          state = AuthState(status: AuthStatus.unauthenticated);
        }
      } catch (e) {
        print('Silent sign-in failed (likely offline): $e');
        state = AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signIn() async {
    state = AuthState(status: AuthStatus.loading);
    try {
      if (kIsWeb) {
        final started = await _authRepository.signInWithWebOAuth();
        if (!started) {
          state = AuthState(
            status: AuthStatus.unauthenticated,
            errorMessage: 'Browser sign-in is unavailable.',
          );
        }
        // Supabase redirects the browser to Google and restores the session
        // through the configured callback URL; no local token is handled here.
        return;
      }

      final client = await _authRepository.signIn();
      final hasSupabaseSession = await _authRepository
          .hasActiveSupabaseSession();
      if (client != null && hasSupabaseSession) {
        state = AuthState(status: AuthStatus.authenticated_online);
      } else {
        state = AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: client == null
              ? 'Google sign-in was cancelled or unavailable.'
              : 'Google sign-in did not create a cloud session.',
        );
      }
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = AuthState(status: AuthStatus.loading);
    try {
      final response = await _authRepository.signInWithEmail(email, password);
      if (response.session == null) {
        state = AuthState(status: AuthStatus.emailConfirmationPending);
      } else {
        state = AuthState(status: AuthStatus.authenticated_online);
      }
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    state = AuthState(status: AuthStatus.loading);
    try {
      final response = await _authRepository.signUpWithEmail(email, password);
      if (response.session == null) {
        state = AuthState(status: AuthStatus.emailConfirmationPending);
      } else {
        state = AuthState(status: AuthStatus.authenticated_online);
      }
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}
