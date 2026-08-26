import 'package:core_l10n/app_localizations.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/owner_control_center_contract.dart';
import '../data/owner_control_center_repository.dart';

class OwnerBranchSettingsScreen extends ConsumerWidget {
  const OwnerBranchSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(ownerControlSettingsProvider);
    final rawRecords = settings.section(
      OwnerSettingSections.branches,
    )['branch_records'];
    final records = rawRecords is List
        ? rawRecords
              .whereType<Map>()
              .map((item) => Map<String, Object?>.from(item))
              .toList()
        : <Map<String, Object?>>[];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.branchManagement)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref, null),
        icon: const Icon(Icons.add),
        label: Text(l10n.addBranch),
      ),
      body: records.isEmpty
          ? Center(child: Text(l10n.noBranchesYet))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final record = records[index];
                final name = record['name'] as String? ?? '';
                final code = record['code'] as String? ?? '';
                final active = record['active'] as bool? ?? false;
                return Card(
                  child: ListTile(
                    leading: Icon(
                      active ? Icons.storefront : Icons.storefront_outlined,
                      color: active ? context.appColors.success : null,
                    ),
                    title: Text(name),
                    subtitle: Text(
                      code.isEmpty
                          ? (record['address'] as String? ?? '')
                          : code,
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _openEditor(context, ref, record);
                        } else if (value == 'delete') {
                          _delete(context, ref, record);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(l10n.remove),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref,
    Map<String, Object?>? existing,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(
      text: existing?['name'] as String? ?? '',
    );
    final codeController = TextEditingController(
      text: existing?['code'] as String? ?? '',
    );
    final addressController = TextEditingController(
      text: existing?['address'] as String? ?? '',
    );
    var active = existing?['active'] as bool? ?? true;
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? l10n.addBranch : l10n.editBranch),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: l10n.branchName),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? l10n.requiredField
                        : null,
                  ),
                  TextFormField(
                    controller: codeController,
                    decoration: InputDecoration(labelText: l10n.branchCode),
                    maxLength: 16,
                  ),
                  TextFormField(
                    controller: addressController,
                    decoration: InputDecoration(labelText: l10n.branchAddress),
                    maxLines: 2,
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.activeBranch),
                    value: active,
                    onChanged: (value) => setDialogState(() => active = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;
                Navigator.of(dialogContext).pop({
                  'id':
                      existing?['id'] ??
                      'branch-${DateTime.now().microsecondsSinceEpoch}',
                  'name': nameController.text.trim(),
                  'code': codeController.text.trim(),
                  'address': addressController.text.trim(),
                  'active': active,
                });
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    codeController.dispose();
    addressController.dispose();
    if (result == null) return;

    final settings = ref.read(ownerControlSettingsProvider);
    final branchSection = Map<String, Object?>.from(
      settings.section(OwnerSettingSections.branches),
    );
    final rawRecords = branchSection['branch_records'];
    final records = rawRecords is List
        ? rawRecords
              .whereType<Map>()
              .map((item) => Map<String, Object?>.from(item))
              .toList()
        : <Map<String, Object?>>[];
    final index = records.indexWhere((item) => item['id'] == result['id']);
    if (index == -1) {
      records.add(result);
    } else {
      records[index] = result;
    }
    branchSection['branch_records'] = records;
    branchSection['default_branch_id'] ??= result['id'];
    branchSection['default_branch_name'] ??= result['name'];
    await ref
        .read(ownerControlSettingsProvider.notifier)
        .saveSection(OwnerSettingSections.branches, branchSection);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.branchSaved)));
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Map<String, Object?> record,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.read(ownerControlSettingsProvider);
    final branchSection = Map<String, Object?>.from(
      settings.section(OwnerSettingSections.branches),
    );
    final rawRecords = branchSection['branch_records'];
    final records = rawRecords is List
        ? rawRecords
              .whereType<Map>()
              .map((item) => Map<String, Object?>.from(item))
              .toList()
        : <Map<String, Object?>>[];
    if (records.length <= 1) return;
    records.removeWhere((item) => item['id'] == record['id']);
    branchSection['branch_records'] = records;
    if (branchSection['default_branch_id'] == record['id']) {
      branchSection['default_branch_id'] = records.first['id'];
      branchSection['default_branch_name'] = records.first['name'];
    }
    await ref
        .read(ownerControlSettingsProvider.notifier)
        .saveSection(OwnerSettingSections.branches, branchSection);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.branchDeleted)));
    }
  }
}
