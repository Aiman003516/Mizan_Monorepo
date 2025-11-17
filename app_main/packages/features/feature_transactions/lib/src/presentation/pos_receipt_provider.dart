import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import 'package:equatable/equatable.dart';

@immutable
class PosReceiptItem extends Equatable {
  const PosReceiptItem({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  PosReceiptItem copyWith({Product? product, int? quantity}) {
    return PosReceiptItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [product, quantity];
}

@immutable
class PosReceiptState extends Equatable {
  const PosReceiptState({this.items = const []});

  final List<PosReceiptItem> items;

  double get total {
    return items.fold(
      0.0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );
  }

  @override
  List<Object?> get props => [items];
}

class PosReceiptNotifier extends Notifier<PosReceiptState> {
  @override
  PosReceiptState build() {
    return const PosReceiptState();
  }

  void addProduct(Product product) {
    final currentState = state;
    final existingItemIndex = currentState.items.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingItemIndex != -1) {
      final updatedItems = List<PosReceiptItem>.from(currentState.items);
      final existingItem = updatedItems[existingItemIndex];
      updatedItems[existingItemIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + 1,
      );
      state = PosReceiptState(items: updatedItems);
    } else {
      final newItem = PosReceiptItem(product: product, quantity: 1);
      state = PosReceiptState(items: [...currentState.items, newItem]);
    }
  }

  void clear() {
    state = const PosReceiptState();
  }
}

final posReceiptProvider =
    NotifierProvider<PosReceiptNotifier, PosReceiptState>(
  PosReceiptNotifier.new,
);