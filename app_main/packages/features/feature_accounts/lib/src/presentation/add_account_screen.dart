import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:feature_accounts/src/data/accounts_repository.dart';
import 'package:core_database/core_database.dart';
import 'package:drift/drift.dart' as d;
import 'package:feature_accounts/src/data/classifications_repository.dart';
import 'package:core_data/src/services/currency_service.dart';

class AddAccountScreen extends ConsumerStatefulWidget {
  final Account? accountToEdit;
  const AddAccountScreen({super.key, this.accountToEdit});
  @override
  ConsumerState<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends ConsumerState<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _debitBalanceController = TextEditingController();
  final _creditBalanceController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  String _selectedAccountType = 'asset';
  Classification? _selectedClassification;
  String _selectedCurrency = 'Local';
  bool _isLoading = false;
  Map<String, double> _exchangeRates = {};

  final _accountTypes = ['asset', 'liability', 'equity', 'revenue', 'expense'];

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  String _getLocalizedClassification(String dbName) {
    switch (dbName.toLowerCase()) {
      case 'clients':
        return l10n.clients;
      case 'suppliers':
        return l10n.suppliers;
      case 'general':
        return l10n.general;
      default:
        return dbName;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
    if (widget.accountToEdit != null) {
      final account = widget.accountToEdit!;
      _nameController.text = account.name;

      // Parse customAttributes for multi-currency data
      final customAttrs = account.customAttributes;
      if (customAttrs != null && customAttrs.isNotEmpty) {
        try {
          // It's saved as a stringified JSON representation from Drift or a JSON string.
          // Since it might be stored via `customAttributes.toString()` which produces `{key: value}`,
          // we should ideally use jsonDecode if it's true JSON, but due to earlier bugs, we'll try to parse it safely.
          final String attrsStr = customAttrs as String;
          if (attrsStr.startsWith('{') && attrsStr.endsWith('}')) {
            // Very simple parsing for the legacy format or JSON format
            // If it's proper JSON, jsonDecode would work, but we will use regex or simple split for safety if it's Dart's .toString()
            // Assuming it's simple JSON-like for currency
            if (attrsStr.contains('"currency":"')) {
              final currencyMatch = RegExp(
                r'"currency":"([^"]+)"',
              ).firstMatch(attrsStr);
              if (currencyMatch != null) {
                _selectedCurrency = currencyMatch.group(1)!;
              }
            } else if (attrsStr.contains('currency: ')) {
              final currencyMatch = RegExp(
                r'currency:\s*([^,}]+)',
              ).firstMatch(attrsStr);
              if (currencyMatch != null) {
                _selectedCurrency = currencyMatch.group(1)!.trim();
              }
            }
          }
        } catch (_) {
          // Ignore parsing errors
        }
      }

      // Set initial balance based on sign
      final balance = account.initialBalance / 100.0;
      if (balance >= 0) {
        _debitBalanceController.text = balance.toStringAsFixed(2);
        _creditBalanceController.text = '0.00';
      } else {
        _debitBalanceController.text = '0.00';
        _creditBalanceController.text = balance.abs().toStringAsFixed(2);
      }

      _phoneNumberController.text = account.phoneNumber ?? '';
      _selectedAccountType = account.type;
      if (account.classificationId != null) {
        _selectedClassification = Classification(
          id: account.classificationId!,
          name: 'Loading...',
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
          isDeleted: false,
        );
      }
    } else {
      _debitBalanceController.text = '0.00';
      _creditBalanceController.text = '0.00';
    }

    _debitBalanceController.addListener(() {
      setState(() {});
    });
    _creditBalanceController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _loadCurrencies() async {
    try {
      final currencyService = ref.read(currencyServiceProvider);
      final currencies = await currencyService.getAllCurrencies();
      if (currencies.isNotEmpty) {
        setState(() {
          _selectedCurrency = currencies.first.code;
        });
      }
    } catch (_) {
      // Use default
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _debitBalanceController.dispose();
    _creditBalanceController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });
      try {
        final name = _nameController.text;
        final debitBalance =
            double.tryParse(_debitBalanceController.text) ?? 0.0;
        final creditBalance =
            double.tryParse(_creditBalanceController.text) ?? 0.0;
        final phoneNumber = _phoneNumberController.text.isNotEmpty
            ? _phoneNumberController.text
            : null;
        final classificationId = _selectedClassification?.id;

        // Calculate net balance (debit - credit)
        final netBalance = debitBalance - creditBalance;
        final int balanceCents = (netBalance * 100).round();

        // Build custom attributes for multi-currency support
        final customAttributes = {
          'currency': _selectedCurrency,
          'debitBalance': debitBalance,
          'creditBalance': creditBalance,
          'exchangeRates': _exchangeRates,
        };

        if (widget.accountToEdit == null) {
          await ref
              .read(accountsRepositoryProvider)
              .createAccount(
                name: name,
                type: _selectedAccountType,
                initialBalance: netBalance,
                phoneNumber: phoneNumber,
                classificationId: classificationId,
                customAttributes: customAttributes.toString(),
              );
        } else {
          final updatedAccount = widget.accountToEdit!.copyWith(
            name: name,
            type: _selectedAccountType,
            initialBalance: balanceCents,
            phoneNumber: d.Value(phoneNumber),
            classificationId: d.Value(classificationId),
            customAttributes: d.Value(customAttributes.toString()),
          );
          await ref
              .read(accountsRepositoryProvider)
              .updateAccount(updatedAccount);
        }
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.failedToSaveAccount} $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Map<String, String> _getTranslatedAccountTypes(AppLocalizations l10n) {
    return {
      'asset': l10n.accountTypeAsset,
      'liability': l10n.accountTypeLiability,
      'equity': l10n.accountTypeEquity,
      'revenue': l10n.accountTypeRevenue,
      'expense': l10n.accountTypeExpense,
    };
  }

  void _addExchangeRate() {
    showDialog(
      context: context,
      builder: (context) {
        String fromCurrency = _selectedCurrency;
        String toCurrency = '';
        double rate = 1.0;
        final fromController = TextEditingController(text: fromCurrency);
        final toController = TextEditingController();
        final rateController = TextEditingController(text: '1.0');

        return AlertDialog(
          title: Text(l10n.addExchangeRate),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: fromController,
                  decoration: InputDecoration(
                    labelText: l10n.fromCurrency,
                    border: const OutlineInputBorder(),
                  ),
                  readOnly: true,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: toController,
                  decoration: InputDecoration(
                    labelText: l10n.toCurrency,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.pleaseEnterCurrency;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: rateController,
                  decoration: InputDecoration(
                    labelText: l10n.exchangeRateShort,
                    border: const OutlineInputBorder(),
                    helperText: '1 From = X To',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,6}'),
                    ),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.pleaseEnterRate;
                    }
                    if (double.tryParse(value) == null ||
                        double.parse(value) <= 0) {
                      return l10n.pleaseEnterValidRate;
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                if (toController.text.isNotEmpty &&
                    double.tryParse(rateController.text) != null) {
                  setState(() {
                    _exchangeRates['${fromController.text}_${toController.text}'] =
                        double.parse(rateController.text);
                    _exchangeRates['${toController.text}_${fromController.text}'] =
                        1 / double.parse(rateController.text);
                  });
                  Navigator.pop(context);
                }
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
  }

  void _removeExchangeRate(String key) {
    setState(() {
      _exchangeRates.remove(key);
      // Also remove inverse
      final parts = key.split('_');
      if (parts.length == 2) {
        _exchangeRates.remove('${parts[1]}_${parts[0]}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final classificationsAsync = ref.watch(classificationsStreamProvider);
    final translatedAccountTypes = _getTranslatedAccountTypes(l10n);

    if (widget.accountToEdit != null &&
        _selectedClassification?.name == 'Loading...') {
      _selectedClassification = _selectedClassification?.copyWith(
        name: l10n.loading,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.accountToEdit == null ? l10n.addNewAccount : l10n.editAccount,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveAccount,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Account Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n.accountNameHint,
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

                    // Account Type
                    DropdownButtonFormField<String>(
                      initialValue: _selectedAccountType,
                      decoration: InputDecoration(
                        labelText: l10n.accountType,
                        border: const OutlineInputBorder(),
                      ),
                      items: _accountTypes.map((String key) {
                        return DropdownMenuItem<String>(
                          value: key,
                          child: Text(translatedAccountTypes[key] ?? key),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedAccountType = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Currency Selection
                    FutureBuilder<List<Currency>>(
                      future: ref
                          .read(currencyServiceProvider)
                          .getAllCurrencies(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final currencies = snapshot.data!;
                        return DropdownButtonFormField<String>(
                          initialValue: _selectedCurrency,
                          decoration: InputDecoration(
                            labelText: l10n.accountCurrency,
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.currency_exchange),
                          ),
                          items: currencies.map((Currency currency) {
                            return DropdownMenuItem<String>(
                              value: currency.code,
                              child: Text(
                                '${currency.code} - ${currency.name}',
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedCurrency = newValue;
                              });
                            }
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Classification
                    classificationsAsync.when(
                      data: (classifications) {
                        final validIds = classifications
                            .map((c) => c.id)
                            .toSet();
                        String? selectedId = _selectedClassification?.id;
                        if (selectedId != null &&
                            !validIds.contains(selectedId)) {
                          selectedId = null;
                        }

                        return DropdownButtonFormField<String>(
                          value: selectedId,
                          hint: Text(l10n.classificationOptional),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          items: classifications.map((Classification cls) {
                            return DropdownMenuItem<String>(
                              value: cls.id,
                              child: Text(
                                _getLocalizedClassification(cls.name),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newId) {
                            setState(() {
                              if (newId == null) {
                                _selectedClassification = null;
                              } else {
                                _selectedClassification = classifications
                                    .firstWhere((c) => c.id == newId);
                              }
                            });
                          },
                        );
                      },
                      error: (err, stack) =>
                          Text('${l10n.errorLoadingClassifications} $err'),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                    ),
                    const SizedBox(height: 16),

                    // Phone Number
                    TextFormField(
                      controller: _phoneNumberController,
                      decoration: InputDecoration(
                        labelText: l10n.phoneNumberOptional,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // Debit/Credit Balance Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.initialBalances,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _debitBalanceController,
                                    decoration: InputDecoration(
                                      labelText: l10n.debitBalance,
                                      border: const OutlineInputBorder(),
                                      prefixIcon: const Icon(
                                        Icons.arrow_upward,
                                        color: Colors.green,
                                      ),
                                      prefixText: '\$ ',
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d+\.?\d{0,2}'),
                                      ),
                                    ],
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return l10n.pleaseEnterBalance;
                                      }
                                      if (double.tryParse(value) == null) {
                                        return l10n.pleaseEnterValidNumber;
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _creditBalanceController,
                                    decoration: InputDecoration(
                                      labelText: l10n.creditBalance,
                                      border: const OutlineInputBorder(),
                                      prefixIcon: const Icon(
                                        Icons.arrow_downward,
                                        color: Colors.red,
                                      ),
                                      prefixText: '\$ ',
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d+\.?\d{0,2}'),
                                      ),
                                    ],
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return l10n.pleaseEnterBalance;
                                      }
                                      if (double.tryParse(value) == null) {
                                        return l10n.pleaseEnterValidNumber;
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Net Balance Display
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    l10n.netBalance,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '\$${((double.tryParse(_debitBalanceController.text) ?? 0.0) - (double.tryParse(_creditBalanceController.text) ?? 0.0)).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Exchange Rates Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.exchangeRates,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: _addExchangeRate,
                                  tooltip: l10n.addExchangeRate,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_exchangeRates.isEmpty)
                              Text(
                                l10n.noExchangeRates,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              )
                            else
                              ..._exchangeRates.entries
                                  .where((e) => !e.key.endsWith('_inverse'))
                                  .map((entry) {
                                    final parts = entry.key.split('_');
                                    if (parts.length != 2)
                                      return const SizedBox.shrink();
                                    final from = parts[0];
                                    final to = parts[1];
                                    // Only show one direction to avoid duplicates
                                    if (from.compareTo(to) > 0)
                                      return const SizedBox.shrink();

                                    return ListTile(
                                      dense: true,
                                      leading: const Icon(
                                        Icons.currency_exchange,
                                      ),
                                      title: Text('$from → $to'),
                                      subtitle: Text(
                                        '1 $from = ${entry.value.toStringAsFixed(4)} $to',
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            _removeExchangeRate(entry.key),
                                      ),
                                    );
                                  })
                                  .toList(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _saveAccount,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isLoading ? l10n.saving : l10n.saveAccount),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
