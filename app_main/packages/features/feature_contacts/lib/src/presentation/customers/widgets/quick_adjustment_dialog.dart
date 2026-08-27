import 'package:core_data/core_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_ui/shared_ui.dart';

import '../../widgets/balance_adjustment_dialog.dart';

class QuickAdjustmentDialog extends ConsumerWidget {
  const QuickAdjustmentDialog({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.currentBalance,
  });

  final String customerId;
  final String customerName;
  final int currentBalance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyCode = ref.watch(currentCurrencyCodeProvider);
    return BalanceAdjustmentDialog(
      contactType: ContactType.receivable,
      contactName: customerName,
      currentBalance: currentBalance,
      currencyCode: currencyCode,
      onSubmit:
          ({
            required amountMinor,
            required increase,
            required reason,
            reference,
            required effectiveDate,
            required currencyCode,
          }) => ref
              .read(arRepositoryProvider)
              .recordQuickAdjustment(
                customerId: customerId,
                amount: amountMinor,
                isCharge: increase,
                notes: reason,
                reference: reference,
                effectiveDate: effectiveDate,
                currencyCode: currencyCode,
              ),
    );
  }
}
