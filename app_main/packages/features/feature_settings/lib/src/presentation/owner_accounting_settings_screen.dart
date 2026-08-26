import 'package:core_l10n/app_localizations.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/owner_control_center_contract.dart';
import '../data/owner_control_center_repository.dart';

class OwnerAccountingSettingsScreen extends ConsumerStatefulWidget {
  const OwnerAccountingSettingsScreen({super.key});

  @override
  ConsumerState<OwnerAccountingSettingsScreen> createState() =>
      _OwnerAccountingSettingsScreenState();
}

class _OwnerAccountingSettingsScreenState
    extends ConsumerState<OwnerAccountingSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _taxCodeController = TextEditingController();
  final _invoicePrefixController = TextEditingController();
  final _billPrefixController = TextEditingController();
  final _receiptPrefixController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  final _billNumberController = TextEditingController();
  final _receiptNumberController = TextEditingController();

  String _currency = 'USD';
  String _roundingMode = 'half_up';
  String _exchangeRateSource = 'manual';
  String _taxPeriod = 'monthly';
  Set<String> _enabledCurrencies = {'USD'};
  bool _periodCloseRequiresOwner = true;
  bool _manualRateRequiresOwner = true;
  bool _revaluationEnabled = false;
  bool _taxInclusive = false;
  bool _taxNumberRequired = false;
  bool _isSaving = false;

  static const _currencyCodes = ['USD', 'SAR', 'YER', 'EUR', 'AED'];

  @override
  void initState() {
    super.initState();
    final settings = ref.read(ownerControlSettingsProvider);
    final accounting = settings.section(OwnerSettingSections.accounting);
    final currencies = settings.section(OwnerSettingSections.currencies);
    final taxes = settings.section(OwnerSettingSections.taxes);
    final documents = settings.section(OwnerSettingSections.documents);

    _currency = accounting['base_currency_code'] as String? ?? 'USD';
    _roundingMode = accounting['rounding_mode'] as String? ?? 'half_up';
    _periodCloseRequiresOwner =
        accounting['period_close_requires_owner'] as bool? ?? true;
    _exchangeRateSource =
        currencies['exchange_rate_source'] as String? ?? 'manual';
    _manualRateRequiresOwner =
        currencies['manual_rate_requires_owner'] as bool? ?? true;
    _revaluationEnabled = currencies['revaluation_enabled'] as bool? ?? false;
    final enabled = currencies['enabled_currency_codes'];
    if (enabled is List && enabled.whereType<String>().isNotEmpty) {
      _enabledCurrencies = enabled.whereType<String>().toSet();
    }
    _taxCodeController.text = taxes['default_tax_code'] as String? ?? '';
    _taxPeriod = taxes['tax_period'] as String? ?? 'monthly';
    _taxInclusive = taxes['tax_inclusive_pricing'] as bool? ?? false;
    _taxNumberRequired = taxes['tax_number_required'] as bool? ?? false;
    _invoicePrefixController.text =
        documents['invoice_prefix'] as String? ?? 'INV-';
    _billPrefixController.text = documents['bill_prefix'] as String? ?? 'BILL-';
    _receiptPrefixController.text =
        documents['receipt_prefix'] as String? ?? 'REC-';
    _invoiceNumberController.text =
        '${documents['invoice_next_number'] as int? ?? 1}';
    _billNumberController.text =
        '${documents['bill_next_number'] as int? ?? 1}';
    _receiptNumberController.text =
        '${documents['receipt_next_number'] as int? ?? 1}';
  }

  @override
  void dispose() {
    _taxCodeController.dispose();
    _invoicePrefixController.dispose();
    _billPrefixController.dispose();
    _receiptPrefixController.dispose();
    _invoiceNumberController.dispose();
    _billNumberController.dispose();
    _receiptNumberController.dispose();
    super.dispose();
  }

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_enabledCurrencies.isEmpty) {
      _showError(l10n.settingsInvalid);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final controller = ref.read(ownerControlSettingsProvider.notifier);
      await controller.saveSection(OwnerSettingSections.accounting, {
        'base_currency_code': _currency,
        'rounding_mode': _roundingMode,
        'period_close_requires_owner': _periodCloseRequiresOwner,
        'opening_balance_status': 'not_started',
      });
      await controller.saveSection(OwnerSettingSections.currencies, {
        'enabled_currency_codes': _enabledCurrencies.toList()..sort(),
        'exchange_rate_source': _exchangeRateSource,
        'manual_rate_requires_owner': _manualRateRequiresOwner,
        'rate_effective_date_policy': 'effective_date_required',
        'revaluation_enabled': _revaluationEnabled,
      });
      await controller.saveSection(OwnerSettingSections.taxes, {
        'default_tax_code': _taxCodeController.text.trim(),
        'tax_inclusive_pricing': _taxInclusive,
        'tax_number_required': _taxNumberRequired,
        'tax_exempt_reasons': const <String>[],
        'tax_period': _taxPeriod,
      });
      await controller.saveSection(OwnerSettingSections.documents, {
        'invoice_prefix': _invoicePrefixController.text.trim(),
        'invoice_next_number': int.parse(_invoiceNumberController.text),
        'bill_prefix': _billPrefixController.text.trim(),
        'bill_next_number': int.parse(_billNumberController.text),
        'receipt_prefix': _receiptPrefixController.text.trim(),
        'receipt_next_number': int.parse(_receiptNumberController.text),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.settingsSaved),
          backgroundColor: context.appColors.success,
        ),
      );
    } catch (error) {
      if (mounted) _showError('${l10n.error} $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: context.appColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountingAndPeriods),
        actions: [
          IconButton(
            tooltip: l10n.saveSettings,
            onPressed: _isSaving ? null : _save,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionCard(
              title: l10n.accountingAndPeriods,
              icon: Icons.account_balance,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _currency,
                  decoration: InputDecoration(
                    labelText: l10n.selectCurrency,
                    prefixIcon: const Icon(Icons.currency_exchange),
                  ),
                  items: _currencyCodes
                      .map(
                        (code) =>
                            DropdownMenuItem(value: code, child: Text(code)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _currency = value;
                      _enabledCurrencies.add(value);
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _roundingMode,
                  decoration: InputDecoration(
                    labelText: l10n.roundingMode,
                    prefixIcon: const Icon(Icons.tune),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'half_up',
                      child: Text(l10n.roundingHalfUp),
                    ),
                    DropdownMenuItem(
                      value: 'bankers',
                      child: Text(l10n.roundingBankers),
                    ),
                  ],
                  onChanged: (value) => setState(() => _roundingMode = value!),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.periodCloseRequiresOwner),
                  value: _periodCloseRequiresOwner,
                  onChanged: (value) =>
                      setState(() => _periodCloseRequiresOwner = value),
                ),
              ],
            ),
            _sectionCard(
              title: l10n.currenciesAndExchangeRates,
              icon: Icons.currency_exchange,
              children: [
                Text(l10n.enabledCurrencies),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _currencyCodes.map((code) {
                    final selected = _enabledCurrencies.contains(code);
                    return FilterChip(
                      label: Text(code),
                      selected: selected,
                      onSelected: (value) {
                        if (code == _currency) return;
                        setState(() {
                          if (value) {
                            _enabledCurrencies.add(code);
                          } else {
                            _enabledCurrencies.remove(code);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _exchangeRateSource,
                  decoration: InputDecoration(
                    labelText: l10n.exchangeRateSource,
                    prefixIcon: const Icon(Icons.swap_horiz),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'manual',
                      child: Text(l10n.exchangeRateManual),
                    ),
                    DropdownMenuItem(
                      value: 'provider',
                      child: Text(l10n.exchangeRateProvider),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _exchangeRateSource = value!),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.manualRateRequiresOwner),
                  value: _manualRateRequiresOwner,
                  onChanged: (value) =>
                      setState(() => _manualRateRequiresOwner = value),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.revaluationEnabled),
                  value: _revaluationEnabled,
                  onChanged: (value) =>
                      setState(() => _revaluationEnabled = value),
                ),
              ],
            ),
            _sectionCard(
              title: l10n.taxSettings,
              icon: Icons.receipt_long,
              children: [
                TextFormField(
                  controller: _taxCodeController,
                  decoration: InputDecoration(
                    labelText: l10n.defaultTaxCode,
                    prefixIcon: const Icon(Icons.percent),
                  ),
                  maxLength: 32,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _taxPeriod,
                  decoration: InputDecoration(
                    labelText: l10n.taxPeriod,
                    prefixIcon: const Icon(Icons.date_range),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'monthly',
                      child: Text(l10n.taxPeriodMonthly),
                    ),
                    DropdownMenuItem(
                      value: 'quarterly',
                      child: Text(l10n.taxPeriodQuarterly),
                    ),
                    DropdownMenuItem(
                      value: 'annual',
                      child: Text(l10n.taxPeriodAnnual),
                    ),
                  ],
                  onChanged: (value) => setState(() => _taxPeriod = value!),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.taxInclusivePricing),
                  value: _taxInclusive,
                  onChanged: (value) => setState(() => _taxInclusive = value),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.taxNumberRequired),
                  value: _taxNumberRequired,
                  onChanged: (value) =>
                      setState(() => _taxNumberRequired = value),
                ),
              ],
            ),
            _sectionCard(
              title: l10n.documentsAndNumbering,
              icon: Icons.format_list_numbered,
              children: [
                _numberingRow(
                  l10n.invoices,
                  _invoicePrefixController,
                  _invoiceNumberController,
                ),
                _numberingRow(
                  l10n.bills,
                  _billPrefixController,
                  _billNumberController,
                ),
                _numberingRow(
                  l10n.printReceipt,
                  _receiptPrefixController,
                  _receiptNumberController,
                ),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(l10n.saveSettings),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: context.appColors.primary),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _numberingRow(
    String title,
    TextEditingController prefix,
    TextEditingController nextNumber,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: prefix,
              decoration: InputDecoration(
                labelText: '$title ${l10n.documentPrefix}',
              ),
              maxLength: 12,
              validator: (value) => value == null || value.trim().isEmpty
                  ? l10n.requiredField
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: nextNumber,
              decoration: InputDecoration(labelText: l10n.nextNumber),
              keyboardType: TextInputType.number,
              validator: (value) {
                final number = int.tryParse(value?.trim() ?? '');
                return number == null || number < 1 ? l10n.invalidNumber : null;
              },
            ),
          ),
        ],
      ),
    );
  }
}
