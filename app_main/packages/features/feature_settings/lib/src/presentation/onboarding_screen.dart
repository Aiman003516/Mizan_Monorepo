import 'package:flutter/material.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';
import 'package:feature_settings/src/presentation/onboarding_tutorial_screen.dart';

// We need a provider to trigger the "First Run Completed" action
// This will just refresh the main app state
final onboardingCompletedProvider = StateProvider<bool>((ref) => false);

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  // Local state for the "Custom Currency" fields
  final TextEditingController _customCodeCtrl = TextEditingController();
  final TextEditingController _customSymbolCtrl = TextEditingController();
  bool _isCustomCurrency = false;
  String _selectedCurrency = 'USD';
  bool _isLoading = false;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  List<Map<String, String>> get _commonCurrencies {
    final isAr = ref.read(localeControllerProvider)?.languageCode == 'ar';
    return [
      {'code': 'USD', 'symbol': '\$', 'name': isAr ? 'دولار أمريكي' : 'US Dollar'},
      {'code': 'SAR', 'symbol': isAr ? 'ر.س' : 'SAR', 'name': isAr ? 'ريال سعودي' : 'Saudi Riyal'},
      {'code': 'YER', 'symbol': '﷼', 'name': isAr ? 'ريال يمني' : 'Yemeni Rial'},
      {'code': 'AED', 'symbol': isAr ? 'د.إ' : 'AED', 'name': isAr ? 'درهم إماراتي' : 'UAE Dirham'},
      {'code': 'EUR', 'symbol': '€', 'name': isAr ? 'يورو' : 'Euro'},
      {'code': 'CUSTOM', 'symbol': '?', 'name': isAr ? 'مخصص / آخر' : 'Custom / Other'},
    ];
  }

  @override
  void dispose() {
    _customCodeCtrl.dispose();
    _customSymbolCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeControllerProvider);
    final locale = ref.watch(localeControllerProvider);
    // ignore: unused_local_variable
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/mizan_full.png', // Ensure this exists or use icon
                    height: 60,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.account_balance_wallet, size: 60),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.welcomeToMizan,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(l10n.letsSetUpCorrectly),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  // 🌍 SECTION 1: LANGUAGE
                  _buildSectionHeader(
                    l10n.language,
                    Icons.language,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _LanguageCard(
                          title: "English",
                          isSelected: locale?.languageCode == 'en',
                          onTap: () => ref
                              .read(localeControllerProvider.notifier)
                              .setLocale(const Locale('en')),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _LanguageCard(
                          title: "العربية",
                          isSelected: locale?.languageCode == 'ar',
                          onTap: () => ref
                              .read(localeControllerProvider.notifier)
                              .setLocale(const Locale('ar')),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 🎨 SECTION 2: THEME
                  _buildSectionHeader(
                    "${l10n.light} / ${l10n.dark}",
                    Icons.palette,
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<ThemeMode>(
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: const Icon(Icons.wb_sunny),
                        label: Text(l10n.light),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: const Icon(Icons.nightlight_round),
                        label: Text(l10n.dark),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: const Icon(Icons.settings_suggest),
                        label: Text(l10n.systemDefault),
                      ),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (newSelection) {
                      ref
                          .read(themeControllerProvider.notifier)
                          .setThemeMode(newSelection.first);
                    },
                  ),
                  const SizedBox(height: 32),

                  // 💰 SECTION 3: CURRENCY
                  _buildSectionHeader(
                    l10n.currencyOptions,
                    Icons.monetization_on,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCurrency,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: l10n.selectPrimaryCurrency,
                    ),
                    items: _commonCurrencies.map((c) {
                      return DropdownMenuItem(
                        value: c['code'],
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(c['symbol']!, style: const TextStyle(fontWeight: FontWeight.bold, fontFamilyFallback: ['packages/core_ui/SaudiRiyal'])),
                              const SizedBox(width: 12),
                              Text(c['code']!),
                              const Text(' - '),
                              Text(c['name']!),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCurrency = val!;
                        _isCustomCurrency = val == 'CUSTOM';

                        // Auto-fill symbol for known currencies
                        if (!_isCustomCurrency) {
                          final cur = _commonCurrencies.firstWhere(
                            (c) => c['code'] == val,
                          );
                          _customCodeCtrl.text = cur['code']!;
                          _customSymbolCtrl.text = cur['symbol']!;
                        } else {
                          _customCodeCtrl.clear();
                          _customSymbolCtrl.clear();
                        }
                      });
                    },
                  ),

                  // Custom Currency Fields (Animated)
                  if (_isCustomCurrency) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _customCodeCtrl,
                            decoration: InputDecoration(
                              labelText: l10n.currencyCodeLabel,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _customSymbolCtrl,
                            style: const TextStyle(fontFamilyFallback: ['packages/core_ui/SaudiRiyal']),
                            decoration: InputDecoration(
                              labelText: l10n.currencySymbolLabel,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // 🚀 Footer Action
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isLoading ? null : () => _completeOnboarding(ref),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Text(
                          l10n.getStarted,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Future<void> _completeOnboarding(WidgetRef ref) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Validate Currency
      String finalCode = _selectedCurrency;
      String finalSymbol = '\$';

      if (_isCustomCurrency) {
        if (_customCodeCtrl.text.isEmpty || _customSymbolCtrl.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please enter currency details")),
          );
          setState(() { _isLoading = false; });
          return;
        }
        finalCode = _customCodeCtrl.text.toUpperCase();
        finalSymbol = _customSymbolCtrl.text;
      } else {
        final cur = _commonCurrencies.firstWhere(
          (c) => c['code'] == _selectedCurrency,
        );
        finalCode = cur['code']!;
        finalSymbol = cur['symbol']!;
      }

      // 2. Save to Preferences
      final prefs = ref.read(preferencesRepositoryProvider);
      await prefs.setDefaultCurrencyCode(finalCode);
      await prefs.setCurrencySymbol(finalSymbol);

      // 3. Ensure currency exists in database to prevent Dropdown AssertionErrors
      final currencyService = ref.read(currencyServiceProvider);
      try {
        final existingCurrencies = await currencyService.getAllCurrencies();
        if (!existingCurrencies.any((c) => c.code == finalCode)) {
          await currencyService.addCurrency(
            code: finalCode,
            name: _isCustomCurrency
                ? 'Custom Currency'
                : _commonCurrencies.firstWhere(
                    (c) => c['code'] == finalCode,
                  )['name']!,
            symbol: finalSymbol,
          );
        }
      } catch (e) {
        debugPrint("Error adding currency to DB: $e");
      }

      // 4. Mark as Complete
      await prefs.completeFirstRun();

      // 4. Show feature tutorial, then trigger App Rebuild
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (builderContext) => OnboardingTutorialScreen(
              onComplete: () {
                // Trigger App Rebuild via ProviderScope to avoid 'ref disposed' error
                ProviderScope.containerOf(builderContext).read(onboardingCompletedProvider.notifier).state = true;
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class _LanguageCard extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : null,
          ),
        ),
      ),
    );
  }
}
