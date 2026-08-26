import 'package:core_l10n/app_localizations.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/owner_control_center_contract.dart';
import '../data/owner_control_center_repository.dart';

class OwnerPolicySettingsScreen extends ConsumerStatefulWidget {
  const OwnerPolicySettingsScreen({required this.section, super.key});

  final String section;

  @override
  ConsumerState<OwnerPolicySettingsScreen> createState() =>
      _OwnerPolicySettingsScreenState();
}

class _OwnerPolicySettingsScreenState
    extends ConsumerState<OwnerPolicySettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  late Map<String, Object?> _values;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _values = Map<String, Object?>.from(
      ref.read(ownerControlSettingsProvider).section(widget.section),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(ownerControlSettingsProvider.notifier)
          .saveSection(widget.section, _values);
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
    final title = _titleFor(widget.section);
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
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.tune, color: context.appColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ..._fieldsFor(widget.section),
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

  List<Widget> _fieldsFor(String section) {
    switch (section) {
      case OwnerSettingSections.approvals:
        return [
          _intField('expense_threshold_minor', l10n.approvalExpenseThreshold),
          _intField('invoice_threshold_minor', l10n.approvalInvoiceThreshold),
          _intField('bill_threshold_minor', l10n.approvalBillThreshold),
          _switch(
            'journal_requires_second_approver',
            l10n.journalSecondApprover,
            true,
          ),
          _switch(
            'balance_adjustment_requires_owner',
            l10n.balanceAdjustmentOwner,
            true,
          ),
          _switch(
            'refund_requires_approval',
            l10n.refundApprovalRequired,
            true,
          ),
          _numberField(
            'discount_max_percent_without_approval',
            l10n.discountApprovalLimit,
            0,
            100,
          ),
          _switch(
            'period_reopen_requires_owner',
            l10n.restoreRequiresOwner,
            true,
          ),
        ];
      case OwnerSettingSections.crm:
        return [
          _textField(
            'lead_stages',
            l10n.crmLeadStages,
            hint: 'New, Qualified, Won, Lost',
          ),
          _textField(
            'pipeline_stages',
            l10n.crmPipelineStages,
            hint: 'Prospect, Proposal, Negotiation, Closed',
          ),
          _textField(
            'interaction_types',
            l10n.crmInteractionTypes,
            hint: 'Call, Meeting, Email',
          ),
          _intField(
            'default_follow_up_days',
            l10n.followUpDays,
            min: 0,
            max: 365,
          ),
          _intField(
            'default_customer_credit_limit_minor',
            l10n.creditLimitOptional,
            min: 0,
          ),
          _textField(
            'duplicate_match_fields',
            l10n.duplicateDetection,
            hint: 'email, phone, tax_id',
          ),
        ];
      case OwnerSettingSections.inventory:
        return [
          _textField('default_warehouse_id', l10n.defaultWarehouse),
          _dropdown('stock_valuation_method', l10n.stockValuationMethod, const [
            'fifo',
            'weighted_average',
            'lifo',
          ]),
          _dropdown(
            'negative_stock_policy',
            l10n.negativeStockPolicy,
            const ['strict', 'warn', 'allow'],
            labels: [l10n.policyStrict, l10n.policyWarn, l10n.policyAllow],
          ),
          _intField('default_reorder_point', l10n.lowStockThreshold, min: 0),
          _switch(
            'low_stock_notification_enabled',
            l10n.notificationLowStock,
            true,
          ),
          _switch('barcode_required_for_pos', l10n.barcodeScanner, false),
        ];
      case OwnerSettingSections.pos:
        return [
          _textField(
            'terminal_ids',
            l10n.posAndCashControl,
            hint: 'POS-01, POS-02',
          ),
          _textField('cash_drawer_ids', l10n.cashDrawer, hint: 'Drawer-01'),
          _switch(
            'shift_close_requires_owner',
            l10n.shiftCloseRequiresOwner,
            true,
          ),
          _switch(
            'refund_requires_approval',
            l10n.refundApprovalRequired,
            true,
          ),
          _numberField(
            'max_discount_percent',
            l10n.discountApprovalLimit,
            0,
            100,
          ),
          _switch('allow_suspend_sale', l10n.suspendSale, true),
        ];
      case OwnerSettingSections.payments:
        return [
          _textField(
            'enabled_methods',
            l10n.paymentMethodsSettings,
            hint: 'cash, bank_transfer, jaib, al_kuraimi, yemen_wallet, card',
          ),
          _textField(
            'merchant_payment_instructions',
            l10n.paymentInstructions,
            maxLines: 4,
          ),
          _switch('proof_review_required', l10n.proofReviewRequired, true),
          _switch('credit_terms_enabled', l10n.creditTermsEnabled, false),
          _textField('default_payment_method', l10n.defaultPaymentMethod),
        ];
      case OwnerSettingSections.notifications:
        return [
          _switch('invoice_due_reminders', l10n.notificationInvoiceDue, true),
          _switch('low_stock_alerts', l10n.notificationLowStock, true),
          _switch('approval_alerts', l10n.notificationApprovals, true),
          _switch('sync_failure_alerts', l10n.notificationSyncFailures, true),
          _switch('invitation_alerts', l10n.notificationInvitations, true),
          _switch('backup_alerts', l10n.notificationBackups, true),
          _switch(
            'suspicious_login_alerts',
            l10n.notificationSuspiciousLogin,
            true,
          ),
        ];
      case OwnerSettingSections.sync:
        return [
          _switch('sync_enabled', l10n.syncEnabled, true),
          _switch('wifi_only_backup', l10n.wifiOnlyBackup, true),
          _intField(
            'backup_frequency_hours',
            l10n.backupFrequencyHours,
            min: 1,
            max: 720,
          ),
          _switch('restore_requires_owner', l10n.restoreRequiresOwner, true),
          _dropdown(
            'conflict_policy',
            l10n.conflictPolicy,
            const ['newest', 'review'],
            labels: [l10n.conflictNewest, l10n.conflictReview],
          ),
        ];
      case OwnerSettingSections.privacy:
        return [
          _dropdown(
            'ai_mode',
            l10n.aiMode,
            const ['disabled', 'local_only', 'cloud_opt_in'],
            labels: [l10n.aiDisabled, l10n.aiLocalOnly, l10n.aiCloudOptIn],
          ),
          _switch('local_model_enabled', l10n.localModelEnabled, false),
          _dropdown(
            'prompt_retention',
            l10n.promptRetention,
            const ['none', 'local'],
            labels: [l10n.retentionNone, l10n.retentionLocal],
          ),
          _switch('allow_employee_ai_access', l10n.employeeAiAccess, false),
          _switch(
            'minimize_cloud_ai_identifiers',
            l10n.minimizeCloudAiIdentifiers,
            true,
          ),
        ];
      case OwnerSettingSections.security:
        return [
          _intField(
            'session_duration_hours',
            l10n.sessionDurationHours,
            min: 1,
            max: 720,
          ),
          _intField(
            'audit_retention_days',
            l10n.auditRetentionDays,
            min: 30,
            max: 36500,
          ),
          _switch('export_requires_owner', l10n.exportRequiresOwner, true),
          _dropdown(
            'mfa_policy',
            l10n.mfaPolicy,
            const ['optional', 'required'],
            labels: [l10n.mfaOptional, l10n.mfaRequired],
          ),
        ];
      case OwnerSettingSections.localization:
        return [
          _dropdown(
            'default_language',
            l10n.language,
            const ['en', 'ar'],
            labels: [l10n.english, l10n.arabic],
          ),
          _dropdown(
            'document_language',
            l10n.documentLanguage,
            const ['en', 'ar', 'bilingual'],
            labels: [l10n.english, l10n.arabic, l10n.bilingual],
          ),
          _switch('rtl_enabled', l10n.rtlEnabled, true),
          _textField('timezone', l10n.timezone, hint: 'Asia/Aden'),
          _textField('default_country', l10n.defaultCountry, hint: 'YE'),
        ];
      case OwnerSettingSections.integrations:
        return [
          _switch('email_enabled', l10n.emailIntegration, false),
          _switch('sms_enabled', l10n.smsIntegration, false),
          _textField('bank_import_format', l10n.bankImportFormat, hint: 'CSV'),
          _switch('barcode_scanner_enabled', l10n.barcodeScanner, false),
          _switch('printer_enabled', l10n.printerIntegration, false),
          _switch('google_drive_enabled', l10n.driveIntegration, false),
          _textField(
            'payment_provider_status',
            l10n.paymentMethodsSettings,
            hint: 'manual_only',
          ),
        ];
      case OwnerSettingSections.expenses:
        return [
          _textField('default_expense_account_id', l10n.defaultExpenseAccount),
          _textField(
            'expense_categories',
            l10n.expenseCategories,
            hint: 'Rent, Utilities, Travel',
          ),
          _switch('receipt_required', l10n.receiptRequired, true),
          _switch(
            'reimbursement_requires_approval',
            l10n.reimbursementApprovalRequired,
            true,
          ),
          _switch('mileage_enabled', l10n.mileageEnabled, false),
        ];
      case OwnerSettingSections.banking:
        return [
          _textField(
            'bank_account_ids',
            l10n.bankAccountIds,
            hint: 'Operating account, savings account',
          ),
          _textField(
            'statement_import_format',
            l10n.statementImportFormat,
            hint: 'CSV',
          ),
          _switch(
            'reconciliation_requires_owner',
            l10n.reconciliationRequiresOwner,
            true,
          ),
          _switch('auto_match_enabled', l10n.autoMatchEnabled, true),
          _textField(
            'banking_currency_codes',
            l10n.bankingCurrencies,
            hint: 'SAR, YER, USD',
          ),
        ];
      case OwnerSettingSections.reports:
        return [
          _dropdown(
            'default_report_period',
            l10n.defaultReportPeriod,
            const ['monthly', 'quarterly', 'annual'],
            labels: [
              l10n.reportPeriodMonthly,
              l10n.reportPeriodQuarterly,
              l10n.reportPeriodAnnual,
            ],
          ),
          _switch(
            'report_export_requires_owner',
            l10n.reportExportRequiresOwner,
            true,
          ),
          _textField(
            'dashboard_metrics',
            l10n.dashboardMetrics,
            hint: 'cash, receivables, payables, revenue',
          ),
          _textField(
            'scheduled_reports',
            l10n.scheduledReports,
            hint: 'monthly_pnl, monthly_balance_sheet',
          ),
        ];
      case OwnerSettingSections.close:
        return [
          _textField(
            'close_checklist',
            l10n.closeChecklist,
            hint: 'Reconcile cash, approve drafts, verify backup',
          ),
          _switch(
            'close_requires_reconciliation',
            l10n.closeRequiresReconciliation,
            true,
          ),
          _switch('close_requires_backup', l10n.closeRequiresBackup, true),
          _switch('reopen_requires_owner', l10n.reopenRequiresOwner, true),
        ];
      default:
        return [Text(l10n.ownerSettingsComingNext)];
    }
  }

  Widget _textField(
    String key,
    String label, {
    String? hint,
    int maxLines = 1,
  }) {
    final controller = _controllers.putIfAbsent(
      key,
      () => TextEditingController(text: _values[key] as String? ?? ''),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLines > 1 ? 1000 : 200,
        decoration: InputDecoration(labelText: label, hintText: hint),
        onChanged: (value) => _values[key] = value.trim(),
      ),
    );
  }

  Widget _intField(
    String key,
    String label, {
    int min = 0,
    int max = 9000000000000000,
  }) => _numberField(key, label, min, max);

  Widget _numberField(String key, String label, int min, int max) {
    final controller = _controllers.putIfAbsent(
      key,
      () => TextEditingController(text: '${_values[key] as num? ?? min}'),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          final number = int.tryParse(value?.trim() ?? '');
          if (number == null || number < min || number > max) {
            return l10n.invalidNumber;
          }
          return null;
        },
        onChanged: (value) {
          final number = int.tryParse(value.trim());
          if (number != null) _values[key] = number;
        },
      ),
    );
  }

  Widget _switch(String key, String title, bool defaultValue) {
    final value = _values[key] as bool? ?? defaultValue;
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      value: value,
      onChanged: (next) => setState(() => _values[key] = next),
    );
  }

  Widget _dropdown(
    String key,
    String label,
    List<String> values, {
    List<String>? labels,
  }) {
    final current = values.contains(_values[key])
        ? _values[key] as String
        : values.first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: current,
        decoration: InputDecoration(labelText: label),
        items: [
          for (var index = 0; index < values.length; index++)
            DropdownMenuItem(
              value: values[index],
              child: Text(labels != null ? labels[index] : values[index]),
            ),
        ],
        onChanged: (value) {
          if (value != null) setState(() => _values[key] = value);
        },
      ),
    );
  }

  String _titleFor(String section) => switch (section) {
    OwnerSettingSections.approvals => l10n.approvalWorkflows,
    OwnerSettingSections.crm => l10n.crmConfiguration,
    OwnerSettingSections.inventory => l10n.productsInventoryWarehouses,
    OwnerSettingSections.pos => l10n.posAndCashControl,
    OwnerSettingSections.payments => l10n.paymentMethodsSettings,
    OwnerSettingSections.notifications => l10n.notificationsSettings,
    OwnerSettingSections.sync => l10n.backupAndSyncSettings,
    OwnerSettingSections.privacy => l10n.privacyAndLocalAiSettings,
    OwnerSettingSections.security => l10n.securityAndAuditSettings,
    OwnerSettingSections.localization => l10n.languageRegionAppearance,
    OwnerSettingSections.integrations => l10n.integrationsSettings,
    OwnerSettingSections.expenses => l10n.expenseSettings,
    OwnerSettingSections.banking => l10n.bankingAndReconciliation,
    OwnerSettingSections.reports => l10n.reportsSettings,
    OwnerSettingSections.close => l10n.closeManagement,
    _ => l10n.ownerControlCenter,
  };
}
