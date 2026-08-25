// FILE: packages/features/feature_auth/lib/src/data/auth_repository.dart

import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:googleapis_auth/auth_io.dart' as auth_io;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:core_data/core_data.dart';

import 'package:rxdart/rxdart.dart';

const _scopes = ['https://www.googleapis.com/auth/drive.appdata'];

/// 🧠 THE IDENTITY ENGINE (Hybrid: Drive + SaaS)
class AuthRepository {
  final FlutterSecureStorage _secureStorage;
  final SupabaseClient _supabase;

  AuthRepository(this._secureStorage, this._supabase);

  static const _windowsRefreshTokenKey = 'windows_refresh_token';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: _scopes,
    serverClientId: EnvConfig.hasGoogleWebClientId
        ? EnvConfig.googleWebClientId
        : null,
  );
  auth.AuthClient? _client;
  GoogleSignInAccount? _googleUser;

  GoogleSignInAccount? get currentGoogleUser => _googleUser;
  User? get currentSupabaseUser => _supabase.auth.currentUser;
  Session? get currentSupabaseSession => _supabase.auth.currentSession;

  // --- 🛡️ SAAS IDENTITY LOGIC ---

  /// Listens to the enriched AppUser profile (Supabase Auth + user_profiles table)
  Stream<AppUser?> watchCurrentUser() {
    return _supabase.auth.onAuthStateChange.switchMap((authState) {
      final user = authState.session?.user;
      if (user == null) return Stream.value(null);
      return _supabase
          .from('user_profiles')
          .stream(primaryKey: ['id'])
          .eq('id', user.id)
          .startWith(const <Map<String, dynamic>>[])
          .asyncMap((_) => _loadCurrentUser(user));
    });
  }

  Future<AppUser> _loadCurrentUser(User user) async {
    final profile = await _supabase
        .from('user_profiles')
        .select('id,email,display_name,full_name,tenant_id')
        .eq('id', user.id)
        .maybeSingle();

    if (profile == null) {
      return AppUser(
        uid: user.id,
        email: user.email ?? '',
        displayName: user.userMetadata?['full_name'] as String? ?? user.email,
        tenantId: null,
        role: 'staff',
        isPro: false,
      );
    }

    final tenantId = profile['tenant_id'] as String?;
    if (tenantId == null || tenantId.isEmpty) {
      return AppUser(
        uid: user.id,
        email: profile['email'] as String? ?? user.email ?? '',
        displayName:
            (profile['display_name'] ?? profile['full_name']) as String? ??
            user.email,
        tenantId: null,
        role: 'staff',
        isPro: false,
      );
    }

    final membership = await _supabase
        .from('staff_members')
        .select('role_id,roles(name,is_system_admin)')
        .eq('tenant_id', tenantId)
        .eq('user_id', user.id)
        .eq('status', 'active')
        .maybeSingle();
    final roleMap = membership?['roles'] is Map
        ? Map<String, dynamic>.from(membership!['roles'] as Map)
        : const <String, dynamic>{};
    final isSystemAdmin = roleMap['is_system_admin'] == true;
    final tenant = await _supabase
        .from('tenants')
        .select('subscription_status')
        .eq('id', tenantId)
        .maybeSingle();
    final subscriptionStatus = tenant?['subscription_status'] as String?;

    return AppUser(
      uid: user.id,
      email: profile['email'] as String? ?? user.email ?? '',
      displayName: profile['display_name'] as String? ?? user.email,
      tenantId: tenantId,
      role: isSystemAdmin ? 'owner' : (roleMap['name'] as String? ?? 'staff'),
      isPro: subscriptionStatus == 'trial' || subscriptionStatus == 'active',
    );
  }

  /// 🚀 ACTION: CREATE BUSINESS (Tenant Generation)
  Future<String> createBusinessTenant({
    required String businessName,
    required String taxId,
    required String phone,
    String currencyCode = 'USD',
  }) async {
    if (_supabase.auth.currentUser == null) {
      throw const AuthException('Authentication is required.');
    }

    final result = await _supabase.rpc(
      'create_business',
      params: {
        'p_name': businessName.trim(),
        'p_tax_id': taxId.trim().isEmpty ? null : taxId.trim(),
        'p_phone': phone.trim().isEmpty ? null : phone.trim(),
        'p_currency_code': currencyCode.toUpperCase(),
      },
    );
    if (result is String && result.isNotEmpty) return result;
    if (result is Map && result['id'] is String) return result['id'] as String;
    throw const PostgrestException(
      message: 'Business bootstrap returned no tenant identifier.',
      code: 'MIZAN_BOOTSTRAP_INVALID_RESPONSE',
    );
  }

  // --- 🔒 EMAIL & PHONE AUTH LOGIC ---

  Future<AuthResponse> signInWithEmail(String email, String password) {
    return _supabase.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmail(String email, String password) {
    return _supabase.auth.signUp(
      email: email.trim().toLowerCase(),
      password: password,
      data: {'full_name': email.trim().split('@').first},
    );
  }

  Future<AuthResponse> signInWithPhone(String phone, String password) {
    return _supabase.auth.signInWithPassword(
      phone: phone.trim(),
      password: password,
    );
  }

  Future<AuthResponse> signUpWithPhone(String phone, String password) {
    return _supabase.auth.signUp(phone: phone.trim(), password: password);
  }

  // --- ☁️ DRIVE AUTH LOGIC (Existing Backup System) ---

  Future<auth.AuthClient?> signIn() async {
    if (kIsWeb) {
      throw UnimplementedError('Web platform is not supported');
    }

    try {
      if (Platform.isAndroid) {
        // A. Google Sign In
        final user = await _googleSignIn.signIn();
        if (user == null) {
          throw 'Sign-in cancelled by user.';
        }
        _googleUser = user;

        // B. Supabase Sign In (Hybrid Link)
        final googleAuth = await user.authentication;
        final idToken = googleAuth.idToken;
        final accessToken = googleAuth.accessToken;
        if (idToken == null || accessToken == null) {
          throw const AuthException(
            'Google did not return the credentials required for cloud sign-in.',
          );
        }

        final response = await _supabase.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );
        if (response.session == null || _supabase.auth.currentUser == null) {
          throw const AuthException(
            'Google sign-in completed, but the Supabase session was not created.',
          );
        }

        // C. Create Drive Client
        final authHeaders = await user.authHeaders;
        _client = auth.authenticatedClient(
          http.Client(),
          auth.AccessCredentials(
            auth.AccessToken(
              'Bearer',
              authHeaders['Authorization']!.substring(7),
              DateTime.now().toUtc().add(const Duration(hours: 1)),
            ),
            null,
            _scopes,
          ),
        );
      } else if (Platform.isWindows) {
        final clientId = EnvConfig.googleWindowsClientId;
        final clientSecret = EnvConfig.googleWindowsClientSecret;

        if (!EnvConfig.hasGoogleKeys) {
          throw 'Windows Client ID/Secret not found.';
        }

        final id = auth.ClientId(clientId, clientSecret);

        _client = await auth_io
            .obtainAccessCredentialsViaUserConsent(id, _scopes, http.Client(), (
              url,
            ) async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                throw 'Could not launch $url';
              }
            })
            .then((credentials) {
              _secureStorage.write(
                key: _windowsRefreshTokenKey,
                value: credentials.refreshToken,
              );

              _googleUser = null;
              // Note: Windows Supabase Auth fallback logic would go here if needed.
              return auth.authenticatedClient(http.Client(), credentials);
            });
      }
      return _client;
    } catch (e) {
      print('Error during sign-in: $e');
      _client = null;
      _googleUser = null;
      rethrow;
    }
  }

  Future<auth.AuthClient?> signInSilently() async {
    if (_client != null) return _client;

    try {
      if (Platform.isAndroid) {
        final user = await _googleSignIn.signInSilently();
        if (user == null) return null;
        _googleUser = user;

        // Ensure Supabase is also signed in silently.
        if (_supabase.auth.currentUser == null) {
          final googleAuth = await user.authentication;
          final idToken = googleAuth.idToken;
          final accessToken = googleAuth.accessToken;
          if (idToken == null || accessToken == null) return null;
          final response = await _supabase.auth.signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: idToken,
            accessToken: accessToken,
          );
          if (response.session == null) return null;
        }

        final authHeaders = await user.authHeaders;
        _client = auth.authenticatedClient(
          http.Client(),
          auth.AccessCredentials(
            auth.AccessToken(
              'Bearer',
              authHeaders['Authorization']!.substring(7),
              DateTime.now().toUtc().add(const Duration(hours: 1)),
            ),
            null,
            _scopes,
          ),
        );
      } else if (Platform.isWindows) {
        final refreshToken = await _secureStorage.read(
          key: _windowsRefreshTokenKey,
        );
        if (refreshToken == null) return null;

        final clientId = EnvConfig.googleWindowsClientId;
        final clientSecret = EnvConfig.googleWindowsClientSecret;

        if (!EnvConfig.hasGoogleKeys) return null;

        final id = auth.ClientId(clientId, clientSecret);

        final credentials = auth.AccessCredentials(
          auth.AccessToken(
            'Bearer',
            '',
            DateTime.now().toUtc().subtract(const Duration(minutes: 5)),
          ),
          refreshToken,
          _scopes,
        );

        final refreshedCredentials = await auth_io.refreshCredentials(
          id,
          credentials,
          http.Client(),
        );

        _googleUser = null;
        _client = auth.authenticatedClient(http.Client(), refreshedCredentials);
      }
      return _client;
    } catch (e) {
      print('Error during silent sign-in: $e');
      _client = null;
      _googleUser = null;
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      if (Platform.isAndroid) {
        await _googleSignIn.signOut();
      } else if (Platform.isWindows) {
        await _secureStorage.delete(key: _windowsRefreshTokenKey);
      }
    } catch (e) {
      print('Error during sign-out: $e');
    } finally {
      _client = null;
      _googleUser = null;
    }
  }

  Future<auth.AuthClient> getHttpClient() async {
    if (_client != null) return _client!;
    final client = await signInSilently();
    if (client != null) return client;
    final newClient = await signIn();
    if (newClient != null) return newClient;
    throw 'Authentication failed.';
  }

  Future<bool> hasActiveSupabaseSession() async {
    final session = _supabase.auth.currentSession;
    return session != null && !session.isExpired;
  }

  Future<bool> hasStoredCredentials() async {
    if (await hasActiveSupabaseSession()) return true;
    if (Platform.isAndroid) {
      return await _googleSignIn.isSignedIn();
    } else if (Platform.isWindows) {
      final token = await _secureStorage.read(key: _windowsRefreshTokenKey);
      return token != null && token.isNotEmpty;
    }
    return false;
  }

  /// Helper to get an authenticated Drive client silently (for background workers)
  static Future<auth.AuthClient?> getSilentDriveClient() async {
    final googleSignIn = GoogleSignIn(
      scopes: _scopes,
      serverClientId: EnvConfig.hasGoogleWebClientId
          ? EnvConfig.googleWebClientId
          : null,
    );
    final user = await googleSignIn.signInSilently();
    if (user == null) return null;

    final authHeaders = await user.authHeaders;
    return auth.authenticatedClient(
      http.Client(),
      auth.AccessCredentials(
        auth.AccessToken(
          'Bearer',
          authHeaders['Authorization']!.substring(7),
          DateTime.now().toUtc().add(const Duration(hours: 1)),
        ),
        null,
        _scopes,
      ),
    );
  }
}

// 💉 PROVIDERS
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // Inject all dependencies explicitly
  return AuthRepository(
    ref.watch(flutterSecureStorageProvider),
    Supabase.instance.client,
  );
});

// The Stream that the UI listens to for "Am I a Business Owner?"
final currentUserStreamProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).watchCurrentUser();
});
