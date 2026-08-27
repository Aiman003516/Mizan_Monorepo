import 'package:core_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

/// JavaScript can represent integers exactly only through 2^53 - 1.
const _maxSafeInteger = 9007199254740991;

/// Shared submit contract used by customer and supplier adjustment flows.
typedef BalanceAdjustmentSubmit =
    Future<void> Function({
      required int amountMinor,
      required bool increase,
      required String reason,
      String? reference,
      required DateTime effectiveDate,
      required String currencyCode,
    });

class BalanceAdjustmentDialog extends StatefulWidget {
  const BalanceAdjustmentDialog({
    super.key,
    required this.contactType,
    required this.contactName,
    required this.currentBalance,
    required this.currencyCode,
    required this.onSubmit,
  });

  final ContactType contactType;
  final String contactName;
  final int currentBalance;
  final String currencyCode;
  final BalanceAdjustmentSubmit onSubmit;

  @override
  State<BalanceAdjustmentDialog> createState() =>
      _BalanceAdjustmentDialogState();
}

class _BalanceAdjustmentDialogState extends State<BalanceAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  final _referenceController = TextEditingController();
  bool _increase = true;
  bool _isLoading = false;
  DateTime _effectiveDate = DateTime.now();

  bool get _isCustomer => widget.contactType == ContactType.receivable;

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  int? get _amountMinor {
    final value = double.tryParse(_amountController.text.trim());
    if (value == null || !value.isFinite || value <= 0) return null;
    final minor = value * 100;
    if (minor > _maxSafeInteger || minor.round() <= 0) return null;
    return minor.round();
  }

  int get _previewBalance =>
      widget.currentBalance +
      (_increase ? (_amountMinor ?? 0) : -(_amountMinor ?? 0));

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _effectiveDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null && mounted) setState(() => _effectiveDate = selected);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    final amountMinor = _amountMinor;
    if (amountMinor == null) return;
    if (_previewBalance < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.balanceAdjustmentCannotBeNegative)),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.reviewAdjustment),
        content: Text(
          l10n.reviewBalanceAdjustment(
            widget.contactName,
            CurrencyFormatter.formatAmount(amountMinor, widget.currencyCode),
            CurrencyFormatter.formatAmount(
              _previewBalance,
              widget.currencyCode,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.confirmAdjustment),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      await widget.onSubmit(
        amountMinor: amountMinor,
        increase: _increase,
        reason: _reasonController.text.trim(),
        reference: _referenceController.text.trim().isEmpty
            ? null
            : _referenceController.text.trim(),
        effectiveDate: _effectiveDate,
        currencyCode: widget.currencyCode,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.balanceAdjustmentFailed),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final increaseLabel = _isCustomer ? l10n.charge : l10n.increasePayable;
    final decreaseLabel = _isCustomer ? l10n.receive : l10n.decreasePayable;
    final increaseHelp = _isCustomer
        ? l10n.increasesDebt
        : l10n.increasesPayable;
    final decreaseHelp = _isCustomer
        ? l10n.decreasesDebt
        : l10n.decreasesPayable;

    return AlertDialog(
      title: Text(l10n.adjustBalance(widget.contactName)),
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
                    label: Text(increaseLabel),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text(decreaseLabel),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                ],
                selected: {_increase},
                onSelectionChanged: _isLoading
                    ? null
                    : (selection) =>
                          setState(() => _increase = selection.first),
              ),
              const SizedBox(height: 12),
              Text(
                _increase ? increaseHelp : decreaseHelp,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                enabled: !_isLoading,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: l10n.amount,
                  prefixText:
                      '${CurrencyFormatter.getCurrencySymbol(widget.currencyCode)} ',
                  border: const OutlineInputBorder(),
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _reasonController,
                enabled: !_isLoading,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: l10n.adjustmentReason,
                  hintText: l10n.adjustmentReasonHint,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.length < 3) return l10n.adjustmentReasonRequired;
                  return null;
                },
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _referenceController,
                enabled: !_isLoading,
                maxLength: 120,
                decoration: InputDecoration(
                  labelText: l10n.adjustmentReferenceOptional,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _chooseDate,
                icon: const Icon(Icons.event),
                label: Text(
                  '${l10n.effectiveDate}: ${MaterialLocalizations.of(context).formatMediumDate(_effectiveDate)}',
                ),
              ),
              const SizedBox(height: 12),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.resultingBalance,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatAmount(
                          _previewBalance,
                          widget.currencyCode,
                        ),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        l10n.balanceAdjustmentPreview,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
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
