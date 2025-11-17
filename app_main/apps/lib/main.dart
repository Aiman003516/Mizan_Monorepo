// [!code focus:18-24]
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Import from our new packages
import 'package:core_l10n/app_localizations.dart';
import 'package:core_data/core_data.dart';
import 'package:feature_dashboard/feature_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- THIS IS THE FIX ---
// Use relative paths to import files from within the same 'app_mizan' package
import 'src/app_database_provider.dart' as app_db;
import 'src/app_localizations_provider.dart' as app_l10n;
// --- END OF FIX ---

// Import placeholder providers from features that we must override
import 'package:feature_accounts/feature_accounts.dart' as accounts;
import 'package:feature_products/feature_products.dart' as products;
import 'package:feature_reports/feature_reports.dart' as reports;
import 'package:feature_settings/feature_settings.dart' as settings;
import 'package:feature_sync/feature_sync.dart' as sync;
import 'package:feature_transactions/feature_transactions.dart' as transactions;
import 'package:feature_dashboard/feature_dashboard.dart' as dashboard; // For dashboard's db provider

// ADD THIS IMPORT
import 'package:flutter_dotenv/flutter_dotenv.dart';

// MAKE MAIN ASYNC AND ADD DOTENV
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load the environment variables from the .env file
  // This file must be in the 'apps/' folder
  await dotenv.load(fileName: ".env");

  final sharedPrefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        // 1. Override the SharedPreferences provider
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        
        // 2. Override the placeholder Database provider in ALL feature packages
        //    with our single, concrete instance from app_db.
        accounts.databaseProvider.overrideWith((ref) => ref.watch(app_db.databaseProvider)),
        dashboard.databaseProvider.overrideWith((ref) => ref.watch(app_db.databaseProvider)),
        products.databaseProvider.overrideWith((ref) => ref.watch(app_db.databaseProvider)),
        reports.databaseProvider.overrideWith((ref) => ref.watch(app_db.databaseProvider)),
        settings.databaseProvider.overrideWith((ref) => ref.watch(app_db.databaseProvider)),
        sync.databaseProvider.overrideWith((ref) => ref.watch(app_db.databaseProvider)),
        transactions.databaseProvider.overrideWith((ref) => ref.watch(app_db.databaseProvider)),
        
        // 3. The l10n provider in feature_transactions will be overridden inside MyApp
        //    where we have a BuildContext.
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeControllerProvider);
    final locale = ref.watch(localeControllerProvider);

    return MaterialApp(
      title: 'Mizan',

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: themeMode,

      locale: locale,
      
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,

      debugShowCheckedModeBanner: false,

      // We wrap the home in a Builder to get a valid BuildContext
      // for our final provider override.
      home: Builder(
        builder: (context) {
          return ProviderScope(
            overrides: [
              // 4. Override the appLocalizationsProvider with the context-aware one
              transactions.appLocalizationsProvider.overrideWith(
                (ref) => ref.watch(app_l10n.contextualAppLocalizationsProvider(context)),
              ),
            ],
            child: const MainScaffold(),
          );
        },
      ),
    );
  }
}