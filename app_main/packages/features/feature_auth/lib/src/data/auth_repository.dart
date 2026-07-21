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
import 'package:uuid/uuid.dart';

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
    serverClientId: EnvConfig.hasGoogleWebClientId ? EnvConfig.googleWebClientId : null,
  );
  auth.AuthClient? _client;
  GoogleSignInAccount? _googleUser;

  GoogleSignInAccount? get currentGoogleUser => _googleUser;
  User? get currentSupabaseUser => _supabase.auth.currentUser;

  // --- 🛡️ SAAS IDENTITY LOGIC ---

  /// Listens to the enriched AppUser profile (Supabase Auth + user_profiles table)
  Stream<AppUser?> watchCurrentUser() {
    return _supabase.auth.onAuthStateChange.switchMap((authState) {
      final user = authState.session?.user;
      if (user == null) return Stream.value(null);

      // Listen to the User's Profile Document in Supabase Postgres
      return _supabase
          .from('user_profiles')
          .stream(primaryKey: ['id'])
          .eq('id', user.id)
          .map((maps) {
            if (maps.isEmpty) {
              return AppUser(
                uid: user.id,
                email: user.email ?? '',
                displayName: user.userMetadata?['full_name'] ?? 'Unknown',
                role: 'owner',
                tenantId: null,
                isPro: false,
              );
            }
            final data = maps.first;
            return AppUser(
              uid: user.id,
              email: data['email'] ?? user.email ?? '',
              displayName: data['display_name'] ?? user.userMetadata?['full_name'] ?? 'Unknown',
              role: data['role'] ?? 'owner',
              tenantId: data['tenant_id'],
              isPro: data['is_pro'] ?? false,
            );
          });
    });
  }

  /// 🚀 ACTION: CREATE BUSINESS (Tenant Generation)
  Future<void> createBusinessTenant({
    required String businessName,
    required String taxId,
    required String phone,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("User must be logged in");

    // 1. Generate ID (Supabase uses UUID)
    final tenantId = const Uuid().v4();

    // 2. Insert Tenant
    await _supabase.from('tenants').insert({
      'id': tenantId,
      'name': businessName,
      'tax_id': taxId,
      'phone': phone,
      'owner_uid': user.id,
      'subscription_status': 'trial', 
      'currency': 'USD', 
    });

    // 3. Link User to Tenant (The Promotion)
    await _supabase.from('user_profiles').upsert({
      'id': user.id,
      'tenant_id': tenantId,
      'role': 'owner',
      'email': user.email,
      'display_name': user.userMetadata?['full_name'] ?? user.email,
      'is_pro': true,
    });
  }

  // --- 🔒 EMAIL & PHONE AUTH LOGIC ---

  Future<void> signInWithEmail(String email, String password) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUpWithEmail(String email, String password) async {
    await _supabase.auth.signUp(email: email, password: password);
  }

  Future<void> signInWithPhone(String phone, String password) async {
    await _supabase.auth.signInWithPassword(phone: phone, password: password);
  }

  Future<void> signUpWithPhone(String phone, String password) async {
    await _supabase.auth.signUp(phone: phone, password: password);
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
        if (googleAuth.idToken != null && googleAuth.accessToken != null) {
          await _supabase.auth.signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: googleAuth.idToken!,
            accessToken: googleAuth.accessToken!,
          );
        }
        print("✅ [Auth] Supabase Sign-In Successful: ${_supabase.auth.currentUser?.id}");

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

        _client = await auth_io.obtainAccessCredentialsViaUserConsent(
          id,
          _scopes,
          http.Client(),
          (url) async {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            } else {
              throw 'Could not launch $url';
            }
          },
        ).then((credentials) {
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

        // Ensure Supabase is also signed in silently
        if (_supabase.auth.currentUser == null) {
           final googleAuth = await user.authentication;
           if (googleAuth.idToken != null && googleAuth.accessToken != null) {
              await _supabase.auth.signInWithIdToken(
                provider: OAuthProvider.google,
                idToken: googleAuth.idToken!,
                accessToken: googleAuth.accessToken!,
              );
           }
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
        final refreshToken =
            await _secureStorage.read(key: _windowsRefreshTokenKey);
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

  Future<bool> hasStoredCredentials() async {
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
      serverClientId: EnvConfig.hasGoogleWebClientId ? EnvConfig.googleWebClientId : null,
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