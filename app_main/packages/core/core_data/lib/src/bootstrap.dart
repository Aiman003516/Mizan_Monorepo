import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 1. Import Sibling Package (For Database)
import 'package:core_database/core_database.dart';

// 2. Import Local Files (For Preferences)
import 'preferences_repository.dart';

/// The Mizan Bootstrap System.
/// Handles all "Pre-Flight" checks and initialization before the UI starts.
class Bootstrap {
  /// Initializes the core services and returns the list of Provider overrides.
  static Future<List<Override>> init() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 1. Initialize SharedPreferences
    final sharedPrefs = await SharedPreferences.getInstance();

    // 2. Initialize Database
    // We create the instance here to ensure it's ready.
    final database = AppDatabase();

    // 3. Construct Overrides
    // We inject the concrete instances into the abstract providers.
    return [
      // Override the SharedPreferences provider in core_data
      sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      
      // Override the Central Database provider in core_database
      appDatabaseProvider.overrideWithValue(database),
    ];
  }
}