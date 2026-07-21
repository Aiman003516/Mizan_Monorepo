import 'package:flutter/material.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';

/// 📝 Customer Form Screen
/// Add or edit a customer.
class CustomerFormScreen extends ConsumerStatefulWidget {
  final String? customerId; // null for new customer

  const CustomerFormScreen({super.key, this.customerId});

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _notesController = TextEditingController();
  final _openingBalanceController = TextEditingController();
  bool _isDebit = true;

  bool _isLoading = false;
  bool _isEdit = false;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.customerId != null;
    if (_isEdit) {
      _loadCustomer();
    }
  }

  Future<void> _loadCustomer() async {
    setState(() => _isLoading = true);
    try {
      final arRepo = ref.read(arRepositoryProvider);
      final customer = await arRepo.getCustomer(widget.customerId!);
      if (customer != null && mounted) {
        _nameController.text = customer.name;
        _emailController.text = customer.email ?? '';
        _phoneController.text = customer.phone ?? '';
        _addressController.text = customer.address ?? '';
        _taxIdController.text = customer.taxId ?? '';
        _creditLimitController.text = (customer.creditLimit / 100).toString();
        _notesController.text = customer.notes ?? '';
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _taxIdController.dispose();
    _creditLimitController.dispose();
    _openingBalanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final arRepo = ref.read(arRepositoryProvider);
      final creditLimit = double.tryParse(_creditLimitController.text) ?? 0;

      if (_isEdit) {
        await arRepo.updateCustomer(
          widget.customerId!,
          CustomersCompanion(
            name: Value(_nameController.text.trim()),
            email: Value(
              _emailController.text.trim().isNotEmpty
                  ? _emailController.text.trim()
                  : null,
            ),
            phone: Value(
              _phoneController.text.trim().isNotEmpty
                  ? _phoneController.text.trim()
                  : null,
            ),
            address: Value(
              _addressController.text.trim().isNotEmpty
                  ? _addressController.text.trim()
                  : null,
            ),
            taxId: Value(
              _taxIdController.text.trim().isNotEmpty
                  ? _taxIdController.text.trim()
                  : null,
            ),
            creditLimit: Value((creditLimit * 100).round()),
            notes: Value(
              _notesController.text.trim().isNotEmpty
                  ? _notesController.text.trim()
                  : null,
            ),
          ),
        );
      } else {
        final openingBalance =
            double.tryParse(_openingBalanceController.text) ?? 0;
        await arRepo.createCustomer(
          name: _nameController.text.trim(),
          email: _emailController.text.trim().isNotEmpty
              ? _emailController.text.trim()
              : null,
          phone: _phoneController.text.trim().isNotEmpty
              ? _phoneController.text.trim()
              : null,
          address: _addressController.text.trim().isNotEmpty
              ? _addressController.text.trim()
              : null,
          taxId: _taxIdController.text.trim().isNotEmpty
              ? _taxIdController.text.trim()
              : null,
          creditLimit: (creditLimit * 100).round(),
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          openingBalance: (openingBalance * 100).round() * (_isDebit ? 1 : -1),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? l10n.customerUpdated : l10n.customerCreated),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.editCustomer : l10n.newCustomer),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.saving),
          ),
        ],
      ),
      body: _isLoading && _isEdit
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Name (Required)
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: '${l10n.customerName} *',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.requiredField;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: l10n.emailOptional,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    // Phone
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: l10n.phoneOptional,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // Address
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: l10n.addressOptional,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.location_on),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // Tax ID / VAT
                    TextFormField(
                      controller: _taxIdController,
                      decoration: InputDecoration(
                        labelText: l10n.taxIdOptional,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.receipt_long),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (!_isEdit) ...[
                      // Opening Balance Toggle
                      Row(
                        children: [
                          Expanded(
                            child: SegmentedButton<bool>(
                              segments: [
                                ButtonSegment(
                                  value: true,
                                  label: Text(l10n.debit),
                                  icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                ),
                                ButtonSegment(
                                  value: false,
                                  label: Text(l10n.credit),
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                ),
                              ],
                              selected: {_isDebit},
                              onSelectionChanged: (Set<bool> newSelection) {
                                setState(() {
                                  _isDebit = newSelection.first;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Opening Balance
                      TextFormField(
                        controller: _openingBalanceController,
                        decoration: InputDecoration(
                          labelText: l10n.openingBalanceHint,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.account_balance_wallet),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.requiredField;
                          }
                          if (double.tryParse(value) == null) {
                            return l10n.requiredField;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Credit Limit
                    TextFormField(
                      controller: _creditLimitController,
                      decoration: InputDecoration(
                        labelText: l10n.creditLimitOptional,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.credit_card),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: l10n.notesOptional,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.note),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    FilledButton(
                      onPressed: _isLoading ? null : _save,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _isEdit ? l10n.editCustomer : l10n.newCustomer,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
