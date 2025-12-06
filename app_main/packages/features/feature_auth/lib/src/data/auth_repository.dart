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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:core_data/core_data.dart';
import 'package:uuid/uuid.dart';

import 'package:rxdart/rxdart.dart';

const _scopes = ['https://www.googleapis.com/auth/drive.appdata'];

/// 🧠 THE IDENTITY ENGINE (Hybrid: Drive + SaaS)
class AuthRepository {
  final FlutterSecureStorage _secureStorage;
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepository(this._secureStorage, this._firebaseAuth, this._firestore);

  static const _windowsRefreshTokenKey = 'windows_refresh_token';

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: _scopes);

  auth.AuthClient? _client;
  GoogleSignInAccount? _googleUser;

  GoogleSignInAccount? get currentGoogleUser => _googleUser;
  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  // --- 🛡️ SAAS IDENTITY LOGIC (New for Phase 4) ---

  /// Listens to the enriched AppUser profile (Firestore + Auth)
  Stream<AppUser?> watchCurrentUser() {
    return _firebaseAuth.authStateChanges().switchMap((firebaseUser) {
      if (firebaseUser == null) return Stream.value(null);

      // Listen to the User's Profile Document in Firestore
      return _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .snapshots()
          .map((snapshot) {
            // If the user doc exists, map it. If not, create a basic shell.
            return AppUser.fromFirestore(
              snapshot,
              uid: firebaseUser.uid,
              email: firebaseUser.email ?? '',
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
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception("User must be logged in");

    // 1. Generate ID (Slugify Name + Random suffix)
    final slug = businessName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');
    final suffix = const Uuid().v4().substring(0, 4);
    final tenantId = '$slug-$suffix';

    final batch = _firestore.batch();

    // 2. Define References
    final tenantRef = _firestore.collection('tenants').doc(tenantId);
    final userRef = _firestore.collection('users').doc(user.uid);

    // 3. Set Tenant Data
    batch.set(tenantRef, {
      'name': businessName,
      'taxId': taxId,
      'phone': phone,
      'ownerUid': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'subscriptionStatus': 'trial', 
      'currency': 'USD', 
    });

    // 4. Link User to Tenant (The Promotion)
    batch.set(userRef, {
      'tenantId': tenantId,
      'role': 'owner',
      'email': user.email,
      'displayName': user.displayName,
      'updatedAt': FieldValue.serverTimestamp(),
      'isPro': true, // Auto-upgrade for trial/owner
    }, SetOptions(merge: true));

    // 5. Commit atomically
    await batch.commit();
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

        // B. Firebase Sign In (Hybrid Link)
        final googleAuth = await user.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        
        await _firebaseAuth.signInWithCredential(credential);
        print("✅ [Auth] Firebase Sign-In Successful: ${_firebaseAuth.currentUser?.uid}");

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
          // Note: Windows Firebase Auth fallback logic would go here if needed.
          // For now, Windows acts as a "Data Terminal" using sync, 
          // relying on Android to set up the account initially if using Firebase.
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

        // Ensure Firebase is also signed in silently
        if (_firebaseAuth.currentUser == null) {
           final googleAuth = await user.authentication;
           final credential = GoogleAuthProvider.credential(
             accessToken: googleAuth.accessToken,
             idToken: googleAuth.idToken,
           );
           await _firebaseAuth.signInWithCredential(credential);
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
      await signOut();
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      if (Platform.isAndroid) {
        await _googleSignIn.signOut();
        await _firebaseAuth.signOut();
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
}

// 💉 PROVIDERS
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // Inject all dependencies explicitly
  return AuthRepository(
    ref.watch(flutterSecureStorageProvider),
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  );
});

// The Stream that the UI listens to for "Am I a Business Owner?"
final currentUserStreamProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).watchCurrentUser();
});