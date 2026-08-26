import 'package:core_l10n/app_localizations.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/owner_control_center_contract.dart';
import '../data/owner_control_center_repository.dart';
import 'roles/roles_list_screen.dart';
import 'staff/staff_list_screen.dart';

class OwnerEmployeeSettingsScreen extends ConsumerStatefulWidget {
  const OwnerEmployeeSettingsScreen({super.key});

  @override
  ConsumerState<OwnerEmployeeSettingsScreen> createState() =>
      _OwnerEmployeeSettingsScreenState();
}

class _OwnerEmployeeSettingsScreenState
    extends ConsumerState<OwnerEmployeeSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _defaultRoleController = TextEditingController();
  final _expiryController = TextEditingController();
  final _maxStaffController = TextEditingController();
  final _branchController = TextEditingController();
  bool _requireMfa = false;
  bool _allowSelfService = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final values = ref
        .read(ownerControlSettingsProvider)
        .section(OwnerSettingSections.employees);
    _defaultRoleController.text = values['default_role_id'] as String? ?? '';
    _expiryController.text =
        '${values['invitation_expiry_hours'] as int? ?? 24}';
    _maxStaffController.text = '${values['max_active_staff'] as int? ?? 100}';
    _branchController.text =
        values['default_branch_assignment'] as String? ?? '';
    _requireMfa = values['require_mfa_for_staff'] as bool? ?? false;
    _allowSelfService =
        values['allow_self_service_profile_edit'] as bool? ?? true;
  }

  @override
  void dispose() {
    _defaultRoleController.dispose();
    _expiryController.dispose();
    _maxStaffController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(ownerControlSettingsProvider.notifier)
          .saveSection(OwnerSettingSections.employees, {
            'default_role_id': _defaultRoleController.text.trim(),
            'invitation_expiry_hours': int.parse(_expiryController.text),
            'max_active_staff': int.parse(_maxStaffController.text),
            'require_mfa_for_staff': _requireMfa,
            'allow_self_service_profile_edit': _allowSelfService,
            'default_branch_assignment': _branchController.text.trim(),
          });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.settingsSaved),
          backgroundColor: context.appColors.success,
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorWithDetails(l10n.error, error.toString())),
            backgroundColor: context.appColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _open(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.employeeGovernance),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.employeeGovernance,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.employeesRolesInvitations),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _defaultRoleController,
              decoration: InputDecoration(
                labelText: l10n.defaultRole,
                prefixIcon: const Icon(Icons.badge),
              ),
            ),
            const SizedBox(height: 12),
            _numberField(_expiryController, l10n.invitationExpiryHours, 1, 720),
            _numberField(_maxStaffController, l10n.maxActiveStaff, 1, 10000),
            TextFormField(
              controller: _branchController,
              decoration: InputDecoration(
                labelText: l10n.defaultBranchAssignment,
                prefixIcon: const Icon(Icons.storefront),
              ),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.requireMfaForStaff),
              value: _requireMfa,
              onChanged: (value) => setState(() => _requireMfa = value),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.allowSelfServiceProfileEdit),
              value: _allowSelfService,
              onChanged: (value) => setState(() => _allowSelfService = value),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(l10n.saveSettings),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _open(const StaffListScreen()),
              icon: const Icon(Icons.groups),
              label: Text(l10n.manageEmployees),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _open(const RolesListScreen()),
              icon: const Icon(Icons.admin_panel_settings),
              label: Text(l10n.manageRoles),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String label,
    int min,
    int max,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          final number = int.tryParse(value?.trim() ?? '');
          return number == null || number < min || number > max
              ? l10n.invalidNumber
              : null;
        },
      ),
    );
  }
}
