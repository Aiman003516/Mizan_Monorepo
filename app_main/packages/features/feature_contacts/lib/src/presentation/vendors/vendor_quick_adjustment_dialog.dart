import 'package:core_data/core_data.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_ui/shared_ui.dart';

class VendorQuickAdjustmentDialog extends ConsumerStatefulWidget {
  const VendorQuickAdjustmentDialog({
    super.key,
    required this.vendorId,
    required this.vendorName,
  });

  final String vendorId;
  final String vendorName;

  @override
  ConsumerState<VendorQuickAdjustmentDialog> createState() =>
      _VendorQuickAdjustmentDialogState();
}

class _VendorQuickAdjustmentDialogState
    extends ConsumerState<VendorQuickAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _increasePayable = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text.trim());
    setState(() => _isLoading = true);

    try {
      await ref
          .read(apRepositoryProvider)
          .recordQuickAdjustment(
            vendorId: widget.vendorId,
            amount: (amount * 100).round(),
            increasePayable: _increasePayable,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.supplierAdjustmentFailed),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currencyCode = ref.watch(currentCurrencyCodeProvider);
    final currencySymbol = CurrencyFormatter.getCurrencySymbol(currencyCode);

    return AlertDialog(
      title: Text(l10n.adjustBalance(widget.vendorName)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: true,
                    label: Text(l10n.increasePayable),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text(l10n.decreasePayable),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                ],
                selected: {_increasePayable},
                onSelectionChanged: _isLoading
                    ? null
                    : (selection) =>
                          setState(() => _increasePayable = selection.first),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                enabled: !_isLoading,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.amount,
                  prefixText: '$currencySymbol ',
                  border: const OutlineInputBorder(),
                  helperText: _increasePayable
                      ? l10n.increasesPayable
                      : l10n.decreasesPayable,
                ),
                validator: (value) => InputValidators.requiredDecimal(
                  value,
                  requiredMessage: l10n.pleaseEnterValidAmount,
                  invalidMessage: l10n.pleaseEnterValidAmount,
                  minimum: 0,
                  allowNegative: false,
                  exclusiveMinimum: true,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: l10n.notesOptional,
                  prefixIcon: const Icon(Icons.notes),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.saveAdjustment),
        ),
      ],
    );
  }
}
