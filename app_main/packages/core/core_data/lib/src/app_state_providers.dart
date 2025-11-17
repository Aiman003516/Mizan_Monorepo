// lib/src/core/presentation/app_state_providers.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/src/preferences_repository.dart'; // UPDATED import

// --- Theme Controller ---

final themeControllerProvider = StateNotifierProvider<ThemeController, ThemeMode>((ref) {
  return ThemeController(ref.watch(preferencesRepositoryProvider));
});

class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController(this._repo) : super(_repo.getThemeMode().toThemeMode());
  final PreferencesRepository _repo;

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _repo.setThemeMode(mode.toStorageString());
  }
}

// --- Locale Controller ---

final localeControllerProvider = StateNotifierProvider<LocaleController, Locale?>((ref) {
  return LocaleController(ref.watch(preferencesRepositoryProvider));
});

class LocaleController extends StateNotifier<Locale?> {
  LocaleController(this._repo) : super(_repo.getLocale()?.toLocale());
  final PreferencesRepository _repo;

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    if (locale != null) {
      await _repo.setLocale(locale.languageCode);
    }
  }
}

// ⭐️ --- NEW: Default Currency Controller --- ⭐️

final defaultCurrencyProvider = StateNotifierProvider<DefaultCurrencyController, String>((ref) {
  return DefaultCurrencyController(ref.watch(preferencesRepositoryProvider));
});

class DefaultCurrencyController extends StateNotifier<String> {
  DefaultCurrencyController(this._repo) : super(_repo.getDefaultCurrencyCode());
  final PreferencesRepository _repo;

  Future<void> setCurrency(String code) async {
    state = code;
    await _repo.setDefaultCurrencyCode(code);
  }
}
// ⭐️ --- END NEW --- ⭐️


// --- Extensions for conversion ---
extension on String {
  ThemeMode toThemeMode() {
    switch (this) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }
  Locale toLocale() => Locale(this);
}

extension on ThemeMode {
  String toStorageString() {
    switch (this) {
      case ThemeMode.light: return 'light';
      case ThemeMode.dark: return 'dark';
      case ThemeMode.system: return 'system';
    }
  }
}