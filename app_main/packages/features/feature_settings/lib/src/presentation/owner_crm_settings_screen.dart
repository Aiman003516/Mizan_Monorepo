import 'package:core_l10n/app_localizations.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/owner_control_center_contract.dart';
import '../data/owner_control_center_repository.dart';

class OwnerCrmSettingsScreen extends ConsumerStatefulWidget {
  const OwnerCrmSettingsScreen({super.key});

  @override
  ConsumerState<OwnerCrmSettingsScreen> createState() =>
      _OwnerCrmSettingsScreenState();
}

class _OwnerCrmSettingsScreenState
    extends ConsumerState<OwnerCrmSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _leadStagesController = TextEditingController();
  final _pipelineStagesController = TextEditingController();
  final _interactionTypesController = TextEditingController();
  final _followUpDaysController = TextEditingController();
  final _customerCategoriesController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _duplicateFieldsController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final values = ref
        .read(ownerControlSettingsProvider)
        .section(OwnerSettingSections.crm);
    _leadStagesController.text =
        values['lead_stages'] as String? ??
        'New, Qualified, Contacted, Proposal, Won, Lost';
    _pipelineStagesController.text =
        values['pipeline_stages'] as String? ??
        'Prospecting, Discovery, Negotiation, Closed';
    _interactionTypesController.text =
        values['interaction_types'] as String? ?? 'Call, Meeting, Email, Note';
    _followUpDaysController.text = '${values['follow_up_days'] as int? ?? 7}';
    _customerCategoriesController.text =
        values['customer_categories'] as String? ?? 'Retail, Wholesale, VIP';
    _creditLimitController.text =
        '${values['default_credit_limit_minor'] as int? ?? 0}';
    _duplicateFieldsController.text =
        values['duplicate_matching_fields'] as String? ??
        'email, phone, tax_id';
  }

  @override
  void dispose() {
    _leadStagesController.dispose();
    _pipelineStagesController.dispose();
    _interactionTypesController.dispose();
    _followUpDaysController.dispose();
    _customerCategoriesController.dispose();
    _creditLimitController.dispose();
    _duplicateFieldsController.dispose();
    super.dispose();
  }

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(ownerControlSettingsProvider.notifier).saveSection(
        OwnerSettingSections.crm,
        {
          'lead_stages': _leadStagesController.text.trim(),
          'pipeline_stages': _pipelineStagesController.text.trim(),
          'interaction_types': _interactionTypesController.text.trim(),
          'follow_up_days': int.parse(_followUpDaysController.text),
          'customer_categories': _customerCategoriesController.text.trim(),
          'default_credit_limit_minor': int.parse(_creditLimitController.text),
          'duplicate_matching_fields': _duplicateFieldsController.text.trim(),
        },
      );
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
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.crmSettings),
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
            _text(_leadStagesController, l10n.crmLeadStages),
            _text(_pipelineStagesController, l10n.crmPipelineStages),
            _text(_interactionTypesController, l10n.crmInteractionTypes),
            _number(_followUpDaysController, l10n.followUpDays, 0, 3650),
            _text(_customerCategoriesController, l10n.customerCategories),
            _number(
              _creditLimitController,
              l10n.creditLimit,
              0,
              9000000000000000,
            ),
            _text(_duplicateFieldsController, l10n.duplicateDetection),
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

  Widget _text(TextEditingController controller, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      maxLength: 500,
      decoration: InputDecoration(labelText: label),
      validator: (value) =>
          value == null || value.trim().isEmpty ? l10n.requiredField : null,
    ),
  );

  Widget _number(
    TextEditingController controller,
    String label,
    int min,
    int max,
  ) => Padding(
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
