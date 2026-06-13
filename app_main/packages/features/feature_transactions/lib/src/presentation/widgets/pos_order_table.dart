// FILE: packages/features/feature_transactions/lib/src/presentation/widgets/pos_order_table.dart

import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:core_l10n/app_localizations.dart';
import '../pos_state_provider.dart';

class PosOrderTable extends ConsumerWidget {
  final int? selectedIndex;
  final Function(int) onRowTap;

  const PosOrderTable({
    super.key,
    required this.selectedIndex,
    required this.onRowTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posState = ref.watch(posStateProvider);
    final items = posState.activeOrder.items;
    final l10n = AppLocalizations.of(context)!;

    if (items.isEmpty) {
      return Center(
        child: Text(l10n.cartIsEmpty, style: TextStyle(color: context.appColors.subtleText)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;

        return Column(
          children: [
            // HEADER
            Container(
              color: context.appColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: isSmallScreen ? 4 : 3, 
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(l10n.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    )
                  ),
                  if (!isSmallScreen)
                    Expanded(
                      flex: 2, 
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(l10n.byCategory, style: const TextStyle(fontWeight: FontWeight.bold)),
                      )
                    ),
                  Expanded(
                    flex: 1, 
                    child: Text(l10n.quantityShort, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))
                  ),
                  Expanded(
                    flex: 2, 
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(l10n.price, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.bold)),
                    )
                  ),
                ],
              ),
            ),
            // BODY
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = index == selectedIndex;

                  return InkWell(
                    onTap: () => onRowTap(index),
                    child: Container(
                      // ignore: deprecated_member_use
                      color: isSelected ? context.appColors.info.withValues(alpha: 0.1) : null,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: Row(
                        children: [
                          // 1. Name (& Category on small screens)
                          Expanded(
                            flex: isSmallScreen ? 4 : 3, 
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item.product.name, 
                                    maxLines: 2, 
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  if (isSmallScreen)
                                    Text(
                                      item.product.name, 
                                      style: TextStyle(fontSize: 12, color: context.appColors.subtleText),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          // 2. Category (Desktop only)
                          if (!isSmallScreen)
                            Expanded(
                              flex: 2, 
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Text(
                                  item.product.name, 
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13, color: context.appColors.subtleText),
                                ),
                              ), 
                            ),
                          // 3. Qty
                          Expanded(
                            flex: 1, 
                            child: Text(
                              item.quantity.toStringAsFixed(0), 
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          // 4. Price (Total)
                          Expanded(
                            flex: 2, 
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Text(
                                CurrencyFormatter.formatCentsToCurrency((item.product.price * item.quantity).round()),
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}