import 'package:core_data/core_data.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_ui/shared_ui.dart';

import '../data/owner_control_center_contract.dart';
import '../data/owner_control_center_repository.dart';

class OwnerCompanySetupWizardScreen extends ConsumerStatefulWidget {
  const OwnerCompanySetupWizardScreen({super.key});

  @override
  ConsumerState<OwnerCompanySetupWizardScreen> createState() =>
      _OwnerCompanySetupWizardScreenState();
}

class _OwnerCompanySetupWizardScreenState
    extends ConsumerState<OwnerCompanySetupWizardScreen> {
  final _companyFormKey = GlobalKey<FormState>();
  final _accountingFormKey = GlobalKey<FormState>();
  final _branchFormKey = GlobalKey<FormState>();
  final _operationsFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _taxNumberController = TextEditingController();
  final _branchController = TextEditingController();
  final _taxCodeController = TextEditingController();
  final _paymentMethodsController = TextEditingController();
  final _firstEmployeeController = TextEditingController();

  int _currentStep = 0;
  int _fiscalYearStartMonth = 1;
  String _industry = 'retail';
  String _currency = 'USD';
  bool _receiptRequired = true;
  bool _proofReviewRequired = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(companyProfileProvider);
    final settings = ref.read(ownerControlSettingsProvider);
    final company = settings.section(OwnerSettingSections.company);
    final accounting = settings.section(OwnerSettingSections.accounting);
    final branches = settings.section(OwnerSettingSections.branches);
    final taxes = settings.section(OwnerSettingSections.taxes);
    final payments = settings.section(OwnerSettingSections.payments);
    final employees = settings.section(OwnerSettingSections.employees);

    _nameController.text =
        company['business_name'] as String? ?? profile.companyName;
    _addressController.text =
        company['address'] as String? ?? profile.companyAddress;
    _taxNumberController.text =
        company['tax_number'] as String? ?? profile.taxID;
    _industry = company['industry'] as String? ?? 'retail';
    _currency =
        accounting['base_currency_code'] as String? ??
        ref.read(defaultCurrencyProvider);
    _fiscalYearStartMonth = accounting['fiscal_year_start_month'] as int? ?? 1;
    _branchController.text =
        branches['default_branch_name'] as String? ?? 'Main branch';
    _taxCodeController.text = taxes['default_tax_code'] as String? ?? '';
    _paymentMethodsController.text =
        payments['enabled_methods'] as String? ?? 'cash, bank_transfer';
    _firstEmployeeController.text =
        employees['pending_first_employee_email'] as String? ?? '';
    _receiptRequired =
        settings.section(OwnerSettingSections.expenses)['receipt_required']
            as bool? ??
        true;
    _proofReviewRequired = payments['proof_review_required'] as bool? ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _taxNumberController.dispose();
    _branchController.dispose();
    _taxCodeController.dispose();
    _paymentMethodsController.dispose();
    _firstEmployeeController.dispose();
    super.dispose();
  }

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  Future<void> _save() async {
    final valid =
        (_companyFormKey.currentState?.validate() ?? false) &&
        (_accountingFormKey.currentState?.validate() ?? false) &&
        (_branchFormKey.currentState?.validate() ?? false) &&
        (_operationsFormKey.currentState?.validate() ?? false);
    if (!valid) return;

    setState(() => _isSaving = true);
    try {
      final profile = ref.read(companyProfileProvider);
      await ref
          .read(companyProfileProvider.notifier)
          .saveProfile(
            companyName: _nameController.text.trim(),
            userName: profile.userName,
            companyAddress: _addressController.text.trim(),
            taxID: _taxNumberController.text.trim(),
            imagePath: profile.imagePath,
          );

      final settingsController = ref.read(
        ownerControlSettingsProvider.notifier,
      );
      await settingsController.saveSection(OwnerSettingSections.company, {
        'business_name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'tax_number': _taxNumberController.text.trim(),
        'industry': _industry,
        'fiscal_year_start_month': _fiscalYearStartMonth,
      });
      await settingsController.saveSection(OwnerSettingSections.accounting, {
        'base_currency_code': _currency,
        'rounding_mode': 'half_up',
        'period_close_requires_owner': true,
        'opening_balance_status': 'not_started',
      });
      await settingsController.saveSection(OwnerSettingSections.branches, {
        'default_branch_name': _branchController.text.trim(),
        'branch_access_mode': 'assigned_branches',
        'branch_records': [
          {
            'id': 'local-default-branch',
            'name': _branchController.text.trim(),
            'active': true,
          },
        ],
      });
      await settingsController.saveSection(OwnerSettingSections.taxes, {
        'default_tax_code': _taxCodeController.text.trim(),
        'tax_inclusive_pricing': false,
        'tax_number_required': _taxNumberController.text.trim().isNotEmpty,
        'tax_exempt_reasons': const <String>[],
        'tax_period': 'monthly',
      });
      await settingsController.saveSection(OwnerSettingSections.payments, {
        'enabled_methods': _paymentMethodsController.text.trim(),
        'merchant_payment_instructions': '',
        'proof_review_required': _proofReviewRequired,
        'credit_terms_enabled': false,
        'default_payment_method': 'cash',
      });
      await settingsController.saveSection(OwnerSettingSections.expenses, {
        'expense_categories': '',
        'receipt_required': _receiptRequired,
        'reimbursement_requires_approval': true,
        'mileage_enabled': false,
      });
      await settingsController.saveSection(OwnerSettingSections.employees, {
        'invitation_expiry_hours': 24,
        'max_active_staff': 100,
        'require_mfa_for_staff': false,
        'allow_self_service_profile_edit': true,
        'default_branch_assignment': _branchController.text.trim(),
        'pending_first_employee_email': _firstEmployeeController.text.trim(),
      });
      await ref.read(defaultCurrencyProvider.notifier).setCurrency(_currency);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.setupSaved),
          backgroundColor: context.appColors.success,
        ),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorWithDetails(l10n.error, error.toString())),
          backgroundColor: context.appColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l10n.setupWizardTitle)),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _isSaving
            ? null
            : () {
                if (_currentStep == 0 &&
                    !(_companyFormKey.currentState?.validate() ?? false)) {
                  return;
                }
                if (_currentStep == 1 &&
                    !(_accountingFormKey.currentState?.validate() ?? false)) {
                  return;
                }
                if (_currentStep == 2 &&
                    !(_branchFormKey.currentState?.validate() ?? false)) {
                  return;
                }
                if (_currentStep < 3) {
                  setState(() => _currentStep++);
                } else {
                  _save();
                }
              },
        onStepCancel: _currentStep == 0 || _isSaving
            ? null
            : () => setState(() => _currentStep--),
        controlsBuilder: (context, details) {
          final isLast = _currentStep == 3;
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                FilledButton(
                  onPressed: details.onStepContinue,
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isLast ? l10n.finishSetup : l10n.continueText),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: Text(l10n.back),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          Step(
            title: Text(l10n.setupWizardCompanyStep),
            isActive: _currentStep >= 0,
            content: Form(
              key: _companyFormKey,
              child: Column(
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(l10n.setupWizardDescription),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l10n.companyName,
                      prefixIcon: const Icon(Icons.business),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? l10n.requiredField
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _industry,
                    decoration: InputDecoration(
                      labelText: l10n.selectIndustry,
                      prefixIcon: const Icon(Icons.category),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'retail',
                        child: Text(l10n.retailBusinessTemplate),
                      ),
                      DropdownMenuItem(
                        value: 'service',
                        child: Text(l10n.serviceBusinessTemplate),
                      ),
                      DropdownMenuItem(
                        value: 'professional',
                        child: Text(l10n.professionalServices),
                      ),
                    ],
                    onChanged: (value) => setState(() => _industry = value!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: l10n.companyAddress,
                      prefixIcon: const Icon(Icons.location_on),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _taxNumberController,
                    decoration: InputDecoration(
                      labelText: l10n.taxID,
                      prefixIcon: const Icon(Icons.receipt_long),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Step(
            title: Text(l10n.setupWizardAccountingStep),
            isActive: _currentStep >= 1,
            content: Form(
              key: _accountingFormKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _currency,
                    decoration: InputDecoration(
                      labelText: l10n.selectCurrency,
                      prefixIcon: const Icon(Icons.currency_exchange),
                    ),
                    items: const ['USD', 'SAR', 'YER', 'EUR', 'AED']
                        .map(
                          (code) =>
                              DropdownMenuItem(value: code, child: Text(code)),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _currency = value!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _fiscalYearStartMonth,
                    decoration: InputDecoration(
                      labelText: l10n.fiscalYearStartMonth,
                      prefixIcon: const Icon(Icons.calendar_month),
                    ),
                    items: List.generate(
                      12,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}'),
                      ),
                    ),
                    onChanged: (value) =>
                        setState(() => _fiscalYearStartMonth = value!),
                  ),
                ],
              ),
            ),
          ),
          Step(
            title: Text(l10n.setupWizardBranchStep),
            isActive: _currentStep >= 2,
            content: Form(
              key: _branchFormKey,
              child: TextFormField(
                controller: _branchController,
                decoration: InputDecoration(
                  labelText: l10n.defaultBranchName,
                  prefixIcon: const Icon(Icons.storefront),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? l10n.requiredField
                    : null,
              ),
            ),
          ),
          Step(
            title: Text(l10n.setupWizardOperationsStep),
            isActive: _currentStep >= 3,
            content: Form(
              key: _operationsFormKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _taxCodeController,
                    decoration: InputDecoration(
                      labelText: l10n.defaultTaxCode,
                      prefixIcon: const Icon(Icons.percent),
                    ),
                    maxLength: 32,
                  ),
                  TextFormField(
                    controller: _paymentMethodsController,
                    decoration: InputDecoration(
                      labelText: l10n.defaultPaymentMethods,
                      hintText: l10n.paymentMethodsExample,
                      prefixIcon: const Icon(Icons.payments),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? l10n.requiredField
                        : null,
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.receiptRequired),
                    value: _receiptRequired,
                    onChanged: (value) =>
                        setState(() => _receiptRequired = value),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.proofReviewRequired),
                    value: _proofReviewRequired,
                    onChanged: (value) =>
                        setState(() => _proofReviewRequired = value),
                  ),
                  TextFormField(
                    controller: _firstEmployeeController,
                    decoration: InputDecoration(
                      labelText: l10n.firstEmployeeEmail,
                      prefixIcon: const Icon(Icons.person_add),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => InputValidators.optionalEmail(
                      value,
                      invalidMessage: l10n.invalidEmail,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      l10n.inviteAfterConnect,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
