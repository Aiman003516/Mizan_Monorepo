import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
// Assuming localization exists
import 'package:core_database/core_database.dart';
import 'package:shared_ui/shared_ui.dart'; // CurrencyFormatter
import 'package:feature_accounts/feature_accounts.dart'; // Account selection

import '../data/bank_reconciliation_repository.dart';

class BankReconciliationScreen extends ConsumerStatefulWidget {
  const BankReconciliationScreen({super.key});

  @override
  ConsumerState<BankReconciliationScreen> createState() =>
      _BankReconciliationScreenState();
}

class _BankReconciliationScreenState
    extends ConsumerState<BankReconciliationScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- STEP 1 STATE ---
  int _currentStep = 0;
  String? _selectedAccountId;
  DateTime _statementDate = DateTime.now();
  final _endingBalanceController = TextEditingController();

  // --- STEP 2 STATE ---
  int _systemStartingBalance = 0; // Calculated from past reconciliations
  List<TransactionEntry> _candidates = [];
  final Set<String> _selectedTxIds = {};

  bool _isLoading = false;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void dispose() {
    _endingBalanceController.dispose();
    super.dispose();
  }

  // --- COMPUTED MATH ---
  // Target = User Input
  int get _targetBalanceCents {
    final doubleVal = double.tryParse(_endingBalanceController.text) ?? 0.0;
    return (doubleVal * 100).round();
  }

  // Cleared = Start + (Sum of checked items)
  int get _clearedBalanceCents {
    int sumChecked = 0;
    for (final tx in _candidates) {
      if (_selectedTxIds.contains(tx.transactionId)) {
        sumChecked += tx.amount;
      }
    }
    return _systemStartingBalance + sumChecked;
  }

  // Difference = Target - Cleared
  int get _differenceCents => _targetBalanceCents - _clearedBalanceCents;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l10n.bankReconciliations)),
      body: _currentStep == 0 ? _buildSetupStep() : _buildReconcileStep(),
    );
  }

  // --------------------------------------------------------------------------
  // STEP 1: SETUP (Account & Statement Details)
  // --------------------------------------------------------------------------
  Widget _buildSetupStep() {
    final accountsAsync = ref.watch(accountsStreamProvider);

    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.statementDetails,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // 1. Account Selector
            accountsAsync.when(
              data: (accounts) {
                final assetAccounts = accounts
                    .where((a) => a.type == 'asset')
                    .toList();
                return DropdownButtonFormField<String>(
                  initialValue: _selectedAccountId,
                  decoration: InputDecoration(
                    labelText: l10n.selectBankAccount,
                    border: const OutlineInputBorder(),
                  ),
                  items: assetAccounts
                      .map(
                        (a) =>
                            DropdownMenuItem(value: a.id, child: Text(a.name)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedAccountId = v),
                  validator: (value) =>
                      value == null ? l10n.requiredField : null,
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => Text(l10n.errorLoadingAccounts),
            ),
            const SizedBox(height: 16),

            // 2. Statement Date
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _statementDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _statementDate = picked);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.statementDate,
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                child: Text(DateFormat.yMMMd().format(_statementDate)),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Ending Balance
            TextFormField(
              controller: _endingBalanceController,
              decoration: InputDecoration(
                labelText: l10n.statementEndingBalance,
                border: const OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) => InputValidators.requiredDecimal(
                value,
                requiredMessage: l10n.requiredField,
                invalidMessage: l10n.invalidAmount,
              ),
            ),

            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed:
                    (_selectedAccountId == null ||
                        _endingBalanceController.text.isEmpty)
                    ? null
                    : _startReconciliation,
                child: Text(l10n.startReconciling),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startReconciliation() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(bankReconciliationRepositoryProvider);

      // A. Get Starting Balance
      _systemStartingBalance = await repo.getReconciledBalance(
        _selectedAccountId!,
      );

      // B. Get Candidates
      _candidates = await repo.getUnreconciledEntries(
        accountId: _selectedAccountId!,
        statementDate: _statementDate,
      );

      setState(() {
        _currentStep = 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorWithDetails(l10n.error, e.toString())),
        ),
      );
    }
  }

  // --------------------------------------------------------------------------
  // STEP 2: THE RECONCILIATION GAME
  // --------------------------------------------------------------------------
  Widget _buildReconcileStep() {
    final diff = _differenceCents;
    final isBalanced = diff == 0;
    final color = isBalanced
        ? context.appColors.success
        : context.appColors.error;

    return Column(
      children: [
        // --- THE SCOREBOARD ---
        Container(
          // ignore: deprecated_member_use
          color: color.withValues(alpha: 0.1),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${l10n.statementEnding}:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    CurrencyFormatter.formatCentsToCurrency(
                      _targetBalanceCents,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.labelWithColon(l10n.clearedBalance)),
                  Text(
                    CurrencyFormatter.formatCentsToCurrency(
                      _clearedBalanceCents,
                    ),
                  ),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${l10n.difference.toUpperCase()}:',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatCentsToCurrency(diff),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              if (!isBalanced)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    l10n.selectTransactionsUntilBalanced,
                    style: TextStyle(color: color, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),

        // --- THE LIST ---
        Expanded(
          child: _candidates.isEmpty
              ? Center(child: Text(l10n.noUnreconciledTransactions))
              : ListView.builder(
                  itemCount: _candidates.length,
                  itemBuilder: (context, index) {
                    final tx = _candidates[index];
                    final isSelected = _selectedTxIds.contains(
                      tx.transactionId,
                    );
                    // Amount > 0 = Debit (Deposit), Amount < 0 = Credit (Payment)
                    final isDeposit = tx.amount >= 0;

                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedTxIds.add(tx.transactionId);
                          } else {
                            _selectedTxIds.remove(tx.transactionId);
                          }
                        });
                      },
                      title: Text(isDeposit ? l10n.deposit : l10n.payment),
                      subtitle: Text(
                        '${l10n.idLabel}: ...${tx.transactionId.substring(0, 6)}',
                      ), // Show description later if joined
                      secondary: Text(
                        CurrencyFormatter.formatCentsToCurrency(
                          tx.amount.abs(),
                        ),
                        style: TextStyle(
                          color: isDeposit
                              ? context.appColors.success
                              : context.appColors.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
        ),

        // --- THE ACTIONS ---
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: context.appColors.primary)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.bankFeeInterestComingSoon)),
                    );
                  },
                  child: Text(l10n.addAdjustment),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  // 🔒 GUARD: Disable until balanced
                  onPressed: (!isBalanced || _isLoading)
                      ? null
                      : _finishReconciliation,
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: context.appColors.onPrimary,
                          ),
                        )
                      : Text(l10n.finish),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _finishReconciliation() async {
    setState(() => _isLoading = true);
    try {
      await ref
          .read(bankReconciliationRepositoryProvider)
          .finalizeReconciliation(
            accountId: _selectedAccountId!,
            statementDate: _statementDate,
            statementEndingBalance: _targetBalanceCents,
            selectedTransactionIds: _selectedTxIds.toList(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.reconciliationComplete),
            backgroundColor: context.appColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorWithDetails(l10n.error, e.toString())),
          ),
        );
      }
    }
  }
}
