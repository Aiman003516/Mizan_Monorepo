import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// --- Core Packages ---
import 'package:core_l10n/app_localizations.dart';
import 'package:core_data/core_data.dart'; // Exports Bootstrap, Preferences, EnvConfig

// --- Feature Packages ---
import 'package:feature_dashboard/feature_dashboard.dart';

// --- Feature Aliases (For Context-Aware Overrides) ---
import 'package:feature_transactions/feature_transactions.dart' as transactions_ui;

// --- App-Level Providers ---
import 'src/app_localizations_provider.dart' as app_l10n;

Future<void> main() async {
  // 1. Run the Bootstrap System
  // This single line handles:
  // - WidgetsBinding.ensureInitialized()
  // - initializing SharedPreferences
  // - initializing the Database
  // - creating the list of secure Provider Overrides
  // Note: Secrets are now injected via --dart-define (EnvConfig), not .env
  final overrides = await Bootstrap.init();

  runApp(
    ProviderScope(
      // We simply pass the pre-calculated overrides from Bootstrap
      overrides: overrides,
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // These providers are now safely initialized by Bootstrap
    final themeMode = ref.watch(themeControllerProvider);
    final locale = ref.watch(localeControllerProvider);

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
              // This MUST stay here because it requires the 'context' 
              // which is only available inside the Builder.
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