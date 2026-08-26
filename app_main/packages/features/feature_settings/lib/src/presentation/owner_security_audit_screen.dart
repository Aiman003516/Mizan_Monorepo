import 'package:core_l10n/app_localizations.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/owner_control_center_repository.dart';
import 'security_settings_screen.dart';

class OwnerSecurityAuditScreen extends ConsumerWidget {
  const OwnerSecurityAuditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final repository = ref.watch(ownerControlCenterRepositoryProvider);
    final entries = repository.auditLog().reversed.toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.securityAndAuditSettings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(Icons.security, color: context.appColors.primary),
              title: Text(l10n.openSecuritySettings),
              subtitle: Text(l10n.securityOptions),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SecuritySettingsScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.settingsAuditHistory,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.localAuditScope,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.noSettingsAuditEntries),
              ),
            )
          else
            ...entries.map(
              (entry) => Card(
                child: ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(l10n.revisionNumber(entry.revision.toString())),
                  subtitle: Text(
                    '${entry.createdAt.toLocal()}\n${entry.sectionNames.join(', ')}',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
