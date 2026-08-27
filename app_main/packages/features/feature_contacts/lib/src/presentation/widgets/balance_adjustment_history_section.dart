import 'package:core_data/core_data.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_ui/shared_ui.dart';

class BalanceAdjustmentHistorySection extends StatelessWidget {
  const BalanceAdjustmentHistorySection({
    super.key,
    required this.adjustments,
    required this.currencyCode,
  });

  final AsyncValue<List<BalanceAdjustment>> adjustments;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return adjustments.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          l10n.balanceAdjustmentHistoryFailed,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
      data: (items) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.adjustmentHistory,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (items.isEmpty)
                Text(
                  l10n.noBalanceAdjustments,
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else
                ...items.map(
                  (item) =>
                      _AdjustmentTile(item: item, currencyCode: currencyCode),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AdjustmentTile extends StatelessWidget {
  const _AdjustmentTile({required this.item, required this.currencyCode});

  final BalanceAdjustment item;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isIncrease = item.direction == 'increase';
    final signedAmount = isIncrease ? item.amount : -item.amount;
    final color = isIncrease
        ? Theme.of(context).colorScheme.error
        : context.appColors.success;
    final date = MaterialLocalizations.of(
      context,
    ).formatMediumDate(item.effectiveDate);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.14),
          foregroundColor: color,
          child: Icon(isIncrease ? Icons.arrow_upward : Icons.arrow_downward),
        ),
        title: Text(
          CurrencyFormatter.formatAmount(signedAmount, currencyCode),
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${isIncrease ? l10n.adjustmentIncrease : l10n.adjustmentDecrease} • $date\n${item.reason}${item.reference == null ? '' : '\n${l10n.reference}: ${item.reference}'}',
        ),
        isThreeLine: item.reference != null,
        trailing: item.status == 'posted'
            ? Text(l10n.posted)
            : Text(item.status),
      ),
    );
  }
}
