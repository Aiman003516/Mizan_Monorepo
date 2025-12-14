import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';
import 'package:drift/drift.dart' hide Column;

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

  bool _isLoading = false;
  bool _isEdit = false;

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
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Customer updated' : 'Customer created'),
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
        title: Text(_isEdit ? 'Edit Customer' : 'New Customer'),
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
                : const Text('Save'),
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
                      decoration: const InputDecoration(
                        labelText: 'Customer Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter customer name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    // Phone
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // Address
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // Tax ID / VAT
                    TextFormField(
                      controller: _taxIdController,
                      decoration: const InputDecoration(
                        labelText: 'Tax ID / VAT Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.receipt_long),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Credit Limit
                    TextFormField(
                      controller: _creditLimitController,
                      decoration: const InputDecoration(
                        labelText: 'Credit Limit',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.credit_card),
                        prefixText: '\$ ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
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
                          _isEdit ? 'Update Customer' : 'Create Customer',
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
