import 'package:flutter_riverpod/flutter_riverpod.dart';
// UPDATED import
import 'package:feature_auth/src/data/auth_repository.dart'; 

enum AuthStatus {
  initial,
  loading,
  authenticated_online, 
  authenticated_offline,
  unauthenticated
}

class AuthState {
  AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
  });

  final AuthStatus status;
  final String? errorMessage;
}

final authControllerProvider =
StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._authRepository) : super(AuthState()) {
    _trySilentSignIn();
  }

  final AuthRepository _authRepository;
// ignore: unused_field

  Future<void> _trySilentSignIn() async {
    state = AuthState(status: AuthStatus.loading);
    try {
      final hasCredentials = await _authRepository.hasStoredCredentials();

      if (hasCredentials) {
        try {
          final client = await _authRepository.signInSilently();
          if (client != null) {
            state = AuthState(status: AuthStatus.authenticated_online);
          } else {
            state = AuthState(status: AuthStatus.unauthenticated);
          }
        } catch (e) {
          print('Silent sign-in failed (likely offline): $e');
          state = AuthState(status: AuthStatus.authenticated_offline);
        }
      } else {
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
      final client = await _authRepository.signIn();
      if (client != null) {
        state = AuthState(status: AuthStatus.authenticated_online);
      } else {
        state = AuthState(status: AuthStatus.unauthenticated);
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
      await _authRepository.signInWithEmail(email, password);
      // Supabase signInWithEmail doesn't return the Google Drive client.
      // But it does sign the user into Supabase.
      state = AuthState(status: AuthStatus.authenticated_online);
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
      await _authRepository.signUpWithEmail(email, password);
      // After sign up, they are signed in (Supabase auto-logins after signup if email confirmations are disabled)
      state = AuthState(status: AuthStatus.authenticated_online);
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