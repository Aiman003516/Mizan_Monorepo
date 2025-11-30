import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';

// --- Core Packages ---
import 'package:core_l10n/app_localizations.dart';
import 'package:core_data/core_data.dart'; // Exports Bootstrap, Preferences, EnvConfig, MizanFirebaseConfig

// --- Feature Packages ---
import 'package:feature_dashboard/feature_dashboard.dart';
// 🚀 NEW: Import Sync Feature to access the service
import 'package:feature_sync/feature_sync.dart';

// --- Feature Aliases (For Context-Aware Overrides) ---
import 'package:feature_transactions/feature_transactions.dart' as transactions_ui;

// --- App-Level Providers ---
import 'src/app_localizations_provider.dart' as app_l10n;

Future<void> main() async {
  // 1. Initialize Bindings Explicitly
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Ignite the Cloud Engine (The Logic Switch)
  // Checks EnvConfig.appEnv and picks Dev/Prod keys automatically.
  await Firebase.initializeApp(
    options: MizanFirebaseConfig.currentPlatform,
  );

  // 3. Run the Bootstrap System (Local Engine)
  final overrides = await Bootstrap.init();

  runApp(
    ProviderScope(
      overrides: overrides,
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

    // 🚀 IGNITION SEQUENCE
    // We watch the Cloud Sync Service here to ensure it stays alive
    // as long as the app is running. This triggers the 'startSync()' logic.
    final _ = ref.watch(cloudSyncServiceProvider);

    return MaterialApp(
      title: 'Mizan',
      debugShowCheckedModeBanner: false,
      
      // Theme Configuration
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
      
      // Localization Configuration
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      
      // App Shell
      home: Builder(
        builder: (context) {
          return ProviderScope(
            overrides: [
              // Context-Aware Override
              transactions_ui.appLocalizationsProvider.overrideWith(
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