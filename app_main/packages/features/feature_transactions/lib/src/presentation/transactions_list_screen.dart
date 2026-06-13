import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
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
        child: _buildBody(listState, transactions, l10n),
      ),
    );
  }

  Widget _buildBody(listState, transactions, l10n) {
    // Initial loading state
    if (transactions.isEmpty && listState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Empty state
    if (transactions.isEmpty && !listState.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: context.appColors.subtleText),
            const SizedBox(height: 16),
            Text(l10n.noTransactionsYet, style: TextStyle(color: context.appColors.subtleText)),
          ],
        ),
      );
    }

    // List view
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(), // Ensures RefreshIndicator works even if list is small
      padding: const EdgeInsets.all(8.0), // Better spacing around the edges
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
        return Card( // Wrap ListTile in a Card for better UI spacing
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.receipt),
            ),
            title: Text(transaction.description),
            subtitle: Text(
              DateFormat.yMMMd(l10n.localeName).add_jm().format(transaction.transactionDate),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Future: Navigate to details screen
              // Navigator.of(context).push(...);
            },
          ),
        );
      },
    );
  }
}