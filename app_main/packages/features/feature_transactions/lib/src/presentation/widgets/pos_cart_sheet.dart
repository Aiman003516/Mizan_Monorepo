// FILE: packages/features/feature_transactions/lib/src/presentation/widgets/pos_cart_sheet.dart

import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:shared_ui/shared_ui.dart';
import '../pos_state_provider.dart';

class PosCartSheet extends ConsumerStatefulWidget {
  final VoidCallback onPayPressed;
  final VoidCallback onHoldPressed;

  const PosCartSheet({
    super.key,
    required this.onPayPressed,
    required this.onHoldPressed,
  });

  @override
  ConsumerState<PosCartSheet> createState() => _PosCartSheetState();
}

class _PosCartSheetState extends ConsumerState<PosCartSheet> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posState = ref.watch(posStateProvider);
    final items = posState.activeOrder.items;
    final total = posState.activeOrder.total;
    final l10n = AppLocalizations.of(context)!;
    final totalFormatted = CurrencyFormatter.formatCentsToCurrency(
      (total * 100).round(),
    );

    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.08,
      minChildSize: 0.08,
      maxChildSize: 0.85,
      snap: true,
      snapSizes: const [0.08, 0.5, 0.85],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              // ═══════════════════════════════════════════
              // COLLAPSED HEADER (Cart Bar)
              // ═══════════════════════════════════════════
              SliverToBoxAdapter(
                child: GestureDetector(
                  onTap: () {
                    final currentSize = _sheetController.size;
                    if (currentSize < 0.15) {
                      _sheetController.animateTo(
                        0.5,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                      );
                    } else {
                      _sheetController.animateTo(
                        0.08,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.appColors.primary,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Drag Handle
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: context.appColors.onPrimary
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        // Cart Summary
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              color: context.appColors.onPrimary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              items.isEmpty
                                  ? l10n.cartEmpty
                                  : l10n.cartSummary(items.length, totalFormatted),
                              style: TextStyle(
                                color: context.appColors.onPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ═══════════════════════════════════════════
              // ORDER SUMMARY HEADER
              // ═══════════════════════════════════════════
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Text(
                    l10n.orderSummary,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),

              // ═══════════════════════════════════════════
              // CART ITEMS
              // ═══════════════════════════════════════════
              if (items.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.remove_shopping_cart_outlined,
                            size: 48,
                            color: context.appColors.subtleText
                                .withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.cartEmptyHint,
                            style: TextStyle(
                              color: context.appColors.subtleText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = items[index];
                      return _CartItemTile(
                        item: item,
                        onIncrement: () {
                          ref
                              .read(posStateProvider.notifier)
                              .updateLineItem(index,
                                  quantity: item.quantity + 1);
                        },
                        onDecrement: () {
                          if (item.quantity > 1) {
                            ref
                                .read(posStateProvider.notifier)
                                .updateLineItem(index,
                                    quantity: item.quantity - 1);
                          } else {
                            ref
                                .read(posStateProvider.notifier)
                                .removeItem(index);
                          }
                        },
                        onRemove: () {
                          ref
                              .read(posStateProvider.notifier)
                              .removeItem(index);
                        },
                      );
                    },
                    childCount: items.length,
                  ),
                ),

              // ═══════════════════════════════════════════
              // TOTALS & ACTIONS
              // ═══════════════════════════════════════════
              if (items.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      children: [
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        // Subtotal
                        _SummaryRow(
                          label: l10n.subtotal,
                          value: totalFormatted,
                        ),
                        const SizedBox(height: 6),
                        // Tax
                        _SummaryRow(
                          label: l10n.taxLabel('0'),
                          value: CurrencyFormatter.formatCentsToCurrency(0),
                          isSubtle: true,
                        ),
                        const SizedBox(height: 6),
                        // Discount
                        _SummaryRow(
                          label: l10n.discountLabel,
                          value: '—',
                          isSubtle: true,
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        // TOTAL
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.totalUppercase,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            Text(
                              totalFormatted,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: context.appColors.primary,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Action Buttons
                        Row(
                          children: [
                            // Hold Order
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: widget.onHoldPressed,
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(
                                      color: context.appColors.primary),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.pause_circle_outline),
                                label: Text(l10n.holdOrder),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Pay & Print
                            Expanded(
                              flex: 2,
                              child: FilledButton.icon(
                                onPressed: widget.onPayPressed,
                                style: FilledButton.styleFrom(
                                  backgroundColor: context.appColors.primary,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.payment),
                                label: Text(
                                  l10n.payPrintButton,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════
// CART ITEM TILE
// ══════════════════════════════════════════════════════════
class _CartItemTile extends StatelessWidget {
  final PosReceiptItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const _CartItemTile({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unitPrice = CurrencyFormatter.formatCentsToCurrency(item.product.price);
    final lineTotal = CurrencyFormatter.formatCentsToCurrency(
      (item.product.price * item.quantity).round(),
    );

    return Dismissible(
      key: ValueKey(item.product.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: context.appColors.error.withValues(alpha: 0.15),
        child: Icon(Icons.delete_outline, color: context.appColors.error),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            // Product Name
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    unitPrice,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.appColors.subtleText,
                    ),
                  ),
                ],
              ),
            ),
            // Quantity Stepper
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: context.appColors.primary.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StepperButton(
                    icon: Icons.remove,
                    onTap: onDecrement,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      item.quantity.toStringAsFixed(0),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _StepperButton(
                    icon: Icons.add,
                    onTap: onIncrement,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Line Total
            SizedBox(
              width: 70,
              child: Text(
                lineTotal,
                textAlign: TextAlign.end,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: context.appColors.primary),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// SUMMARY ROW
// ══════════════════════════════════════════════════════════
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isSubtle;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isSubtle = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: isSubtle ? context.appColors.subtleText : null,
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
