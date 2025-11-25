import 'dart:convert';
import 'package:core_database/core_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:shared_ui/shared_ui.dart'; // CurrencyFormatter
import '../data/adjusting_entries_repository.dart';
import 'package:feature_accounts/feature_accounts.dart'; // To select accounts

// ⭐️ IMPORT THE WIZARD SCREEN
import 'period_end_wizard_screen.dart';

class AdjustingEntriesScreen extends ConsumerWidget {
  const AdjustingEntriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Note: l10n strings are hardcoded for Phase 2 speed
    final repo = ref.watch(adjustingEntriesRepositoryProvider);
    final tasksStream = repo.watchPendingTasks();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Adjustments & Closing"),
        actions: [
          // ⭐️ THE NAVIGATION BUTTON YOU REQUESTED
          IconButton(
            tooltip: "Close Period",
            icon: const Icon(Icons.lock_clock),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PeriodEndWizardScreen()),
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
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final tasks = snapshot.data!;
                
                if (tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                        const SizedBox(height: 16),
                        Text("All adjustments approved!", style: Theme.of(context).textTheme.titleMedium),
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("What do you need to record?", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _WizardButton(
                  icon: Icons.hourglass_bottom,
                  label: "Use Prepaid Asset\n(Rent/Insurance)",
                  color: Colors.blue.shade100,
                  onTap: () => _showSimpleAdjustmentDialog(context, ref, 'prepaid'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _WizardButton(
                  icon: Icons.access_time,
                  label: "Accrue Expense\n(Unpaid Wages)",
                  color: Colors.orange.shade100,
                  onTap: () => _showSimpleAdjustmentDialog(context, ref, 'accrual'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSimpleAdjustmentDialog(BuildContext context, WidgetRef ref, String type) {
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

  const _WizardButton({required this.icon, required this.label, required this.color, required this.onTap});

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
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.black87),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
    final payload = jsonDecode(widget.task.proposedEntryJson) as List;
    final totalCents = payload.fold<int>(0, (sum, e) => sum + (e['amount'] as int).abs());
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
                Chip(label: Text(widget.task.taskType.toUpperCase()), labelStyle: const TextStyle(fontSize: 10)),
                const SizedBox(width: 8),
                Expanded(child: Text(widget.task.description, style: const TextStyle(fontWeight: FontWeight.bold))),
                Text(CurrencyFormatter.formatCentsToCurrency(displayAmount.round())),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isProcessing ? null : () {
                    ref.read(adjustingEntriesRepositoryProvider).deleteTask(widget.task.id);
                  },
                  child: const Text("Reject", style: TextStyle(color: Colors.red)),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  icon: _isProcessing 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Icon(Icons.check),
                  label: const Text("Approve"),
                  onPressed: _isProcessing ? null : () async {
                    setState(() => _isProcessing = true);
                    try {
                      await ref.read(adjustingEntriesRepositoryProvider).approveTask(widget.task);
                    } finally {
                      if (mounted) setState(() => _isProcessing = false);
                    }
                  },
                ),
              ],
            )
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
  ConsumerState<_SimpleWizardDialog> createState() => _SimpleWizardDialogState();
}

class _SimpleWizardDialogState extends ConsumerState<_SimpleWizardDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  
  String? _selectedDebitAccountId;
  String? _selectedCreditAccountId;
  DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsStreamProvider); // From feature_accounts
    final isPrepaid = widget.type == 'prepaid';
    
    final title = isPrepaid ? "Record Asset Usage" : "Accrue Unpaid Expense";
    final debitLabel = isPrepaid ? "Expense Account (Where did value go?)" : "Expense Account (What is the cost?)";
    final creditLabel = isPrepaid ? "Asset Account (What was used?)" : "Liability Account (Who do we owe?)";

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
                decoration: const InputDecoration(labelText: "Amount", prefixText: "\$"),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
              ),
              const SizedBox(height: 16),
              accountsAsync.when(
                data: (accounts) => Column(
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: debitLabel, border: const OutlineInputBorder()),
                      items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                      onChanged: (v) => _selectedDebitAccountId = v,
                      validator: (v) => v == null ? "Required" : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: creditLabel, border: const OutlineInputBorder()),
                      items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                      onChanged: (v) => _selectedCreditAccountId = v,
                      validator: (v) => v == null ? "Required" : null,
                    ),
                  ],
                ),
                loading: () => const CircularProgressIndicator(),
                error: (e, s) => const Text("Error loading accounts"),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        FilledButton(
          onPressed: _saveProposal,
          child: const Text("Propose Adjustment"),
        ),
      ],
    );
  }

  void _saveProposal() {
    if (_formKey.currentState!.validate() && _selectedDebitAccountId != null && _selectedCreditAccountId != null) {
      final amountDouble = double.tryParse(_amountController.text) ?? 0.0;
      final amountCents = (amountDouble * 100).round();
      
      final description = widget.type == 'prepaid' ? "Adjust: Prepaid Usage" : "Adjust: Accrued Expense";

      final payload = [
        {'accountId': _selectedDebitAccountId, 'amount': amountCents}, 
        {'accountId': _selectedCreditAccountId, 'amount': -amountCents},
      ];

      ref.read(adjustingEntriesRepositoryProvider).createProposal(
        date: _date,
        description: description,
        taskType: widget.type,
        proposedEntries: payload,
      );
      
      Navigator.pop(context);
    }
  }
}