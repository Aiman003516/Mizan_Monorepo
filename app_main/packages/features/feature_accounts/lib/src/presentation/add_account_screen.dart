import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:feature_accounts/src/data/accounts_repository.dart';
import 'package:core_database/core_database.dart';
import 'package:drift/drift.dart' as d;
import 'package:feature_accounts/src/data/classifications_repository.dart';

class AddAccountScreen extends ConsumerStatefulWidget {
  final Account? accountToEdit;
  const AddAccountScreen({super.key, this.accountToEdit});
  @override
  ConsumerState<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends ConsumerState<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _initialBalanceController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  String _selectedAccountType = 'asset';
  Classification? _selectedClassification;
  bool _isLoading = false;

  final _accountTypes = [
    'asset',
    'liability',
    'equity',
    'revenue',
    'expense',
  ];

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    if (widget.accountToEdit != null) {
      final account = widget.accountToEdit!;
      _nameController.text = account.name;
      
      // FIX: Convert stored Int (Cents) to Double String for display
      // 1050 -> 10.50
      _initialBalanceController.text = (account.initialBalance / 100.0).toStringAsFixed(2);
      
      _phoneNumberController.text = account.phoneNumber ?? '';
      _selectedAccountType = account.type;
      if (account.classificationId != null) {
        // 🛠️ FIX APPLIED HERE: Added missing isDeleted parameter
        _selectedClassification = Classification(
          id: account.classificationId!,
          name: 'Loading...', 
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
          isDeleted: false, // <--- The Missing Argument
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _initialBalanceController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() { _isLoading = true; });
      try {
        final name = _nameController.text;
        final initialBalanceDouble =
            double.tryParse(_initialBalanceController.text) ?? 0.0;
        final phoneNumber = _phoneNumberController.text.isNotEmpty
            ? _phoneNumberController.text
            : null;
        final classificationId = _selectedClassification?.id;

        if (widget.accountToEdit == null) {
          // Create handles conversion inside the repository
          await ref.read(accountsRepositoryProvider).createAccount(
            name: name,
            type: _selectedAccountType,
            initialBalance: initialBalanceDouble,
            phoneNumber: phoneNumber,
            classificationId: classificationId,
          );
        } else {
          // FIX: Convert Double to Int (Cents) for copyWith
          final int balanceCents = (initialBalanceDouble * 100).round();

          final updatedAccount = widget.accountToEdit!.copyWith(
            name: name,
            type: _selectedAccountType,
            initialBalance: balanceCents, // Pass Int
            phoneNumber: d.Value(phoneNumber),
            classificationId: d.Value(classificationId),
          );
          await ref
              .read(accountsRepositoryProvider)
              .updateAccount(updatedAccount);
        }
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        setState(() { _isLoading = false; });
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

  @override
  Widget build(BuildContext context) {
    final classificationsAsync = ref.watch(classificationsStreamProvider);
    final translatedAccountTypes = _getTranslatedAccountTypes(l10n);

    if (widget.accountToEdit != null &&
        _selectedClassification?.name == 'Loading...') {
      _selectedClassification = _selectedClassification?.copyWith(name: l10n.loading);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.accountToEdit == null
            ? l10n.addNewAccount
            : l10n.editAccount),
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
              DropdownButtonFormField<String>(
                value: _selectedAccountType,
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
              classificationsAsync.when(
                data: (classifications) {
                  Classification? initialSelection;
                  if (widget.accountToEdit != null &&
                      _selectedClassification != null) {
                    try {
                      initialSelection = classifications.firstWhere(
                            (c) => c.id == _selectedClassification!.id,
                      );
                    } catch (e) {
                      initialSelection = null;
                    }
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted &&
                          _selectedClassification != initialSelection) {
                        setState(() {
                          _selectedClassification = initialSelection;
                        });
                      }
                    });
                  }

                  return DropdownButtonFormField<Classification>(
                    value: _selectedClassification,
                    hint: Text(l10n.classificationOptional),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: classifications
                        .map((Classification cls) {
                      return DropdownMenuItem<Classification>(
                        value: cls,
                        child: Text(cls.name),
                      );
                    }).toList(),
                    onChanged: (Classification? newValue) {
                      setState(() {
                        _selectedClassification = newValue;
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
              TextFormField(
                controller: _initialBalanceController,
                decoration: InputDecoration(
                  labelText: l10n.initialBalance,
                  border: const OutlineInputBorder(),
                ),
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}')),
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
            ],
          ),
        ),
      ),
    );
  }
}