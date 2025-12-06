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

  // --- 🔑 Keys ---
  static const keyIsFirstRun = 'is_first_run'; // 🟢 NEW
  static const keyThemeMode = 'theme_mode';
  static const keyLocale = 'locale_code';
  static const keyPasscodeEnabled = 'passcode_enabled';
  static const keyBiometricsEnabled = 'biometrics_enabled';
  static const keyHasSeenSyncWarning = 'has_seen_sync_warning';
  static const keyCompanyName = 'company_name';
  static const keyUserName = 'user_name';
  static const keyCompanyAddress = 'company_address';
  static const keyTaxID = 'tax_id';
  static const keyDefaultCurrency = 'default_currency_code';
  static const keyCurrencySymbol = 'currency_symbol'; // 🟢 NEW
  static const keyPeriodLockDate = 'period_lock_date';
  static const keyInventoryCostingMethod = 'inventory_costing_method';
  static const keyLastSyncTimestamp = 'last_sync_timestamp';
  static const _kPasscodePin = 'passcode_pin';

  // --- 🚪 Gatekeeper (First Run) ---
  bool isFirstRun() => _prefs.getBool(keyIsFirstRun) ?? true;
  
  Future<void> completeFirstRun() async =>
      await _prefs.setBool(keyIsFirstRun, false);

  // --- Theme ---
  String getThemeMode() => _prefs.getString(keyThemeMode) ?? 'system';
  Future<void> setThemeMode(String mode) async =>
      await _prefs.setString(keyThemeMode, mode);

  // --- Locale ---
  String? getLocale() => _prefs.getString(keyLocale);
  Future<void> setLocale(String code) async =>
      await _prefs.setString(keyLocale, code);

  // --- Currency (Enhanced) ---
  String getDefaultCurrencyCode() => _prefs.getString(keyDefaultCurrency) ?? 'USD';
  Future<void> setDefaultCurrencyCode(String code) async =>
      await _prefs.setString(keyDefaultCurrency, code);

  String getCurrencySymbol() => _prefs.getString(keyCurrencySymbol) ?? '\$'; // 🟢 NEW
  Future<void> setCurrencySymbol(String symbol) async =>
      await _prefs.setString(keyCurrencySymbol, symbol);

  // --- Passcode Enabled ---
  bool isPasscodeEnabled() => _prefs.getBool(keyPasscodeEnabled) ?? false;
  Future<void> setPasscodeEnabled(bool enabled) async =>
      await _prefs.setBool(keyPasscodeEnabled, enabled);

  // --- Biometrics Enabled ---
  bool isBiometricsEnabled() => _prefs.getBool(keyBiometricsEnabled) ?? false;
  Future<void> setBiometricsEnabled(bool enabled) async =>
      await _prefs.setBool(keyBiometricsEnabled, enabled);

  // --- Passcode PIN (Secure) ---
  Future<String?> getPasscode() async =>
      await _secureStorage.read(key: _kPasscodePin);
  Future<void> setPasscode(String pin) async =>
      await _secureStorage.write(key: _kPasscodePin, value: pin);
  Future<void> clearPasscode() async =>
      await _secureStorage.delete(key: _kPasscodePin);

  // --- Sync Warning ---
  bool hasSeenSyncWarning() => _prefs.getBool(keyHasSeenSyncWarning) ?? false;
  Future<void> setHasSeenSyncWarning(bool value) async =>
      await _prefs.setBool(keyHasSeenSyncWarning, value);

  // --- Company Profile ---
  String getCompanyName() => _prefs.getString(keyCompanyName) ?? '';
  Future<void> setCompanyName(String name) async =>
      await _prefs.setString(keyCompanyName, name);

  String getUserName() => _prefs.getString(keyUserName) ?? '';
  Future<void> setUserName(String name) async =>
      await _prefs.setString(keyUserName, name);

  String getCompanyAddress() => _prefs.getString(keyCompanyAddress) ?? '';
  Future<void> setCompanyAddress(String address) async =>
      await _prefs.setString(keyCompanyAddress, address);

  String getTaxID() => _prefs.getString(keyTaxID) ?? '';
  Future<void> setTaxID(String taxId) async =>
      await _prefs.setString(keyTaxID, taxId);

  // --- Period Locking ---
  DateTime? getPeriodLockDate() {
    final str = _prefs.getString(keyPeriodLockDate);
    if (str == null) return null;
    return DateTime.tryParse(str);
  }
  Future<void> setPeriodLockDate(DateTime date) async {
    await _prefs.setString(keyPeriodLockDate, date.toIso8601String());
  }

  // --- Inventory Costing ---
  String getInventoryCostingMethod() => _prefs.getString(keyInventoryCostingMethod) ?? 'fifo';
  Future<void> setInventoryCostingMethod(String method) async {
    await _prefs.setString(keyInventoryCostingMethod, method);
  }

  // --- ☁️ Sync Engine Methods ---
  DateTime getLastSyncTime() {
    final str = _prefs.getString(keyLastSyncTimestamp);
    if (str == null) return DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.parse(str);
  }

  Future<void> setLastSyncTime(DateTime date) async {
    await _prefs.setString(keyLastSyncTimestamp, date.toIso8601String());
  }
}