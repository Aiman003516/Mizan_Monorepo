import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';
import 'package:core_database/core_database.dart';

import 'bank_reconciliation_screen.dart';

/// 🏦 Bank Reconciliations List Screen
/// Shows all reconciliation sessions and allows starting new ones.
class BankReconciliationsListScreen extends ConsumerWidget {
  const BankReconciliationsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(bankReconciliationRepositoryProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Reconciliations'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewReconciliationDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Reconciliation'),
      ),
      body: StreamBuilder<List<ReconciliationSummary>>(
        stream: repo.watchAllReconciliations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final summaries = snapshot.data ?? [];

          if (summaries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance,
                    size: 64,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No reconciliations yet',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start reconciling your bank statements',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: summaries.length,
            itemBuilder: (context, index) {
              final summary = summaries[index];
              final isCompleted = summary.reconciliation.status == 'completed';

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCompleted
                        ? Colors.green
                        : colorScheme.primaryContainer,
                    child: Icon(
                      isCompleted ? Icons.check : Icons.pending,
                      color: isCompleted ? Colors.white : colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    summary.account.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${summary.reconciliation.statementDate.day}/${summary.reconciliation.statementDate.month}/${summary.reconciliation.statementDate.year} • ${summary.reconciledCount} transactions',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${(summary.reconciliation.statementEndingBalance / 100).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        summary.reconciliation.status.toUpperCase(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isCompleted
                              ? Colors.green
                              : colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => BankReconciliationScreen(
                          reconciliationId: summary.reconciliation.id,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showNewReconciliationDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final repo = ref.read(bankReconciliationRepositoryProvider);
    final accounts = await repo.getBankAccounts();

    if (accounts.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No bank accounts found. Create a bank/cash account first.',
            ),
          ),
        );
      }
      return;
    }

    Account? selectedAccount = accounts.first;
    DateTime statementDate = DateTime.now();
    final balanceController = TextEditingController();

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New Reconciliation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Account>(
                  value: selectedAccount,
                  decoration: const InputDecoration(
                    labelText: 'Bank Account',
                    border: OutlineInputBorder(),
                  ),
                  items: accounts
                      .map(
                        (a) => DropdownMenuItem(value: a, child: Text(a.name)),
                      )
                      .toList(),
                  onChanged: (a) => setState(() => selectedAccount = a),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Statement Date'),
                  subtitle: Text(
                    '${statementDate.day}/${statementDate.month}/${statementDate.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: statementDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => statementDate = picked);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: balanceController,
                  decoration: const InputDecoration(
                    labelText: 'Statement Ending Balance',
                    border: OutlineInputBorder(),
                    prefixText: '\$ ',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (selectedAccount == null || balanceController.text.isEmpty)
                  return;
                final balance =
                    (double.tryParse(balanceController.text) ?? 0) * 100;
                await repo.createReconciliation(
                  accountId: selectedAccount!.id,
                  statementDate: statementDate,
                  statementEndingBalance: balance.round(),
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
