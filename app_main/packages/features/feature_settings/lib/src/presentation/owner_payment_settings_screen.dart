import 'package:core_l10n/app_localizations.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/owner_control_center_contract.dart';
import '../data/owner_control_center_repository.dart';

class OwnerPaymentSettingsScreen extends ConsumerStatefulWidget {
  const OwnerPaymentSettingsScreen({super.key});

  @override
  ConsumerState<OwnerPaymentSettingsScreen> createState() =>
      _OwnerPaymentSettingsScreenState();
}

class _OwnerPaymentSettingsScreenState
    extends ConsumerState<OwnerPaymentSettingsScreen> {
  final _instructionsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _enabled = <String, bool>{
    'cash': true,
    'bank_transfer': true,
    'jaib': false,
    'al_kuraimi': false,
    'yemen_wallet': false,
    'card': false,
    'credit': false,
  };
  bool _proofReviewRequired = true;
  bool _creditTermsEnabled = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final values = ref
        .read(ownerControlSettingsProvider)
        .section(OwnerSettingSections.payments);
    final rawMethods = values['enabled_methods'];
    if (rawMethods is String) {
      for (final method in rawMethods.split(',')) {
        final key = method.trim().toLowerCase();
        if (_enabled.containsKey(key)) _enabled[key] = true;
      }
    }
    _instructionsController.text =
        values['merchant_payment_instructions'] as String? ?? '';
    _proofReviewRequired = values['proof_review_required'] as bool? ?? true;
    _creditTermsEnabled = values['credit_terms_enabled'] as bool? ?? false;
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  String _label(String key) => switch (key) {
    'cash' => l10n.cashPayment,
    'bank_transfer' => l10n.bankTransferPayment,
    'jaib' => l10n.jaibPayment,
    'al_kuraimi' => l10n.alKuraimiPayment,
    'yemen_wallet' => l10n.yemenWalletPayment,
    'card' => l10n.cardPayment,
    'credit' => l10n.creditPayment,
    _ => key,
  };

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      final methods = _enabled.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .join(', ');
      if (methods.isEmpty) throw StateError(l10n.requiredField);
      await ref.read(ownerControlSettingsProvider.notifier).saveSection(
        OwnerSettingSections.payments,
        {
          'enabled_methods': methods,
          'merchant_payment_instructions': _instructionsController.text.trim(),
          'proof_review_required': _proofReviewRequired,
          'credit_terms_enabled': _creditTermsEnabled,
          'default_payment_method': _enabled['cash'] == true
              ? 'cash'
              : methods.split(',').first,
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
        title: Text(l10n.paymentMethodCatalog),
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
              child: Column(
                children: _enabled.keys
                    .map(
                      (key) => SwitchListTile.adaptive(
                        title: Text(_label(key)),
                        value: _enabled[key]!,
                        onChanged: (value) =>
                            setState(() => _enabled[key] = value),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _instructionsController,
              maxLines: 4,
              maxLength: 1000,
              decoration: InputDecoration(
                labelText: l10n.merchantPaymentInstructions,
                helperText: l10n.merchantInstructionHint,
              ),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.proofReviewRequired),
              subtitle: Text(l10n.paymentProofReview),
              value: _proofReviewRequired,
              onChanged: (value) =>
                  setState(() => _proofReviewRequired = value),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.creditTermsEnabled),
              value: _creditTermsEnabled,
              onChanged: (value) => setState(() => _creditTermsEnabled = value),
            ),
            const SizedBox(height: 12),
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
