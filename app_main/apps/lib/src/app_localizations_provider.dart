import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_l10n/app_localizations.dart';

/// Provides the AppLocalizations object based on the current context.
/// This provider is intended to be used within a build context.
final appLocalizationsProvider = Provider<AppLocalizations>((ref) {
  // This default implementation will be overridden in main.dart
  // with one that has a BuildContext.
  throw UnimplementedError('appLocalizationsProvider must be overridden in a context-aware way');
});

/// Helper provider that gives a BuildContext-aware AppLocalizations instance.
/// This is the one you'll use in main.dart's MyApp.
final contextualAppLocalizationsProvider = Provider.family<AppLocalizations, BuildContext>(
  (ref, context) => AppLocalizations.of(context)!,
);