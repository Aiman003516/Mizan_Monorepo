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
  return AuthController(ref.watch(authRepositoryProvider), ref);
});

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._authRepository, this._ref) : super(AuthState()) {
    _trySilentSignIn();
  }

  final AuthRepository _authRepository;
  final Ref _ref;

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

  Future<void> signOut() async {
    await _authRepository.signOut();
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}