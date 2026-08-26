import 'package:core_l10n/app_localizations.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/owner_control_center_contract.dart';
import '../data/owner_control_center_repository.dart';

class OwnerCloseManagementScreen extends ConsumerStatefulWidget {
  const OwnerCloseManagementScreen({super.key});

  @override
  ConsumerState<OwnerCloseManagementScreen> createState() =>
      _OwnerCloseManagementScreenState();
}

class _OwnerCloseManagementScreenState
    extends ConsumerState<OwnerCloseManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _checklistController = TextEditingController();
  final _dateController = TextEditingController();
  bool _requiresReconciliation = true;
  bool _requiresBackup = true;
  bool _requiresOwnerToReopen = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final values = ref
        .read(ownerControlSettingsProvider)
        .section(OwnerSettingSections.close);
    _checklistController.text =
        values['close_checklist'] as String? ??
        'Reconcile cash, review approvals, verify drafts, confirm backup';
    _dateController.text = values['close_through_date'] as String? ?? '';
    _requiresReconciliation =
        values['close_requires_reconciliation'] as bool? ?? true;
    _requiresBackup = values['close_requires_backup'] as bool? ?? true;
    _requiresOwnerToReopen = values['reopen_requires_owner'] as bool? ?? true;
  }

  @override
  void dispose() {
    _checklistController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(ownerControlSettingsProvider.notifier)
          .saveSection(OwnerSettingSections.close, {
            'close_checklist': _checklistController.text.trim(),
            'close_through_date': _dateController.text.trim(),
            'close_requires_reconciliation': _requiresReconciliation,
            'close_requires_backup': _requiresBackup,
            'reopen_requires_owner': _requiresOwnerToReopen,
          });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.closeChecklistSaved),
          backgroundColor: context.appColors.success,
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error} $error'),
            backgroundColor: context.appColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.closeManagement),
        actions: [
          IconButton(
            tooltip: l10n.saveSettings,
            onPressed: _isSaving ? null : _save,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.closeNotExecutedGuest),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _checklistController,
              maxLines: 4,
              maxLength: 1000,
              decoration: InputDecoration(labelText: l10n.closeChecklist),
              validator: (value) => value == null || value.trim().isEmpty
                  ? l10n.requiredField
                  : null,
            ),
            TextFormField(
              controller: _dateController,
              keyboardType: TextInputType.datetime,
              decoration: InputDecoration(
                labelText: l10n.closeThroughDate,
                hintText: 'YYYY-MM-DD',
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return null;
                final parsed = DateTime.tryParse(text);
                return parsed == null ||
                        parsed.toIso8601String().substring(0, 10) != text
                    ? l10n.invalidDate
                    : null;
              },
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.closeRequiresReconciliation),
              value: _requiresReconciliation,
              onChanged: (value) =>
                  setState(() => _requiresReconciliation = value),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.closeRequiresBackup),
              value: _requiresBackup,
              onChanged: (value) => setState(() => _requiresBackup = value),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.reopenRequiresOwner),
              value: _requiresOwnerToReopen,
              onChanged: (value) =>
                  setState(() => _requiresOwnerToReopen = value),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(l10n.saveSettings),
            ),
          ],
        ),
      ),
    );
  }
}
