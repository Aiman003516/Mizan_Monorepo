import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as d;
import 'package:core_l10n/app_localizations.dart';
import 'package:core_database/core_database.dart';
import 'package:core_data/core_data.dart';
import 'package:feature_accounts/feature_accounts.dart';
import 'package:feature_reports/feature_reports.dart' hide databaseProvider;
import 'package:feature_transactions/src/data/transactions_repository.dart';
import 'package:feature_transactions/src/data/database_provider.dart' hide databaseProvider;

// REMOVED: import 'package:feature_settings/feature_settings.dart';

// FIX: Create a local provider to break dependency on feature_settings
final _currenciesStreamProvider = StreamProvider<List<Currency>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.currencies)
        ..orderBy([(t) => d.OrderingTerm.asc(t.code)]))
      .watch();
});

// Provider to fetch the name of the account being edited
final _accountNameProvider =
    FutureProvider.autoDispose.family<String, String>((ref, accountId) async {
  // This provider MUST be overridden in main.dart to provide a real l10n object
  final l10n = ref.watch(appLocalizationsProvider);

  final db = ref.watch(databaseProvider);
  final account = await (db.select(db.accounts)
        ..where((tbl) => tbl.id.equals(accountId)))
      .getSingleOrNull();
  return account?.name ?? l10n.unknownAccount;
});

// Placeholder provider. This MUST be overridden in main.dart
final appLocalizationsProvider = Provider<AppLocalizations>((ref) {
  throw UnimplementedError('appLocalizationsProvider must be overridden');
});

class AddAmountScreen extends ConsumerStatefulWidget {
  final String? accountId;
  final String? classificationName;

  const AddAmountScreen({super.key, this.accountId, this.classificationName});

  @override
  ConsumerState<AddAmountScreen> createState() => _AddAmountScreenState();
}

class _AddAmountScreenState extends ConsumerState<AddAmountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _detailsController = TextEditingController();
  final _rateController = TextEditingController(text: '1.0');

  DateTime _selectedDate = DateTime.now();
  String? _selectedCurrency;
  bool _isCredit = false;
  bool _isLoading = false;
  Account? _selectedAccount;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _selectedCurrency = ref.read(defaultCurrencyProvider);

    if (widget.accountId != null) {
      ref.read(_accountNameProvider(widget.accountId!).future).then((name) {
        if (mounted) {
          _nameController.text = name;
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _detailsController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_selectedCurrency == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.pleaseSelectCurrency)));
      return;
    }
    final accountName = _nameController.text.trim();
    if (accountName.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.pleaseEnterAccountName)));
      return;
    }
    setState(() {
      _isLoading = true;
    });
    final messenger = ScaffoldMessenger.of(context);
    final accountsRepo = ref.read(accountsRepositoryProvider);
    final db = ref.read(databaseProvider);
    final defaultCurrency = ref.read(defaultCurrencyProvider);

    try {
      String targetAccountId;

      if (_selectedAccount != null && _selectedAccount!.name == accountName) {
        targetAccountId = _selectedAccount!.id;
      } else {
        final existingAccountId =
            await accountsRepo.getAccountIdByName(accountName);
        if (existingAccountId != null) {
          targetAccountId = existingAccountId;
        } else {
          final classificationId = await accountsRepo.getClassificationIdByName(
              widget.classificationName ?? kClassificationGeneral);

          final newAccountCompanion = AccountsCompanion.insert(
            name: accountName,
            type: 'asset',
            classificationId: d.Value(classificationId),
            initialBalance: 0.0,
          );
          final newAccount =
              await db.into(db.accounts).insertReturning(newAccountCompanion);
          targetAccountId = newAccount.id;
        }
      }

      final equityAccountId =
          await accountsRepo.getAccountIdByName(kEquityAccountName);
      if (equityAccountId == null) {
        messenger
            .showSnackBar(SnackBar(content: Text(l10n.criticalAccountError)));
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final transactionAmount = _isCredit ? -amount : amount;
      final description = _detailsController.text;

      final currencyCode = _selectedCurrency!;
      final currencyRate = double.tryParse(_rateController.text) ?? 1.0;

      final entries = [
        TransactionEntriesCompanion.insert(
          accountId: targetAccountId,
          amount: transactionAmount,
          transactionId: 'TEMP',
          currencyRate: d.Value(currencyRate),
        ),
        TransactionEntriesCompanion.insert(
          accountId: equityAccountId,
          amount: -transactionAmount,
          transactionId: 'TEMP',
          currencyRate: d.Value(currencyRate),
        ),
      ];

      await ref.read(transactionsRepositoryProvider).createTransaction(
            description: description.isNotEmpty
                ? description
                : (_isCredit ? l10n.paymentCredit : l10n.chargeDebit),
            transactionDate: _selectedDate,
            entries: entries,
            currencyCode: currencyCode,
          );

      _amountController.clear();
      _detailsController.clear();
      _rateController.text = '1.0';
      if (widget.accountId == null) {
        _nameController.clear();
        setState(() {
          _selectedAccount = null;
        });
      }
      setState(() {
        _isLoading = false;
        _selectedCurrency = defaultCurrency;
      });
      messenger.showSnackBar(SnackBar(content: Text(l10n.transactionSaved)));
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      messenger.showSnackBar(SnackBar(content: Text('${l10n.failedToSave} $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountNameAsync =
        ref.watch(_accountNameProvider(widget.accountId ?? ''));

    //
    // 💡--- THIS IS THE FIX (Part 1) ---
    // We watch the public provider from feature_reports.
    final historyAsync = ref.watch(generalLedgerStreamProvider);
    //
    //

    final allAccountsAsync = ref.watch(allAccountsStreamProvider);

    final currenciesAsync =
        ref.watch(_currenciesStreamProvider); // FIX: Use local provider
    final defaultCurrency =
        ref.watch(defaultCurrencyProvider); // FIX: Use provider from core_data

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.accountId != null
            ? accountNameAsync.when(
                data: (name) => l10n.forAccount(name),
                loading: () => l10n.loading,
                error: (e, s) => l10n.error)
            : l10n.addNewTransaction),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveTransaction,
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.accountId == null)
                    allAccountsAsync.when(
                      data: (accounts) {
                        return Autocomplete<Account>(
                          fieldViewBuilder: (context, textEditingController,
                              focusNode, onFieldSubmitted) {
                            _nameController.text = textEditingController.text;

                            return TextFormField(
                              controller: textEditingController,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                labelText: l10n.accountName,
                                border: const OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return l10n.pleaseEnterOrSelectAccount;
                                }
                                return null;
                              },
                              onChanged: (text) => _nameController.text = text,
                            );
                          },
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text == '') {
                              return const Iterable<Account>.empty();
                            }
                            return accounts.where((Account account) {
                              return account.name.toLowerCase().contains(
                                    textEditingValue.text.toLowerCase(),
                                  );
                            });
                          },
                          displayStringForOption: (Account option) =>
                              option.name,
                          onSelected: (Account selection) {
                            setState(() {
                              _selectedAccount = selection;
                              _nameController.text = selection.name;
                            });
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, s) =>
                          Text('${l10n.errorLoadingAccounts} $e'),
                    ),
                  if (widget.accountId != null)
                    TextFormField(
                      controller: _nameController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: l10n.account,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                        labelText: l10n.amount,
                        prefixIcon: const Icon(Icons.calculate)),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.pleaseEnterAmount;
                      }
                      if (double.tryParse(value) == null ||
                          double.parse(value) <= 0) {
                        return l10n.invalidAmount;
                      }
                      return null;
                    },
                  ),
                  if (_selectedCurrency != defaultCurrency)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: TextFormField(
                        controller: _rateController,
                        decoration: InputDecoration(
                          labelText: l10n.exchangeRate(
                              _selectedCurrency ?? '', defaultCurrency),
                          prefixIcon: const Icon(Icons.swap_horiz),
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.pleaseEnterRate;
                          }
                          if (double.tryParse(value) == null ||
                              double.parse(value) <= 0) {
                            return l10n.invalidRate;
                          }
                          return null;
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: InkWell(
                          onTap: () => _selectDate(context),
                          child: InputDecorator(
                            decoration: InputDecoration(
                                labelText: l10n.date,
                                border: InputBorder.none),
                            child: Text(DateFormat.yMd().format(_selectedDate)),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.camera_alt),
                        tooltip: l10n.addAttachment,
                        onPressed: () {
                          /* TODO */
                        },
                      ),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _detailsController,
                          decoration: InputDecoration(labelText: l10n.details),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  currenciesAsync.when(
                    data: (currencies) => Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      alignment: WrapAlignment.center,
                      children: currencies.map((currency) {
                        return ChoiceChip(
                          label: Text(currency.code),
                          selected: _selectedCurrency == currency.code,
                          onSelected: (isSelected) {
                            if (isSelected) {
                              setState(() {
                                _selectedCurrency = currency.code;
                                if (_selectedCurrency == defaultCurrency) {
                                  _rateController.text = '1.0';
                                }
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Text(l10n.couldNotLoadCurrencies),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          icon: const Icon(Icons.arrow_upward),
                          label: Text(l10n.paymentCredit),
                          style: FilledButton.styleFrom(
                            backgroundColor: _isCredit
                                ? Colors.green.shade100
                                : Colors.grey.shade300,
                          ),
                          onPressed: () => setState(() => _isCredit = true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          icon: const Icon(Icons.arrow_downward),
                          label: Text(l10n.chargeDebit),
                          style: FilledButton.styleFrom(
                            backgroundColor: !_isCredit
                                ? Colors.red.shade100
                                : Colors.grey.shade300,
                          ),
                          onPressed: () => setState(() => _isCredit = false),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(thickness: 2),
          if (widget.accountId != null)
            Expanded(
              child: historyAsync.when(
                data: (allHistory) {
                  //
                  // 💡--- THIS IS THE FIX (Part 2) ---
                  // We filter the full list to get only items for this account.
                  final history = allHistory
                      .where((detail) => detail.accountId == widget.accountId)
                      .toList();
                  //
                  //

                  if (history.isEmpty) {
                    return Center(child: Text(l10n.noHistory));
                  }
                  return ListView.builder(
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final detail = history[index];
                      final isDebit = detail.entryAmount > 0;
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          isDebit ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isDebit ? Colors.redAccent : Colors.green,
                        ),
                        title: Text(detail.transactionDescription),
                        subtitle: Text(DateFormat.yMd()
                            .add_jm()
                            .format(detail.transactionDate)),
                        trailing: Text(
                          '${detail.entryAmount.abs().toStringAsFixed(2)} ${detail.currencyCode}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDebit ? Colors.redAccent : Colors.green,
                          ),
                        ),
                        onTap: () {},
                      );
                    },
                  );
                },
                error: (e, s) =>
                    Center(child: Text('${l10n.errorLoadingHistory} $e')),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}