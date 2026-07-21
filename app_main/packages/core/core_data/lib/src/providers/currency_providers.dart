// FILE: packages/core/core_data/lib/src/providers/currency_providers.dart
// Purpose: Riverpod providers for the user's active currency configuration.
// All UI screens should ref.watch(currentCurrencyCodeProvider) instead of
// hardcoding '$' or any other currency symbol.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/src/preferences_repository.dart';

/// The user's currently configured default currency code (e.g., 'USD', 'SAR').
/// All screens that display currency should watch this provider.
final currentCurrencyCodeProvider = Provider<String>((ref) {
  final prefs = ref.watch(preferencesRepositoryProvider);
  return prefs.getDefaultCurrencyCode();
});
