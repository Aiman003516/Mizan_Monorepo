import 'dart:convert';
import 'package:core_data/core_data.dart';
import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_ui/shared_ui.dart'; // CurrencyFormatter
import '../data/adjusting_entries_repository.dart';

// ⭐️ IMPORT THE WIZARD SCREEN
import 'period_end_wizard_screen.dart';

class AdjustingEntriesScreen extends ConsumerWidget {
  const AdjustingEntriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.watch(adjustingEntriesRepositoryProvider);
    final tasksStream = repo.watchPendingTasks();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adjustmentsAndClosing),
        actions: [
          // ⭐️ THE NAVIGATION BUTTON YOU REQUESTED
          IconButton(
            tooltip: l10n.closePeriod,
            icon: const Icon(Icons.lock_clock),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PeriodEndWizardScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // --- THE WIZARD BUTTONS ---
          _buildWizardHeader(context, ref),

          const Divider(thickness: 4),

          // --- THE PENDING LIST ---
          Expanded(
            child: StreamBuilder<List<AdjustingEntryTask>>(
              stream: tasksStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final tasks = snapshot.data!;

                if (tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: context.appColors.success,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.allAdjustmentsApproved,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return _TaskCard(task: task);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWizardHeader(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.whatNeedToRecord,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _WizardButton(
                  icon: Icons.hourglass_bottom,
                  label: l10n.usePrepaidAssetLabel,
                  color: context.appColors.primary,
                  onTap: () =>
                      _showSimpleAdjustmentDialog(context, ref, 'prepaid'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _WizardButton(
                  icon: Icons.access_time,
                  label: l10n.accrueExpenseLabel,
                  color: context.appColors.primary,
                  onTap: () =>
                      _showSimpleAdjustmentDialog(context, ref, 'accrual'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSimpleAdjustmentDialog(
    BuildContext context,
    WidgetRef ref,
    String type,
  ) {
    showDialog(
      context: context,
      builder: (context) => _SimpleWizardDialog(type: type),
    );
  }
}

class _WizardButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _WizardButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.appColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: context.appColors.onSurface),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends ConsumerStatefulWidget {
  final AdjustingEntryTask task;
  const _TaskCard({required this.task});

  @override
  ConsumerState<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends ConsumerState<_TaskCard> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final payload = jsonDecode(widget.task.proposedEntryJson) as List;
    final totalCents = payload.fold<int>(
      0,
      (sum, e) => sum + (e['amount'] as int).abs(),
    );
    final displayAmount = totalCents / 2;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label: Text(widget.task.taskType.toUpperCase()),
                  labelStyle: const TextStyle(fontSize: 10),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.task.description,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  CurrencyFormatter.formatCentsToCurrency(
                    displayAmount.round(),
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isProcessing
                      ? null
                      : () {
                          ref
                              .read(adjustingEntriesRepositoryProvider)
                              .deleteTask(widget.task.id);
                        },
                  child: Text(
                    l10n.rejectAction,
                    style: TextStyle(color: context.appColors.error),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  icon: _isProcessing
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: context.appColors.onPrimary,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(l10n.approveAction),
                  onPressed: _isProcessing
                      ? null
                      : () async {
                          setState(() => _isProcessing = true);
                          try {
                            await ref
                                .read(adjustingEntriesRepositoryProvider)
                                .approveTask(widget.task);
                          } finally {
                            if (mounted) setState(() => _isProcessing = false);
                          }
                        },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleWizardDialog extends ConsumerStatefulWidget {
  final String type; // 'prepaid' or 'accrual'
  const _SimpleWizardDialog({required this.type});

  @override
  ConsumerState<_SimpleWizardDialog> createState() =>
      _SimpleWizardDialogState();
}

class _SimpleWizardDialogState extends ConsumerState<_SimpleWizardDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  String? _selectedDebitAccountId;
  String? _selectedCreditAccountId;
  DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(
      accountsStreamProvider,
    ); // From feature_accounts
    final l10n = AppLocalizations.of(context)!;
    final isPrepaid = widget.type == 'prepaid';

    final title = isPrepaid ? l10n.recordAssetUsage : l10n.accrueUnpaidExpense;
    final debitLabel = isPrepaid
        ? l10n.expenseAccountWhereValueWent
        : l10n.expenseAccountWhatCost;
    final creditLabel = isPrepaid
        ? l10n.assetAccountWhatWasUsed
        : l10n.liabilityAccountWhoOwed;

    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: l10n.amount,
                  prefixText: "\$",
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? l10n.requiredField : null,
              ),
              const SizedBox(height: 16),
              accountsAsync.when(
                data: (accounts) => Column(
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: debitLabel,
                        border: const OutlineInputBorder(),
                      ),
                      items: accounts
                          .map(
                            (a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(a.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => _selectedDebitAccountId = v,
                      validator: (v) => v == null ? l10n.requiredField : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: creditLabel,
                        border: const OutlineInputBorder(),
                      ),
                      items: accounts
                          .map(
                            (a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(a.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => _selectedCreditAccountId = v,
                      validator: (v) => v == null ? l10n.requiredField : null,
                    ),
                  ],
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, s) => Text(l10n.errorLoadingAccountsShort),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _saveProposal,
          child: Text(l10n.proposeAdjustment),
        ),
      ],
    );
  }

  void _saveProposal() {
    if (_formKey.currentState!.validate() &&
        _selectedDebitAccountId != null &&
        _selectedCreditAccountId != null) {
      final amountDouble = double.tryParse(_amountController.text) ?? 0.0;
      final amountCents = (amountDouble * 100).round();

      final description = widget.type == 'prepaid'
          ? "Adjust: Prepaid Usage"
          : "Adjust: Accrued Expense";

      final payload = [
        {'accountId': _selectedDebitAccountId, 'amount': amountCents},
        {'accountId': _selectedCreditAccountId, 'amount': -amountCents},
      ];

      ref
          .read(adjustingEntriesRepositoryProvider)
          .createProposal(
            date: _date,
            description: description,
            taskType: widget.type,
            proposedEntries: payload,
          );

      Navigator.pop(context);
    }
  }
}
