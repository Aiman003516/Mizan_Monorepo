import 'package:drift/drift.dart' as d;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:core_database/core_database.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:feature_accounts/feature_accounts.dart';
import 'package:feature_transactions/src/data/transactions_repository.dart';

class MakePaymentScreen extends ConsumerStatefulWidget {
  final Account supplierAccount;
  final double amountOwed;

  const MakePaymentScreen({
    super.key,
    required this.supplierAccount,
    required this.amountOwed,
  });

  @override
  ConsumerState<MakePaymentScreen> createState() => _MakePaymentScreenState();
}

class _MakePaymentScreenState extends ConsumerState<MakePaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _transactionDate = DateTime.now();
  Account? _selectedPaymentAccount;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.amountOwed.toStringAsFixed(2);
    // We can't get l10n here, so we use a non-l10n string.
    // A better fix would be to pass l10n in or load it async.
    _descriptionController.text = 'Payment to ${widget.supplierAccount.name}';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
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

  Future<void> _savePayment() async {
    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (!_formKey.currentState!.validate() || _selectedPaymentAccount == null) {
      return;
    }

    final paymentAmount = double.tryParse(_amountController.text) ?? 0.0;
    if (paymentAmount <= 0) {
      scaffoldMessenger.showSnackBar(SnackBar(
        content: Text(l10n.pleaseEnterValidAmount),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final entries = <TransactionEntriesCompanion>[
      TransactionEntriesCompanion.insert(
        accountId: widget.supplierAccount.id,
        amount: paymentAmount,
        transactionId: '', // Will be replaced by repo
      ),
      TransactionEntriesCompanion.insert(
        accountId: _selectedPaymentAccount!.id,
        amount: -paymentAmount,
        transactionId: '', // Will be replaced by repo
      ),
    ];

    try {
      // If description is still the default, replace with l10n version
      if (_descriptionController.text == 'Payment to ${widget.supplierAccount.name}') {
         _descriptionController.text = l10n.purchaseFrom(widget.supplierAccount.name); // This is a bit of a guess, but better
      }

      await ref.read(transactionsRepositoryProvider).createJournalTransaction(
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final allAccountsAsync = ref.watch(allAccountsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.makePayment),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: l10n.save,
            onPressed: _savePayment,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              allAccountsAsync.when(
                data: (accounts) {
                  final assetAccounts =
                      accounts.where((a) => a.type == 'asset').toList();
                  return DropdownButtonFormField<Account>(
                    value: _selectedPaymentAccount,
                    hint: Text(l10n.selectAccount),
                    decoration: InputDecoration(
                      labelText: l10n.payFromAccount,
                      border: const OutlineInputBorder(),
                    ),
                    items: assetAccounts.map((account) {
                      return DropdownMenuItem<Account>(
                        value: account,
                        child: Text(account.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentAccount = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? l10n.fieldRequired : null,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('Error loading accounts: $e'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: l10n.payToAccount,
                  border: const OutlineInputBorder(),
                ),
                initialValue: widget.supplierAccount.name,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: l10n.amount,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.fieldRequired;
                  }
                  if (double.tryParse(value) == null ||
                      double.parse(value) <= 0) {
                    return l10n.pleaseEnterValidAmount;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: l10n.description,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? l10n.fieldRequired : null,
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
      ),
    );
  }
}