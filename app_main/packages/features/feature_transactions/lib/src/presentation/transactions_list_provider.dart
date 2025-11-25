import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_database/core_database.dart';
import '../data/transactions_repository.dart';

/// The State Class holding our list data + loading status
class TransactionListState {
  final List<Transaction> transactions;
  final bool isLoading;
  final bool hasMore;

  TransactionListState({
    required this.transactions,
    this.isLoading = false,
    this.hasMore = true,
  });

  TransactionListState copyWith({
    List<Transaction>? transactions,
    bool? isLoading,
    bool? hasMore,
  }) {
    return TransactionListState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// The Notifier that manages the pagination logic
class TransactionsListNotifier extends StateNotifier<TransactionListState> {
  final TransactionsRepository _repository;
  
  // PAGE SIZE: How many items to load at once. 
  // 20 is a good balance between network/db load and scrolling smoothness.
  static const int _pageSize = 20;

  TransactionsListNotifier(this._repository)
      : super(TransactionListState(transactions: [])) {
    loadInitialData();
  }

  /// Loads the first page (0 to 20). Resets the list.
  Future<void> loadInitialData() async {
    // Prevent double-loading if already busy
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true);
    
    try {
      final newItems = await _repository.getTransactions(
        limit: _pageSize, 
        offset: 0
      );
      
      state = state.copyWith(
        transactions: newItems,
        isLoading: false,
        // If we got fewer items than requested, we are at the end.
        hasMore: newItems.length >= _pageSize,
      );
    } catch (e) {
      // In a real app, you might set an error state here
      state = state.copyWith(isLoading: false);
      print("Error loading initial transactions: $e");
    }
  }

  /// Loads the next page based on current length. Appends to list.
  Future<void> loadMore() async {
    // Stop if:
    // 1. Already loading
    // 2. No more items to load (end of DB)
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);
    
    try {
      final currentLength = state.transactions.length;
      final newItems = await _repository.getTransactions(
        limit: _pageSize,
        offset: currentLength,
      );

      state = state.copyWith(
        transactions: [...state.transactions, ...newItems],
        isLoading: false,
        hasMore: newItems.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      print("Error loading more transactions: $e");
    }
  }
  
  /// Pull-to-refresh action
  Future<void> refresh() async {
    // Reset to empty and reload
    state = TransactionListState(transactions: [], isLoading: false, hasMore: true);
    await loadInitialData();
  }
}

/// The Provider consumed by the UI
final transactionsListProvider =
    StateNotifierProvider.autoDispose<TransactionsListNotifier, TransactionListState>((ref) {
  final repository = ref.watch(transactionsRepositoryProvider);
  return TransactionsListNotifier(repository);
});