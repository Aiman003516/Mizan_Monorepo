import 'package:core_l10n/app_localizations.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/owner_control_center_contract.dart';
import '../data/owner_control_center_repository.dart';

class OwnerPosSettingsScreen extends ConsumerStatefulWidget {
  const OwnerPosSettingsScreen({super.key});

  @override
  ConsumerState<OwnerPosSettingsScreen> createState() =>
      _OwnerPosSettingsScreenState();
}

class _OwnerPosSettingsScreenState
    extends ConsumerState<OwnerPosSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _terminalsController = TextEditingController();
  final _drawersController = TextEditingController();
  final _discountController = TextEditingController();
  final _receiptTemplateController = TextEditingController();
  String _defaultPaymentMethod = 'cash';
  bool _shiftCloseRequiresOwner = true;
  bool _refundRequiresApproval = true;
  bool _suspendSale = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final values = ref
        .read(ownerControlSettingsProvider)
        .section(OwnerSettingSections.pos);
    _terminalsController.text =
        values['terminals'] as String? ?? 'Main terminal';
    _drawersController.text =
        values['cash_drawers'] as String? ?? 'Main drawer';
    _discountController.text =
        '${values['discount_max_percent'] as num? ?? 10}';
    _receiptTemplateController.text =
        values['receipt_template'] as String? ?? 'standard';
    _defaultPaymentMethod =
        values['default_payment_method'] as String? ?? 'cash';
    _shiftCloseRequiresOwner =
        values['shift_close_requires_owner'] as bool? ?? true;
    _refundRequiresApproval =
        values['refund_requires_approval'] as bool? ?? true;
    _suspendSale = values['suspend_sale_enabled'] as bool? ?? true;
  }

  @override
  void dispose() {
    _terminalsController.dispose();
    _drawersController.dispose();
    _discountController.dispose();
    _receiptTemplateController.dispose();
    super.dispose();
  }

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(ownerControlSettingsProvider.notifier)
          .saveSection(OwnerSettingSections.pos, {
            'terminals': _terminalsController.text.trim(),
            'cash_drawers': _drawersController.text.trim(),
            'opening_balance_required': true,
            'shift_close_requires_owner': _shiftCloseRequiresOwner,
            'refund_requires_approval': _refundRequiresApproval,
            'discount_max_percent': double.parse(_discountController.text),
            'suspend_sale_enabled': _suspendSale,
            'receipt_template': _receiptTemplateController.text.trim(),
            'default_payment_method': _defaultPaymentMethod,
            'cashier_permissions': 'sell, collect_payment',
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
        title: Text(l10n.posAndCashControl),
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
            _text(_terminalsController, l10n.posTerminals),
            _text(_drawersController, l10n.cashDrawer),
            _text(_receiptTemplateController, l10n.receiptTemplate),
            TextFormField(
              controller: _discountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.discountApprovalLimit,
              ),
              validator: (value) {
                final number = double.tryParse(value?.trim() ?? '');
                return number == null || number < 0 || number > 100
                    ? l10n.invalidNumber
                    : null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _defaultPaymentMethod,
              decoration: InputDecoration(labelText: l10n.defaultPaymentMethod),
              items: [
                DropdownMenuItem(value: 'cash', child: Text(l10n.cashPayment)),
                DropdownMenuItem(
                  value: 'bank_transfer',
                  child: Text(l10n.bankTransferPayment),
                ),
                DropdownMenuItem(value: 'card', child: Text(l10n.cardPayment)),
                DropdownMenuItem(
                  value: 'credit',
                  child: Text(l10n.creditPayment),
                ),
              ],
              onChanged: (value) =>
                  setState(() => _defaultPaymentMethod = value!),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.shiftCloseRequiresOwner),
              value: _shiftCloseRequiresOwner,
              onChanged: (value) =>
                  setState(() => _shiftCloseRequiresOwner = value),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.refundApprovalRequired),
              value: _refundRequiresApproval,
              onChanged: (value) =>
                  setState(() => _refundRequiresApproval = value),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.suspendSale),
              value: _suspendSale,
              onChanged: (value) => setState(() => _suspendSale = value),
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
}
