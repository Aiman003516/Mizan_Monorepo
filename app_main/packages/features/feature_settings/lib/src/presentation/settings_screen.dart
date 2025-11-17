import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// UPDATED Local Imports
import 'package:core_l10n/app_localizations.dart';
import 'package:core_data/core_data.dart';
import 'package:feature_settings/src/presentation/company_profile_screen.dart';
import 'package:feature_settings/src/presentation/security_settings_screen.dart';
import 'package:feature_settings/src/presentation/currency_settings_screen.dart';

// We will create this package soon. This error is expected.
import 'package:feature_sync/feature_sync.dart'; 

import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _showRestoreDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;

    // This provider will be defined in feature_sync. This error is expected.
    final syncStatus = ref.read(syncStatusProvider); 
    if (syncStatus == SyncStatus.inProgress) return;

    final didConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.restoreBackupTitle),
        content: Text(l10n.restoreBackupMessage),
        actions: [
          TextButton(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(l10n.restore),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (didConfirm == true) {
      // This provider will be defined in feature_sync. This error is expected.
      await ref.read(syncControllerProvider.notifier).runRestore();
    }
  }

  void _launchPlaceholderUrl(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final uri = Uri.parse('https://mizan.app/help/coming-soon');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.featureNotImplemented)),
        );
      }
    }
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentTheme = ref.read(themeControllerProvider);
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.chooseTheme),
        children: [
          RadioListTile<ThemeMode>(
            title: Text(l10n.light),
            value: ThemeMode.light,
            groupValue: currentTheme,
            onChanged: (mode) {
              ref.read(themeControllerProvider.notifier).setThemeMode(mode!);
              Navigator.pop(context);
            },
          ),
          RadioListTile<ThemeMode>(
            title: Text(l10n.dark),
            value: ThemeMode.dark,
            groupValue: currentTheme,
            onChanged: (mode) {
              ref.read(themeControllerProvider.notifier).setThemeMode(mode!);
              Navigator.pop(context);
            },
          ),
          RadioListTile<ThemeMode>(
            title: Text(l10n.systemDefault),
            value: ThemeMode.system,
            groupValue: currentTheme,
            onChanged: (mode) {
              ref.read(themeControllerProvider.notifier).setThemeMode(mode!);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.read(localeControllerProvider);
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.chooseLanguage),
        children: [
          RadioListTile<Locale?>(
            title: Text(l10n.english),
            value: const Locale('en'),
            groupValue: currentLocale,
            onChanged: (locale) {
              ref.read(localeControllerProvider.notifier).setLocale(locale);
              Navigator.pop(context);
            },
          ),
          RadioListTile<Locale?>(
            title: Text(l10n.arabic),
            value: const Locale('ar'),
            groupValue: currentLocale,
            onChanged: (locale) {
              ref.read(localeControllerProvider.notifier).setLocale(locale);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    // This provider will be defined in feature_sync. This error is expected.
    final syncState = ref.watch(syncControllerProvider);
    final isSyncing = syncState.isLoading;

    ref.listen(syncControllerProvider, (previous, next) {
      if (next.isLoading) return;
      if (next.hasError) {
        final e = next.error;
        final errorMessage = e is String ? e : e.toString();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.backupFailed(errorMessage)),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      if (!next.hasError && (previous?.isLoading ?? false)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.restoreSuccessful),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    });

    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.person),
          title: Text(l10n.companyProfile),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const CompanyProfileScreen(),
            ));
          },
        ),
        ListTile(
          leading: const Icon(Icons.lock),
          title: Text(l10n.securityOptions),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const SecuritySettingsScreen(),
            ));
          },
        ),
        ListTile(
          leading: const Icon(Icons.monetization_on),
          title: Text(l10n.currencyOptions),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const CurrencySettingsScreen(),
            ));
          },
        ),
        ListTile(
          leading: const Icon(Icons.brightness_6),
          title: Text(l10n.chooseTheme),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => _showThemeDialog(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.language),
          title: Text(l10n.language),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => _showLanguageDialog(context, ref),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child:
              Text(l10n.dataAndSync, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        ListTile(
          leading: isSyncing
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.sync),
          title: Text(l10n.backupNow),
          subtitle: Text(l10n.backupHint),
          onTap: isSyncing
              ? null
              : () => ref.read(syncControllerProvider.notifier).runBackup(),
        ),
        ListTile(
          leading: isSyncing
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.restore, color: Colors.redAccent),
          title: Text(l10n.restoreFromBackup,
              style: const TextStyle(color: Colors.redAccent)),
          subtitle: Text(l10n.restoreWarning),
          onTap: isSyncing ? null : () => _showRestoreDialog(context, ref),
        ),
        const Divider(),
        Card(
          margin: const EdgeInsets.all(16.0),
          child: InkWell(
            onTap: () => _launchPlaceholderUrl(context),
            borderRadius: BorderRadius.circular(12.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.upgradeToMizanPro,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.mizanProDescription,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}