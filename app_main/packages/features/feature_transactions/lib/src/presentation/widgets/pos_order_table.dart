// FILE: packages/features/feature_transactions/lib/src/presentation/widgets/pos_order_table.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_ui/shared_ui.dart';
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

    if (items.isEmpty) {
      return const Center(
        child: Text("Cart is empty", style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: [
        // HEADER
        Container(
          color: Colors.grey.shade200,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: const Row(
            children: [
              Expanded(flex: 3, child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('Cat', style: TextStyle(fontWeight: FontWeight.bold))), // Category
              Expanded(flex: 1, child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('Price', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
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
                  color: isSelected ? Colors.blue.withOpacity(0.1) : null,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Row(
                    children: [
                      // 1. Name
                      Expanded(
                        flex: 3, 
                        child: Text(
                          item.product.name, 
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      // 2. Category (Placeholder for now, assuming you can fetch it or its in product)
                      const Expanded(
                        flex: 2, 
                        child: Text("Gen", style: TextStyle(fontSize: 12, color: Colors.grey)), 
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
                        child: Text(
                          CurrencyFormatter.formatCentsToCurrency((item.product.price * item.quantity).round()),
                          textAlign: TextAlign.right,
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
  }
}