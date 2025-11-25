// FILE: packages/features/feature_transactions/lib/src/presentation/pos_receipt_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:shared_ui/shared_ui.dart'; // Import the formatter

class PosReceiptItem {
  final Product product;
  final double quantity;

  PosReceiptItem({required this.product, required this.quantity});

  // NEW LOGIC: product.price is now INT (Cents).
  // Total must be calculated as (Cents * Quantity) / 100.0
  double get totalAmount {
    return (product.price * quantity) / 100.0;
  }

  PosReceiptItem copyWith({Product? product, double? quantity}) {
    return PosReceiptItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

class PosReceiptNotifier extends StateNotifier<List<PosReceiptItem>> {
  PosReceiptNotifier() : super([]);

  void addItem(Product product) {
    // Check if product exists
    final index = state.indexWhere((item) => item.product.id == product.id);
    if (index != -1) {
      // Update quantity
      final oldItem = state[index];
      final newItem = oldItem.copyWith(quantity: oldItem.quantity + 1);
      state = [
        ...state.sublist(0, index),
        newItem,
        ...state.sublist(index + 1),
      ];
    } else {
      // Add new
      state = [...state, PosReceiptItem(product: product, quantity: 1)];
    }
  }

  void updateQuantity(String productId, double newQuantity) {
    state = [
      for (final item in state)
        if (item.product.id == productId)
          item.copyWith(quantity: newQuantity)
        else
          item
    ];
  }

  void removeItem(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void clear() {
    state = [];
  }

  // Get Total Sale Amount (in Dollars/Double)
  double get totalSaleAmount {
    return state.fold(0.0, (sum, item) => sum + item.totalAmount);
  }
}

final posReceiptProvider =
    StateNotifierProvider<PosReceiptNotifier, List<PosReceiptItem>>((ref) {
  return PosReceiptNotifier();
});

// Helper to get the total amount easily in the UI
final posTotalAmountProvider = Provider<double>((ref) {
  final items = ref.watch(posReceiptProvider);
  return items.fold(0.0, (sum, item) => sum + item.totalAmount);
});