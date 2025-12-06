// FILE: packages/features/feature_transactions/lib/src/presentation/pos_state_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:uuid/uuid.dart';

// --- MODELS ---

class PosReceiptItem {
  final Product product;
  final double quantity;

  PosReceiptItem({required this.product, required this.quantity});

  double get totalAmount => (product.price * quantity) / 100.0;

  PosReceiptItem copyWith({Product? product, double? quantity}) {
    return PosReceiptItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

class PosOrder {
  final String id;
  final DateTime createdAt;
  final List<PosReceiptItem> items;

  PosOrder({
    required this.id,
    required this.createdAt,
    this.items = const [],
  });

  double get total => items.fold(0.0, (sum, item) => sum + item.totalAmount);

  PosOrder copyWith({List<PosReceiptItem>? items}) {
    return PosOrder(
      id: id,
      createdAt: createdAt,
      items: items ?? this.items,
    );
  }
}

class PosState {
  final PosOrder activeOrder;
  final List<PosOrder> parkedOrders;

  PosState({required this.activeOrder, this.parkedOrders = const []});

  PosState copyWith({PosOrder? activeOrder, List<PosOrder>? parkedOrders}) {
    return PosState(
      activeOrder: activeOrder ?? this.activeOrder,
      parkedOrders: parkedOrders ?? this.parkedOrders,
    );
  }
}

// --- NOTIFIER ---

class PosOrderNotifier extends StateNotifier<PosState> {
  PosOrderNotifier()
      : super(PosState(
            activeOrder: PosOrder(id: const Uuid().v4(), createdAt: DateTime.now())));

  // 1. CART ACTIONS
  void addItem(Product product) {
    final items = [...state.activeOrder.items];
    final index = items.indexWhere((i) => i.product.id == product.id);

    if (index != -1) {
      items[index] = items[index].copyWith(quantity: items[index].quantity + 1);
    } else {
      items.add(PosReceiptItem(product: product, quantity: 1));
    }
    _updateActiveItems(items);
  }

  void updateLineItem(int index, {double? quantity, double? priceOverride}) {
    // Note: Price override would require changing the Product model or wrapping it. 
    // For now we stick to Quantity as requested.
    if (index < 0 || index >= state.activeOrder.items.length) return;
    
    final items = [...state.activeOrder.items];
    if (quantity != null) {
      if (quantity <= 0) {
        items.removeAt(index);
      } else {
        items[index] = items[index].copyWith(quantity: quantity);
      }
    }
    _updateActiveItems(items);
  }

  void removeItem(int index) {
    final items = [...state.activeOrder.items];
    items.removeAt(index);
    _updateActiveItems(items);
  }

  void clearActiveOrder() {
    state = state.copyWith(
      activeOrder: PosOrder(id: const Uuid().v4(), createdAt: DateTime.now()),
    );
  }

  void _updateActiveItems(List<PosReceiptItem> newItems) {
    state = state.copyWith(
      activeOrder: state.activeOrder.copyWith(items: newItems),
    );
  }

  // 2. PARKING LOGIC (HOLD/RECALL)
  void parkOrder() {
    if (state.activeOrder.items.isEmpty) return;

    final orderToPark = state.activeOrder; // Snapshot current
    
    // Create fresh active order
    final newActive = PosOrder(id: const Uuid().v4(), createdAt: DateTime.now());

    state = state.copyWith(
      activeOrder: newActive,
      parkedOrders: [...state.parkedOrders, orderToPark],
    );
  }

  void recallOrder(String orderId) {
    final orderIndex = state.parkedOrders.indexWhere((o) => o.id == orderId);
    if (orderIndex == -1) return;

    final orderToRecall = state.parkedOrders[orderIndex];
    
    // If current active has items, we should park it first? 
    // For simplicity, we assume the user cleared or wants to swap.
    // Let's Park the current one if it has items.
    List<PosOrder> newParked = [...state.parkedOrders];
    newParked.removeAt(orderIndex); // Remove the one we are recalling

    if (state.activeOrder.items.isNotEmpty) {
      newParked.add(state.activeOrder); // Park the current clutter
    }

    state = state.copyWith(
      activeOrder: orderToRecall,
      parkedOrders: newParked,
    );
  }
}

final posStateProvider = StateNotifierProvider<PosOrderNotifier, PosState>((ref) {
  return PosOrderNotifier();
});

// Helper for UI convenience
final posActiveTotalProvider = Provider<double>((ref) {
  return ref.watch(posStateProvider).activeOrder.total;
});