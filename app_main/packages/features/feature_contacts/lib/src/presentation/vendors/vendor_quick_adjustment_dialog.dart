import 'package:core_data/core_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_ui/shared_ui.dart';

import '../widgets/balance_adjustment_dialog.dart';

class VendorQuickAdjustmentDialog extends ConsumerWidget {
  const VendorQuickAdjustmentDialog({
    super.key,
    required this.vendorId,
    required this.vendorName,
    required this.currentBalance,
  });

  final String vendorId;
  final String vendorName;
  final int currentBalance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyCode = ref.watch(currentCurrencyCodeProvider);
    return BalanceAdjustmentDialog(
      contactType: ContactType.payable,
      contactName: vendorName,
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
              .read(apRepositoryProvider)
              .recordQuickAdjustment(
                vendorId: vendorId,
                amount: amountMinor,
                increasePayable: increase,
                notes: reason,
                reference: reference,
                effectiveDate: effectiveDate,
                currencyCode: currencyCode,
              ),
    );
  }
}
