// lib/src/core/data/preferences_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:core_data/src/secure_storage_provider.dart'; // UPDATED import
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for SharedPreferences.
/// This MUST be overridden in main.dart
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.dart');
});

/// Provider for the new repository
final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  final sharedPrefs = ref.watch(sharedPreferencesProvider);
  final secureStorage = ref.watch(flutterSecureStorageProvider);
  return PreferencesRepository(sharedPrefs, secureStorage);
});

/// A repository for managing all user-configurable settings.
/// It abstracts whether a setting is stored securely or in plain preferences.
class PreferencesRepository {
  PreferencesRepository(this._prefs, this._secureStorage);

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  // --- Keys ---
  // Non-sensitive
  static const _kThemeMode = 'theme_mode';
  static const _kLocale = 'locale_code';
  static const _kPasscodeEnabled = 'passcode_enabled';
  static const _kBiometricsEnabled = 'biometrics_enabled';
  static const _kHasSeenSyncWarning = 'has_seen_sync_warning';
  static const _kCompanyName = 'company_name';
  static const _kUserName = 'user_name';
  static const _kCompanyAddress = 'company_address';
  static const _kTaxID = 'tax_id';

  // ⭐️ 1. ADD NEW KEY FOR DEFAULT CURRENCY
  static const _kDefaultCurrency = 'default_currency_code';

  // Sensitive
  static const _kPasscodePin = 'passcode_pin';

  // --- Theme ---
  String getThemeMode() => _prefs.getString(_kThemeMode) ?? 'system';
  Future<void> setThemeMode(String mode) async =>
      await _prefs.setString(_kThemeMode, mode);

  // --- Locale ---
  String? getLocale() => _prefs.getString(_kLocale);
  Future<void> setLocale(String code) async =>
      await _prefs.setString(_kLocale, code);

  // --- Passcode Enabled ---
  bool isPasscodeEnabled() => _prefs.getBool(_kPasscodeEnabled) ?? false;
  Future<void> setPasscodeEnabled(bool enabled) async =>
      await _prefs.setBool(_kPasscodeEnabled, enabled);

  // --- Biometrics Enabled ---
  bool isBiometricsEnabled() => _prefs.getBool(_kBiometricsEnabled) ?? false;
  Future<void> setBiometricsEnabled(bool enabled) async =>
      await _prefs.setBool(_kBiometricsEnabled, enabled);

  // --- Passcode PIN (Secure) ---
  Future<String?> getPasscode() async =>
      await _secureStorage.read(key: _kPasscodePin);
  Future<void> setPasscode(String pin) async =>
      await _secureStorage.write(key: _kPasscodePin, value: pin);
  Future<void> clearPasscode() async =>
      await _secureStorage.delete(key: _kPasscodePin);

  // --- Sync Warning ---
  bool hasSeenSyncWarning() => _prefs.getBool(_kHasSeenSyncWarning) ?? false;

  Future<void> setHasSeenSyncWarning(bool value) async =>
      await _prefs.setBool(_kHasSeenSyncWarning, value);

  // --- Company Profile ---
  String getCompanyName() => _prefs.getString(_kCompanyName) ?? '';
  Future<void> setCompanyName(String name) async =>
      await _prefs.setString(_kCompanyName, name);

  String getUserName() => _prefs.getString(_kUserName) ?? '';
  Future<void> setUserName(String name) async =>
      await _prefs.setString(_kUserName, name);

  String getCompanyAddress() => _prefs.getString(_kCompanyAddress) ?? '';
  Future<void> setCompanyAddress(String address) async =>
      await _prefs.setString(_kCompanyAddress, address);

  String getTaxID() => _prefs.getString(_kTaxID) ?? '';
  Future<void> setTaxID(String taxId) async =>
      await _prefs.setString(_kTaxID, taxId);

  // ⭐️ 2. --- ADD DEFAULT CURRENCY METHODS --- ⭐️

  /// Gets the user's preferred default currency code.
  /// Defaults to "Local" for backward compatibility.
  String getDefaultCurrencyCode() => _prefs.getString(_kDefaultCurrency) ?? 'Local';

  /// Sets the user's preferred default currency code.
  Future<void> setDefaultCurrencyCode(String code) async =>
      await _prefs.setString(_kDefaultCurrency, code);
}