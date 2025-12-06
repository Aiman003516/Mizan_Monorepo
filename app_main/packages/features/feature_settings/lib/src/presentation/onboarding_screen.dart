import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';

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

  final List<Map<String, String>> _commonCurrencies = [
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
    {'code': 'SAR', 'symbol': 'ر.س', 'name': 'Saudi Riyal'},
    {'code': 'YER', 'symbol': '﷼', 'name': 'Yemeni Rial'},
    {'code': 'AED', 'symbol': 'د.إ', 'name': 'UAE Dirham'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'CUSTOM', 'symbol': '?', 'name': 'Custom / Other'},
  ];

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
                    errorBuilder: (_, __, ___) => const Icon(Icons.account_balance_wallet, size: 60),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Welcome to Mizan",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Text("Let's set things up correctly."),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  // 🌍 SECTION 1: LANGUAGE
                  _buildSectionHeader("1. Language / اللغة", Icons.language),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _LanguageCard(
                          title: "English",
                          isSelected: locale?.languageCode == 'en',
                          onTap: () => ref.read(localeControllerProvider.notifier).setLocale(const Locale('en')),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _LanguageCard(
                          title: "العربية",
                          isSelected: locale?.languageCode == 'ar',
                          onTap: () => ref.read(localeControllerProvider.notifier).setLocale(const Locale('ar')),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 🎨 SECTION 2: THEME
                  _buildSectionHeader("2. Appearance", Icons.palette),
                  const SizedBox(height: 16),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.wb_sunny), label: Text("Light")),
                      ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.nightlight_round), label: Text("Dark")),
                      ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.settings_suggest), label: Text("Auto")),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (newSelection) {
                      ref.read(themeControllerProvider.notifier).setThemeMode(newSelection.first);
                    },
                  ),
                  const SizedBox(height: 32),

                  // 💰 SECTION 3: CURRENCY
                  _buildSectionHeader("3. Currency", Icons.monetization_on),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCurrency,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Select Primary Currency",
                    ),
                    items: _commonCurrencies.map((c) {
                      return DropdownMenuItem(
                        value: c['code'],
                        child: Text("${c['code']} - ${c['name']} (${c['symbol']})"),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCurrency = val!;
                        _isCustomCurrency = val == 'CUSTOM';
                        
                        // Auto-fill symbol for known currencies
                        if (!_isCustomCurrency) {
                          final cur = _commonCurrencies.firstWhere((c) => c['code'] == val);
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
                            decoration: const InputDecoration(
                              labelText: "Code (e.g. YER)",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _customSymbolCtrl,
                            decoration: const InputDecoration(
                              labelText: "Symbol (﷼)",
                              border: OutlineInputBorder(),
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
                  onPressed: () => _completeOnboarding(ref),
                  child: const Text("Get Started", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Future<void> _completeOnboarding(WidgetRef ref) async {
    // 1. Validate Currency
    String finalCode = _selectedCurrency;
    String finalSymbol = '\$';

    if (_isCustomCurrency) {
      if (_customCodeCtrl.text.isEmpty || _customSymbolCtrl.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter currency details")));
        return;
      }
      finalCode = _customCodeCtrl.text.toUpperCase();
      finalSymbol = _customSymbolCtrl.text;
    } else {
      final cur = _commonCurrencies.firstWhere((c) => c['code'] == _selectedCurrency);
      finalCode = cur['code']!;
      finalSymbol = cur['symbol']!;
    }

    // 2. Save to Preferences
    final prefs = ref.read(preferencesRepositoryProvider);
    await prefs.setDefaultCurrencyCode(finalCode);
    await prefs.setCurrencySymbol(finalSymbol);
    
    // 3. Mark as Complete
    await prefs.completeFirstRun();

    // 4. Trigger App Rebuild (via main.dart)
    ref.read(onboardingCompletedProvider.notifier).state = true;
  }
}

class _LanguageCard extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageCard({required this.title, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceVariant,
          border: isSelected ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : null,
          ),
        ),
      ),
    );
  }
}