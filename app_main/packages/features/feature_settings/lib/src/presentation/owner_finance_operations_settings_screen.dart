import 'package:core_l10n/app_localizations.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/owner_control_center_contract.dart';
import '../data/owner_control_center_repository.dart';

class OwnerFinanceOperationsSettingsScreen extends ConsumerStatefulWidget {
  const OwnerFinanceOperationsSettingsScreen({
    required this.section,
    super.key,
  });

  final String section;

  @override
  ConsumerState<OwnerFinanceOperationsSettingsScreen> createState() =>
      _OwnerFinanceOperationsSettingsScreenState();
}

class _OwnerFinanceOperationsSettingsScreenState
    extends ConsumerState<OwnerFinanceOperationsSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  final _categoriesController = TextEditingController();
  final _formatController = TextEditingController();
  final _currencyController = TextEditingController();
  bool _receiptRequired = true;
  bool _approvalRequired = true;
  bool _mileageEnabled = false;
  bool _ownerReconciliation = true;
  bool _autoMatch = true;
  bool _isSaving = false;

  bool get isExpenses => widget.section == OwnerSettingSections.expenses;
  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    final values = ref
        .read(ownerControlSettingsProvider)
        .section(widget.section);
    if (isExpenses) {
      _accountController.text =
          values['default_expense_account_id'] as String? ?? '';
      _categoriesController.text =
          values['expense_categories'] as String? ?? '';
      _receiptRequired = values['receipt_required'] as bool? ?? true;
      _approvalRequired =
          values['reimbursement_requires_approval'] as bool? ?? true;
      _mileageEnabled = values['mileage_enabled'] as bool? ?? false;
    } else {
      _accountController.text = values['bank_account_ids'] as String? ?? '';
      _formatController.text =
          values['statement_import_format'] as String? ?? 'CSV';
      _currencyController.text =
          values['banking_currency_codes'] as String? ?? '';
      _ownerReconciliation =
          values['reconciliation_requires_owner'] as bool? ?? true;
      _autoMatch = values['auto_match_enabled'] as bool? ?? true;
    }
  }

  @override
  void dispose() {
    _accountController.dispose();
    _categoriesController.dispose();
    _formatController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      final values = isExpenses
          ? <String, Object?>{
              'default_expense_account_id': _accountController.text.trim(),
              'expense_categories': _categoriesController.text.trim(),
              'receipt_required': _receiptRequired,
              'reimbursement_requires_approval': _approvalRequired,
              'mileage_enabled': _mileageEnabled,
            }
          : <String, Object?>{
              'bank_account_ids': _accountController.text.trim(),
              'statement_import_format': _formatController.text.trim(),
              'reconciliation_requires_owner': _ownerReconciliation,
              'auto_match_enabled': _autoMatch,
              'banking_currency_codes': _currencyController.text.trim(),
            };
      await ref
          .read(ownerControlSettingsProvider.notifier)
          .saveSection(widget.section, values);
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

  @override
  Widget build(BuildContext context) {
    final title = isExpenses
        ? l10n.expenseSettings
        : l10n.bankingAndReconciliation;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
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
          children: isExpenses ? _expenseFields() : _bankingFields(),
        ),
      ),
    );
  }

  List<Widget> _expenseFields() => [
    _textField(_accountController, l10n.defaultExpenseAccount, required: false),
    _textField(_categoriesController, l10n.expenseCategories, required: false),
    SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.receiptRequired),
      value: _receiptRequired,
      onChanged: (value) => setState(() => _receiptRequired = value),
    ),
    SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.reimbursementApprovalRequired),
      value: _approvalRequired,
      onChanged: (value) => setState(() => _approvalRequired = value),
    ),
    SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.mileageEnabled),
      value: _mileageEnabled,
      onChanged: (value) => setState(() => _mileageEnabled = value),
    ),
    _saveButton(),
  ];

  List<Widget> _bankingFields() => [
    _textField(_accountController, l10n.bankAccountIds, required: false),
    _textField(_formatController, l10n.statementImportFormat),
    _textField(_currencyController, l10n.bankingCurrencies, required: false),
    SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.reconciliationRequiresOwner),
      value: _ownerReconciliation,
      onChanged: (value) => setState(() => _ownerReconciliation = value),
    ),
    SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.autoMatchEnabled),
      value: _autoMatch,
      onChanged: (value) => setState(() => _autoMatch = value),
    ),
    _saveButton(),
  ];

  Widget _textField(
    TextEditingController controller,
    String label, {
    bool required = true,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      maxLength: 500,
      decoration: InputDecoration(labelText: label),
      validator: required && controller.text.trim().isEmpty
          ? (_) => l10n.requiredField
          : null,
    ),
  );

  Widget _saveButton() => FilledButton.icon(
    onPressed: _isSaving ? null : _save,
    icon: const Icon(Icons.save),
    label: Text(l10n.saveSettings),
  );
}
