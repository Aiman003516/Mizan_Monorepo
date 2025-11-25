import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:core_l10n/app_localizations.dart';
import 'transactions_list_provider.dart';

class TransactionsListScreen extends ConsumerStatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  ConsumerState<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends ConsumerState<TransactionsListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Detects when user scrolls to the bottom
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Trigger load more when we are 200 pixels from the bottom
      ref.read(transactionsListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the pagination state
    final listState = ref.watch(transactionsListProvider);
    final transactions = listState.transactions;
    final l10n = AppLocalizations.of(context)!;

    // Use Scaffold for structure
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.transactionHistory),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(transactionsListProvider.notifier).refresh(),
        child: transactions.isEmpty && !listState.isLoading
            ? Center(
                // Empty State
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(l10n.noTransactionsYet, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            : ListView.builder(
                controller: _scrollController,
                // Add 1 to item count for the loading indicator if there is more to load
                itemCount: transactions.length + (listState.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  // --- Loading Indicator Row ---
                  if (index == transactions.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  // --- Transaction Row ---
                  final transaction = transactions[index];
                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.receipt),
                    ),
                    title: Text(transaction.description),
                    subtitle: Text(
                      DateFormat.yMMMd().add_jm().format(transaction.transactionDate),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Future: Navigate to details screen
                      // Navigator.of(context).push(...);
                    },
                  );
                },
              ),
      ),
    );
  }
}