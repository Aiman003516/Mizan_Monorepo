import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:core_data/src/secure_storage_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.dart');
});

final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  final sharedPrefs = ref.watch(sharedPreferencesProvider);
  final secureStorage = ref.watch(flutterSecureStorageProvider);
  return PreferencesRepository(sharedPrefs, secureStorage);
});

class PreferencesRepository {
  PreferencesRepository(this._prefs, this._secureStorage);

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  // --- Keys ---
  static const _kThemeMode = 'theme_mode';
  static const _kLocale = 'locale_code';
  static const _kPasscodeEnabled = 'passcode_enabled';
  static const _kBiometricsEnabled = 'biometrics_enabled';
  static const _kHasSeenSyncWarning = 'has_seen_sync_warning';
  static const _kCompanyName = 'company_name';
  static const _kUserName = 'user_name';
  static const _kCompanyAddress = 'company_address';
  static const _kTaxID = 'tax_id';
  static const _kDefaultCurrency = 'default_currency_code';
  static const _kPeriodLockDate = 'period_lock_date';
  
  // ⭐️ NEW KEY: Costing Method
  static const _kInventoryCostingMethod = 'inventory_costing_method';

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

  // --- Default Currency ---
  String getDefaultCurrencyCode() => _prefs.getString(_kDefaultCurrency) ?? 'Local';
  Future<void> setDefaultCurrencyCode(String code) async =>
      await _prefs.setString(_kDefaultCurrency, code);

  // --- Period Locking ---
  DateTime? getPeriodLockDate() {
    final str = _prefs.getString(_kPeriodLockDate);
    if (str == null) return null;
    return DateTime.tryParse(str);
  }
  Future<void> setPeriodLockDate(DateTime date) async {
    await _prefs.setString(_kPeriodLockDate, date.toIso8601String());
  }

  // ⭐️ NEW METHODS: Inventory Costing ⭐️
  
  /// Returns 'fifo' (default) or 'weighted_average'
  String getInventoryCostingMethod() => _prefs.getString(_kInventoryCostingMethod) ?? 'fifo';

  Future<void> setInventoryCostingMethod(String method) async {
    await _prefs.setString(_kInventoryCostingMethod, method);
  }
}