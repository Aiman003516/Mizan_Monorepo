import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:core_database/core_database.dart';
import 'package:feature_settings/src/data/currencies_repository.dart';
import 'package:feature_settings/src/presentation/currency_controller.dart';
import 'package:core_data/core_data.dart'; // Import for defaultCurrencyProvider

class CurrencySettingsScreen extends ConsumerStatefulWidget {
  const CurrencySettingsScreen({super.key});

  @override
  ConsumerState<CurrencySettingsScreen> createState() =>
      _CurrencySettingsScreenState();
}

class _CurrencySettingsScreenState
    extends ConsumerState<CurrencySettingsScreen> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _symbolController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _symbolController.dispose();
    super.dispose();
  }

  void _showAddCurrencyDialog() {
    _codeController.clear();
    _nameController.clear();
    _symbolController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.addNewCurrency),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: l10n.currencyCodeHint,
                    helperText: l10n.currencyCodeHelper,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.pleaseEnterCode;
                    }
                    if (value.length > 5) return l10n.codeTooLong;
                    return null;
                  },
                ),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: l10n.currencyNameHint),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.pleaseEnterCurrencyName;
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _symbolController,
                  decoration: InputDecoration(labelText: l10n.currencySymbolHint),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text(l10n.cancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
            FilledButton(
              child: Text(l10n.save),
              onPressed: () async {
                if (_formKey.currentState?.validate() ?? false) {
                  try {
                    await ref
                        .read(currenciesRepositoryProvider)
                        .createCurrency(
                      code: _codeController.text.trim().toUpperCase(),
                      name: _nameController.text.trim(),
                      symbol: _symbolController.text.trim().isNotEmpty
                          ? _symbolController.text.trim()
                          : null,
                    );
                    if (mounted) Navigator.of(context).pop();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${l10n.failedToSave} $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currenciesAsync = ref.watch(currenciesStreamProvider);
    final defaultCurrencyCode = ref.watch(defaultCurrencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.currencyOptions),
      ),
      body: currenciesAsync.when(
        data: (currencies) {
          if (currencies.isEmpty) {
            return Center(
              child: Text(l10n.noCurrenciesFound),
            );
          }
          return ListView.builder(
            itemCount: currencies.length,
            itemBuilder: (context, index) {
              final currency = currencies[index];
              return RadioListTile<String>(
                title: Text(currency.name),
                subtitle: Text(
                  '${l10n.codeLabel} ${currency.code}${currency.symbol != null ? " (${currency.symbol})" : ""}',
                ),
                value: currency.code,
                groupValue: defaultCurrencyCode,
                onChanged: (String? newCode) {
                  if (newCode != null) {
                    ref
                        .read(defaultCurrencyProvider.notifier)
                        .setCurrency(newCode); // Use correct method name
                  }
                },
                secondary:
                defaultCurrencyCode == currency.code
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
              );
            },
          );
        },
        error: (err, stack) => Center(child: Text('${l10n.error} ${err.toString()}')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCurrencyDialog,
        tooltip: l10n.addNewCurrency,
        child: const Icon(Icons.add),
      ),
    );
  }
}