import 'package:flutter/material.dart';
import 'package:core_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';

/// 📝 Vendor Form Screen
class VendorFormScreen extends ConsumerStatefulWidget {
  final String? vendorId;
  const VendorFormScreen({super.key, this.vendorId});

  @override
  ConsumerState<VendorFormScreen> createState() => _VendorFormScreenState();
}

class _VendorFormScreenState extends ConsumerState<VendorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _paymentTermsController = TextEditingController();
  final _openingBalanceController = TextEditingController(); // 🟢 NEW
  final _notesController = TextEditingController();
  bool _isCredit = true;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  bool _isLoading = false;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.vendorId != null;
    if (_isEdit) _loadVendor();
  }

  Future<void> _loadVendor() async {
    setState(() => _isLoading = true);
    try {
      final apRepo = ref.read(apRepositoryProvider);
      final vendor = await apRepo.getVendor(widget.vendorId!);
      if (vendor != null && mounted) {
        _nameController.text = vendor.name;
        _emailController.text = vendor.email ?? '';
        _phoneController.text = vendor.phone ?? '';
        _addressController.text = vendor.address ?? '';
        _taxIdController.text = vendor.taxId ?? '';
        _paymentTermsController.text = vendor.paymentTerms ?? '';
        _notesController.text = vendor.notes ?? '';
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
    _paymentTermsController.dispose();
    _openingBalanceController.dispose(); // 🟢 NEW
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final apRepo = ref.read(apRepositoryProvider);
      if (_isEdit) {
        await apRepo.updateVendor(
          widget.vendorId!,
          VendorsCompanion(
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
            paymentTerms: Value(
              _paymentTermsController.text.trim().isNotEmpty
                  ? _paymentTermsController.text.trim()
                  : null,
            ),
            notes: Value(
              _notesController.text.trim().isNotEmpty
                  ? _notesController.text.trim()
                  : null,
            ),
          ),
        );
      } else {
        final openingBalance = double.tryParse(_openingBalanceController.text) ?? 0;
        await apRepo.createVendor(
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
          paymentTerms: _paymentTermsController.text.trim().isNotEmpty
              ? _paymentTermsController.text.trim()
              : null,
          openingBalance: (openingBalance * 100).round() * (_isCredit ? 1 : -1), // 🟢 NEW
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? l10n.vendorUpdated : l10n.vendorCreated),
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
        title: Text(_isEdit ? l10n.editVendor : l10n.newVendor),
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
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: '${l10n.vendorName} *',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.business),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? l10n.requiredField : null,
                    ),
                    const SizedBox(height: 16),
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
                      // 🟢 NEW: Opening Balance Toggle
                      Row(
                        children: [
                          Expanded(
                            child: SegmentedButton<bool>(
                              segments: [
                                ButtonSegment(
                                  value: true,
                                  label: Text(l10n.credit),
                                  icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                ),
                                ButtonSegment(
                                  value: false,
                                  label: Text(l10n.debit),
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                ),
                              ],
                              selected: {_isCredit},
                              onSelectionChanged: (Set<bool> newSelection) {
                                setState(() {
                                  _isCredit = newSelection.first;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 🟢 NEW: Opening Balance Field
                      TextFormField(
                        controller: _openingBalanceController,
                        decoration: InputDecoration(
                          labelText: l10n.openingBalanceHintVendor,
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
                    TextFormField(
                      controller: _paymentTermsController,
                      decoration: InputDecoration(
                        labelText: l10n.paymentTermsOptional,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.schedule),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                    FilledButton(
                      onPressed: _isLoading ? null : _save,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _isEdit ? l10n.editVendor : l10n.newVendor,
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
