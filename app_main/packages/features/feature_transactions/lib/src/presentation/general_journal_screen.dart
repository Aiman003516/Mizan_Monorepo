import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:core_database/core_database.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:feature_accounts/feature_accounts.dart';
import 'package:feature_transactions/src/data/transactions_repository.dart';
import 'package:drift/drift.dart' as d;

class JournalEntryLine {
  Account? account;
  final TextEditingController debitController = TextEditingController();
  final TextEditingController creditController = TextEditingController();
  double get debit => double.tryParse(debitController.text) ?? 0.0;
  double get credit => double.tryParse(creditController.text) ?? 0.0;

  JournalEntryLine() {
    debitController.addListener(() {
      if (debitController.text.isNotEmpty) {
        creditController.clear();
      }
    });
    creditController.addListener(() {
      if (creditController.text.isNotEmpty) {
        debitController.clear();
      }
    });
  }

  void dispose() {
    debitController.dispose();
    creditController.dispose();
  }
}

class GeneralJournalScreen extends ConsumerStatefulWidget {
  const GeneralJournalScreen({super.key});

  @override
  ConsumerState<GeneralJournalScreen> createState() =>
      _GeneralJournalScreenState();
}

class _GeneralJournalScreenState extends ConsumerState<GeneralJournalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  DateTime _transactionDate = DateTime.now();
  List<JournalEntryLine> _lines = [JournalEntryLine(), JournalEntryLine()];

  double _totalDebits = 0.0;
  double _totalCredits = 0.0;
  double _balance = 0.0;

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(_validateForm);
    for (var line in _lines) {
      line.debitController.addListener(_calculateTotals);
      line.creditController.addListener(_calculateTotals);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    for (var line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  void _calculateTotals() {
    double debits = 0.0;
    double credits = 0.0;
    for (final line in _lines) {
      debits += line.debit;
      credits += line.credit;
    }
    setState(() {
      _totalDebits = debits;
      _totalCredits = credits;
      _balance = _totalDebits - _totalCredits;
    });
  }

  void _validateForm() {
    _calculateTotals();
  }

  void _addLine() {
    final newLine = JournalEntryLine();
    newLine.debitController.addListener(_calculateTotals);
    newLine.creditController.addListener(_calculateTotals);
    setState(() {
      _lines.add(newLine);
    });
  }

  void _removeLine(int index) {
    _lines[index].dispose();
    setState(() {
      _lines.removeAt(index);
    });
    _calculateTotals();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _transactionDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _transactionDate) {
      setState(() {
        _transactionDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final bool isBalanced = _balance.abs() < 0.001 && _totalDebits > 0;

    if (_formKey.currentState!.validate() && isBalanced) {
      final entries = <TransactionEntriesCompanion>[];
      for (final line in _lines) {
        if (line.account == null || (line.debit == 0 && line.credit == 0)) {
          continue;
        }
        final amount = line.debit > 0 ? line.debit : -line.credit;
        entries.add(
          TransactionEntriesCompanion.insert(
            accountId: line.account!.id,
            amount: amount,
            transactionId: '', // Will be replaced by repo
          ),
        );
      }

      if (entries.length < 2) {
        scaffoldMessenger.showSnackBar(SnackBar(
          content: Text(l10n.error),
          backgroundColor: Colors.red,
        ));
        return;
      }

      try {
        await ref
            .read(transactionsRepositoryProvider)
            .createJournalTransaction(
              description: _descriptionController.text,
              transactionDate: _transactionDate,
              entries: entries,
            );

        scaffoldMessenger.showSnackBar(SnackBar(
          content: Text(l10n.transactionSaved),
          backgroundColor: Colors.green,
        ));
        navigator.pop();
      } catch (e) {
        scaffoldMessenger.showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final allAccountsAsync = ref.watch(allAccountsStreamProvider);

    final bool isBalanced = _balance.abs() < 0.001 && _totalDebits > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addNewTransaction),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: l10n.save,
            onPressed: isBalanced ? _saveTransaction : null,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: l10n.description,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.pleaseEnterName;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: l10n.date,
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(
                      text: DateFormat.yMd().format(_transactionDate),
                    ),
                    onTap: () => _selectDate(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(l10n.account, style: Theme.of(context).textTheme.titleSmall)),
                  Expanded(
                      flex: 2,
                      child: Text(l10n.debit, textAlign: TextAlign.right, style: Theme.of(context).textTheme.titleSmall)),
                  Expanded(
                      flex: 2,
                      child: Text(l10n.credit, textAlign: TextAlign.right, style: Theme.of(context).textTheme.titleSmall)),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: allAccountsAsync.when(
                data: (accounts) {
                  return ListView.builder(
                    itemCount: _lines.length,
                    itemBuilder: (context, index) {
                      final line = _lines[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<Account>(
                                value: line.account,
                                hint: Text(l10n.selectAccount),
                                isExpanded: true,
                                items: accounts.map((account) {
                                  return DropdownMenuItem<Account>(
                                    value: account,
                                    child: Text(account.name,
                                        overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    line.account = value;
                                  });
                                  _validateForm();
                                },
                                validator: (value) {
                                  if (line.debit != 0 || line.credit != 0) {
                                    if (value == null) {
                                      return l10n.fieldRequired;
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: line.debitController,
                                decoration:
                                    InputDecoration(labelText: l10n.debit),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: line.creditController,
                                decoration:
                                    InputDecoration(labelText: l10n.credit),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: Colors.red),
                              onPressed: _lines.length > 2
                                  ? () => _removeLine(index)
                                  : null,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text(e.toString()),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.total,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        "${l10n.drLabel} ${_totalDebits.toStringAsFixed(2)}",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        "${l10n.crLabel} ${_totalCredits.toStringAsFixed(2)}",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.balance,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        _balance.toStringAsFixed(2),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: isBalanced
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextButton.icon(
                icon: const Icon(Icons.add),
                label: Text(l10n.addProduct), // "Add Product"
                onPressed: _addLine,
              ),
            ),
          ],
        ),
      ),
    );
  }
}