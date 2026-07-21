// FILE: packages/features/feature_settings/lib/src/presentation/custom_fields/custom_fields_screen.dart

import 'package:feature_settings/src/data/custom_fields_repository.dart';
import 'package:flutter/material.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:core_ui/core_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';
// Assuming PermissionGuard/EmptyState

class CustomFieldsScreen extends ConsumerWidget {
  final String tenantId;

  const CustomFieldsScreen({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    // For now, we only support Product fields. Can add tabs for Accounts/Transactions later.
    final fieldsAsync = ref.watch(productFieldsProvider(tenantId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.customFieldsProducts)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditor(context, ref, null),
        child: const Icon(Icons.add),
      ),
      body: fieldsAsync.when(
        data: (fields) {
          if (fields.isEmpty) {
            return const Center(child: Text("No custom fields defined."));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: fields.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final field = fields[index];
              return ListTile(
                title: Text(field.label),
                subtitle: Text("Type: ${field.type.name} | Key: ${field.key}"),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: context.appColors.error),
                  onPressed: () => ref
                      .read(customFieldsRepositoryProvider)
                      .deleteDefinition(tenantId, field.id),
                ),
                onTap: () => _showEditor(context, ref, field),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
      ),
    );
  }

  void _showEditor(
    BuildContext context,
    WidgetRef ref,
    CustomFieldDefinition? existing,
  ) {
    showDialog(
      context: context,
      builder: (ctx) =>
          _FieldEditorDialog(tenantId: tenantId, existing: existing),
    );
  }
}

class _FieldEditorDialog extends ConsumerStatefulWidget {
  final String tenantId;
  final CustomFieldDefinition? existing;

  const _FieldEditorDialog({required this.tenantId, this.existing});

  @override
  ConsumerState<_FieldEditorDialog> createState() => _FieldEditorDialogState();
}

class _FieldEditorDialogState extends ConsumerState<_FieldEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _labelCtrl;
  late TextEditingController _keyCtrl;
  CustomFieldType _selectedType = CustomFieldType.text;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.existing?.label ?? '');
    _keyCtrl = TextEditingController(text: widget.existing?.key ?? '');
    _selectedType = widget.existing?.type ?? CustomFieldType.text;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.existing == null ? l10n.addField : l10n.editField),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _labelCtrl,
              decoration: const InputDecoration(
                labelText: "Display Label (e.g. Color)",
              ),
              validator: (v) => v!.isEmpty ? "Required" : null,
              onChanged: (val) {
                // Auto-generate key if new
                if (widget.existing == null) {
                  _keyCtrl.text = val.trim().toLowerCase().replaceAll(' ', '_');
                }
              },
            ),
            TextFormField(
              controller: _keyCtrl,
              decoration: const InputDecoration(
                labelText: "Internal Key (e.g. color)",
              ),
              validator: (v) => v!.isEmpty ? "Required" : null,
            ),
            DropdownButtonFormField<CustomFieldType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(labelText: "Data Type"),
              items: CustomFieldType.values.map((t) {
                return DropdownMenuItem(
                  value: t,
                  child: Text(t.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedType = val!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final newDef = CustomFieldDefinition(
                id: widget.existing?.id ?? 'new',
                key: _keyCtrl.text,
                label: _labelCtrl.text,
                targetTable: 'products', // Hardcoded for this screen
                type: _selectedType,
              );
              await ref
                  .read(customFieldsRepositoryProvider)
                  .saveDefinition(widget.tenantId, newDef);
              if (mounted) Navigator.pop(context);
            }
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}
