import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Core Packages ---
import 'package:core_l10n/app_localizations.dart';
import 'package:core_data/core_data.dart';

// --- Feature Packages ---
import 'package:feature_dashboard/feature_dashboard.dart';
import 'package:feature_sync/feature_sync.dart';
// 🟢 NEW: Import Settings to access Onboarding
import 'package:feature_settings/feature_settings.dart';
import 'package:core_ui/core_ui.dart'; // 🟢 NEW: AppTheme
import 'package:local_auth/local_auth.dart'; // 🟢 NEW: Biometrics
import 'package:window_manager/window_manager.dart'; // 🟢 Window Management

import 'package:workmanager/workmanager.dart'; // 🟢 NEW: Background Sync

// --- Feature Aliases ---
import 'package:feature_transactions/feature_transactions.dart'
    as transactions_ui;

// --- App-Level Providers ---
import 'src/app_localizations_provider.dart' as app_l10n;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Background Sync Worker (Only needed on Mobile usually)
  if (Platform.isAndroid || Platform.isIOS) {
    Workmanager().initialize(
      callbackDispatcher, // The top level function from feature_sync
      isInDebugMode: true, // If enabled it will post a notification whenever the task is running
    );
    // Register the task to run periodically when connected
    Workmanager().registerPeriodicTask(
      "1",
      "silentBackupTask",
      frequency: const Duration(hours: 1), // Minimum is usually 15 mins on Android
      constraints: Constraints(
        networkType: NetworkType.connected, // Only run when internet is available
      ),
    );
  }

  // 🖥️ WINDOWS: Initialize window manager for size/position retention
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    
    // Load saved window preferences or use defaults
    final prefs = await SharedPreferences.getInstance();
    final double width = prefs.getDouble('window_width') ?? 1280;
    final double height = prefs.getDouble('window_height') ?? 800;
    final double? x = prefs.getDouble('window_x');
    final double? y = prefs.getDouble('window_y');
    final bool wasMaximized = prefs.getBool('window_maximized') ?? false;
    
    final WindowOptions windowOptions = WindowOptions(
      size: Size(width, height),
      center: x == null || y == null, // Center if no saved position
      minimumSize: const Size(800, 600),
      title: 'Mizan',
    );
    
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      if (x != null && y != null) {
        await windowManager.setPosition(Offset(x, y));
      }
      if (wasMaximized) {
        await windowManager.maximize();
      }
      await windowManager.show();
      await windowManager.focus();
    });
  }

  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    anonKey: EnvConfig.supabaseAnonKey,
  );

  final overrides = await Bootstrap.init();

  runApp(ProviderScope(overrides: overrides, child: const MyApp()));
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

      // 🎨 UPDATED: Use Curated Themes
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
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
          : _AuthenticatedApp(
              child: Builder(
                builder: (context) {
                  return ProviderScope(
                    overrides: [
                      transactions_ui.appLocalizationsProvider.overrideWith(
                        (ref) => ref.watch(
                          app_l10n.contextualAppLocalizationsProvider(context),
                        ),
                      ),
                    ],
                    child: const MainScaffold(),
                  );
                },
              ),
            ),
    );
  }
}

// 🔒 WRAPPER: Handles Biometric Lock lifecycle
class _AuthenticatedApp extends ConsumerStatefulWidget {
  final Widget child;
  const _AuthenticatedApp({required this.child});

  @override
  ConsumerState<_AuthenticatedApp> createState() => _AuthenticatedAppState();
}

class _AuthenticatedAppState extends ConsumerState<_AuthenticatedApp>
    with WidgetsBindingObserver, WindowListener {
  bool _isLocked = false;
  bool _biometricsEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialAuth();
    // Register as window listener on Windows
    if (Platform.isWindows) {
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    if (Platform.isWindows) {
      windowManager.removeListener(this);
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 🖥️ WINDOW STATE SAVING: Save position/size when window moves or resizes
  @override
  void onWindowResized() => _saveWindowState();
  
  @override  
  void onWindowMoved() => _saveWindowState();
  
  @override
  void onWindowMaximize() => _saveWindowState();
  
  @override
  void onWindowUnmaximize() => _saveWindowState();

  Future<void> _saveWindowState() async {
    if (!Platform.isWindows) return;
    
    final prefs = await SharedPreferences.getInstance();
    final size = await windowManager.getSize();
    final position = await windowManager.getPosition();
    final isMaximized = await windowManager.isMaximized();
    
    await prefs.setDouble('window_width', size.width);
    await prefs.setDouble('window_height', size.height);
    await prefs.setDouble('window_x', position.dx);
    await prefs.setDouble('window_y', position.dy);
    await prefs.setBool('window_maximized', isMaximized);
  }

  Future<void> _checkInitialAuth() async {
    final prefs = ref.read(preferencesRepositoryProvider);
    _biometricsEnabled = prefs.isBiometricsEnabled();

    // If enabled, start locked!
    if (_biometricsEnabled) {
      if (mounted) setState(() => _isLocked = true);
      _authenticate();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _biometricsEnabled) {
      // App came to foreground -> Lock it!
      if (!_isLocked) {
        setState(() => _isLocked = true);
        _authenticate();
      }
    }
  }

  Future<void> _authenticate() async {
    final auth = LocalAuthentication();
    try {
      final didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to access Mizan',
        options: const AuthenticationOptions(stickyAuth: true),
      );
      if (didAuthenticate && mounted) {
        setState(() => _isLocked = false);
      }
    } catch (e) {
      // Handle error (maybe fallback to PIN if implemented later)
      debugPrint("Biometric Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocked && _biometricsEnabled) {
      // Simple Lock Screen
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.blue),
              const SizedBox(height: 16),
              const Text("Mizan is Locked", style: TextStyle(fontSize: 24)),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _authenticate,
                child: const Text("Unlock"),
              ),
            ],
          ),
        ),
      );
    }
    return widget.child;
  }
}
