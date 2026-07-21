import 'package:flutter/material.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';
import 'package:shared_ui/shared_ui.dart';

class QuickAdjustmentDialog extends ConsumerStatefulWidget {
  final String customerId;
  final String customerName;

  const QuickAdjustmentDialog({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  ConsumerState<QuickAdjustmentDialog> createState() =>
      _QuickAdjustmentDialogState();
}

class _QuickAdjustmentDialogState extends ConsumerState<QuickAdjustmentDialog> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isCharge =
      true; // true = Add money (Customer owes more), false = Subtract money (Customer paid)
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) return;

    final amountDouble = double.tryParse(amountText);
    if (amountDouble == null || amountDouble <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseEnterValidAmount)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(arRepositoryProvider);
      await repo.recordQuickAdjustment(
        customerId: widget.customerId,
        amount: (amountDouble * 100).round(),
        isCharge: _isCharge,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.adjustBalance(widget.customerName)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Toggle
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: true,
                        label: Text(l10n.charge),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text(l10n.receive),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                    ],
                    selected: {_isCharge},
                    onSelectionChanged: (Set<bool> newSelection) {
                      setState(() {
                        _isCharge = newSelection.first;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Amount
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: l10n.amount,
                prefixText: '${CurrencyFormatter.getCurrencySymbol(ref.watch(currentCurrencyCodeProvider))} ',
                border: const OutlineInputBorder(),
                helperText: _isCharge
                    ? l10n.increasesDebt
                    : l10n.decreasesDebt,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            TextField(
              controller: _notesController,
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
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(l10n.saveAdjustment),
        ),
      ],
    );
  }
}
