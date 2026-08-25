import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:core_ui/core_ui.dart';
import 'package:shared_ui/shared_ui.dart';

import '../pos_state_provider.dart';

class PosCheckoutPanel extends ConsumerWidget {
  final VoidCallback onPayPressed;
  final VoidCallback onHoldPressed;
  final VoidCallback onRecallPressed;
  final VoidCallback onClearPressed;

  const PosCheckoutPanel({
    super.key,
    required this.onPayPressed,
    required this.onHoldPressed,
    required this.onRecallPressed,
    required this.onClearPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = ref.watch(posStateProvider);
    final items = state.activeOrder.items;
    final totalCents = (state.activeOrder.total * 100).round();
    final total = CurrencyFormatter.formatCentsToCurrency(totalCents);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.orderSummary,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        items.isEmpty
                            ? l10n.cartEmpty
                            : l10n.cartSummary(items.length, total),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: context.appColors.subtleText,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.recallOrderTooltip,
                  onPressed: onRecallPressed,
                  icon: Badge(
                    isLabelVisible: state.parkedOrders.isNotEmpty,
                    label: Text(state.parkedOrders.length.toString()),
                    child: const Icon(Icons.inbox_outlined),
                  ),
                ),
                IconButton(
                  tooltip: l10n.clearOrder,
                  onPressed: items.isEmpty ? null : onClearPressed,
                  icon: const Icon(Icons.delete_sweep_outlined),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: items.isEmpty
                  ? _EmptyCartState(l10n: l10n)
                  : ListView.separated(
                      padding: const EdgeInsets.only(right: 2),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _CheckoutLineItem(
                          item: item,
                          onIncrement: () => ref
                              .read(posStateProvider.notifier)
                              .updateLineItem(
                                index,
                                quantity: item.quantity + 1,
                              ),
                          onDecrement: () {
                            if (item.quantity > 1) {
                              ref
                                  .read(posStateProvider.notifier)
                                  .updateLineItem(
                                    index,
                                    quantity: item.quantity - 1,
                                  );
                            } else {
                              ref
                                  .read(posStateProvider.notifier)
                                  .removeItem(index);
                            }
                          },
                          onRemove: () => ref
                              .read(posStateProvider.notifier)
                              .removeItem(index),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.55,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  _SummaryLine(label: l10n.subtotal, value: total),
                  const SizedBox(height: 8),
                  _SummaryLine(
                    label: l10n.taxLabel('0'),
                    value: CurrencyFormatter.formatCentsToCurrency(0),
                    subtle: true,
                  ),
                  const SizedBox(height: 8),
                  _SummaryLine(
                    label: l10n.discountLabel,
                    value: '—',
                    subtle: true,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.totalUppercase,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        total,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: items.isEmpty ? null : onHoldPressed,
                    icon: const Icon(Icons.pause_circle_outline),
                    label: Text(l10n.holdOrder),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: items.isEmpty ? null : onPayPressed,
                    icon: const Icon(Icons.point_of_sale_outlined),
                    label: Text(l10n.payPrintButton),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCartState extends StatelessWidget {
  final AppLocalizations l10n;

  const _EmptyCartState({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 56,
            color: context.appColors.subtleText.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 12),
          Text(l10n.cartEmpty, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            l10n.cartEmptyHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appColors.subtleText,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutLineItem extends StatelessWidget {
  final PosReceiptItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const _CheckoutLineItem({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lineTotal = CurrencyFormatter.formatCentsToCurrency(
      (item.product.price * item.quantity).round(),
    );

    return Dismissible(
      key: ValueKey('checkout-${item.product.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.delete_outline,
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                color: theme.colorScheme.onPrimaryContainer,
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    CurrencyFormatter.formatCentsToCurrency(item.product.price),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.appColors.subtleText,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  lineTotal,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _QuantityButton(icon: Icons.remove, onTap: onDecrement),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        child: Text(
                          item.quantity.toStringAsFixed(0),
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _QuantityButton(icon: Icons.add, onTap: onIncrement),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QuantityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
      padding: EdgeInsets.zero,
      onPressed: onTap,
      icon: Icon(icon, size: 16),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;
  final bool subtle;

  const _SummaryLine({
    required this.label,
    required this.value,
    this.subtle = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: subtle ? context.appColors.subtleText : null,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}
