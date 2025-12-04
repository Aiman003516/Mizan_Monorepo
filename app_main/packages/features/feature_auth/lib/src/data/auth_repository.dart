import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:googleapis_auth/auth_io.dart' as auth_io;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// 1. Add Firebase Auth Import
import 'package:firebase_auth/firebase_auth.dart';

import 'package:core_data/core_data.dart';

const _scopes = ['https://www.googleapis.com/auth/drive.appdata'];

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(flutterSecureStorageProvider));
});

class AuthRepository {
  AuthRepository(this._secureStorage);

  final FlutterSecureStorage _secureStorage;

  static const _windowsRefreshTokenKey = 'windows_refresh_token';

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: _scopes);

  auth.AuthClient? _client;
  GoogleSignInAccount? _googleUser;

  GoogleSignInAccount? get currentUser => _googleUser;

  Future<auth.AuthClient?> signIn() async {
    if (kIsWeb) {
      throw UnimplementedError('Web platform is not supported');
    }

    try {
      if (Platform.isAndroid) {
        // A. Trigger Google Sign In
        final user = await _googleSignIn.signIn();
        if (user == null) {
          throw 'Sign-in cancelled by user.';
        }
        _googleUser = user;

        // B. 🚀 CRITICAL FIX: Sign in to Firebase using Google Credentials
        final googleAuth = await user.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        
        // This populates FirebaseAuth.instance.currentUser
        await FirebaseAuth.instance.signInWithCredential(credential);
        print("✅ [Auth] Firebase Sign-In Successful: ${FirebaseAuth.instance.currentUser?.uid}");

        // C. Create Drive Client (Existing Logic)
        final authHeaders = await user.authHeaders;
        _client = auth.authenticatedClient(
          http.Client(),
          auth.AccessCredentials(
            auth.AccessToken(
              'Bearer',
              authHeaders['Authorization']!.substring(7), // Remove 'Bearer '
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
          throw 'Windows Client ID/Secret not found. Please check your launch.json configuration.';
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
          // Note: Windows Firebase Auth requires a different flow (Custom Token)
          // For Phase 4, we focus on Android. Windows syncs via the common DB logic.
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

        // 🚀 FIX: Ensure Firebase is also signed in silently
        if (FirebaseAuth.instance.currentUser == null) {
           final googleAuth = await user.authentication;
           final credential = GoogleAuthProvider.credential(
             accessToken: googleAuth.accessToken,
             idToken: googleAuth.idToken,
           );
           await FirebaseAuth.instance.signInWithCredential(credential);
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

        if (!EnvConfig.hasGoogleKeys) {
           throw 'Windows Client ID/Secret not found. Please check your launch.json configuration.';
        }

        final id = auth.ClientId(clientId, clientSecret);

        final credentials = auth.AccessCredentials(
          auth.AccessToken(
            'Bearer',
            '',
            DateTime.now()
                .toUtc()
                .subtract(const Duration(minutes: 5)),
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
      await signOut();
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      if (Platform.isAndroid) {
        await _googleSignIn.signOut();
        await FirebaseAuth.instance.signOut(); // 🚀 Sign out of Firebase too
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

    throw 'Authentication failed. Unable to get HTTP client.';
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
}