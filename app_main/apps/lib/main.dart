import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';

// --- Core Packages ---
import 'package:core_l10n/app_localizations.dart';
import 'package:core_data/core_data.dart'; 

// --- Feature Packages ---
import 'package:feature_dashboard/feature_dashboard.dart';
import 'package:feature_sync/feature_sync.dart';
// 🟢 NEW: Import Settings to access Onboarding
import 'package:feature_settings/feature_settings.dart'; 

// --- Feature Aliases ---
import 'package:feature_transactions/feature_transactions.dart' as transactions_ui;

// --- App-Level Providers ---
import 'src/app_localizations_provider.dart' as app_l10n;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: MizanFirebaseConfig.currentPlatform,
  );
  

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

    // Watch Sync Service
    final _ = ref.watch(cloudSyncServiceProvider);

    // 🟢 GATEKEEPER LOGIC
    // We check the repo directly. If the UI button updates the repo and notifies a provider,
    // we can use a provider here. For simplicity, we read the Repo state or
    // watch the special provider we created in OnboardingScreen to trigger a rebuild.
    final prefs = ref.watch(preferencesRepositoryProvider);
    final isFirstRun = prefs.isFirstRun();
    
    // We also watch the 'completion' provider so the app rebuilds immediately 
    // when the user clicks 'Get Started'.
    final justCompleted = ref.watch(onboardingCompletedProvider);

    // If it WAS first run, but user JUST completed it, show dashboard.
    // Otherwise, respect the stored pref.
    final showOnboarding = isFirstRun && !justCompleted;

    return MaterialApp(
      title: 'Mizan',
      debugShowCheckedModeBanner: false,
      
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
      
      // 🟢 ROUTING SWITCH
      home: showOnboarding 
        ? const OnboardingScreen() 
        : Builder(
            builder: (context) {
              return ProviderScope(
                overrides: [
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