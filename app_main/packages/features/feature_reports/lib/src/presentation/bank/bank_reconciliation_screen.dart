import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';

/// 🏦 Bank Reconciliation Screen
/// Match transactions to statement balance.
class BankReconciliationScreen extends ConsumerStatefulWidget {
  final String reconciliationId;

  const BankReconciliationScreen({super.key, required this.reconciliationId});

  @override
  ConsumerState<BankReconciliationScreen> createState() =>
      _BankReconciliationScreenState();
}

class _BankReconciliationScreenState
    extends ConsumerState<BankReconciliationScreen> {
  BankReconciliation? _reconciliation;
  Account? _account;
  List<UnreconciledTransaction> _transactions = [];
  bool _isLoading = true;
  double _bookBalance = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final db = ref.read(appDatabaseProvider);
      final repo = ref.read(bankReconciliationRepositoryProvider);

      final rec = await (db.select(
        db.bankReconciliations,
      )..where((r) => r.id.equals(widget.reconciliationId))).getSingleOrNull();
      if (rec == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      final account = await (db.select(
        db.accounts,
      )..where((a) => a.id.equals(rec.accountId))).getSingleOrNull();
      final transactions = await repo.getUnreconciledTransactions(
        rec.accountId,
      );
      final bookBalance = await repo.getBookBalance(rec.accountId);

      setState(() {
        _reconciliation = rec;
        _account = account;
        _transactions = transactions;
        _bookBalance = bookBalance;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  double get _selectedTotal {
    double total = 0;
    for (final t in _transactions) {
      if (t.isSelected) total += t.amount;
    }
    return total;
  }

  int get _selectedCount => _transactions.where((t) => t.isSelected).length;

  double get _difference {
    if (_reconciliation == null) return 0;
    final statementBalance = _reconciliation!.statementEndingBalance / 100;
    return statementBalance - (_bookBalance - _selectedTotal);
  }

  Future<void> _completeReconciliation() async {
    if (_reconciliation == null) return;

    final selectedTxnIds = _transactions
        .where((t) => t.isSelected)
        .map((t) => t.transaction.id)
        .toList();

    if (selectedTxnIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select transactions to reconcile'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(bankReconciliationRepositoryProvider);
      await repo.reconcileTransactions(
        reconciliationId: _reconciliation!.id,
        transactionIds: selectedTxnIds,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reconciliation completed!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isBalanced = _difference.abs() < 0.01;

    return Scaffold(
      appBar: AppBar(
        title: Text(_account?.name ?? 'Reconciliation'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      bottomNavigationBar:
          _reconciliation != null && _reconciliation!.status != 'completed'
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: _isLoading ? null : _completeReconciliation,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Complete Reconciliation ($_selectedCount selected)',
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isBalanced
                        ? Colors.green.withValues(alpha: 0.1)
                        : colorScheme.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isBalanced ? Colors.green : colorScheme.error,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Statement Balance:'),
                          Text(
                            '\$${((_reconciliation?.statementEndingBalance ?? 0) / 100).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Book Balance:'),
                          Text(
                            '\$${_bookBalance.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Selected Cleared:'),
                          Text(
                            '\$${_selectedTotal.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Difference:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isBalanced
                                  ? Colors.green
                                  : colorScheme.error,
                            ),
                          ),
                          Text(
                            '\$${_difference.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: isBalanced
                                  ? Colors.green
                                  : colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                      if (isBalanced) ...[
                        const SizedBox(height: 8),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Balanced!',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Transactions Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Uncleared Transactions (${_transactions.length})',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          final allSelected = _transactions.every(
                            (t) => t.isSelected,
                          );
                          setState(() {
                            for (final t in _transactions) {
                              t.isSelected = !allSelected;
                            }
                          });
                        },
                        child: Text(
                          _transactions.every((t) => t.isSelected)
                              ? 'Deselect All'
                              : 'Select All',
                        ),
                      ),
                    ],
                  ),
                ),

                // Transactions List
                Expanded(
                  child: _transactions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                size: 48,
                                color: Colors.green,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'All transactions reconciled!',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _transactions.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, index) {
                            final txn = _transactions[index];
                            final isPositive = txn.amount >= 0;
                            final txnDate = txn.transaction.createdAt;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 4),
                              color: txn.isSelected
                                  ? colorScheme.primaryContainer.withValues(
                                      alpha: 0.3,
                                    )
                                  : null,
                              child: CheckboxListTile(
                                value: txn.isSelected,
                                onChanged: (value) => setState(
                                  () => txn.isSelected = value ?? false,
                                ),
                                title: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        txn.description ?? 'No description',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '${isPositive ? "+" : ""}\$${txn.amount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isPositive
                                            ? Colors.green
                                            : colorScheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Text(
                                  '${txnDate.day}/${txnDate.month}/${txnDate.year}',
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
