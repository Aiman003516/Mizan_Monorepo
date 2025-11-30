// FILE: packages/core/core_data/lib/src/bootstrap.dart

import 'dart:io'; 
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import Sibling Package (For Database)
import 'package:core_database/core_database.dart';

// Import Local Files
import 'preferences_repository.dart';

/// The Mizan Bootstrap System.
/// Handles all "Pre-Flight" checks and initialization before the UI starts.
class Bootstrap {
  /// Initializes the core services and returns the list of Provider overrides.
  static Future<List<Override>> init() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 1. Initialize SharedPreferences
    final sharedPrefs = await SharedPreferences.getInstance();

    // 🧭 LAYER 1: THE CONTEXT ENGINE (First-Run Detection)
    if (sharedPrefs.getString(PreferencesRepository.keyLocale) == null) {
      try {
        final String systemLocale = Platform.localeName;
        String detectedLang = 'en';
        String detectedCurrency = 'USD';

        if (systemLocale.startsWith('ar')) {
          detectedLang = 'ar';
          detectedCurrency = 'SAR'; 
        } else if (systemLocale.startsWith('en_GB') || systemLocale.startsWith('en_UK')) {
          detectedLang = 'en';
          detectedCurrency = 'USD';
        } else {
          detectedLang = 'en';
          detectedCurrency = 'USD';
        }

        await sharedPrefs.setString(PreferencesRepository.keyLocale, detectedLang);
        await sharedPrefs.setString(PreferencesRepository.keyDefaultCurrency, detectedCurrency);
        
        debugPrint('🚀 Context Engine: Detected $systemLocale. Configured App -> Lang: $detectedLang, Currency: $detectedCurrency');
      } catch (e) {
        debugPrint('⚠️ Context Engine Failed: $e');
      }
    }

    // 2. CONSTRUCT OVERRIDES
    return [
      // Override the SharedPreferences provider
      sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      
      // ⚡ CRITICAL FIX: Use 'overrideWith' (Factory Pattern)
      // Instead of passing a dead value, we pass a factory function.
      // If the database is closed or the provider is refreshed, Riverpod
      // calls this function again to create a FRESH connection.
      appDatabaseProvider.overrideWith((ref) {
        final db = AppDatabase();
        
        // Safety: Ensure we close the connection when the provider dies
        ref.onDispose(() {
          db.close();
        });
        
        return db;
      }),
    ];
  }
}