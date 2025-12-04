import 'dart:io';
import 'package:feature_settings/feature_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ⚡ FIXED: Added missing import
import 'staff/staff_list_screen.dart'; // Add import

// Local Imports
import 'package:core_l10n/app_localizations.dart';
import 'package:core_data/core_data.dart';
import 'package:feature_settings/src/presentation/company_profile_screen.dart';
import 'package:feature_settings/src/presentation/security_settings_screen.dart';
import 'package:feature_settings/src/presentation/currency_settings_screen.dart';
import 'package:feature_settings/src/presentation/roles/roles_list_screen.dart'; // ⚡ NEW: Import Roles Screen

// Import Sync Feature
import 'package:feature_sync/feature_sync.dart'; 

import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _showRestoreDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;

    final syncStatus = ref.read(syncStatusProvider);
    
    // Prevent double-action
    if (syncStatus == SyncStatus.backupInProgress || 
        syncStatus == SyncStatus.restoreInProgress) return;

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
          // ⚡ FIX: Removed const
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
            // ⚡ FIX: Removed 'const'
            value: Locale('en'), 
            groupValue: currentLocale,
            onChanged: (locale) {
              ref.read(localeControllerProvider.notifier).setLocale(locale);
              Navigator.pop(context);
            },
          ),
          RadioListTile<Locale?>(
            title: Text(l10n.arabic),
            // ⚡ FIX: Removed 'const'
            value: Locale('ar'), 
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

    final syncStatus = ref.watch(syncStatusProvider);
    final isBackingUp = syncStatus == SyncStatus.backupInProgress;
    final isRestoring = syncStatus == SyncStatus.restoreInProgress;
    final isBusy = isBackingUp || isRestoring; 

    // 👂 LISTENER 1: Success Messages (Granular)
    ref.listen<SyncStatus>(syncStatusProvider, (previous, next) {
      if (next == SyncStatus.backupSuccess) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            // ⚡ FIX: No 'const', and passed argument "Google Drive"
            SnackBar(
              content: Text(l10n.backupSuccessful), 
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (next == SyncStatus.restoreSuccess) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            // ⚡ FIX: No 'const'
            SnackBar(
              content: Text(l10n.restoreSuccessful),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    });

    // 👂 LISTENER 2: Error Messages (From Controller)
    ref.listen(syncControllerProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            // ⚡ FIX: No 'const'
            SnackBar(
              content: Text(l10n.backupFailed),
              backgroundColor: Colors.red,
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
          leading: isBackingUp
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.sync),
          title: Text(l10n.backupNow),
          subtitle: Text(l10n.backupHint),
          onTap: isBusy
              ? null
              : () => ref.read(syncControllerProvider.notifier).runBackup(),
        ),
        ListTile(
          leading: isRestoring
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.restore, color: Colors.redAccent),
          title: Text(l10n.restoreFromBackup,
              style: const TextStyle(color: Colors.redAccent)),
          subtitle: Text(l10n.restoreWarning),
          onTap: isBusy ? null : () => _showRestoreDialog(context, ref),
        ),
        
        const Divider(),

        // 🛡️ SYSTEM ACTIVATION & ADMIN CONTROLS (Phase 4 Logic)
        Consumer(
          builder: (context, ref, _) {
            final roleAsync = ref.watch(userRoleProvider);
            
            return roleAsync.when(
              data: (role) {
                // Scenario A: User is already the Owner/Admin
                // Show a passive "Badge" indicating success AND the Admin Tools.
                if (role.isSystemAdmin) {
                  return Column(
                    children: [
                      const ListTile(
                        leading: Icon(Icons.verified, color: Colors.blue),
                        title: Text("Enterprise License Active"),
                        subtitle: Text("You are the System Administrator"),
                      ),
                      
                      // 🌟 NEW: Roles Management Button (Only for Admins)
                      ListTile(
                        leading: const Icon(Icons.badge, color: Colors.purple),
                        title: const Text("Manage Roles"),
                        subtitle: const Text("Define staff permissions"),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RolesListScreen()),
                          );
                        },
                      ),


                      // 🌟 NEW: Billing Management
                      ListTile(
                        leading: const Icon(Icons.credit_card, color: Colors.orange),
                        title: const Text("Manage Subscription"),
                        subtitle: const Text("View plans & billing"),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
                          );
                        },
                      ),

                      ListTile(
                        leading: const Icon(Icons.group, color: Colors.indigo),
                        title: const Text("Manage Staff"),
                        subtitle: const Text("View list & invite members"),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const StaffListScreen()),
                          );
                        },
                      ),
                    ],
                  );
                }

                // Scenario B: User is a Guest (New Buyer)
                // Show the interactive "Activate" button to run the Genesis Script.
                return ListTile(
                  leading: const Icon(Icons.rocket_launch, color: Colors.green),
                  title: const Text("Activate Business License"),
                  subtitle: const Text("Initialize system & claim ownership"),
                  onTap: () async {
                    
                    // 🔍 DEBUGGING: Check who is logged in
                    final user = FirebaseAuth.instance.currentUser;
                    print("🕵️‍♂️ [DEBUG] Current User: ${user?.email ?? 'NULL (Guest)'}");
                    print("🕵️‍♂️ [DEBUG] UID: ${user?.uid}");

                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("⚠️ You are not logged in! Please Sign In first."),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    try {
                      // 👑 RUN THE CLEAN GENESIS
                      await ref.read(saasSeedingServiceProvider).activateSystemForBuyer();
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("✅ System Activated! Welcome, Admin."),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("❌ Activation Failed: $e"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            );
          },
        ),

        const SizedBox(height: 16), // Spacing

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