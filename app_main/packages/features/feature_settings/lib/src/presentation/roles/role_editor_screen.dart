import 'package:flutter/material.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:core_ui/core_ui.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart'; // Exports AppRole, AppPermission, RolesRepository

class RoleEditorScreen extends ConsumerStatefulWidget {
  final AppRole? roleToEdit;

  const RoleEditorScreen({super.key, this.roleToEdit});

  @override
  ConsumerState<RoleEditorScreen> createState() => _RoleEditorScreenState();
}

class _RoleEditorScreenState extends ConsumerState<RoleEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  // Local state for the checklist
  final Set<AppPermission> _selectedPermissions = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.roleToEdit != null) {
      // Editing Mode: Populate data
      _nameController.text = widget.roleToEdit!.name;
      _selectedPermissions.addAll(widget.roleToEdit!.permissions);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // 📝 Helper to get human-readable localized labels
  String _getPermissionLabel(AppPermission p, AppLocalizations l10n) {
    switch (p) {
      case AppPermission.viewDashboard:
        return l10n.permViewDashboard;
      case AppPermission.viewFinancialReports:
        return l10n.permViewFinancialReports;
      case AppPermission.performSale:
        return l10n.permPerformSale;
      case AppPermission.voidTransaction:
        return l10n.permVoidTransaction;
      case AppPermission.processRefund:
        return l10n.permProcessRefund;
      case AppPermission.viewSalesHistory:
        return l10n.permViewSalesHistory;
      case AppPermission.viewInventory:
        return l10n.permViewInventory;
      case AppPermission.manageProducts:
        return l10n.permManageProducts;
      case AppPermission.adjustInventory:
        return l10n.permAdjustInventory;
      case AppPermission.manageStaff:
        return l10n.permManageStaff;
      case AppPermission.manageSettings:
        return l10n.permManageSettings;
      case AppPermission.switchTenant:
        return l10n.permSwitchTenant;
    }
  }

  /// Shows a user-friendly dialog explaining this is a paid/online feature.
  void _showPaidFeatureError(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.paidFeatureTitle),
        content: Text(l10n.paidFeatureMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _saveRole() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPermissions.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.selectPermission)));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newRole = AppRole(
        // If editing, keep ID. If new, pass empty string (Repository will auto-id)
        id: widget.roleToEdit?.id ?? '',
        name: _nameController.text.trim(),
        permissions: _selectedPermissions.toList(),
        isSystemAdmin: false, // Custom roles are never System Admins
      );

      await ref.read(rolesRepositoryProvider).saveRole(newRole);

      if (mounted) {
        Navigator.pop(context); // Close screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.roleSaved),
            backgroundColor: context.appColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorStr = e.toString().toLowerCase();
        // Check if this is an auth/subscription error — show friendly dialog
        if (errorStr.contains('not logged in') ||
            errorStr.contains('tenant id') ||
            errorStr.contains('unauthorized') ||
            errorStr.contains('unauthenticated') ||
            errorStr.contains('permission denied')) {
          _showPaidFeatureError(l10n);
        } else {
          // Other unexpected errors — show in snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: context.appColors.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.roleToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.editRole : l10n.createNewRole),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _saveRole,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  // --- Identity Section ---
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n.roleNameLabel,
                        hintText: l10n.roleNameHint,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.badge),
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? l10n.nameIsRequired
                          : null,
                    ),
                  ),
                  const Divider(),

                  // --- Permissions Section ---
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.permissionsLabel,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                      ),
                    ),
                  ),

                  Expanded(
                    child: ListView.separated(
                      itemCount: AppPermission.values.length,
                      separatorBuilder: (ctx, i) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final permission = AppPermission.values[index];
                        final isSelected = _selectedPermissions.contains(
                          permission,
                        );

                        return CheckboxListTile(
                          title: Text(_getPermissionLabel(permission, l10n)),
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedPermissions.add(permission);
                              } else {
                                _selectedPermissions.remove(permission);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
